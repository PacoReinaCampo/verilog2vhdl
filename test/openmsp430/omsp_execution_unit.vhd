-- Converted from omsp_execution_unit.v
-- by verilog2vhdl - QueenField

------------------------------------------------------------------------------
-- Copyright (C) 2009 , Olivier Girard
--
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions
-- are met:
--     * Redistributions of source code must retain the above copyright
--       notice, this list of conditions and the following disclaimer.
--     * Redistributions in binary form must reproduce the above copyright
--       notice, this list of conditions and the following disclaimer in the
--       documentation and/or other materials provided with the distribution.
--     * Neither the name of the authors nor the names of its contributors
--       may be used to endorse or promote products derived from this software
--       without specific prior written permission.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
-- IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
-- ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
-- OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
-- THE POSSIBILITY OF SUCH DAMAGE
--
------------------------------------------------------------------------------
--
-- *File Name: omsp_execution_unit.v
--
-- *Module Description:
--                       openMSP430 Execution unit
--
-- *Author(s):
--              - Olivier Girard,    olgirard@gmail.com
--

use work."openMSP430_defines.v".all;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity omsp_execution_unit is
  port (
  -- OUTPUTs
  --========
    cpuoff : out std_logic;  -- Turns off the CPU
    dbg_reg_din : out std_logic_vector(15 downto 0);  -- Debug unit CPU register data input
    gie : out std_logic;  -- General interrupt enable
    mab : out std_logic_vector(15 downto 0);  -- Memory address bus
    mb_en : out std_logic;  -- Memory bus enable
    mb_wr : out std_logic_vector(1 downto 0);  -- Memory bus write transfer
    mdb_out : out std_logic_vector(15 downto 0);  -- Memory data bus output
    oscoff : out std_logic;  -- Turns off LFXT1 clock input
    pc_sw : out std_logic_vector(15 downto 0);  -- Program counter software value
    pc_sw_wr : out std_logic;  -- Program counter software write
    scg0 : out std_logic;  -- System clock generator 1. Turns off the DCO
    scg1 : out std_logic;  -- System clock generator 1. Turns off the SMCLK

  -- INPUTs
  --=======
    dbg_halt_st : in std_logic;  -- Halt/Run status from CPU
    dbg_mem_dout : in std_logic_vector(15 downto 0);  -- Debug unit data output
    dbg_reg_wr : in std_logic;  -- Debug unit CPU register write
    e_state : in std_logic_vector(3 downto 0);  -- Execution state
    exec_done : in std_logic;  -- Execution completed
    inst_ad : in std_logic_vector(7 downto 0);  -- Decoded Inst: destination addressing mode
    inst_as : in std_logic_vector(7 downto 0);  -- Decoded Inst: source addressing mode
    inst_alu : in std_logic_vector(11 downto 0);  -- ALU control signals
    inst_bw : in std_logic;  -- Decoded Inst: byte width
    inst_dest : in std_logic_vector(15 downto 0);  -- Decoded Inst: destination (one hot)
    inst_dext : in std_logic_vector(15 downto 0);  -- Decoded Inst: destination extended instruction word
    inst_irq_rst : in std_logic;  -- Decoded Inst: reset interrupt
    inst_jmp : in std_logic_vector(7 downto 0);  -- Decoded Inst: Conditional jump
    inst_mov : in std_logic;  -- Decoded Inst: mov instruction
    inst_sext : in std_logic_vector(15 downto 0);  -- Decoded Inst: source extended instruction word
    inst_so : in std_logic_vector(7 downto 0);  -- Decoded Inst: Single-operand arithmetic
    inst_src : in std_logic_vector(15 downto 0);  -- Decoded Inst: source (one hot)
    inst_type : in std_logic_vector(2 downto 0);  -- Decoded Instruction type
    mclk : in std_logic;  -- Main system clock
    mdb_in : in std_logic_vector(15 downto 0);  -- Memory data bus input
    pc : in std_logic_vector(15 downto 0);  -- Program counter
    pc_nxt : in std_logic_vector(15 downto 0);  -- Next PC value (for CALL & IRQ)
    puc_rst : in std_logic   -- Main system reset
    scan_enable : in std_logic  -- Scan enable (active during scan shifting)
  );
end omsp_execution_unit;

architecture RTL of omsp_execution_unit is
  component omsp_register_file
  port (
    cpuoff : std_logic_vector(? downto 0);
    gie : std_logic_vector(? downto 0);
    oscoff : std_logic_vector(? downto 0);
    pc_sw : std_logic_vector(? downto 0);
    pc_sw_wr : std_logic_vector(? downto 0);
    reg_dest : std_logic_vector(? downto 0);
    reg_src : std_logic_vector(? downto 0);
    scg0 : std_logic_vector(? downto 0);
    scg1 : std_logic_vector(? downto 0);
    status : std_logic_vector(? downto 0);
    alu_stat : std_logic_vector(? downto 0);
    alu_stat_wr : std_logic_vector(? downto 0);
    inst_bw : std_logic_vector(? downto 0);
    inst_dest : std_logic_vector(? downto 0);
    inst_src : std_logic_vector(? downto 0);
    mclk : std_logic_vector(? downto 0);
    pc : std_logic_vector(? downto 0);
    puc_rst : std_logic_vector(? downto 0);
    reg_dest_val : std_logic_vector(? downto 0);
    reg_dest_wr : std_logic_vector(? downto 0);
    reg_pc_call : std_logic_vector(? downto 0);
    reg_sp_val : std_logic_vector(? downto 0);
    reg_sp_wr : std_logic_vector(? downto 0);
    reg_sr_clr : std_logic_vector(? downto 0);
    reg_sr_wr : std_logic_vector(? downto 0);
    reg_incr : std_logic_vector(? downto 0);
    scan_enable : std_logic_vector(? downto 0)
  );
  end component;

  component omsp_alu
  port (
    alu_out : std_logic_vector(? downto 0);
    alu_out_add : std_logic_vector(? downto 0);
    alu_stat : std_logic_vector(? downto 0);
    alu_stat_wr : std_logic_vector(? downto 0);
    dbg_halt_st : std_logic_vector(? downto 0);
    exec_cycle : std_logic_vector(? downto 0);
    inst_alu : std_logic_vector(? downto 0);
    inst_bw : std_logic_vector(? downto 0);
    inst_jmp : std_logic_vector(? downto 0);
    inst_so : std_logic_vector(? downto 0);
    op_dst : std_logic_vector(? downto 0);
    op_src : std_logic_vector(? downto 0);
    status : std_logic_vector(? downto 0)
  );
  end component;

  component omsp_clock_gate
  port (
    gclk : std_logic_vector(? downto 0);
    clk : std_logic_vector(? downto 0);
    enable : std_logic_vector(? downto 0);
    scan_enable : std_logic_vector(? downto 0)
  );
  end component;

  --=============================================================================
  -- 1)  INTERNAL WIRES/REGISTERS/PARAMETERS DECLARATION
  --=============================================================================

  signal alu_out : std_logic_vector(15 downto 0);
  signal alu_out_add : std_logic_vector(15 downto 0);
  signal alu_stat : std_logic_vector(3 downto 0);
  signal alu_stat_wr : std_logic_vector(3 downto 0);
  signal op_dst : std_logic_vector(15 downto 0);
  signal op_src : std_logic_vector(15 downto 0);
  signal reg_dest : std_logic_vector(15 downto 0);
  signal reg_src : std_logic_vector(15 downto 0);
  signal mdb_in_bw : std_logic_vector(15 downto 0);
  signal mdb_in_val : std_logic_vector(15 downto 0);
  signal status : std_logic_vector(3 downto 0);

  --=============================================================================
  -- 2)  REGISTER FILE
  --=============================================================================

  signal reg_dest_wr : std_logic;

  signal reg_sp_wr : std_logic;

  signal reg_sr_wr : std_logic;

  signal reg_sr_clr : std_logic;

  signal reg_pc_call : std_logic;

  signal reg_incr : std_logic;

  --=============================================================================
  -- 3)  SOURCE OPERAND MUXING
  --=============================================================================
  -- inst_as[`DIR]    : Register direct.   -> Source is in register
  -- inst_as[`IDX]    : Register indexed.  -> Source is in memory, address is register+offset
  -- inst_as[`INDIR]  : Register indirect.
  -- inst_as[`INDIR_I]: Register indirect autoincrement.
  -- inst_as[`SYMB]   : Symbolic (operand is in memory at address PC+x).
  -- inst_as[`IMM]    : Immediate (operand is next word in the instruction stream).
  -- inst_as[`ABS]    : Absolute (operand is in memory at address x).
  -- inst_as[`CONST]  : Constant.

  signal src_reg_src_sel : std_logic;

  signal src_reg_dest_sel : std_logic;

  signal src_mdb_in_val_sel : std_logic;

  signal src_inst_dext_sel : std_logic;

  signal src_inst_sext_sel : std_logic;

  --=============================================================================
  -- 4)  DESTINATION OPERAND MUXING
  --=============================================================================
  -- inst_ad[`DIR]    : Register direct.
  -- inst_ad[`IDX]    : Register indexed.
  -- inst_ad[`SYMB]   : Symbolic (operand is in memory at address PC+x).
  -- inst_ad[`ABS]    : Absolute (operand is in memory at address x).

  signal dst_inst_sext_sel : std_logic;

  signal dst_mdb_in_bw_sel : std_logic;

  signal dst_fffe_sel : std_logic;

  signal dst_reg_dest_sel : std_logic;

  --=============================================================================
  -- 5)  ALU
  --=============================================================================

  signal exec_cycle : std_logic;

  --=============================================================================
  -- 6)  MEMORY INTERFACE
  --=============================================================================

  -- Detect memory read/write access
  signal mb_rd_det : std_logic;

  signal mb_wr_det : std_logic;

  signal mb_wr_msk : std_logic_vector(1 downto 0);

  -- Memory data bus output
  signal mdb_out_nxt : std_logic_vector(15 downto 0);

  signal mdb_out_nxt_en : std_logic;
  signal mclk_mdb_out_nxt : std_logic;

  -- Format memory data bus input depending on BW
  signal mab_lsb : std_logic;

  -- Memory data bus input buffer (buffer after a source read)
  signal mdb_in_buf_en : std_logic;

  signal mdb_in_buf_valid : std_logic;

  signal mdb_in_buf : std_logic_vector(15 downto 0);

  signal mclk_mdb_in_buf : std_logic;

  -- LINT cleanup
  signal UNUSED_inst_ad_idx : std_logic;
  signal UNUSED_inst_ad_indir : std_logic;
  signal UNUSED_inst_ad_indir_i : std_logic;
  signal UNUSED_inst_ad_symb : std_logic;
  signal UNUSED_inst_ad_imm : std_logic;
  signal UNUSED_inst_ad_const : std_logic;

begin
  --=============================================================================
  -- 2)  REGISTER FILE
  --=============================================================================

  reg_dest_wr <= ((e_state = E_EXEC) and ((inst_type(INST_TO) and inst_ad(DIR) and not inst_alu(EXEC_NO_WR)) or (inst_type(INST_SO) and inst_as(DIR) and not (inst_so(PUSH) or inst_so(CALL) or inst_so(RETI))) or inst_type(INST_JMP))) or dbg_reg_wr;

  reg_sp_wr <= (((e_state = E_IRQ_1) or (e_state = E_IRQ_3)) and not inst_irq_rst) or ((e_state = E_DST_RD) and ((inst_so(PUSH) or inst_so(CALL)) and not inst_as(IDX) and not ((inst_as(INDIR) or inst_as(INDIR_I)) and inst_src(1)))) or ((e_state = E_SRC_AD) and ((inst_so(PUSH) or inst_so(CALL)) and inst_as(IDX))) or ((e_state = E_SRC_RD) and ((inst_so(PUSH) or inst_so(CALL)) and ((inst_as(INDIR) or inst_as(INDIR_I)) and inst_src(1))));

  reg_sr_wr <= (e_state = E_DST_RD) and inst_so(RETI);

  reg_sr_clr <= (e_state = E_IRQ_2);

  reg_pc_call <= ((e_state = E_EXEC) and inst_so(CALL)) or ((e_state = E_DST_WR) and inst_so(RETI));

  reg_incr <= (exec_done and inst_as(INDIR_I)) or ((e_state = E_SRC_RD) and inst_so(RETI)) or ((e_state = E_EXEC) and inst_so(RETI));

  dbg_reg_din <= reg_dest;


  register_file_0 : omsp_register_file
  port map (
    -- OUTPUTs
    cpuoff => cpuoff,  -- Turns off the CPU
    gie => gie,  -- General interrupt enable
    oscoff => oscoff,  -- Turns off LFXT1 clock input
    pc_sw => pc_sw,  -- Program counter software value
    pc_sw_wr => pc_sw_wr,  -- Program counter software write
    reg_dest => reg_dest,  -- Selected register destination content
    reg_src => reg_src,  -- Selected register source content
    scg0 => scg0,  -- System clock generator 1. Turns off the DCO
    scg1 => scg1,  -- System clock generator 1. Turns off the SMCLK
    status => status,  -- R2 Status {V,N,Z,C}

    -- INPUTs
    alu_stat => alu_stat,  -- ALU Status {V,N,Z,C}
    alu_stat_wr => alu_stat_wr,  -- ALU Status write {V,N,Z,C}
    inst_bw => inst_bw,  -- Decoded Inst: byte width
    inst_dest => inst_dest,  -- Register destination selection
    inst_src => inst_src,  -- Register source selection
    mclk => mclk,  -- Main system clock
    pc => pc,  -- Program counter
    puc_rst => puc_rst,  -- Main system reset
    reg_dest_val => alu_out,  -- Selected register destination value
    reg_dest_wr => reg_dest_wr,  -- Write selected register destination
    reg_pc_call => reg_pc_call,  -- Trigger PC update for a CALL instruction
    reg_sp_val => alu_out_add,  -- Stack Pointer next value
    reg_sp_wr => reg_sp_wr,  -- Stack Pointer write
    reg_sr_clr => reg_sr_clr,  -- Status register clear for interrupts
    reg_sr_wr => reg_sr_wr,  -- Status Register update for RETI instruction
    reg_incr => reg_incr,  -- Increment source register
    scan_enable => scan_enable  -- Scan enable (active during scan shifting)
  );


  --=============================================================================
  -- 3)  SOURCE OPERAND MUXING
  --=============================================================================
  -- inst_as[`DIR]    : Register direct.   -> Source is in register
  -- inst_as[`IDX]    : Register indexed.  -> Source is in memory, address is register+offset
  -- inst_as[`INDIR]  : Register indirect.
  -- inst_as[`INDIR_I]: Register indirect autoincrement.
  -- inst_as[`SYMB]   : Symbolic (operand is in memory at address PC+x).
  -- inst_as[`IMM]    : Immediate (operand is next word in the instruction stream).
  -- inst_as[`ABS]    : Absolute (operand is in memory at address x).
  -- inst_as[`CONST]  : Constant.

  src_reg_src_sel <= (e_state = E_IRQ_0) or (e_state = E_IRQ_2) or ((e_state = E_SRC_RD) and not inst_as(ABS)) or ((e_state = E_SRC_WR) and not inst_as(ABS)) or ((e_state = E_EXEC) and inst_as(DIR) and not inst_type(INST_JMP));

  src_reg_dest_sel <= (e_state = E_IRQ_1) or (e_state = E_IRQ_3) or ((e_state = E_DST_RD) and (inst_so(PUSH) or inst_so(CALL))) or ((e_state = E_SRC_AD) and (inst_so(PUSH) or inst_so(CALL)) and inst_as(IDX));

  src_mdb_in_val_sel <= ((e_state = E_DST_RD) and inst_so(RETI)) or ((e_state = E_EXEC) and (inst_as(INDIR) or inst_as(INDIR_I) or inst_as(IDX) or inst_as(SYMB) or inst_as(ABS)));

  src_inst_dext_sel <= ((e_state = E_DST_RD) and not (inst_so(PUSH) or inst_so(CALL))) or ((e_state = E_DST_WR) and not (inst_so(PUSH) or inst_so(CALL) or inst_so(RETI)));

  src_inst_sext_sel <= ((e_state = E_EXEC) and (inst_type(INST_JMP) or inst_as(IMM) or inst_as(CONST) or inst_so(RETI)));

  op_src <= reg_src
  when src_reg_src_sel else reg_dest
  when src_reg_dest_sel else mdb_in_val
  when src_mdb_in_val_sel else inst_dext
  when src_inst_dext_sel else inst_sext
  when src_inst_sext_sel else X"0000";

  --=============================================================================
  -- 4)  DESTINATION OPERAND MUXING
  --=============================================================================
  -- inst_ad[`DIR]    : Register direct.
  -- inst_ad[`IDX]    : Register indexed.
  -- inst_ad[`SYMB]   : Symbolic (operand is in memory at address PC+x).
  -- inst_ad[`ABS]    : Absolute (operand is in memory at address x).

  dst_inst_sext_sel <= ((e_state = E_SRC_RD) and (inst_as(IDX) or inst_as(SYMB) or inst_as(ABS))) or ((e_state = E_SRC_WR) and (inst_as(IDX) or inst_as(SYMB) or inst_as(ABS)));

  dst_mdb_in_bw_sel <= ((e_state = E_DST_WR) and inst_so(RETI)) or ((e_state = E_EXEC) and not (inst_ad(DIR) or inst_type(INST_JMP) or inst_type(INST_SO)) and not inst_so(RETI));

  dst_fffe_sel <= (e_state = E_IRQ_0) or (e_state = E_IRQ_1) or (e_state = E_IRQ_3) or ((e_state = E_DST_RD) and (inst_so(PUSH) or inst_so(CALL)) and not inst_so(RETI)) or ((e_state = E_SRC_AD) and (inst_so(PUSH) or inst_so(CALL)) and inst_as(IDX)) or ((e_state = E_SRC_RD) and (inst_so(PUSH) or inst_so(CALL)) and (inst_as(INDIR) or inst_as(INDIR_I)) and inst_src(1));

  dst_reg_dest_sel <= ((e_state = E_DST_RD) and not (inst_so(PUSH) or inst_so(CALL) or inst_ad(ABS) or inst_so(RETI))) or ((e_state = E_DST_WR) and not inst_ad(ABS)) or ((e_state = E_EXEC) and (inst_ad(DIR) or inst_type(INST_JMP) or inst_type(INST_SO)) and not inst_so(RETI));

  op_dst <= dbg_mem_dout
  when dbg_halt_st else inst_sext
  when dst_inst_sext_sel else mdb_in_bw
  when dst_mdb_in_bw_sel else reg_dest
  when dst_reg_dest_sel else X"fffe"
  when dst_fffe_sel else X"0000";

  --=============================================================================
  -- 5)  ALU
  --=============================================================================

  exec_cycle <= (e_state = E_EXEC);

  alu_0 : omsp_alu
  port map (
    -- OUTPUTs
    alu_out => alu_out,  -- ALU output value
    alu_out_add => alu_out_add,  -- ALU adder output value
    alu_stat => alu_stat,  -- ALU Status {V,N,Z,C}
    alu_stat_wr => alu_stat_wr,  -- ALU Status write {V,N,Z,C}

    -- INPUTs
    dbg_halt_st => dbg_halt_st,  -- Halt/Run status from CPU
    exec_cycle => exec_cycle,  -- Instruction execution cycle
    inst_alu => inst_alu,  -- ALU control signals
    inst_bw => inst_bw,  -- Decoded Inst: byte width
    inst_jmp => inst_jmp,  -- Decoded Inst: Conditional jump
    inst_so => inst_so,  -- Single-operand arithmetic
    op_dst => op_dst,  -- Destination operand
    op_src => op_src,  -- Source operand
    status => status  -- R2 Status {V,N,Z,C}
  );


  --=============================================================================
  -- 6)  MEMORY INTERFACE
  --=============================================================================

  -- Detect memory read/write access
  mb_rd_det <= ((e_state = E_SRC_RD) and not inst_as(IMM)) or ((e_state = E_EXEC) and inst_so(RETI)) or ((e_state = E_DST_RD) and not inst_type(INST_SO) and not inst_mov);

  mb_wr_det <= ((e_state = E_IRQ_1) and not inst_irq_rst) or ((e_state = E_IRQ_3) and not inst_irq_rst) or ((e_state = E_DST_WR) and not inst_so(RETI)) or (e_state = E_SRC_WR);

  mb_wr_msk <= "00"
  when inst_alu(EXEC_NO_WR) else "11"
  when not inst_bw else "10"
  when alu_out_add(0) else "01";

  mb_en <= mb_rd_det or (mb_wr_det and not inst_alu(EXEC_NO_WR));

  mb_wr <= ((mb_wr_det & mb_wr_det)) and mb_wr_msk;

  -- Memory address bus
  mab <= alu_out_add(15 downto 0);

  -- Memory data bus output
  CLOCK_GATING_GENERATING_0 : if (CLOCK_GATING = '1') generate
    mdb_out_nxt_en <= (e_state = E_DST_RD) or (((e_state = E_EXEC) and not inst_so(CALL)) or (e_state = E_IRQ_0) or (e_state = E_IRQ_2));

    clock_gate_mdb_out_nxt : omsp_clock_gate
    port map (
      gclk => mclk_mdb_out_nxt,
      clk => mclk,
      enable => mdb_out_nxt_en,
      scan_enable => scan_enable
    );
  elsif (CLOCK_GATING = '0') generate
    mclk_mdb_out_nxt <= mclk;
  end generate;


  CLOCK_GATING_GENERATING_1 : if (CLOCK_GATING = '1') generate
    processing_0 : process (mclk_mdb_out_nxt, puc_rst)
    begin
      if (puc_rst) then
        mdb_out_nxt <= X"0000";
      elsif (rising_edge(mclk_mdb_out_nxt)) then
        if (e_state = E_DST_RD) then
          mdb_out_nxt <= pc_nxt;
        else
          mdb_out_nxt <= alu_out;
        end if;
      end if;
    end process;
  elsif (CLOCK_GATING = '0') generate
    processing_1 : process (mclk_mdb_out_nxt, puc_rst)
    begin
      if (puc_rst) then
        mdb_out_nxt <= X"0000";
      elsif (rising_edge(mclk_mdb_out_nxt)) then
        if (e_state = E_DST_RD) then
          mdb_out_nxt <= pc_nxt;
        elsif ((e_state = E_EXEC and not inst_so(CALL)) or (e_state = E_IRQ_0) or (e_state = E_IRQ_2)) then
          mdb_out_nxt <= alu_out;
        end if;
      end if;
    end process;
  end generate;


  mdb_out <= (mdb_out_nxt(7 downto 0) & mdb_out_nxt(7 downto 0))
  when inst_bw else mdb_out_nxt;

  -- Format memory data bus input depending on BW
  processing_2 : process (mclk, puc_rst)
  begin
    if (puc_rst) then
      mab_lsb <= '0';
    elsif (rising_edge(mclk)) then
      if (mb_en) then
        mab_lsb <= alu_out_add(0);
      end if;
    end if;
  end process;


  mdb_in_bw <= mdb_in
  when not inst_bw else (mdb_in(15 downto 8) & mdb_in(15 downto 8))
  when mab_lsb else mdb_in;

  -- Memory data bus input buffer (buffer after a source read)
  processing_3 : process (mclk, puc_rst)
  begin
    if (puc_rst) then
      mdb_in_buf_en <= '0';
    elsif (rising_edge(mclk)) then
      mdb_in_buf_en <= (e_state = E_SRC_RD);
    end if;
  end process;


  processing_4 : process (mclk, puc_rst)
  begin
    if (puc_rst) then
      mdb_in_buf_valid <= '0';
    elsif (rising_edge(mclk)) then
      if (e_state = E_EXEC) then
        mdb_in_buf_valid <= '0';
      elsif (mdb_in_buf_en) then
        mdb_in_buf_valid <= '1';
      end if;
    end if;
  end process;


  CLOCK_GATING_GENERATING_2 : if (CLOCK_GATING = '1') generate
    clock_gate_mdb_in_buf : omsp_clock_gate
    port map (
      gclk => mclk_mdb_in_buf,
      clk => mclk,
      enable => mdb_in_buf_en,
      scan_enable => scan_enable
    );
  elsif (CLOCK_GATING = '0') generate
    mclk_mdb_in_buf <= mclk;
  end generate;


  CLOCK_GATING_GENERATING_3 : if (CLOCK_GATING = '1') generate
    processing_5 : process (mclk_mdb_in_buf, puc_rst)
    begin
      if (puc_rst) then
        mdb_in_buf <= X"0000";
      elsif (rising_edge(mclk_mdb_in_buf)) then
        mdb_in_buf <= mdb_in_bw;
      end if;
    end process;
  elsif (CLOCK_GATING = '0') generate
    processing_6 : process (mclk_mdb_in_buf, puc_rst)
    begin
      if (puc_rst) then
        mdb_in_buf <= X"0000";
      elsif (rising_edge(mclk_mdb_in_buf)) then
        if (mdb_in_buf_en) then
          mdb_in_buf <= mdb_in_bw;
        end if;
      end if;
    end process;
  end generate;


  mdb_in_val <= mdb_in_buf
  when mdb_in_buf_valid else mdb_in_bw;

  -- LINT cleanup
  UNUSED_inst_ad_idx <= inst_ad(IDX);
  UNUSED_inst_ad_indir <= inst_ad(INDIR);
  UNUSED_inst_ad_indir_i <= inst_ad(INDIR_I);
  UNUSED_inst_ad_symb <= inst_ad(SYMB);
  UNUSED_inst_ad_imm <= inst_ad(IMM);
  UNUSED_inst_ad_const <= inst_ad(CONST);
end RTL;
