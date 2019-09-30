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
// *File Name: omsp_multiplier.v
//
// *Module Description:
//                       16x16 Hardware multiplier.
//
// *Author(s):
//              - Olivier Girard,    olgirard@gmail.com
//

`include "openMSP430_defines.v"

module  omsp_multiplier (
  // OUTPUTs
  //========
  output       [15:0] per_dout,       // Peripheral data output

  // INPUTs
  //=======
  input               mclk,           // Main system clock
  input        [13:0] per_addr,       // Peripheral address
  input        [15:0] per_din,        // Peripheral data input
  input               per_en,         // Peripheral enable (high active)
  input         [1:0] per_we,         // Peripheral write enable (high active)
  input               puc_rst,        // Main system reset
  input               scan_enable     // Scan enable (active during scan shifting)
);
  //=============================================================================
  // 1)  PARAMETER/REGISTERS & WIRE DECLARATION
  //=============================================================================

  // Register base address (must be aligned to decoder bit width)
  parameter       [14:0] BASE_ADDR   = 15'h0130;

  // Decoder bit width (defines how many bits are considered for address decoding)
  parameter              DEC_WD      =  4;

  // Register addresses offset
  parameter [DEC_WD-1:0] OP1_MPY     = 'h0,
                         OP1_MPYS    = 'h2,
                         OP1_MAC     = 'h4,
                         OP1_MACS    = 'h6,
                         OP2         = 'h8,
                         RESLO       = 'hA,
                         RESHI       = 'hC,
                         SUMEXT      = 'hE;

  // Register one-hot decoder utilities
  parameter              DEC_SZ      =  (1 << DEC_WD);
  parameter [DEC_SZ-1:0] BASE_REG    =  {{DEC_SZ-1{1'b0}}, 1'b1};

  // Register one-hot decoder
  parameter [DEC_SZ-1:0] OP1_MPY_D   = (BASE_REG << OP1_MPY),
                         OP1_MPYS_D  = (BASE_REG << OP1_MPYS),
                         OP1_MAC_D   = (BASE_REG << OP1_MAC),
                         OP1_MACS_D  = (BASE_REG << OP1_MACS),
                         OP2_D       = (BASE_REG << OP2),
                         RESLO_D     = (BASE_REG << RESLO),
                         RESHI_D     = (BASE_REG << RESHI),
                         SUMEXT_D    = (BASE_REG << SUMEXT);

  // Wire pre-declarations
  wire  result_wr;
  wire  result_clr;
  wire  early_read;

  //============================================================================
  // 2)  REGISTER DECODER
  //============================================================================

  // Local register selection
  wire              reg_sel;

  // Register local address
  wire [DEC_WD-1:0] reg_addr;

  // Register address decode
  wire [DEC_SZ-1:0] reg_dec;

  // Read/Write probes
  wire              reg_write;
  wire              reg_read;

  // Read/Write vectors
  wire [DEC_SZ-1:0] reg_wr;
  wire [DEC_SZ-1:0] reg_rd;

  // Masked input data for byte access
  wire       [15:0] per_din_msk;

  //============================================================================
  // 3) REGISTERS
  //============================================================================

  // OP1 Register
  //-------------
  reg  [15:0] op1;

  wire        op1_wr;

  wire        mclk_op1;

  wire        UNUSED_scan_enable;

  wire [15:0] op1_rd;


  // OP2 Register
  //-------------
  reg  [15:0] op2;

  wire        op2_wr;

  wire        mclk_op2;

  wire [15:0] op2_rd;


  // RESLO Register
  //---------------
  reg  [15:0] reslo;

  wire [15:0] reslo_nxt;
  wire        reslo_wr;

  wire        reslo_en;
  wire        mclk_reslo;

  wire [15:0] reslo_rd;

  // RESHI Register
  //---------------
  reg  [15:0] reshi;

  wire [15:0] reshi_nxt;
  wire        reshi_wr;

  wire        reshi_en;
  wire        mclk_reshi;

  wire [15:0] reshi_rd;


  // SUMEXT Register
  //----------------
  reg  [1:0] sumext_s;

  wire [1:0] sumext_s_nxt;

  wire [15:0] sumext_nxt;
  wire [15:0] sumext;
  wire [15:0] sumext_rd;


  //============================================================================
  // 4) DATA OUTPUT GENERATION
  //============================================================================

  // Data output mux
  wire [15:0] op1_mux;
  wire [15:0] op2_mux;
  wire [15:0] reslo_mux;
  wire [15:0] reshi_mux;
  wire [15:0] sumext_mux;

  //============================================================================
  // 5) HARDWARE MULTIPLIER FUNCTIONAL LOGIC
  //============================================================================

  // Multiplier configuration
  //-------------------------

  // Detect signed mode
  reg sign_sel;

  // Detect accumulate mode
  reg acc_sel;

  // Combine RESHI & RESLO
  wire [31:0] result;


  // 16x16 Multiplier (result computed in 1 clock cycle)
  //----------------------------------------------------

  // Detect start of a multiplication
  reg cycle1;

  // Expand the operands to support signed & unsigned operations
  wire        [16:0] op1_xp1; // signed
  wire        [16:0] op2_xp1; // signed


  // 17x17 signed multiplication
  wire        [33:0] product1; // signed

  // Accumulate
  wire        [32:0] result_nxt1;

// 16x8 Multiplier (result computed in 2 clock cycles)
//----------------------------------------------------

  // Detect start of a multiplication
  reg [1:0] cycle2;


  // Expand the operands to support signed & unsigned operations
  wire        [16:0] op1_xp2;   // signed
  wire         [8:0] op2_hi_xp; // signed
  wire         [8:0] op2_lo_xp; // signed
  wire         [8:0] op2_xp2;   // signed


  // 17x9 signed multiplication
  wire        [25:0] product2;  // signed

  wire        [31:0] product_xp;

  // Accumulate
  wire        [32:0] result_nxt2;

  //============================================================================
  // 2)  REGISTER DECODER
  //============================================================================

  // Local register selection
  assign            reg_sel     =  per_en & (per_addr[13:DEC_WD-1]==BASE_ADDR[14:DEC_WD]);

  // Register local address
  assign            reg_addr    =  {per_addr[DEC_WD-2:0], 1'b0};

  // Register address decode
  assign            reg_dec     =  (OP1_MPY_D   &  {DEC_SZ{(reg_addr == OP1_MPY  )}})  |
                                   (OP1_MPYS_D  &  {DEC_SZ{(reg_addr == OP1_MPYS )}})  |
                                   (OP1_MAC_D   &  {DEC_SZ{(reg_addr == OP1_MAC  )}})  |
                                   (OP1_MACS_D  &  {DEC_SZ{(reg_addr == OP1_MACS )}})  |
                                   (OP2_D       &  {DEC_SZ{(reg_addr == OP2      )}})  |
                                   (RESLO_D     &  {DEC_SZ{(reg_addr == RESLO    )}})  |
                                   (RESHI_D     &  {DEC_SZ{(reg_addr == RESHI    )}})  |
                                   (SUMEXT_D    &  {DEC_SZ{(reg_addr == SUMEXT   )}});

  // Read/Write probes
  assign            reg_write   =  |per_we & reg_sel;
  assign            reg_read    = ~|per_we & reg_sel;

  // Read/Write vectors
  assign            reg_wr      = reg_dec & {DEC_SZ{reg_write}};
  assign            reg_rd      = reg_dec & {DEC_SZ{reg_read}};

  // Masked input data for byte access
  assign            per_din_msk =  per_din & {{8{per_we[1]}}, 8'hff};

  //============================================================================
  // 3) REGISTERS
  //============================================================================

  // OP1 Register
  //-------------
  assign      op1_wr = reg_wr[OP1_MPY]  |
                       reg_wr[OP1_MPYS] |
                       reg_wr[OP1_MAC]  |
                       reg_wr[OP1_MACS];

  `ifdef CLOCK_GATING
  omsp_clock_gate clock_gate_op1 (
    .gclk(mclk_op1),
    .clk (mclk),
    .enable(op1_wr),
    .scan_enable(scan_enable)
  );
  `else
  assign      UNUSED_scan_enable = scan_enable;
  assign      mclk_op1           = mclk;
  `endif

  `ifdef CLOCK_GATING
  always @ (posedge mclk_op1 or posedge puc_rst) begin
    if (puc_rst)      op1 <=  16'h0000;
    else              op1 <=  per_din_msk;
  end
  `else
  always @ (posedge mclk_op1 or posedge puc_rst) begin
    if (puc_rst)      op1 <=  16'h0000;
    else if (op1_wr)  op1 <=  per_din_msk;
  end
  `endif

  assign op1_rd  = op1;

  // OP2 Register
  //-------------
  assign      op2_wr = reg_wr[OP2];

  `ifdef CLOCK_GATING
  omsp_clock_gate clock_gate_op2 (
    .gclk(mclk_op2),
    .clk (mclk),
    .enable(op2_wr),
    .scan_enable(scan_enable)
  );
  `else
  assign      mclk_op2 = mclk;
  `endif

  `ifdef CLOCK_GATING
  always @ (posedge mclk_op2 or posedge puc_rst) begin
    if (puc_rst)      op2 <=  16'h0000;
    else              op2 <=  per_din_msk;
  end
  `else
  always @ (posedge mclk_op2 or posedge puc_rst) begin
    if (puc_rst)      op2 <=  16'h0000;
    else if (op2_wr)  op2 <=  per_din_msk;
  end
  `endif

  assign op2_rd  = op2;

  // RESLO Register
  //---------------
  assign      reslo_wr = reg_wr[RESLO];

  `ifdef CLOCK_GATING
  assign      reslo_en = reslo_wr | result_clr | result_wr;
  omsp_clock_gate clock_gate_reslo (
    .gclk(mclk_reslo),
    .clk (mclk),
    .enable(reslo_en),
    .scan_enable(scan_enable)
  );
  `else
  assign      mclk_reslo = mclk;
  `endif

  `ifdef CLOCK_GATING
  always @ (posedge mclk_reslo or posedge puc_rst) begin
    if (puc_rst)         reslo <=  16'h0000;
    else if (reslo_wr)   reslo <=  per_din_msk;
    else if (result_clr) reslo <=  16'h0000;
    else                 reslo <=  reslo_nxt;
  end
  `else
  always @ (posedge mclk_reslo or posedge puc_rst) begin
    if (puc_rst)         reslo <=  16'h0000;
    else if (reslo_wr)   reslo <=  per_din_msk;
    else if (result_clr) reslo <=  16'h0000;
    else if (result_wr)  reslo <=  reslo_nxt;
  end
  `endif

  assign reslo_rd = early_read ? reslo_nxt : reslo;


  // RESHI Register
  //---------------
  assign      reshi_wr = reg_wr[RESHI];

  `ifdef CLOCK_GATING
  assign      reshi_en = reshi_wr | result_clr | result_wr;
  omsp_clock_gate clock_gate_reshi (
    .gclk(mclk_reshi),
    .clk (mclk),
    .enable(reshi_en),
    .scan_enable(scan_enable)
  );
  `else
  assign      mclk_reshi = mclk;
  `endif

  `ifdef CLOCK_GATING
  always @ (posedge mclk_reshi or posedge puc_rst) begin
    if (puc_rst)         reshi <=  16'h0000;
    else if (reshi_wr)   reshi <=  per_din_msk;
    else if (result_clr) reshi <=  16'h0000;
    else                 reshi <=  reshi_nxt;
  end
  `else
  always @ (posedge mclk_reshi or posedge puc_rst) begin
    if (puc_rst)         reshi <=  16'h0000;
    else if (reshi_wr)   reshi <=  per_din_msk;
    else if (result_clr) reshi <=  16'h0000;
    else if (result_wr)  reshi <=  reshi_nxt;
  end
  `endif

  assign reshi_rd = early_read ? reshi_nxt  : reshi;

  // SUMEXT Register
  //----------------
  always @ (posedge mclk or posedge puc_rst) begin
    if (puc_rst)         sumext_s <=  2'b00;
    else if (op2_wr)     sumext_s <=  2'b00;
    else if (result_wr)  sumext_s <=  sumext_s_nxt;
  end

  assign sumext_nxt = {{14{sumext_s_nxt[1]}}, sumext_s_nxt};
  assign sumext     = {{14{sumext_s[1]}},     sumext_s};
  assign sumext_rd  = early_read ? sumext_nxt : sumext;

  //============================================================================
  // 4) DATA OUTPUT GENERATION
  //============================================================================

  // Data output mux
  assign op1_mux    = op1_rd     & {16{reg_rd[OP1_MPY]  |
                                       reg_rd[OP1_MPYS] |
                                       reg_rd[OP1_MAC]  |
                                       reg_rd[OP1_MACS]}};
  assign op2_mux    = op2_rd     & {16{reg_rd[OP2]}};
  assign reslo_mux  = reslo_rd   & {16{reg_rd[RESLO]}};
  assign reshi_mux  = reshi_rd   & {16{reg_rd[RESHI]}};
  assign sumext_mux = sumext_rd  & {16{reg_rd[SUMEXT]}};

  assign per_dout   = op1_mux    |
                      op2_mux    |
                      reslo_mux  |
                      reshi_mux  |
                      sumext_mux;

  //============================================================================
  // 5) HARDWARE MULTIPLIER FUNCTIONAL LOGIC
  //============================================================================

  // Multiplier configuration
  //--------------------------

  // Detect signed mode
  `ifdef CLOCK_GATING
  always @ (posedge mclk_op1 or posedge puc_rst) begin
    if (puc_rst)     sign_sel <=  1'b0;
    else             sign_sel <=  reg_wr[OP1_MPYS] | reg_wr[OP1_MACS];
  end
  `else
  always @ (posedge mclk_op1 or posedge puc_rst) begin
    if (puc_rst)     sign_sel <=  1'b0;
    else if (op1_wr) sign_sel <=  reg_wr[OP1_MPYS] | reg_wr[OP1_MACS];
  end
  `endif

  // Detect accumulate mode
  `ifdef CLOCK_GATING
  always @ (posedge mclk_op1 or posedge puc_rst) begin
    if (puc_rst)     acc_sel  <=  1'b0;
    else             acc_sel  <=  reg_wr[OP1_MAC]  | reg_wr[OP1_MACS];
  end
  `else
  always @ (posedge mclk_op1 or posedge puc_rst) begin
    if (puc_rst)     acc_sel  <=  1'b0;
    else if (op1_wr) acc_sel  <=  reg_wr[OP1_MAC]  | reg_wr[OP1_MACS];
  end
  `endif

  // Detect whenever the RESHI and RESLO registers should be cleared
  assign      result_clr = op2_wr & ~acc_sel;

  // Combine RESHI & RESLO
  assign      result     = {reshi, reslo};

  // 16x16 Multiplier (result computed in 1 clock cycle)
  //-----------------------------------------------------
  `ifdef MPY_16x16

  // Detect start of a multiplication
  always @ (posedge mclk or posedge puc_rst) begin
    if (puc_rst) cycle1 <=  1'b0;
    else         cycle1 <=  op2_wr;
  end

  assign result_wr = cycle1;

  // Expand the operands to support signed & unsigned operations
  assign op1_xp1 = {sign_sel & op1[15], op1};
  assign op2_xp1 = {sign_sel & op2[15], op2};


  // 17x17 signed multiplication
  assign product1 = op1_xp1 * op2_xp1;

  // Accumulate
  assign result_nxt1 = {1'b0, result} + {1'b0, product[31:0]};

  // Next register values
  assign reslo_nxt    = result_nxt1[15:0];
  assign reshi_nxt    = result_nxt1[31:16];
  assign sumext_s_nxt =  sign_sel ? {2{result_nxt1[31]}} :
                                {1'b0, result_nxt1[32]};

  // Since the MAC is completed within 1 clock cycle,
  // an early read can't happen.
  assign early_read   = 1'b0;

  // 16x8 Multiplier (result computed in 2 clock cycles)
  //-----------------------------------------------------
  `else

  // Detect start of a multiplication
  always @ (posedge mclk or posedge puc_rst) begin
    if (puc_rst) cycle2 <=  2'b00;
    else         cycle2 <=  {cycle2[0], op2_wr};
  end

  assign result_wr = |cycle2;

  // Expand the operands to support signed & unsigned operations
  assign op1_xp2   = {sign_sel & op1[15], op1};
  assign op2_hi_xp = {sign_sel & op2[15], op2[15:8]};
  assign op2_lo_xp = {              1'b0, op2[7:0]};
  assign op2_xp2   = cycle2[0] ? op2_hi_xp : op2_lo_xp;

  // 17x9 signed multiplication
  assign product2   = op1_xp2 * op2_xp2;

  assign product_xp = cycle2[0] ? {product2[23:0], 8'h00} :
                    {{8{sign_sel & product2[23]}}, product2[23:0]};

  // Accumulate
  assign result_nxt2 = {1'b0, result} + {1'b0, product_xp[31:0]};

  // Next register values
  assign reslo_nxt    = result_nxt2[15:0];
  assign reshi_nxt    = result_nxt2[31:16];
  assign sumext_s_nxt =  sign_sel ? {2{result_nxt2[31]}} :
                                {1'b0, result_nxt2[32] | sumext_s[0]};

  // Since the MAC is completed within 2 clock cycle,
  // an early read can happen during the second cycle.
  assign early_read   = cycle2[1];
  `endif
endmodule // omsp_multiplier
