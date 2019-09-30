//----------------------------------------------------------------------------
// Copyright (C) 2009 , Olivier Girard
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above copyright
//       notice, this list of conditions and the following disclaimer in the
//       documentation and/or other materials provided with the distribution.
//     * Neither the name of the authors nor the names of its contributors
//       may be used to endorse or promote products derived from this software
//       without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
// OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
// THE POSSIBILITY OF SUCH DAMAGE
//
//----------------------------------------------------------------------------
//
// *File Name: omsp_dbg_hwbrk.v
//
// *Module Description:
//                       Hardware Breakpoint / Watchpoint module
//
// *Author(s):
//              - Olivier Girard,    olgirard@gmail.com
//

`include "openMSP430_defines.v"

module  omsp_dbg_hwbrk (
  // OUTPUTs
  //========
  output         brk_halt,     // Hardware breakpoint command
  output         brk_pnd,      // Hardware break/watch-point pending
  output  [15:0] brk_dout,     // Hardware break/watch-point register data input

  // INPUTs
  //=======
  input    [3:0] brk_reg_rd,   // Hardware break/watch-point register read select
  input    [3:0] brk_reg_wr,   // Hardware break/watch-point register write select
  input          dbg_clk,      // Debug unit clock
  input   [15:0] dbg_din,      // Debug register data input
  input          dbg_rst,      // Debug unit reset
  input          decode_noirq, // Frontend decode instruction
  input   [15:0] eu_mab,       // Execution-Unit Memory address bus
  input          eu_mb_en,     // Execution-Unit Memory bus enable
  input    [1:0] eu_mb_wr,     // Execution-Unit Memory bus write transfer
  input   [15:0] pc            // Program counter
);
  //=============================================================================
  // 1)  WIRE & PARAMETER DECLARATION
  //=============================================================================

  wire      range_wr_set;
  wire      range_rd_set;
  wire      addr1_wr_set;
  wire      addr1_rd_set;
  wire      addr0_wr_set;
  wire      addr0_rd_set;

  parameter BRK_CTL   = 0,
            BRK_STAT  = 1,
            BRK_ADDR0 = 2,
            BRK_ADDR1 = 3;

  //=============================================================================
  // 2)  CONFIGURATION REGISTERS
  //=============================================================================

  // BRK_CTL Register
  //-----------------------------------------------------------------------------
  //       7   6   5        4            3          2            1  0
  //        Reserved    RANGE_MODE    INST_EN    BREAK_EN    ACCESS_MODE
  //
  // ACCESS_MODE: - 00 : Disabled
  //              - 01 : Detect read access
  //              - 10 : Detect write access
  //              - 11 : Detect read/write access
  //              NOTE: '10' & '11' modes are not supported on the instruction flow
  //
  // BREAK_EN:    -  0 : Watchmode enable
  //              -  1 : Break enable
  //
  // INST_EN:     -  0 : Checks are done on the execution unit (data flow)
  //              -  1 : Checks are done on the frontend (instruction flow)
  //
  // RANGE_MODE:  -  0 : Address match on BRK_ADDR0 or BRK_ADDR1
  //              -  1 : Address match on BRK_ADDR0->BRK_ADDR1 range
  //
  //-----------------------------------------------------------------------------

  reg   [4:0] brk_ctl;

  wire        brk_ctl_wr;

  wire  [7:0] brk_ctl_full;

  // BRK_STAT Register
  //-----------------------------------------------------------------------------
  //     7    6       5         4         3         2         1         0
  //    Reserved  RANGE_WR  RANGE_RD  ADDR1_WR  ADDR1_RD  ADDR0_WR  ADDR0_RD
  //-----------------------------------------------------------------------------
  reg   [5:0] brk_stat;

  wire        brk_stat_wr;
  wire  [5:0] brk_stat_set;
  wire  [5:0] brk_stat_clr;

  wire  [7:0] brk_stat_full;
  wire        brk_pnd;

  // BRK_ADDR0 Register
  //-------------------
  reg  [15:0] brk_addr0;

  wire        brk_addr0_wr;

  // BRK_ADDR1/DATA0 Register
  //-------------------------
  reg  [15:0] brk_addr1;

  wire        brk_addr1_wr;

  //============================================================================
  // 3) DATA OUTPUT GENERATION
  //============================================================================

  wire [15:0] brk_ctl_rd;
  wire [15:0] brk_stat_rd;
  wire [15:0] brk_addr0_rd;
  wire [15:0] brk_addr1_rd;

  wire [15:0] brk_dout;

  //============================================================================
  // 4) BREAKPOINT / WATCHPOINT GENERATION
  //============================================================================

  // Comparators
  //------------
  // Note: here the comparison logic is instanciated several times in order
  //       to improve the timings, at the cost of a bit more area.

  wire        equ_d_addr0;
  wire        equ_d_addr1;
  wire        equ_d_range;

  wire        equ_i_addr0;
  wire        equ_i_addr1;
  wire        equ_i_range;

  // Detect accesses
  //----------------

  // Detect Instruction read access
  wire i_addr0_rd;
  wire i_addr1_rd;
  wire i_range_rd;

  // Detect Execution-Unit write access
  wire d_addr0_wr;
  wire d_addr1_wr;
  wire d_range_wr;

  // Detect DATA read access
  wire d_addr0_rd;
  wire d_addr1_rd;
  wire d_range_rd;

  //=============================================================================
  // 2)  CONFIGURATION REGISTERS
  //=============================================================================

  // BRK_CTL Register
  //-----------------------------------------------------------------------------
  //       7   6   5        4            3          2            1  0
  //        Reserved    RANGE_MODE    INST_EN    BREAK_EN    ACCESS_MODE
  //
  // ACCESS_MODE: - 00 : Disabled
  //              - 01 : Detect read access
  //              - 10 : Detect write access
  //              - 11 : Detect read/write access
  //              NOTE: '10' & '11' modes are not supported on the instruction flow
  //
  // BREAK_EN:    -  0 : Watchmode enable
  //              -  1 : Break enable
  //
  // INST_EN:     -  0 : Checks are done on the execution unit (data flow)
  //              -  1 : Checks are done on the frontend (instruction flow)
  //
  // RANGE_MODE:  -  0 : Address match on BRK_ADDR0 or BRK_ADDR1
  //              -  1 : Address match on BRK_ADDR0->BRK_ADDR1 range
  //
  //-----------------------------------------------------------------------------

  assign      brk_ctl_wr = brk_reg_wr[BRK_CTL];

  always @ (posedge dbg_clk or posedge dbg_rst) begin
    if (dbg_rst)         brk_ctl <=  5'h00;
    else if (brk_ctl_wr) brk_ctl <=  {`HWBRK_RANGE & dbg_din[4], dbg_din[3:0]};
  end

  assign      brk_ctl_full = {3'b000, brk_ctl};

  // BRK_STAT Register
  //-----------------------------------------------------------------------------
  //     7    6       5         4         3         2         1         0
  //    Reserved  RANGE_WR  RANGE_RD  ADDR1_WR  ADDR1_RD  ADDR0_WR  ADDR0_RD
  //-----------------------------------------------------------------------------
  assign      brk_stat_wr  = brk_reg_wr[BRK_STAT];
  assign      brk_stat_set = {range_wr_set & `HWBRK_RANGE,
                              range_rd_set & `HWBRK_RANGE,
                              addr1_wr_set, addr1_rd_set,
                              addr0_wr_set, addr0_rd_set};
  assign      brk_stat_clr = ~dbg_din[5:0];

  always @ (posedge dbg_clk or posedge dbg_rst) begin
    if (dbg_rst)          brk_stat <=  6'h00;
    else if (brk_stat_wr) brk_stat <= ((brk_stat & brk_stat_clr) | brk_stat_set);
    else                  brk_stat <=  (brk_stat                 | brk_stat_set);
  end

  assign      brk_stat_full = {2'b00, brk_stat};
  assign      brk_pnd       = |brk_stat;

  // BRK_ADDR0 Register
  //-------------------
  assign      brk_addr0_wr = brk_reg_wr[BRK_ADDR0];

  always @ (posedge dbg_clk or posedge dbg_rst) begin
    if (dbg_rst)           brk_addr0 <=  16'h0000;
    else if (brk_addr0_wr) brk_addr0 <=  dbg_din;
  end

  // BRK_ADDR1/DATA0 Register
  //-------------------------
  assign      brk_addr1_wr = brk_reg_wr[BRK_ADDR1];

  always @ (posedge dbg_clk or posedge dbg_rst) begin
    if (dbg_rst)           brk_addr1 <=  16'h0000;
    else if (brk_addr1_wr) brk_addr1 <=  dbg_din;
  end

  //============================================================================
  // 3) DATA OUTPUT GENERATION
  //============================================================================

  assign      brk_ctl_rd   = {8'h00, brk_ctl_full}  & {16{brk_reg_rd[BRK_CTL]}};
  assign      brk_stat_rd  = {8'h00, brk_stat_full} & {16{brk_reg_rd[BRK_STAT]}};
  assign      brk_addr0_rd = brk_addr0              & {16{brk_reg_rd[BRK_ADDR0]}};
  assign      brk_addr1_rd = brk_addr1              & {16{brk_reg_rd[BRK_ADDR1]}};

  assign      brk_dout = brk_ctl_rd   |
                         brk_stat_rd  |
                         brk_addr0_rd |
                         brk_addr1_rd;

  //============================================================================
  // 4) BREAKPOINT / WATCHPOINT GENERATION
  //============================================================================

  // Comparators
  //------------
  // Note: here the comparison logic is instanciated several times in order
  //       to improve the timings, at the cost of a bit more area.

  assign      equ_d_addr0 = eu_mb_en & (eu_mab==brk_addr0) & ~brk_ctl[`BRK_RANGE];
  assign      equ_d_addr1 = eu_mb_en & (eu_mab==brk_addr1) & ~brk_ctl[`BRK_RANGE];
  assign      equ_d_range = eu_mb_en & ((eu_mab>=brk_addr0) & (eu_mab<=brk_addr1)) &
                                                              brk_ctl[`BRK_RANGE] & `HWBRK_RANGE;

  assign      equ_i_addr0 = decode_noirq & (pc==brk_addr0) & ~brk_ctl[`BRK_RANGE];
  assign      equ_i_addr1 = decode_noirq & (pc==brk_addr1) & ~brk_ctl[`BRK_RANGE];
  assign      equ_i_range = decode_noirq & ((pc>=brk_addr0) & (pc<=brk_addr1)) &
                                                              brk_ctl[`BRK_RANGE] & `HWBRK_RANGE;

  // Detect accesses
  //----------------

  // Detect Instruction read access
  assign i_addr0_rd =  equ_i_addr0 &  brk_ctl[`BRK_I_EN];
  assign i_addr1_rd =  equ_i_addr1 &  brk_ctl[`BRK_I_EN];
  assign i_range_rd =  equ_i_range &  brk_ctl[`BRK_I_EN];

  // Detect Execution-Unit write access
  assign d_addr0_wr =  equ_d_addr0 & ~brk_ctl[`BRK_I_EN] &  |eu_mb_wr;
  assign d_addr1_wr =  equ_d_addr1 & ~brk_ctl[`BRK_I_EN] &  |eu_mb_wr;
  assign d_range_wr =  equ_d_range & ~brk_ctl[`BRK_I_EN] &  |eu_mb_wr;

  // Detect DATA read access
  assign d_addr0_rd =  equ_d_addr0 & ~brk_ctl[`BRK_I_EN] & ~|eu_mb_wr;
  assign d_addr1_rd =  equ_d_addr1 & ~brk_ctl[`BRK_I_EN] & ~|eu_mb_wr;
  assign d_range_rd =  equ_d_range & ~brk_ctl[`BRK_I_EN] & ~|eu_mb_wr;

  // Set flags
  assign addr0_rd_set = brk_ctl[`BRK_MODE_RD] & (d_addr0_rd  | i_addr0_rd);
  assign addr0_wr_set = brk_ctl[`BRK_MODE_WR] &  d_addr0_wr;
  assign addr1_rd_set = brk_ctl[`BRK_MODE_RD] & (d_addr1_rd  | i_addr1_rd);
  assign addr1_wr_set = brk_ctl[`BRK_MODE_WR] &  d_addr1_wr;
  assign range_rd_set = brk_ctl[`BRK_MODE_RD] & (d_range_rd  | i_range_rd);
  assign range_wr_set = brk_ctl[`BRK_MODE_WR] &  d_range_wr;

  // Break CPU
  assign brk_halt     = brk_ctl[`BRK_EN] & |brk_stat_set;
endmodule // omsp_dbg_hwbrk
