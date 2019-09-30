-- Converted from omsp_mem_backbone.v
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
-- *File Name: omsp_mem_backbone.v
--
-- *Module Description:
--                       Memory interface backbone (decoder + arbiter)
--
-- *Author(s):
--              - Olivier Girard,    olgirard@gmail.com
--

use work."openMSP430_defines.v".all;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity omsp_mem_backbone is
  port (
  -- OUTPUTs
  --========
    cpu_halt_cmd : out std_logic;  -- Halt CPU command
    dbg_mem_din : out std_logic_vector(15 downto 0);  -- Debug unit Memory data input
    dmem_addr : out std_logic_vector(DMEM_MSB downto 0);  -- Data Memory address
    dmem_cen : out std_logic;  -- Data Memory chip enable (low active)
    dmem_din : out std_logic_vector(15 downto 0);  -- Data Memory data input
    dmem_wen : out std_logic_vector(1 downto 0);  -- Data Memory write enable (low active)
    eu_mdb_in : out std_logic_vector(15 downto 0);  -- Execution Unit Memory data bus input
    fe_mdb_in : out std_logic_vector(15 downto 0);  -- Frontend Memory data bus input
    fe_pmem_wait : out std_logic;  -- Frontend wait for Instruction fetch
    dma_dout : out std_logic_vector(15 downto 0);  -- Direct Memory Access data output
    dma_ready : out std_logic;  -- Direct Memory Access is complete
    dma_resp : out std_logic;  -- Direct Memory Access response (0:Okay / 1:Error)
    per_addr : out std_logic_vector(13 downto 0);  -- Peripheral address
    per_din : out std_logic_vector(15 downto 0);  -- Peripheral data input
    per_we : out std_logic_vector(1 downto 0);  -- Peripheral write enable (high active)
    per_en : out std_logic;  -- Peripheral enable (high active)
    pmem_addr : out std_logic_vector(PMEM_MSB downto 0);  -- Program Memory address
    pmem_cen : out std_logic;  -- Program Memory chip enable (low active)
    pmem_din : out std_logic_vector(15 downto 0);  -- Program Memory data input (optional)
    pmem_wen : out std_logic_vector(1 downto 0);  -- Program Memory write enable (low active) (optional)

  -- INPUTs
  --=======
    cpu_halt_st : in std_logic;  -- Halt/Run status from CPU
    dbg_halt_cmd : in std_logic;  -- Debug interface Halt CPU command
    dbg_mem_addr : in std_logic_vector(15 downto 1);  -- Debug address for rd/wr access
    dbg_mem_dout : in std_logic_vector(15 downto 0);  -- Debug unit data output
    dbg_mem_en : in std_logic;  -- Debug unit memory enable
    dbg_mem_wr : in std_logic_vector(1 downto 0);  -- Debug unit memory write
    dmem_dout : in std_logic_vector(15 downto 0);  -- Data Memory data output
    eu_mab : in std_logic_vector(14 downto 0);  -- Execution Unit Memory address bus
    eu_mb_en : in std_logic;  -- Execution Unit Memory bus enable
    eu_mb_wr : in std_logic_vector(1 downto 0);  -- Execution Unit Memory bus write transfer
    eu_mdb_out : in std_logic_vector(15 downto 0);  -- Execution Unit Memory data bus output
    fe_mab : in std_logic_vector(14 downto 0);  -- Frontend Memory address bus
    fe_mb_en : in std_logic;  -- Frontend Memory bus enable
    mclk : in std_logic;  -- Main system clock
    dma_addr : in std_logic_vector(15 downto 1);  -- Direct Memory Access address
    dma_din : in std_logic_vector(15 downto 0);  -- Direct Memory Access data input
    dma_en : in std_logic;  -- Direct Memory Access enable (high active)
    dma_priority : in std_logic;  -- Direct Memory Access priority (0:low / 1:high)
    dma_we : in std_logic_vector(1 downto 0);  -- Direct Memory Access write byte enable (high active)
    per_dout : in std_logic_vector(15 downto 0);  -- Peripheral data output
    pmem_dout : in std_logic_vector(15 downto 0);  -- Program Memory data output
    puc_rst : in std_logic   -- Main system reset
    scan_enable : in std_logic  -- Scan enable (active during scan shifting)
  );
end omsp_mem_backbone;

architecture RTL of omsp_mem_backbone is
  component omsp_clock_gate
  port (
    gclk : std_logic_vector(? downto 0);
    clk : std_logic_vector(? downto 0);
    enable : std_logic_vector(? downto 0);
    scan_enable : std_logic_vector(? downto 0)
  );
  end component;

  --=============================================================================
  -- 1)  DECODER
  --=============================================================================

  --------------------------------------------
  -- Arbiter between DMA and Debug interface
  --------------------------------------------

  -- Use delayed version of 'dma_ready' to mask the 'dma_dout' data output
  -- when not accessed and reduce toggle rate (thus power consumption)
  signal dma_ready_dly : std_logic;

  -- Mux between debug and master interface
  signal ext_mem_en : std_logic;
  signal ext_mem_wr : std_logic_vector(1 downto 0);
  signal ext_mem_addr : std_logic_vector(15 downto 1);
  signal ext_mem_dout : std_logic_vector(15 downto 0);

  -- External interface read data
  signal ext_mem_din : std_logic_vector(15 downto 0);

  --------------------------------------------
  -- DATA-MEMORY Interface
  --------------------------------------------
  constant DMEM_BASE : integer := 512;
  constant DMEM_SIZE : integer := 512;

  constant DMEM_END : integer := DMEM_BASE+DMEM_SIZE;

  -- Execution unit access
  signal eu_dmem_sel : std_logic;
  signal eu_dmem_en : std_logic;
  signal eu_dmem_addr : std_logic_vector(15 downto 0);

  -- Front-end access
  -- -- not allowed to execute from data memory --

  -- External Master/Debug interface access
  signal ext_dmem_sel : std_logic;
  signal ext_dmem_en : std_logic;

  -- External Master/Debug interface access
  signal ext_dmem_addr : std_logic_vector(15 downto 0);

  -- Data-Memory Interface
  signal dmem_cen : std_logic;
  signal dmem_wen : std_logic_vector(1 downto 0);
  signal dmem_addr : std_logic_vector(DMEM_MSB downto 0);
  signal dmem_din : std_logic_vector(15 downto 0);

  --------------------------------------------
  -- PROGRAM-MEMORY Interface
  --------------------------------------------
  constant PMEM_SIZE : integer := 512;
  constant PMEM_OFFSET : std_logic_vector(15 downto 0) := (X"FFFF"-PMEM_SIZE+1);

  -- Execution unit access (only read access are accepted)
  signal eu_pmem_sel : std_logic;
  signal eu_pmem_en : std_logic;
  signal eu_pmem_addr : std_logic_vector(15 downto 0);

  -- Front-end access
  signal fe_pmem_sel : std_logic;
  signal fe_pmem_en : std_logic;
  signal fe_pmem_addr : std_logic_vector(15 downto 0);

  -- External Master/Debug interface access
  signal ext_pmem_sel : std_logic;
  signal ext_pmem_en : std_logic;
  signal ext_pmem_addr : std_logic_vector(15 downto 0);

  -- Program-Memory Interface (Execution unit has priority over the Front-end)
  signal pmem_cen : std_logic;
  signal pmem_wen : std_logic_vector(1 downto 0);
  signal pmem_addr : std_logic_vector(PMEM_MSB downto 0);
  signal pmem_din : std_logic_vector(15 downto 0);

  signal fe_pmem_wait : std_logic;

  --------------------------------------------
  -- PERIPHERALS Interface
  --------------------------------------------

  -- Execution unit access
  signal eu_per_sel : std_logic;
  signal eu_per_en : std_logic;

  -- Front-end access
  -- -- not allowed to execute from peripherals memory space --

  -- External Master/Debug interface access
  signal ext_per_sel : std_logic;
  signal ext_per_en : std_logic;

  -- Peripheral Interface
  signal per_en : std_logic;
  signal per_we : std_logic_vector(1 downto 0);
  signal per_addr_mux : std_logic_vector(PER_MSB downto 0);
  signal per_addr_ful : std_logic_vector(14 downto 0);
  signal per_addr : std_logic_vector(13 downto 0);
  signal per_din : std_logic_vector(15 downto 0);

  -- Register peripheral data read path
  signal per_dout_val : std_logic_vector(15 downto 0);

  --------------------------------------------
  -- Frontend data Mux
  --------------------------------------------
  -- Whenever the frontend doesn't access the program memory,  backup the data

  -- Detect whenever the data should be backuped and restored
  signal fe_pmem_en_dly : std_logic;

  signal fe_pmem_save : std_logic;
  signal fe_pmem_restore : std_logic;

  signal mclk_bckup_gated : std_logic;

  signal pmem_dout_bckup : std_logic_vector(15 downto 0);

  -- Mux between the Program memory data and the backup
  signal pmem_dout_bckup_sel : std_logic;

  --------------------------------------------
  -- Execution-Unit data Mux
  --------------------------------------------

  -- Select between Peripherals, Program and Data memories
  signal eu_mdb_in_sel : std_logic_vector(1 downto 0);

  --------------------------------------------
  -- External Master/Debug interface data Mux
  --------------------------------------------

  -- Select between Peripherals, Program and Data memories
  signal ext_mem_din_sel : std_logic_vector(1 downto 0);

begin
  --=============================================================================
  -- 1)  DECODER
  --=============================================================================

  --------------------------------------------
  -- Arbiter between DMA and Debug interface
  --------------------------------------------

  -- Debug-interface always stops the CPU
  -- Master interface stops the CPU in priority mode
  cpu_halt_cmd <= dbg_halt_cmd or (dma_en and dma_priority);

  -- Return ERROR response if address lays outside the memory spaces (Peripheral, Data & Program memories)
  dma_resp <= not dbg_mem_en and not (ext_dmem_sel or ext_pmem_sel or ext_per_sel) and dma_en;

  -- Master interface access is ready when the memory access occures
  dma_ready <= not dbg_mem_en and (ext_dmem_en or ext_pmem_en or ext_per_en or dma_resp);

  -- Use delayed version of 'dma_ready' to mask the 'dma_dout' data output
  -- when not accessed and reduce toggle rate (thus power consumption)
  processing_0 : process (mclk, puc_rst)
  begin
    if (puc_rst) then
      dma_ready_dly <= '0';
    elsif (rising_edge(mclk)) then
      dma_ready_dly <= dma_ready;
    end if;
  end process;


  -- Mux between debug and master interface
  ext_mem_en <= dbg_mem_en or dma_en;
  ext_mem_wr <= dbg_mem_wr
  when dbg_mem_en else dma_we;
  ext_mem_addr <= dbg_mem_addr
  when dbg_mem_en else dma_addr;
  ext_mem_dout <= dbg_mem_dout
  when dbg_mem_en else dma_din;

  -- External interface read data
  dbg_mem_din <= ext_mem_din;
  dma_dout <= ext_mem_din and concatenate(16, dma_ready_dly);

  --------------------------------------------
  -- DATA-MEMORY Interface
  --------------------------------------------

  -- Execution unit access
  eu_dmem_sel <= (eu_mab >= (DMEM_BASE srl 1)) and (eu_mab < (DMEM_END srl 1));
  eu_dmem_en <= eu_mb_en and eu_dmem_sel;
  eu_dmem_addr <= ('0' & eu_mab)-(DMEM_BASE srl 1);

  -- Front-end access
  -- -- not allowed to execute from data memory --

  -- External Master/Debug interface access
  ext_dmem_sel <= (ext_mem_addr(15 downto 1) >= (DMEM_BASE srl 1)) and (ext_mem_addr(15 downto 1) < (DMEM_END srl 1));
  ext_dmem_en <= ext_mem_en and ext_dmem_sel and not eu_dmem_en;
  ext_dmem_addr <= ('0' & ext_mem_addr(15 downto 1))-(DMEM_BASE srl 1);

  -- Data-Memory Interface
  dmem_cen <= not (ext_dmem_en or eu_dmem_en);
  dmem_wen <= not ext_mem_wr
  when ext_dmem_en else not eu_mb_wr;
  dmem_addr <= ext_dmem_addr(DMEM_MSB downto 0)
  when ext_dmem_en else eu_dmem_addr(DMEM_MSB downto 0);
  dmem_din <= ext_mem_dout
  when ext_dmem_en else eu_mdb_out;

  --------------------------------------------
  -- PROGRAM-MEMORY Interface
  --------------------------------------------

  -- Execution unit access (only read access are accepted)
  eu_pmem_sel <= (eu_mab >= (PMEM_OFFSET srl 1));
  eu_pmem_en <= eu_mb_en and nor eu_mb_wr and eu_pmem_sel;
  eu_pmem_addr <= eu_mab-(PMEM_OFFSET srl 1);

  -- Front-end access
  fe_pmem_sel <= (fe_mab >= (PMEM_OFFSET srl 1));
  fe_pmem_en <= fe_mb_en and fe_pmem_sel;
  fe_pmem_addr <= fe_mab-(PMEM_OFFSET srl 1);

  -- External Master/Debug interface access
  ext_pmem_sel <= (ext_mem_addr(15 downto 1) >= (PMEM_OFFSET srl 1));
  ext_pmem_en <= ext_mem_en and ext_pmem_sel and not eu_pmem_en and not fe_pmem_en;
  ext_pmem_addr <= ('0' & ext_mem_addr(15 downto 1))-(PMEM_OFFSET srl 1);

  -- Program-Memory Interface (Execution unit has priority over the Front-end)
  pmem_cen <= not (fe_pmem_en or eu_pmem_en or ext_pmem_en);
  pmem_wen <= not ext_mem_wr
  when ext_pmem_en else "11";
  pmem_addr <= ext_pmem_addr(PMEM_MSB downto 0)
  when ext_pmem_en else eu_pmem_addr(PMEM_MSB downto 0)
  when eu_pmem_en else fe_pmem_addr(PMEM_MSB downto 0);
  pmem_din <= ext_mem_dout;

  fe_pmem_wait <= (fe_pmem_en and eu_pmem_en);

  --------------------------------------------
  -- PERIPHERALS Interface
  --------------------------------------------

  -- Execution unit access
  eu_per_sel <= (eu_mab < (PER_SIZE srl 1));
  eu_per_en <= eu_mb_en and eu_per_sel;

  -- Front-end access
  -- -- not allowed to execute from peripherals memory space --

  -- External Master/Debug interface access
  ext_per_sel <= (ext_mem_addr(15 downto 1) < (PER_SIZE srl 1));
  ext_per_en <= ext_mem_en and ext_per_sel and not eu_per_en;

  -- Peripheral Interface
  per_en <= ext_per_en or eu_per_en;
  per_we <= ext_mem_wr
  when ext_per_en else eu_mb_wr;
  per_addr_mux <= ext_mem_addr(PER_MSB+1 downto 1)
  when ext_per_en else eu_mab(PER_MSB downto 0);
  per_addr_ful <= (concatenate(15-PER_AWIDTH, '0') & per_addr_mux);
  per_addr <= per_addr_ful(13 downto 0);
  per_din <= ext_mem_dout
  when ext_per_en else eu_mdb_out;

  -- Register peripheral data read path
  processing_1 : process (mclk, puc_rst)
  begin
    if (puc_rst) then
      per_dout_val <= X"0000";
    elsif (rising_edge(mclk)) then
      per_dout_val <= per_dout;
    end if;
  end process;


  --------------------------------------------
  -- Frontend data Mux
  --------------------------------------------
  -- Whenever the frontend doesn't access the program memory,  backup the data

  -- Detect whenever the data should be backuped and restored
  processing_2 : process (mclk, puc_rst)
  begin
    if (puc_rst) then
      fe_pmem_en_dly <= '0';
    elsif (rising_edge(mclk)) then
      fe_pmem_en_dly <= fe_pmem_en;
    end if;
  end process;


  fe_pmem_save <= (not fe_pmem_en and fe_pmem_en_dly) and not cpu_halt_st;
  fe_pmem_restore <= (fe_pmem_en and not fe_pmem_en_dly) or cpu_halt_st;

  clock_gate_bckup : omsp_clock_gate
  port map (
    gclk => mclk_bckup_gated,
    clk => mclk,
    enable => fe_pmem_save,
    scan_enable => scan_enable
  );


  CLOCK_GATING_GENERATING_0 : if (CLOCK_GATING = '1') generate
    clock_gate_bckup : omsp_clock_gate
    port map (
      gclk => mclk_bckup_gated,
      clk => mclk,
      enable => fe_pmem_save,
      scan_enable => scan_enable
    );
  end generate;


  CLOCK_GATING_GENERATING_1 : if (CLOCK_GATING = '1') generate
    processing_3 : process (mclk_bckup_gated, puc_rst)
    begin
      if (puc_rst) then
        pmem_dout_bckup <= X"0000";
      elsif (rising_edge(mclk_bckup_gated)) then
        pmem_dout_bckup <= pmem_dout;
      end if;
    end process;
  elsif (CLOCK_GATING = '0') generate
    processing_4 : process (mclk, puc_rst)
    begin
      if (puc_rst) then
        pmem_dout_bckup <= X"0000";
      elsif (rising_edge(mclk)) then
        if (fe_pmem_save) then
          pmem_dout_bckup <= pmem_dout;
        end if;
      end if;
    end process;
  end generate;


  -- Mux between the Program memory data and the backup
  processing_5 : process (mclk, puc_rst)
  begin
    if (puc_rst) then
      pmem_dout_bckup_sel <= '0';
    elsif (rising_edge(mclk)) then
      if (fe_pmem_save) then
        pmem_dout_bckup_sel <= '1';
      elsif (fe_pmem_restore) then
        pmem_dout_bckup_sel <= '0';
      end if;
    end if;
  end process;


  fe_mdb_in <= pmem_dout_bckup
  when pmem_dout_bckup_sel else pmem_dout;

  --------------------------------------------
  -- Execution-Unit data Mux
  --------------------------------------------

  -- Select between Peripherals, Program and Data memories
  processing_6 : process (mclk, puc_rst)
  begin
    if (puc_rst) then
      eu_mdb_in_sel <= "00";
    elsif (rising_edge(mclk)) then
      eu_mdb_in_sel <= (eu_pmem_en & eu_per_en);
    end if;
  end process;


  -- Mux
  eu_mdb_in <= pmem_dout
  when eu_mdb_in_sel(1) else per_dout_val
  when eu_mdb_in_sel(0) else dmem_dout;

  --------------------------------------------
  -- External Master/Debug interface data Mux
  --------------------------------------------

  -- Select between Peripherals, Program and Data memories
  processing_7 : process (mclk, puc_rst)
  begin
    if (puc_rst) then
      ext_mem_din_sel <= "00";
    elsif (rising_edge(mclk)) then
      ext_mem_din_sel <= (ext_pmem_en & ext_per_en);
    end if;
  end process;


  -- Mux
  ext_mem_din <= pmem_dout
  when ext_mem_din_sel(1) else per_dout_val
  when ext_mem_din_sel(0) else dmem_dout;
end RTL;
