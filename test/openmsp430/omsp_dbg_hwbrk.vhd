-- Converted from omsp_dbg_hwbrk.v
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
-- *File Name: omsp_dbg_hwbrk.v
--
-- *Module Description:
--                       Hardware Breakpoint / Watchpoint module
--
-- *Author(s):
--              - Olivier Girard,    olgirard@gmail.com
--

use work."openMSP430_defines.v".all;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity omsp_dbg_hwbrk is
  port (
  -- OUTPUTs
  --========
    brk_halt : out std_logic;  -- Hardware breakpoint command
    brk_pnd : out std_logic;  -- Hardware break/watch-point pending
    brk_dout : out std_logic_vector(15 downto 0);  -- Hardware break/watch-point register data input

  -- INPUTs
  --=======
    brk_reg_rd : in std_logic_vector(3 downto 0);  -- Hardware break/watch-point register read select
    brk_reg_wr : in std_logic_vector(3 downto 0);  -- Hardware break/watch-point register write select
    dbg_clk : in std_logic;  -- Debug unit clock
    dbg_din : in std_logic_vector(15 downto 0);  -- Debug register data input
    dbg_rst : in std_logic;  -- Debug unit reset
    decode_noirq : in std_logic;  -- Frontend decode instruction
    eu_mab : in std_logic_vector(15 downto 0);  -- Execution-Unit Memory address bus
    eu_mb_en : in std_logic;  -- Execution-Unit Memory bus enable
    eu_mb_wr : in std_logic_vector(1 downto 0)   -- Execution-Unit Memory bus write transfer
    pc : in std_logic_vector(15 downto 0)  -- Program counter
  );
end omsp_dbg_hwbrk;

architecture RTL of omsp_dbg_hwbrk is
  --=============================================================================
  -- 1)  WIRE & PARAMETER DECLARATION
  --=============================================================================

  signal range_wr_set : std_logic;
  signal range_rd_set : std_logic;
  signal addr1_wr_set : std_logic;
  signal addr1_rd_set : std_logic;
  signal addr0_wr_set : std_logic;
  signal addr0_rd_set : std_logic;

  constant BRK_CTL : integer := 0;
  constant BRK_STAT : integer := 1;
  constant BRK_ADDR0 : integer := 2;
  constant BRK_ADDR1 : integer := 3;

  --=============================================================================
  -- 2)  CONFIGURATION REGISTERS
  --=============================================================================

  -- BRK_CTL Register
  -------------------------------------------------------------------------------
  --       7   6   5        4            3          2            1  0
  --        Reserved    RANGE_MODE    INST_EN    BREAK_EN    ACCESS_MODE
  --
  -- ACCESS_MODE: - 00 : Disabled
  --              - 01 : Detect read access
  --              - 10 : Detect write access
  --              - 11 : Detect read/write access
  --              NOTE: '10' & '11' modes are not supported on the instruction flow
  --
  -- BREAK_EN:    -  0 : Watchmode enable
  --              -  1 : Break enable
  --
  -- INST_EN:     -  0 : Checks are done on the execution unit (data flow)
  --              -  1 : Checks are done on the frontend (instruction flow)
  --
  -- RANGE_MODE:  -  0 : Address match on BRK_ADDR0 or BRK_ADDR1
  --              -  1 : Address match on BRK_ADDR0->BRK_ADDR1 range
  --
  -------------------------------------------------------------------------------

  signal brk_ctl : std_logic_vector(4 downto 0);

  signal brk_ctl_wr : std_logic;

  signal brk_ctl_full : std_logic_vector(7 downto 0);

  -- BRK_STAT Register
  -------------------------------------------------------------------------------
  --     7    6       5         4         3         2         1         0
  --    Reserved  RANGE_WR  RANGE_RD  ADDR1_WR  ADDR1_RD  ADDR0_WR  ADDR0_RD
  -------------------------------------------------------------------------------
  signal brk_stat : std_logic_vector(5 downto 0);

  signal brk_stat_wr : std_logic;
  signal brk_stat_set : std_logic_vector(5 downto 0);
  signal brk_stat_clr : std_logic_vector(5 downto 0);

  signal brk_stat_full : std_logic_vector(7 downto 0);
  signal brk_pnd : std_logic;

  -- BRK_ADDR0 Register
  ---------------------
  signal brk_addr0 : std_logic_vector(15 downto 0);

  signal brk_addr0_wr : std_logic;

  -- BRK_ADDR1/DATA0 Register
  ---------------------------
  signal brk_addr1 : std_logic_vector(15 downto 0);

  signal brk_addr1_wr : std_logic;

  --============================================================================
  -- 3) DATA OUTPUT GENERATION
  --============================================================================

  signal brk_ctl_rd : std_logic_vector(15 downto 0);
  signal brk_stat_rd : std_logic_vector(15 downto 0);
  signal brk_addr0_rd : std_logic_vector(15 downto 0);
  signal brk_addr1_rd : std_logic_vector(15 downto 0);

  signal brk_dout : std_logic_vector(15 downto 0);

  --============================================================================
  -- 4) BREAKPOINT / WATCHPOINT GENERATION
  --============================================================================

  -- Comparators
  --------------
  -- Note: here the comparison logic is instanciated several times in order
  --       to improve the timings, at the cost of a bit more area.

  signal equ_d_addr0 : std_logic;
  signal equ_d_addr1 : std_logic;
  signal equ_d_range : std_logic;

  signal equ_i_addr0 : std_logic;
  signal equ_i_addr1 : std_logic;
  signal equ_i_range : std_logic;

  -- Detect accesses
  ------------------

  -- Detect Instruction read access
  signal i_addr0_rd : std_logic;
  signal i_addr1_rd : std_logic;
  signal i_range_rd : std_logic;

  -- Detect Execution-Unit write access
  signal d_addr0_wr : std_logic;
  signal d_addr1_wr : std_logic;
  signal d_range_wr : std_logic;

  -- Detect DATA read access
  signal d_addr0_rd : std_logic;
  signal d_addr1_rd : std_logic;
  signal d_range_rd : std_logic;

begin
  --=============================================================================
  -- 2)  CONFIGURATION REGISTERS
  --=============================================================================

  -- BRK_CTL Register
  -------------------------------------------------------------------------------
  --       7   6   5        4            3          2            1  0
  --        Reserved    RANGE_MODE    INST_EN    BREAK_EN    ACCESS_MODE
  --
  -- ACCESS_MODE: - 00 : Disabled
  --              - 01 : Detect read access
  --              - 10 : Detect write access
  --              - 11 : Detect read/write access
  --              NOTE: '10' & '11' modes are not supported on the instruction flow
  --
  -- BREAK_EN:    -  0 : Watchmode enable
  --              -  1 : Break enable
  --
  -- INST_EN:     -  0 : Checks are done on the execution unit (data flow)
  --              -  1 : Checks are done on the frontend (instruction flow)
  --
  -- RANGE_MODE:  -  0 : Address match on BRK_ADDR0 or BRK_ADDR1
  --              -  1 : Address match on BRK_ADDR0->BRK_ADDR1 range
  --
  -------------------------------------------------------------------------------

  brk_ctl_wr <= brk_reg_wr(BRK_CTL);

  processing_0 : process (dbg_clk, dbg_rst)
  begin
    if (dbg_rst) then
      brk_ctl <= X"00";
    elsif (rising_edge(dbg_clk)) then
      if (brk_ctl_wr) then
        brk_ctl <= (HWBRK_RANGE and dbg_din(4) & dbg_din(3 downto 0));
      end if;
    end if;
  end process;


  brk_ctl_full <= ("000" & brk_ctl);

  -- BRK_STAT Register
  -------------------------------------------------------------------------------
  --     7    6       5         4         3         2         1         0
  --    Reserved  RANGE_WR  RANGE_RD  ADDR1_WR  ADDR1_RD  ADDR0_WR  ADDR0_RD
  -------------------------------------------------------------------------------
  brk_stat_wr <= brk_reg_wr(BRK_STAT);
  brk_stat_set <= (range_wr_set and HWBRK_RANGE & range_rd_set and HWBRK_RANGE & addr1_wr_set & addr1_rd_set & addr0_wr_set & addr0_rd_set);
  brk_stat_clr <= not dbg_din(5 downto 0);

  processing_1 : process (dbg_clk, dbg_rst)
  begin
    if (dbg_rst) then
      brk_stat <= X"00";
    elsif (rising_edge(dbg_clk)) then
      if (brk_stat_wr) then
        brk_stat <= ((brk_stat and brk_stat_clr) or brk_stat_set);
      else
        brk_stat <= (brk_stat or brk_stat_set);
      end if;
    end if;
  end process;


  brk_stat_full <= ("00" & brk_stat);
  brk_pnd <= or brk_stat;

  -- BRK_ADDR0 Register
  ---------------------
  brk_addr0_wr <= brk_reg_wr(BRK_ADDR0);

  processing_2 : process (dbg_clk, dbg_rst)
  begin
    if (dbg_rst) then
      brk_addr0 <= X"0000";
    elsif (rising_edge(dbg_clk)) then
      if (brk_addr0_wr) then
        brk_addr0 <= dbg_din;
      end if;
    end if;
  end process;


  -- BRK_ADDR1/DATA0 Register
  ---------------------------
  brk_addr1_wr <= brk_reg_wr(BRK_ADDR1);

  processing_3 : process (dbg_clk, dbg_rst)
  begin
    if (dbg_rst) then
      brk_addr1 <= X"0000";
    elsif (rising_edge(dbg_clk)) then
      if (brk_addr1_wr) then
        brk_addr1 <= dbg_din;
      end if;
    end if;
  end process;


  --============================================================================
  -- 3) DATA OUTPUT GENERATION
  --============================================================================

  brk_ctl_rd <= (X"00" & brk_ctl_full) and concatenate(16, brk_reg_rd(BRK_CTL));
  brk_stat_rd <= (X"00" & brk_stat_full) and concatenate(16, brk_reg_rd(BRK_STAT));
  brk_addr0_rd <= brk_addr0 and concatenate(16, brk_reg_rd(BRK_ADDR0));
  brk_addr1_rd <= brk_addr1 and concatenate(16, brk_reg_rd(BRK_ADDR1));

  brk_dout <= brk_ctl_rd or brk_stat_rd or brk_addr0_rd or brk_addr1_rd;

  --============================================================================
  -- 4) BREAKPOINT / WATCHPOINT GENERATION
  --============================================================================

  -- Comparators
  --------------
  -- Note: here the comparison logic is instanciated several times in order
  --       to improve the timings, at the cost of a bit more area.

  equ_d_addr0 <= eu_mb_en and (eu_mab = brk_addr0) and not brk_ctl(BRK_RANGE);
  equ_d_addr1 <= eu_mb_en and (eu_mab = brk_addr1) and not brk_ctl(BRK_RANGE);
  equ_d_range <= eu_mb_en and ((eu_mab >= brk_addr0) and (eu_mab <= brk_addr1)) and brk_ctl(BRK_RANGE) and HWBRK_RANGE;

  equ_i_addr0 <= decode_noirq and (pc = brk_addr0) and not brk_ctl(BRK_RANGE);
  equ_i_addr1 <= decode_noirq and (pc = brk_addr1) and not brk_ctl(BRK_RANGE);
  equ_i_range <= decode_noirq and ((pc >= brk_addr0) and (pc <= brk_addr1)) and brk_ctl(BRK_RANGE) and HWBRK_RANGE;

  -- Detect accesses
  ------------------

  -- Detect Instruction read access
  i_addr0_rd <= equ_i_addr0 and brk_ctl(BRK_I_EN);
  i_addr1_rd <= equ_i_addr1 and brk_ctl(BRK_I_EN);
  i_range_rd <= equ_i_range and brk_ctl(BRK_I_EN);

  -- Detect Execution-Unit write access
  d_addr0_wr <= equ_d_addr0 and not brk_ctl(BRK_I_EN) and or eu_mb_wr;
  d_addr1_wr <= equ_d_addr1 and not brk_ctl(BRK_I_EN) and or eu_mb_wr;
  d_range_wr <= equ_d_range and not brk_ctl(BRK_I_EN) and or eu_mb_wr;

  -- Detect DATA read access
  d_addr0_rd <= equ_d_addr0 and not brk_ctl(BRK_I_EN) and nor eu_mb_wr;
  d_addr1_rd <= equ_d_addr1 and not brk_ctl(BRK_I_EN) and nor eu_mb_wr;
  d_range_rd <= equ_d_range and not brk_ctl(BRK_I_EN) and nor eu_mb_wr;

  -- Set flags
  addr0_rd_set <= brk_ctl(BRK_MODE_RD) and (d_addr0_rd or i_addr0_rd);
  addr0_wr_set <= brk_ctl(BRK_MODE_WR) and d_addr0_wr;
  addr1_rd_set <= brk_ctl(BRK_MODE_RD) and (d_addr1_rd or i_addr1_rd);
  addr1_wr_set <= brk_ctl(BRK_MODE_WR) and d_addr1_wr;
  range_rd_set <= brk_ctl(BRK_MODE_RD) and (d_range_rd or i_range_rd);
  range_wr_set <= brk_ctl(BRK_MODE_WR) and d_range_wr;

  -- Break CPU
  brk_halt <= brk_ctl(BRK_EN) and or brk_stat_set;
end RTL;
