-- Converted from omsp_register_file.v
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
-- *File Name: omsp_register_file.v
--
-- *Module Description:
--                       openMSP430 Register files
--
-- *Author(s):
--              - Olivier Girard,    olgirard@gmail.com
--

use work."openMSP430_defines.v".all;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity omsp_register_file is
  port (
  -- OUTPUTs
  --========
    cpuoff : out std_logic;  -- Turns off the CPU
    gie : out std_logic;  -- General interrupt enable
    oscoff : out std_logic;  -- Turns off LFXT1 clock input
    pc_sw : out std_logic_vector(15 downto 0);  -- Program counter software value
    pc_sw_wr : out std_logic;  -- Program counter software write
    reg_dest : out std_logic_vector(15 downto 0);  -- Selected register destination content
    reg_src : out std_logic_vector(15 downto 0);  -- Selected register source content
    scg0 : out std_logic;  -- System clock generator 1. Turns off the DCO
    scg1 : out std_logic;  -- System clock generator 1. Turns off the SMCLK
    status : out std_logic_vector(3 downto 0);  -- R2 Status {V,N,Z,C}

  -- INPUTs
  --=======
    alu_stat : in std_logic_vector(3 downto 0);  -- ALU Status {V,N,Z,C}
    alu_stat_wr : in std_logic_vector(3 downto 0);  -- ALU Status write {V,N,Z,C}
    inst_bw : in std_logic;  -- Decoded Inst: byte width
    inst_dest : in std_logic_vector(15 downto 0);  -- Register destination selection
    inst_src : in std_logic_vector(15 downto 0);  -- Register source selection
    mclk : in std_logic;  -- Main system clock
    pc : in std_logic_vector(15 downto 0);  -- Program counter
    puc_rst : in std_logic;  -- Main system reset
    reg_dest_val : in std_logic_vector(15 downto 0);  -- Selected register destination value
    reg_dest_wr : in std_logic;  -- Write selected register destination
    reg_pc_call : in std_logic;  -- Trigger PC update for a CALL instruction
    reg_sp_val : in std_logic_vector(15 downto 0);  -- Stack Pointer next value
    reg_sp_wr : in std_logic;  -- Stack Pointer write
    reg_sr_wr : in std_logic;  -- Status register update for RETI instruction
    reg_sr_clr : in std_logic;  -- Status register clear for interrupts
    reg_incr : in std_logic   -- Increment source register
    scan_enable : in std_logic  -- Scan enable (active during scan shifting)
  );
end omsp_register_file;

architecture RTL of omsp_register_file is
  component omsp_clock_gate
  port (
    gclk : std_logic_vector(? downto 0);
    clk : std_logic_vector(? downto 0);
    enable : std_logic_vector(? downto 0);
    scan_enable : std_logic_vector(? downto 0)
  );
  end component;

  --=============================================================================
  -- 1)  AUTOINCREMENT UNIT
  --=============================================================================

  signal inst_src_in : std_logic_vector(15 downto 0);
  signal incr_op : std_logic_vector(15 downto 0);
  signal reg_incr_val : std_logic_vector(15 downto 0);

  signal reg_dest_val_in : std_logic_vector(15 downto 0);

  --=============================================================================
  -- 2)  SPECIAL REGISTERS (R1/R2/R3)
  --=============================================================================

  -- Source input selection mask (for interrupt support)
  ------------------------------------------------------

  -- R0: Program counter
  ----------------------
  signal r0 : std_logic_vector(15 downto 0);

  signal pc_sw : std_logic_vector(15 downto 0);
  signal pc_sw_wr : std_logic;


  -- R1: Stack pointer
  --------------------
  signal r1 : std_logic_vector(15 downto 0);
  signal r1_wr : std_logic;
  signal r1_inc : std_logic;

  signal r1_en : std_logic;
  signal mclk_r1 : std_logic;

  signal UNUSED_scan_enable : std_logic;
  signal UNUSED_reg_sp_val_0 : std_logic;

  -- R2: Status register
  ----------------------
  signal r2 : std_logic_vector(15 downto 0);
  signal r2_wr : std_logic;

  signal r2_c : std_logic;  -- C
  signal r2_z : std_logic;  -- Z
  signal r2_n : std_logic;  -- N

  signal r2_nxt : std_logic_vector(7 downto 3);
  signal r2_v : std_logic;  -- V

  signal r2_en : std_logic;
  signal mclk_r2 : std_logic;

  signal cpuoff_mask : std_logic_vector(15 downto 0);
  signal oscoff_mask : std_logic_vector(15 downto 0);
  signal scg0_mask : std_logic_vector(15 downto 0);
  signal scg1_mask : std_logic_vector(15 downto 0);

  signal r2_mask : std_logic_vector(15 downto 0);

  -- R3: Constant generator
  ---------------------------------------------------------------
  -- Note: the auto-increment feature is not implemented for R3
  --       because the @R3+ addressing mode is used for constant
  --       generation (#-1).
  signal r3 : std_logic_vector(15 downto 0);
  signal r3_wr : std_logic;
  signal r3_en : std_logic;
  signal mclk_r3 : std_logic;

  --=============================================================================
  -- 4)  GENERAL PURPOSE REGISTERS (R4...R15)
  --=============================================================================

  -- R4
  -----
  signal r4 : std_logic_vector(15 downto 0);
  signal r4_wr : std_logic;
  signal r4_inc : std_logic;

  signal r4_en : std_logic;
  signal mclk_r4 : std_logic;

  -- R5
  -----
  signal r5 : std_logic_vector(15 downto 0);
  signal r5_wr : std_logic;
  signal r5_inc : std_logic;

  signal r5_en : std_logic;
  signal mclk_r5 : std_logic;

  -- R6
  -----
  signal r6 : std_logic_vector(15 downto 0);
  signal r6_wr : std_logic;
  signal r6_inc : std_logic;

  signal r6_en : std_logic;
  signal mclk_r6 : std_logic;

  -- R7
  -----
  signal r7 : std_logic_vector(15 downto 0);
  signal r7_wr : std_logic;
  signal r7_inc : std_logic;

  signal r7_en : std_logic;
  signal mclk_r7 : std_logic;

  -- R8
  -----
  signal r8 : std_logic_vector(15 downto 0);
  signal r8_wr : std_logic;
  signal r8_inc : std_logic;

  signal r8_en : std_logic;
  signal mclk_r8 : std_logic;

  -- R9
  -----
  signal r9 : std_logic_vector(15 downto 0);
  signal r9_wr : std_logic;
  signal r9_inc : std_logic;

  signal r9_en : std_logic;
  signal mclk_r9 : std_logic;

  -- R10
  ------
  signal r10 : std_logic_vector(15 downto 0);
  signal r10_wr : std_logic;
  signal r10_inc : std_logic;

  signal r10_en : std_logic;
  signal mclk_r10 : std_logic;

  -- R11
  ------
  signal r11 : std_logic_vector(15 downto 0);
  signal r11_wr : std_logic;
  signal r11_inc : std_logic;

  signal r11_en : std_logic;
  signal mclk_r11 : std_logic;

  -- R12
  ------
  signal r12 : std_logic_vector(15 downto 0);
  signal r12_wr : std_logic;
  signal r12_inc : std_logic;

  signal r12_en : std_logic;
  signal mclk_r12 : std_logic;

  -- R13
  ------
  signal r13 : std_logic_vector(15 downto 0);
  signal r13_wr : std_logic;
  signal r13_inc : std_logic;

  signal r13_en : std_logic;
  signal mclk_r13 : std_logic;

  -- R14
  ------
  signal r14 : std_logic_vector(15 downto 0);
  signal r14_wr : std_logic;
  signal r14_inc : std_logic;

  signal r14_en : std_logic;
  signal mclk_r14 : std_logic;

  -- R15
  ------
  signal r15 : std_logic_vector(15 downto 0);
  signal r15_wr : std_logic;
  signal r15_inc : std_logic;

  signal r15_en : std_logic;
  signal mclk_r15 : std_logic;

begin
  --=============================================================================
  -- 1)  AUTOINCREMENT UNIT
  --=============================================================================

  incr_op <= X"0001"
  when (inst_bw and not inst_src_in(1)) else X"0002";
  reg_incr_val <= reg_src+incr_op;

  reg_dest_val_in <= (X"00" & reg_dest_val(7 downto 0))
  when inst_bw else reg_dest_val;

  --=============================================================================
  -- 2)  SPECIAL REGISTERS (R1/R2/R3)
  --=============================================================================

  -- Source input selection mask (for interrupt support)
  ------------------------------------------------------
  inst_src_in <= X"0004"
  when reg_sr_clr else inst_src;

  -- R0: Program counter
  ----------------------
  r0 <= pc;

  pc_sw <= reg_dest_val_in;
  pc_sw_wr <= (inst_dest(0) and reg_dest_wr) or reg_pc_call;


  -- R1: Stack pointer
  --------------------
  r1_wr <= inst_dest(1) and reg_dest_wr;
  r1_inc <= inst_src_in(1) and reg_incr;

  CLOCK_GATING_GENERATING_0 : if (CLOCK_GATING = '1') generate
    r1_en <= r1_wr or reg_sp_wr or r1_inc;

    clock_gate_r1 : omsp_clock_gate
    port map (
      gclk => mclk_r1,
      clk => mclk,
      enable => r1_en,
      scan_enable => scan_enable
    );
  elsif (CLOCK_GATING = '0') generate
    UNUSED_scan_enable <= scan_enable;
    mclk_r1 <= mclk;
  end generate;


  CLOCK_GATING_GENERATING_1 : if (CLOCK_GATING = '1') generate
    processing_0 : process (mclk_r1, puc_rst)
    begin
      if (puc_rst) then
        r1 <= X"0000";
      elsif (rising_edge(mclk_r1)) then
        if (r1_wr) then
          r1 <= reg_dest_val_in and X"fffe";
        elsif (reg_sp_wr) then
          r1 <= reg_sp_val and X"fffe";
        else
          r1 <= reg_incr_val and X"fffe";
        end if;
      end if;
    end process;
  elsif (CLOCK_GATING = '0') generate
    processing_1 : process (mclk_r1, puc_rst)
    begin
      if (puc_rst) then
        r1 <= X"0000";
      elsif (rising_edge(mclk_r1)) then
        if (r1_wr) then
          r1 <= reg_dest_val_in and X"fffe";
        elsif (reg_sp_wr) then
          r1 <= reg_sp_val and X"fffe";
        elsif (r1_inc) then
          r1 <= reg_incr_val and X"fffe";
        end if;
      end if;
    end process;
  end generate;


  UNUSED_reg_sp_val_0 <= reg_sp_val(0);

  -- R2: Status register
  ----------------------
  r2_wr <= (inst_dest(2) and reg_dest_wr) or reg_sr_wr;

  CLOCK_GATING_GENERATING_2 : if (CLOCK_GATING = '1') generate  --      -- WITH CLOCK GATING --
    r2_c <= alu_stat(0)
    when alu_stat_wr(0) else reg_dest_val_in(0);    -- C

    r2_z <= alu_stat(1)
    when alu_stat_wr(1) else reg_dest_val_in(1);    -- Z

    r2_n <= alu_stat(2)
    when alu_stat_wr(2) else reg_dest_val_in(2);    -- N

    r2_nxt <= reg_dest_val_in(7 downto 3)
    when r2_wr else r2(7 downto 3);

    r2_v <= alu_stat(3)
    when alu_stat_wr(3) else reg_dest_val_in(8);    -- V

    r2_en <= or alu_stat_wr or r2_wr or reg_sr_clr;

    clock_gate_r2 : omsp_clock_gate
    port map (
      gclk => mclk_r2,
      clk => mclk,
      enable => r2_en,
      scan_enable => scan_enable
    );
  elsif (CLOCK_GATING = '0') generate


    --      -- WITHOUT CLOCK GATING --
    r2_c <= alu_stat(0)
    when alu_stat_wr(0) else reg_dest_val_in(0)
    when r2_wr else r2(0);    -- C

    r2_z <= alu_stat(1)
    when alu_stat_wr(1) else reg_dest_val_in(1)
    when r2_wr else r2(1);    -- Z

    r2_n <= alu_stat(2)
    when alu_stat_wr(2) else reg_dest_val_in(2)
    when r2_wr else r2(2);    -- N

    r2_nxt <= reg_dest_val_in(7 downto 3)
    when r2_wr else r2(7 downto 3);

    r2_v <= alu_stat(3)
    when alu_stat_wr(3) else reg_dest_val_in(8)
    when r2_wr else r2(8);    -- V


    mclk_r2 <= mclk;
  end generate;


  ASIC_CLOCKING_GENERATING_3 : if (ASIC_CLOCKING = '1') generate
    CPUOFF_EN_GENERATING_4 : if (CPUOFF_EN = '1') generate
      cpuoff_mask <= X"0010";
    elsif (CPUOFF_EN = '0') generate
      cpuoff_mask <= X"0000";
    end generate;
    OSCOFF_EN_GENERATING_5 : if (OSCOFF_EN = '1') generate
      oscoff_mask <= X"0020";
    elsif (OSCOFF_EN = '0') generate
      oscoff_mask <= X"0000";
    end generate;
    SCG0_EN_GENERATING_6 : if (SCG0_EN = '1') generate
      scg0_mask <= X"0040";
    elsif (SCG0_EN = '0') generate
      scg0_mask <= X"0000";
    end generate;
    SCG1_EN_GENERATING_7 : if (SCG1_EN = '1') generate
      scg1_mask <= X"0080";
    elsif (SCG1_EN = '0') generate
      scg1_mask <= X"0000";
    end generate;
  elsif (ASIC_CLOCKING = '0') generate
    cpuoff_mask <= X"0010";    -- For the FPGA version: - the CPUOFF mode is emulated
    oscoff_mask <= X"0020";    --                       - the SCG1 mode is emulated
    scg0_mask <= X"0000";    --                       - the SCG0 is not supported
    scg1_mask <= X"0080";    --                       - the SCG1 mode is emulated
  end generate;


  r2_mask <= cpuoff_mask or oscoff_mask or scg0_mask or scg1_mask or X"010f";

  processing_2 : process (mclk_r2, puc_rst)
  begin
    if (puc_rst) then
      r2 <= X"0000";
    elsif (rising_edge(mclk_r2)) then
      if (reg_sr_clr) then
        r2 <= X"0000";
      else
        r2 <= (X"00" & r2_v & r2_nxt & r2_n & r2_z & r2_c) and r2_mask;
      end if;
    end if;
  end process;


  status <= (r2(8) & r2(2 downto 0));
  gie <= r2(3);
  cpuoff <= r2(4) or (r2_nxt(4) and r2_wr and cpuoff_mask(4));
  oscoff <= r2(5);
  scg0 <= r2(6);
  scg1 <= r2(7);

  -- R3: Constant generator
  -------------------------
  -- Note: the auto-increment feature is not implemented for R3
  --       because the @R3+ addressing mode is used for constant
  --       generation (#-1).
  r3_wr <= inst_dest(3) and reg_dest_wr;

  CLOCK_GATING_GENERATING_8 : if (CLOCK_GATING = '1') generate
    r3_en <= r3_wr;

    clock_gate_r3 : omsp_clock_gate
    port map (
      gclk => mclk_r3,
      clk => mclk,
      enable => r3_en,
      scan_enable => scan_enable
    );
  elsif (CLOCK_GATING = '0') generate
    mclk_r3 <= mclk;
  end generate;


  CLOCK_GATING_GENERATING_9 : if (CLOCK_GATING = '1') generate
    processing_3 : process (mclk_r3, puc_rst)
    begin
      if (puc_rst) then
        r3 <= X"0000";
      elsif (rising_edge(mclk_r3)) then
        r3 <= reg_dest_val_in;
      end if;
    end process;
  elsif (CLOCK_GATING = '0') generate
    processing_4 : process (mclk_r3, puc_rst)
    begin
      if (puc_rst) then
        r3 <= X"0000";
      elsif (rising_edge(mclk_r3)) then
        if (r3_wr) then
          r3 <= reg_dest_val_in;
        end if;
      end if;
    end process;
  end generate;


  --=============================================================================
  -- 4)  GENERAL PURPOSE REGISTERS (R4...R15)
  --=============================================================================

  -- R4
  -----
  r4_wr <= inst_dest(4) and reg_dest_wr;
  r4_inc <= inst_src_in(4) and reg_incr;

  CLOCK_GATING_GENERATING_10 : if (CLOCK_GATING = '1') generate
    r4_en <= r4_wr or r4_inc;

    clock_gate_r4 : omsp_clock_gate
    port map (
      gclk => mclk_r4,
      clk => mclk,
      enable => r4_en,
      scan_enable => scan_enable
    );
  elsif (CLOCK_GATING = '0') generate
    mclk_r4 <= mclk;
  end generate;


  CLOCK_GATING_GENERATING_11 : if (CLOCK_GATING = '1') generate
    processing_5 : process (mclk_r4, puc_rst)
    begin
      if (puc_rst) then
        r4 <= X"0000";
      elsif (rising_edge(mclk_r4)) then
        if (r4_wr) then
          r4 <= reg_dest_val_in;
        else
          r4 <= reg_incr_val;
        end if;
      end if;
    end process;
  elsif (CLOCK_GATING = '0') generate
    processing_6 : process (mclk_r4, puc_rst)
    begin
      if (puc_rst) then
        r4 <= X"0000";
      elsif (rising_edge(mclk_r4)) then
        if (r4_wr) then
          r4 <= reg_dest_val_in;
        elsif (r4_inc) then
          r4 <= reg_incr_val;
        end if;
      end if;
    end process;
  end generate;


  -- R5
  -----
  r5_wr <= inst_dest(5) and reg_dest_wr;
  r5_inc <= inst_src_in(5) and reg_incr;

  CLOCK_GATING_GENERATING_12 : if (CLOCK_GATING = '1') generate
    r5_en <= r5_wr or r5_inc;

    clock_gate_r5 : omsp_clock_gate
    port map (
      gclk => mclk_r5,
      clk => mclk,
      enable => r5_en,
      scan_enable => scan_enable
    );
  elsif (CLOCK_GATING = '0') generate
    mclk_r5 <= mclk;
  end generate;


  CLOCK_GATING_GENERATING_13 : if (CLOCK_GATING = '1') generate
    processing_7 : process (mclk_r5, puc_rst)
    begin
      if (puc_rst) then
        r5 <= X"0000";
      elsif (rising_edge(mclk_r5)) then
        if (r5_wr) then
          r5 <= reg_dest_val_in;
        else
          r5 <= reg_incr_val;
        end if;
      end if;
    end process;
  elsif (CLOCK_GATING = '0') generate
    processing_8 : process (mclk_r5, puc_rst)
    begin
      if (puc_rst) then
        r5 <= X"0000";
      elsif (rising_edge(mclk_r5)) then
        if (r5_wr) then
          r5 <= reg_dest_val_in;
        elsif (r5_inc) then
          r5 <= reg_incr_val;
        end if;
      end if;
    end process;
  end generate;


  -- R6
  -----
  r6_wr <= inst_dest(6) and reg_dest_wr;
  r6_inc <= inst_src_in(6) and reg_incr;

  CLOCK_GATING_GENERATING_14 : if (CLOCK_GATING = '1') generate
    r6_en <= r6_wr or r6_inc;

    clock_gate_r6 : omsp_clock_gate
    port map (
      gclk => mclk_r6,
      clk => mclk,
      enable => r6_en,
      scan_enable => scan_enable
    );
  elsif (CLOCK_GATING = '0') generate
    mclk_r6 <= mclk;
  end generate;


  CLOCK_GATING_GENERATING_15 : if (CLOCK_GATING = '1') generate
    processing_9 : process (mclk_r6, puc_rst)
    begin
      if (puc_rst) then
        r6 <= X"0000";
      elsif (rising_edge(mclk_r6)) then
        if (r6_wr) then
          r6 <= reg_dest_val_in;
        else
          r6 <= reg_incr_val;
        end if;
      end if;
    end process;
  elsif (CLOCK_GATING = '0') generate
    processing_10 : process (mclk_r6, puc_rst)
    begin
      if (puc_rst) then
        r6 <= X"0000";
      elsif (rising_edge(mclk_r6)) then
        if (r6_wr) then
          r6 <= reg_dest_val_in;
        elsif (r6_inc) then
          r6 <= reg_incr_val;
        end if;
      end if;
    end process;
  end generate;


  -- R7
  -----
  r7_wr <= inst_dest(7) and reg_dest_wr;
  r7_inc <= inst_src_in(7) and reg_incr;

  CLOCK_GATING_GENERATING_16 : if (CLOCK_GATING = '1') generate
    r7_en <= r7_wr or r7_inc;

    clock_gate_r7 : omsp_clock_gate
    port map (
      gclk => mclk_r7,
      clk => mclk,
      enable => r7_en,
      scan_enable => scan_enable
    );
  elsif (CLOCK_GATING = '0') generate
    mclk_r7 <= mclk;
  end generate;


  CLOCK_GATING_GENERATING_17 : if (CLOCK_GATING = '1') generate
    processing_11 : process (mclk_r7, puc_rst)
    begin
      if (puc_rst) then
        r7 <= X"0000";
      elsif (rising_edge(mclk_r7)) then
        if (r7_wr) then
          r7 <= reg_dest_val_in;
        else
          r7 <= reg_incr_val;
        end if;
      end if;
    end process;
  elsif (CLOCK_GATING = '0') generate
    processing_12 : process (mclk_r7, puc_rst)
    begin
      if (puc_rst) then
        r7 <= X"0000";
      elsif (rising_edge(mclk_r7)) then
        if (r7_wr) then
          r7 <= reg_dest_val_in;
        elsif (r7_inc) then
          r7 <= reg_incr_val;
        end if;
      end if;
    end process;
  end generate;


  -- R8
  -----
  r8_wr <= inst_dest(8) and reg_dest_wr;
  r8_inc <= inst_src_in(8) and reg_incr;

  CLOCK_GATING_GENERATING_18 : if (CLOCK_GATING = '1') generate
    r8_en <= r8_wr or r8_inc;

    clock_gate_r8 : omsp_clock_gate
    port map (
      gclk => mclk_r8,
      clk => mclk,
      enable => r8_en,
      scan_enable => scan_enable
    );
  elsif (CLOCK_GATING = '0') generate
    mclk_r8 <= mclk;
  end generate;


  CLOCK_GATING_GENERATING_19 : if (CLOCK_GATING = '1') generate
    processing_13 : process (mclk_r8, puc_rst)
    begin
      if (puc_rst) then
        r8 <= X"0000";
      elsif (rising_edge(mclk_r8)) then
        if (r8_wr) then
          r8 <= reg_dest_val_in;
        else
          r8 <= reg_incr_val;
        end if;
      end if;
    end process;
  elsif (CLOCK_GATING = '0') generate
    processing_14 : process (mclk_r8, puc_rst)
    begin
      if (puc_rst) then
        r8 <= X"0000";
      elsif (rising_edge(mclk_r8)) then
        if (r8_wr) then
          r8 <= reg_dest_val_in;
        elsif (r8_inc) then
          r8 <= reg_incr_val;
        end if;
      end if;
    end process;
  end generate;


  -- R9
  -----
  r9_wr <= inst_dest(9) and reg_dest_wr;
  r9_inc <= inst_src_in(9) and reg_incr;

  CLOCK_GATING_GENERATING_20 : if (CLOCK_GATING = '1') generate
    r9_en <= r9_wr or r9_inc;

    clock_gate_r9 : omsp_clock_gate
    port map (
      gclk => mclk_r9,
      clk => mclk,
      enable => r9_en,
      scan_enable => scan_enable
    );
  elsif (CLOCK_GATING = '0') generate
    mclk_r9 <= mclk;
  end generate;


  CLOCK_GATING_GENERATING_21 : if (CLOCK_GATING = '1') generate
    processing_15 : process (mclk_r9, puc_rst)
    begin
      if (puc_rst) then
        r9 <= X"0000";
      elsif (rising_edge(mclk_r9)) then
        if (r9_wr) then
          r9 <= reg_dest_val_in;
        else
          r9 <= reg_incr_val;
        end if;
      end if;
    end process;
  elsif (CLOCK_GATING = '0') generate
    processing_16 : process (mclk_r9, puc_rst)
    begin
      if (puc_rst) then
        r9 <= X"0000";
      elsif (rising_edge(mclk_r9)) then
        if (r9_wr) then
          r9 <= reg_dest_val_in;
        elsif (r9_inc) then
          r9 <= reg_incr_val;
        end if;
      end if;
    end process;
  end generate;


  -- R10
  ------
  r10_wr <= inst_dest(10) and reg_dest_wr;
  r10_inc <= inst_src_in(10) and reg_incr;

  CLOCK_GATING_GENERATING_22 : if (CLOCK_GATING = '1') generate
    r10_en <= r10_wr or r10_inc;

    clock_gate_r10 : omsp_clock_gate
    port map (
      gclk => mclk_r10,
      clk => mclk,
      enable => r10_en,
      scan_enable => scan_enable
    );
  elsif (CLOCK_GATING = '0') generate
    mclk_r10 <= mclk;
  end generate;


  CLOCK_GATING_GENERATING_23 : if (CLOCK_GATING = '1') generate
    processing_17 : process (mclk_r10, puc_rst)
    begin
      if (puc_rst) then
        r10 <= X"0000";
      elsif (rising_edge(mclk_r10)) then
        if (r10_wr) then
          r10 <= reg_dest_val_in;
        else
          r10 <= reg_incr_val;
        end if;
      end if;
    end process;
  elsif (CLOCK_GATING = '0') generate
    processing_18 : process (mclk_r10, puc_rst)
    begin
      if (puc_rst) then
        r10 <= X"0000";
      elsif (rising_edge(mclk_r10)) then
        if (r10_wr) then
          r10 <= reg_dest_val_in;
        elsif (r10_inc) then
          r10 <= reg_incr_val;
        end if;
      end if;
    end process;
  end generate;


  -- R11
  ------
  r11_wr <= inst_dest(11) and reg_dest_wr;
  r11_inc <= inst_src_in(11) and reg_incr;

  CLOCK_GATING_GENERATING_24 : if (CLOCK_GATING = '1') generate
    r11_en <= r11_wr or r11_inc;

    clock_gate_r11 : omsp_clock_gate
    port map (
      gclk => mclk_r11,
      clk => mclk,
      enable => r11_en,
      scan_enable => scan_enable
    );
  elsif (CLOCK_GATING = '0') generate
    mclk_r11 <= mclk;
  end generate;


  CLOCK_GATING_GENERATING_25 : if (CLOCK_GATING = '1') generate
    processing_19 : process (mclk_r11, puc_rst)
    begin
      if (puc_rst) then
        r11 <= X"0000";
      elsif (rising_edge(mclk_r11)) then
        if (r11_wr) then
          r11 <= reg_dest_val_in;
        else
          r11 <= reg_incr_val;
        end if;
      end if;
    end process;
  elsif (CLOCK_GATING = '0') generate
    processing_20 : process (mclk_r11, puc_rst)
    begin
      if (puc_rst) then
        r11 <= X"0000";
      elsif (rising_edge(mclk_r11)) then
        if (r11_wr) then
          r11 <= reg_dest_val_in;
        elsif (r11_inc) then
          r11 <= reg_incr_val;
        end if;
      end if;
    end process;
  end generate;


  -- R12
  ------
  r12_wr <= inst_dest(12) and reg_dest_wr;
  r12_inc <= inst_src_in(12) and reg_incr;

  CLOCK_GATING_GENERATING_26 : if (CLOCK_GATING = '1') generate
    r12_en <= r12_wr or r12_inc;

    clock_gate_r12 : omsp_clock_gate
    port map (
      gclk => mclk_r12,
      clk => mclk,
      enable => r12_en,
      scan_enable => scan_enable
    );
  elsif (CLOCK_GATING = '0') generate
    mclk_r12 <= mclk;
  end generate;


  CLOCK_GATING_GENERATING_27 : if (CLOCK_GATING = '1') generate
    processing_21 : process (mclk_r12, puc_rst)
    begin
      if (puc_rst) then
        r12 <= X"0000";
      elsif (rising_edge(mclk_r12)) then
        if (r12_wr) then
          r12 <= reg_dest_val_in;
        else
          r12 <= reg_incr_val;
        end if;
      end if;
    end process;
  elsif (CLOCK_GATING = '0') generate
    processing_22 : process (mclk_r12, puc_rst)
    begin
      if (puc_rst) then
        r12 <= X"0000";
      elsif (rising_edge(mclk_r12)) then
        if (r12_wr) then
          r12 <= reg_dest_val_in;
        elsif (r12_inc) then
          r12 <= reg_incr_val;
        end if;
      end if;
    end process;
  end generate;


  -- R13
  ------
  r13_wr <= inst_dest(13) and reg_dest_wr;
  r13_inc <= inst_src_in(13) and reg_incr;

  CLOCK_GATING_GENERATING_28 : if (CLOCK_GATING = '1') generate
    r13_en <= r13_wr or r13_inc;

    clock_gate_r13 : omsp_clock_gate
    port map (
      gclk => mclk_r13,
      clk => mclk,
      enable => r13_en,
      scan_enable => scan_enable
    );
  elsif (CLOCK_GATING = '0') generate
    mclk_r13 <= mclk;
  end generate;


  CLOCK_GATING_GENERATING_29 : if (CLOCK_GATING = '1') generate
    processing_23 : process (mclk_r13, puc_rst)
    begin
      if (puc_rst) then
        r13 <= X"0000";
      elsif (rising_edge(mclk_r13)) then
        if (r13_wr) then
          r13 <= reg_dest_val_in;
        else
          r13 <= reg_incr_val;
        end if;
      end if;
    end process;
  elsif (CLOCK_GATING = '0') generate
    processing_24 : process (mclk_r13, puc_rst)
    begin
      if (puc_rst) then
        r13 <= X"0000";
      elsif (rising_edge(mclk_r13)) then
        if (r13_wr) then
          r13 <= reg_dest_val_in;
        elsif (r13_inc) then
          r13 <= reg_incr_val;
        end if;
      end if;
    end process;
  end generate;


  -- R14
  ------
  r14_wr <= inst_dest(14) and reg_dest_wr;
  r14_inc <= inst_src_in(14) and reg_incr;

  CLOCK_GATING_GENERATING_30 : if (CLOCK_GATING = '1') generate
    r14_en <= r14_wr or r14_inc;

    clock_gate_r14 : omsp_clock_gate
    port map (
      gclk => mclk_r14,
      clk => mclk,
      enable => r14_en,
      scan_enable => scan_enable
    );
  elsif (CLOCK_GATING = '0') generate
    mclk_r14 <= mclk;
  end generate;


  CLOCK_GATING_GENERATING_31 : if (CLOCK_GATING = '1') generate
    processing_25 : process (mclk_r14, puc_rst)
    begin
      if (puc_rst) then
        r14 <= X"0000";
      elsif (rising_edge(mclk_r14)) then
        if (r14_wr) then
          r14 <= reg_dest_val_in;
        else
          r14 <= reg_incr_val;
        end if;
      end if;
    end process;
  elsif (CLOCK_GATING = '0') generate
    processing_26 : process (mclk_r14, puc_rst)
    begin
      if (puc_rst) then
        r14 <= X"0000";
      elsif (rising_edge(mclk_r14)) then
        if (r14_wr) then
          r14 <= reg_dest_val_in;
        elsif (r14_inc) then
          r14 <= reg_incr_val;
        end if;
      end if;
    end process;
  end generate;


  -- R15
  ------
  r15_wr <= inst_dest(15) and reg_dest_wr;
  r15_inc <= inst_src_in(15) and reg_incr;

  CLOCK_GATING_GENERATING_32 : if (CLOCK_GATING = '1') generate
    r15_en <= r15_wr or r15_inc;

    clock_gate_r15 : omsp_clock_gate
    port map (
      gclk => mclk_r15,
      clk => mclk,
      enable => r15_en,
      scan_enable => scan_enable
    );
  elsif (CLOCK_GATING = '0') generate
    mclk_r15 <= mclk;
  end generate;


  CLOCK_GATING_GENERATING_33 : if (CLOCK_GATING = '1') generate
    processing_27 : process (mclk_r15, puc_rst)
    begin
      if (puc_rst) then
        r15 <= X"0000";
      elsif (rising_edge(mclk_r15)) then
        if (r15_wr) then
          r15 <= reg_dest_val_in;
        else
          r15 <= reg_incr_val;
        end if;
      end if;
    end process;
  elsif (CLOCK_GATING = '0') generate
    processing_28 : process (mclk_r15, puc_rst)
    begin
      if (puc_rst) then
        r15 <= X"0000";
      elsif (rising_edge(mclk_r15)) then
        if (r15_wr) then
          r15 <= reg_dest_val_in;
        elsif (r15_inc) then
          r15 <= reg_incr_val;
        end if;
      end if;
    end process;
  end generate;


  --=============================================================================
  -- 5)  READ MUX
  --=============================================================================

  reg_src <= (r0 and concatenate(16, inst_src_in(0))) or (r1 and concatenate(16, inst_src_in(1))) or (r2 and concatenate(16, inst_src_in(2))) or (r3 and concatenate(16, inst_src_in(3))) or (r4 and concatenate(16, inst_src_in(4))) or (r5 and concatenate(16, inst_src_in(5))) or (r6 and concatenate(16, inst_src_in(6))) or (r7 and concatenate(16, inst_src_in(7))) or (r8 and concatenate(16, inst_src_in(8))) or (r9 and concatenate(16, inst_src_in(9))) or (r10 and concatenate(16, inst_src_in(10))) or (r11 and concatenate(16, inst_src_in(11))) or (r12 and concatenate(16, inst_src_in(12))) or (r13 and concatenate(16, inst_src_in(13))) or (r14 and concatenate(16, inst_src_in(14))) or (r15 and concatenate(16, inst_src_in(15)));

  reg_dest <= (r0 and concatenate(16, inst_dest(0))) or (r1 and concatenate(16, inst_dest(1))) or (r2 and concatenate(16, inst_dest(2))) or (r3 and concatenate(16, inst_dest(3))) or (r4 and concatenate(16, inst_dest(4))) or (r5 and concatenate(16, inst_dest(5))) or (r6 and concatenate(16, inst_dest(6))) or (r7 and concatenate(16, inst_dest(7))) or (r8 and concatenate(16, inst_dest(8))) or (r9 and concatenate(16, inst_dest(9))) or (r10 and concatenate(16, inst_dest(10))) or (r11 and concatenate(16, inst_dest(11))) or (r12 and concatenate(16, inst_dest(12))) or (r13 and concatenate(16, inst_dest(13))) or (r14 and concatenate(16, inst_dest(14))) or (r15 and concatenate(16, inst_dest(15)));
end RTL;
