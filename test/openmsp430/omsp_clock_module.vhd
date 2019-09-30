-- Converted from omsp_clock_module.v
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
-- *File Name: omsp_clock_module.v
--
-- *Module Description:
--                       Basic clock module implementation.
--
-- *Author(s):
--              - Olivier Girard,    olgirard@gmail.com
--

use work."openMSP430_defines.v".all;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity omsp_clock_module is
  port (
  -- OUTPUTs
  --========
    aclk : out std_logic;  -- ACLK
    aclk_en : out std_logic;  -- ACLK enable
    cpu_en_s : out std_logic;  -- Enable CPU code execution (synchronous)
    cpu_mclk : out std_logic;  -- Main system CPU only clock
    dma_mclk : out std_logic;  -- Main system DMA and/or CPU clock
    dbg_clk : out std_logic;  -- Debug unit clock
    dbg_en_s : out std_logic;  -- Debug unit enable (synchronous)
    dbg_rst : out std_logic;  -- Debug unit reset
    dco_enable : out std_logic;  -- Fast oscillator enable
    dco_wkup : out std_logic;  -- Fast oscillator wake-up (asynchronous)
    lfxt_enable : out std_logic;  -- Low frequency oscillator enable
    lfxt_wkup : out std_logic;  -- Low frequency oscillator wake-up (asynchronous)
    per_dout : out std_logic_vector(15 downto 0);  -- Peripheral data output
    por : out std_logic;  -- Power-on reset
    puc_pnd_set : out std_logic;  -- PUC pending set for the serial debug interface
    puc_rst : out std_logic;  -- Main system reset
    smclk : out std_logic;  -- SMCLK
    smclk_en : out std_logic;  -- SMCLK enable

  -- INPUTs
  --=======
    cpu_en : in std_logic;  -- Enable CPU code execution (asynchronous)
    cpuoff : in std_logic;  -- Turns off the CPU
    dbg_cpu_reset : in std_logic;  -- Reset CPU from debug interface
    dbg_en : in std_logic;  -- Debug interface enable (asynchronous)
    dco_clk : in std_logic;  -- Fast oscillator (fast clock)
    lfxt_clk : in std_logic;  -- Low frequency oscillator (typ 32kHz)
    mclk_dma_enable : in std_logic;  -- DMA Sub-System Clock enable
    mclk_dma_wkup : in std_logic;  -- DMA Sub-System Clock wake-up (asynchronous)
    mclk_enable : in std_logic;  -- Main System Clock enable
    mclk_wkup : in std_logic;  -- Main System Clock wake-up (asynchronous)
    oscoff : in std_logic;  -- Turns off LFXT1 clock input
    per_addr : in std_logic_vector(13 downto 0);  -- Peripheral address
    per_din : in std_logic_vector(15 downto 0);  -- Peripheral data input
    per_en : in std_logic;  -- Peripheral enable (high active)
    per_we : in std_logic_vector(1 downto 0);  -- Peripheral write enable (high active)
    reset_n : in std_logic;  -- Reset Pin (low active, asynchronous)
    scan_enable : in std_logic;  -- Scan enable (active during scan shifting)
    scan_mode : in std_logic;  -- Scan mode
    scg0 : in std_logic;  -- System clock generator 1. Turns off the DCO
    scg1 : in std_logic   -- System clock generator 1. Turns off the SMCLK
    wdt_reset : in std_logic  -- Watchdog-timer reset
  );
end omsp_clock_module;

architecture RTL of omsp_clock_module is
  component omsp_and_gate
  port (
    y : std_logic_vector(? downto 0);
    a : std_logic_vector(? downto 0);
    b : std_logic_vector(? downto 0)
  );
  end component;

  component omsp_scan_mux
  port (
    scan_mode : std_logic_vector(? downto 0);
    data_in_scan : std_logic_vector(? downto 0);
    data_in_func : std_logic_vector(? downto 0);
    data_out : std_logic_vector(? downto 0)
  );
  end component;

  component omsp_sync_cell
  port (
    data_out : std_logic_vector(? downto 0);
    data_in : std_logic_vector(? downto 0);
    clk : std_logic_vector(? downto 0);
    rst : std_logic_vector(? downto 0)
  );
  end component;

  component omsp_clock_mux
  port (
    clk_out : std_logic_vector(? downto 0);
    clk_in0 : std_logic_vector(? downto 0);
    clk_in1 : std_logic_vector(? downto 0);
    reset : std_logic_vector(? downto 0);
    scan_mode : std_logic_vector(? downto 0);
    select_in : std_logic_vector(? downto 0)
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

  component omsp_sync_reset
  port (
    rst_s : std_logic_vector(? downto 0);
    clk : std_logic_vector(? downto 0);
    rst_a : std_logic_vector(? downto 0)
  );
  end component;

  --=============================================================================
  -- 1)  WIRES & PARAMETER DECLARATION
  --=============================================================================

  -- Register base address (must be aligned to decoder bit width)
  constant BASE_ADDR : std_logic_vector(14 downto 0) := X"0050";

  -- Decoder bit width (defines how many bits are considered for address decoding)
  constant DEC_WD : integer := 4;

  -- Register addresses offset
  constant BCSCTL1 : std_logic_vector(DEC_WD-1 downto 0) := X"7";
  constant BCSCTL2 : std_logic_vector(DEC_WD-1 downto 0) := X"8";

  -- Register one-hot decoder utilities
  constant DEC_SZ : integer := (1 sll DEC_WD);
  constant BASE_REG : std_logic_vector(DEC_SZ-1 downto 0) := (concatenate(DEC_SZ-1, '0') & '1');

  -- Register one-hot decoder
  constant BCSCTL1_D : std_logic_vector(DEC_SZ-1 downto 0) := (BASE_REG sll BCSCTL1);
  constant BCSCTL2_D : std_logic_vector(DEC_SZ-1 downto 0) := (BASE_REG sll BCSCTL2);

  -- Local wire declarations
  signal nodiv_mclk : std_logic;
  signal nodiv_smclk : std_logic;

  --============================================================================
  -- 2)  REGISTER DECODER
  --============================================================================

  -- Local register selection
  signal reg_sel : std_logic;

  -- Register local address
  signal reg_addr : std_logic_vector(DEC_WD-1 downto 0);

  -- Register address decode
  signal reg_dec : std_logic_vector(DEC_SZ-1 downto 0);

  -- Read/Write probes
  signal reg_lo_write : std_logic;
  signal reg_hi_write : std_logic;
  signal reg_read : std_logic;

  -- Read/Write vectors
  signal reg_hi_wr : std_logic_vector(DEC_SZ-1 downto 0);
  signal reg_lo_wr : std_logic_vector(DEC_SZ-1 downto 0);
  signal reg_rd : std_logic_vector(DEC_SZ-1 downto 0);

  --============================================================================
  -- 3) REGISTERS
  --============================================================================

  -- BCSCTL1 Register
  ----------------
  signal bcsctl1 : std_logic_vector(7 downto 0);
  signal bcsctl1_wr : std_logic;
  signal bcsctl1_nxt : std_logic_vector(7 downto 0);

  signal divax_mask : std_logic_vector(7 downto 0);

  signal dma_cpuoff_mask : std_logic_vector(7 downto 0);

  signal dma_scg0_mask : std_logic_vector(7 downto 0);
  signal dma_scg1_mask : std_logic_vector(7 downto 0);

  signal dma_oscoff_mask : std_logic_vector(7 downto 0);

  -- BCSCTL2 Register
  ----------------
  signal bcsctl2 : std_logic_vector(7 downto 0);
  signal bcsctl2_wr : std_logic;
  signal bcsctl2_nxt : std_logic_vector(7 downto 0);

  signal selmx_mask : std_logic_vector(7 downto 0);
  signal divmx_mask : std_logic_vector(7 downto 0);
  signal sels_mask : std_logic_vector(7 downto 0);
  signal divsx_mask : std_logic_vector(7 downto 0);

  --============================================================================
  -- 4) DATA OUTPUT GENERATION
  --============================================================================

  -- Data output mux
  signal bcsctl1_rd : std_logic_vector(15 downto 0);
  signal bcsctl2_rd : std_logic_vector(15 downto 0);

  signal per_dout : std_logic_vector(15 downto 0);

  --=============================================================================
  -- 5)  DCO_CLK / LFXT_CLK INTERFACES (WAKEUP, ENABLE, ...)
  --=============================================================================

  signal cpuoff_and_mclk_enable : std_logic;
  signal cpuoff_and_mclk_dma_enable : std_logic;
  signal cpuoff_and_mclk_dma_wkup : std_logic;

  signal scg0_and_mclk_dma_enable : std_logic;
  signal scg0_and_mclk_dma_wkup : std_logic;

  signal UNUSED_scg0_mclk_dma_wkup : std_logic;

  signal scg1_and_mclk_dma_enable : std_logic;
  signal scg1_and_mclk_dma_wkup : std_logic;

  signal UNUSED_scg1_mclk_dma_wkup : std_logic;

  signal oscoff_and_mclk_dma_enable : std_logic;
  signal oscoff_and_mclk_dma_wkup : std_logic;

  signal UNUSED_oscoff_mclk_dma_wkup : std_logic;

  signal UNUSED_cpuoff : std_logic;
  signal UNUSED_mclk_enable : std_logic;
  signal UNUSED_mclk_dma_wkup : std_logic;

  -------------------------------------------------------------
  -- 5.1) HIGH SPEED SYSTEM CLOCK GENERATOR (DCO_CLK)
  -------------------------------------------------------------
  -- Note1: switching off the DCO osillator is only
  --        supported in ASIC mode with SCG0 low power mode
  --
  -- Note2: unlike the original MSP430 specification,
  --        we allow to switch off the DCO even
  --        if it is selected by MCLK or SMCLK.

  signal por_a : std_logic;
  signal dco_wkup : std_logic;
  signal cpu_en_wkup : std_logic;

  -- The DCO oscillator is synchronously disabled if:
  --      - the cpu pin is disabled (in that case, wait for mclk_enable==0)
  --      - the debug interface is disabled
  --      - SCG0 is set (in that case, wait for the mclk_enable==0 if selected by SELMx)
  --
  -- Note that we make extensive use of the AND gate module in order
  -- to prevent glitch propagation on the wakeup logic cone.
  signal cpu_enabled_with_dco : std_logic;
  signal dco_not_enabled_by_dbg : std_logic;
  signal dco_disable_by_scg0 : std_logic;
  signal dco_disable_by_cpu_en : std_logic;
  signal dco_enable_nxt : std_logic;

  -- Register to prevent glitch propagation
  signal dco_disable : std_logic;
  signal dco_wkup_set_scan_observe : std_logic;

  -- Optional scan repair
  signal dco_clk_n : std_logic;

  -- Optional scan repair
  signal nodiv_mclk_n : std_logic;

  -- Re-time DCO enable with MCLK falling edge
  signal dco_enable : std_logic;

  -- The DCO oscillator will get an asynchronous wakeup if:
  --      - the MCLK  generates a wakeup (only if the MCLK mux selects dco_clk)
  --      - if the DCO wants to be synchronously enabled (i.e dco_enable_nxt=1)
  signal dco_mclk_wkup : std_logic;
  signal dco_en_wkup : std_logic;

  signal dco_wkup_set : std_logic;

  -- Scan MUX for the asynchronous SET
  signal dco_wkup_set_scan : std_logic;

  -- The wakeup is asynchronously set, synchronously released
  signal dco_wkup_n : std_logic;
  signal UNUSED_scg0 : std_logic;
  signal UNUSED_cpu_en_wkup1 : std_logic;

  -------------------------------------------------------------
  -- 5.2) LOW FREQUENCY CRYSTAL CLOCK GENERATOR (LFXT_CLK)
  -------------------------------------------------------------

  -- ASIC MODE
  --------------------------------------------------
  -- Note: unlike the original MSP430 specification,
  --       we allow to switch off the LFXT even
  --       if it is selected by MCLK or SMCLK.

  -- The LFXT is synchronously disabled if:
  --      - the cpu pin is disabled (in that case, wait for mclk_enable==0)
  --      - the debug interface is disabled
  --      - OSCOFF is set (in that case, wait for the mclk_enable==0 if selected by SELMx)
  signal cpu_enabled_with_lfxt : std_logic;
  signal lfxt_not_enabled_by_dbg : std_logic;
  signal lfxt_disable_by_oscoff : std_logic;
  signal lfxt_disable_by_cpu_en : std_logic;
  signal lfxt_enable_nxt : std_logic;

  -- Register to prevent glitch propagation
  signal lfxt_disable : std_logic;
  signal lfxt_wkup_set_scan_observe : std_logic;

  -- Optional scan repair
  signal lfxt_clk_n : std_logic;

  -- The LFXT will get an asynchronous wakeup if:
  --      - the MCLK  generates a wakeup (only if the MCLK  mux selects lfxt_clk)
  --      - if the LFXT wants to be synchronously enabled (i.e lfxt_enable_nxt=1)
  signal lfxt_mclk_wkup : std_logic;
  signal lfxt_en_wkup : std_logic;

  signal lfxt_wkup_set : std_logic;

  -- Scan MUX for the asynchronous SET
  signal lfxt_wkup_set_scan : std_logic;

  -- The wakeup is asynchronously set, synchronously released
  signal lfxt_wkup_n : std_logic;

  signal UNUSED_oscoff : std_logic;
  signal UNUSED_cpuoff_and_mclk_enable : std_logic;
  signal UNUSED_cpu_en_wkup2 : std_logic;

  -- FPGA MODE
  ------------
  -- Synchronize LFXT_CLK & edge detection

  signal lfxt_clk_s : std_logic;

  signal lfxt_clk_dly : std_logic;
  signal lfxt_clk_en : std_logic;

  --=============================================================================
  -- 6)  CLOCK GENERATION
  --=============================================================================

  -------------------------------------------------------------
  -- 6.1) GLOBAL CPU ENABLE
  ------------------------------------------------------------
  -- ACLK and SMCLK are directly switched-off
  -- with the cpu_en pin (after synchronization).
  -- MCLK will be switched off once the CPU reaches
  -- its IDLE state (through the mclk_enable signal)

  -- Synchronize CPU_EN signal to the ACLK domain
  ------------------------------------------------
  signal cpu_en_aux_s : std_logic;

  -- Synchronize CPU_EN signal to the SMCLK domain
  ------------------------------------------------
  -- Note: the synchronizer is only required if there is a SMCLK_MUX
  signal cpu_en_sm_s : std_logic;

  -------------------------------------------------------------
  -- 6.2) MCLK GENERATION
  -------------------------------------------------------------

  -- Clock MUX
  ------------

  -- Wakeup synchronizer
  ----------------------
  signal cpuoff_and_mclk_dma_wkup_s : std_logic;
  signal mclk_wkup_s : std_logic;

  signal UNUSED_mclk_wkup : std_logic;

  -- Clock Divider
  ----------------

  -- No need for extra synchronizer as bcsctl2
  -- comes from the same clock domain.

  signal mclk_active : std_logic;
  signal mclk_dma_active : std_logic;

  signal mclk_div : std_logic_vector(2 downto 0);

  signal mclk_div_sel : std_logic;

  signal mclk_div_en : std_logic;
  signal mclk_dma_div_en : std_logic;

  -------------------------------------------------------------
  -- 6.3) ACLK GENERATION
  -------------------------------------------------------------

  -- ASIC MODE
  ------------
  signal nodiv_aclk : std_logic;

  -- Synchronizers
  ----------------

  -- Local Reset synchronizer
  signal puc_lfxt_noscan_n : std_logic;
  signal puc_lfxt_rst : std_logic;

  -- If the OSCOFF mode is enabled synchronize OSCOFF signal
  signal oscoff_s : std_logic;

  -- Local synchronizer for the bcsctl1.DIVAx configuration
  -- (note that we can live with a full bus synchronizer as
  --  it won't hurt if we get a wrong DIVAx value for a single clock cycle)
  signal divax_s : std_logic_vector(1 downto 0);
  signal divax_ss : std_logic_vector(1 downto 0);

  -- Wakeup synchronizer
  ----------------------
  signal oscoff_and_mclk_dma_enable_s : std_logic;

  -- Clock Divider
  ----------------
  signal aclk_active : std_logic;

  signal aclk_div : std_logic_vector(2 downto 0);

  signal aclk_div_sel : std_logic;

  signal aclk_div_en : std_logic;

  -- Clock gate
  signal UNUSED_cpu_en_aux_s : std_logic;
  signal UNUSED_lfxt_clk : std_logic;

  -- FPGA MODE
  ------------
  signal aclk_en : std_logic;
  signal aclk_en_nxt : std_logic;

  signal UNUSED_scan_enable : std_logic;
  signal UNUSED_scan_mode : std_logic;

  -------------------------------------------------------------
  -- 6.4) SMCLK GENERATION
  -------------------------------------------------------------

  -- Clock MUX
  ------------

  -- ASIC MODE
  ------------

  -- SMCLK_MUX Synchronizers
  --------------------------------------------------------
  -- When the SMCLK MUX is enabled, the reset and DIVSx
  -- and SCG1 signals must be synchronized, otherwise not.

  -- Local Reset synchronizer
  signal puc_sm_noscan_n : std_logic;
  signal puc_sm_rst : std_logic;

  -- SCG1 synchronizer
  signal scg1_s : std_logic;

  signal UNUSED_scg1 : std_logic;
  signal UNUSED_puc_sm_rst : std_logic;

  -- Local synchronizer for the bcsctl2.DIVSx configuration
  -- (note that we can live with a full bus synchronizer as
  --  it won't hurt if we get a wrong DIVSx value for a single clock cycle)
  signal divsx_s : std_logic_vector(1 downto 0);
  signal divsx_ss : std_logic_vector(1 downto 0);

  -- Wakeup synchronizer
  ----------------------
  signal scg1_and_mclk_dma_enable_s : std_logic;

  -- Clock Divider
  ----------------
  signal smclk_active : std_logic;

  signal smclk_div_en : std_logic;

  -- FPGA MODE
  ------------
  signal smclk_en : std_logic;
  signal smclk_div : std_logic_vector(2 downto 0);

  signal smclk_in : std_logic;
  signal smclk_en_nxt : std_logic;
  signal smclk : std_logic;

  -------------------------------------------------------------
  -- 6.5) DEBUG INTERFACE CLOCK GENERATION (DBG_CLK)
  -------------------------------------------------------------

  -- Synchronize DBG_EN signal to MCLK domain
  -------------------------------------------
  signal dbg_en_n_s : std_logic;
  signal dbg_rst_nxt : std_logic;
  signal UNUSED_dbg_en : std_logic;

  --=============================================================================
  -- 7)  RESET GENERATION
  --=============================================================================
  --
  -- Whenever the reset pin (reset_n) is deasserted, the internal resets of the
  -- openMSP430 will be released in the following order:
  --                1- POR
  --                2- DBG_RST (if the sdi interface is enabled, i.e. dbg_en=1)
  --                3- PUC
  --
  -- Note: releasing the DBG_RST before PUC is particularly important in order
  --       to allow the sdi interface to halt the cpu immediately after a PUC.
  --

  -- Generate synchronized POR to MCLK domain
  -------------------------------------------

  -- Asynchronous reset source
  signal por_noscan : std_logic;

  -- Generate synchronized reset for the SDI
  ------------------------------------------

  -- Reset Generation
  signal dbg_rst_noscan : std_logic;

  -- Generate main system reset (PUC_RST)
  ---------------------------------------
  signal puc_noscan_n : std_logic;
  signal puc_a_scan : std_logic;

  -- Asynchronous PUC reset
  signal puc_a : std_logic;

  -- Synchronous PUC reset
  signal puc_s : std_logic;

begin
  --============================================================================
  -- 2)  REGISTER DECODER
  --============================================================================

  -- Local register selection
  reg_sel <= per_en and (per_addr(13 downto DEC_WD-1) = BASE_ADDR(14 downto DEC_WD));

  -- Register local address
  reg_addr <= ('0' & per_addr(DEC_WD-2 downto 0));

  -- Register address decode
  reg_dec <= (BCSCTL1_D and concatenate(DEC_SZ, (reg_addr = (BCSCTL1 srl 1)))) or (BCSCTL2_D and concatenate(DEC_SZ, (reg_addr = (BCSCTL2 srl 1))));

  -- Read/Write probes
  reg_lo_write <= per_we(0) and reg_sel;
  reg_hi_write <= per_we(1) and reg_sel;
  reg_read <= nor per_we and reg_sel;

  -- Read/Write vectors
  reg_hi_wr <= reg_dec and concatenate(DEC_SZ, reg_hi_write);
  reg_lo_wr <= reg_dec and concatenate(DEC_SZ, reg_lo_write);
  reg_rd <= reg_dec and concatenate(DEC_SZ, reg_read);

  --============================================================================
  -- 3) REGISTERS
  --============================================================================

  -- BCSCTL1 Register
  -------------------
  bcsctl1_wr <= reg_hi_wr(BCSCTL1)
  when BCSCTL1(0) else reg_lo_wr(BCSCTL1);
  bcsctl1_nxt <= per_din(15 downto 8)
  when BCSCTL1(0) else per_din(7 downto 0);

  ASIC_CLOCKING_GENERATING_0 : if (ASIC_CLOCKING = '1') generate
    ACLK_DIVIDER_GENERATING_1 : if (ACLK_DIVIDER = '1') generate
      divax_mask <= X"30";
    elsif (ACLK_DIVIDER = '0') generate
      divax_mask <= X"00";
    end generate;
    DMA_IF_EN_GENERATING_2 : if (DMA_IF_EN = '1') generate
      CPUOFF_EN_GENERATING_3 : if (CPUOFF_EN = '1') generate
        dma_cpuoff_mask <= X"01";
      elsif (CPUOFF_EN = '0') generate
        dma_cpuoff_mask <= X"00";
      end generate;
      OSCOFF_EN_GENERATING_4 : if (OSCOFF_EN = '1') generate
        dma_oscoff_mask <= X"02";
      elsif (OSCOFF_EN = '0') generate
        dma_oscoff_mask <= X"00";
      end generate;
      SCG0_EN_GENERATING_5 : if (SCG0_EN = '1') generate
        dma_scg0_mask <= X"04";
      elsif (SCG0_EN = '0') generate
        dma_scg0_mask <= X"00";
      end generate;
      SCG1_EN_GENERATING_6 : if (SCG1_EN = '1') generate
        dma_scg1_mask <= X"08";
      elsif (SCG1_EN = '0') generate
        dma_scg1_mask <= X"00";
      end generate;
    elsif (DMA_IF_EN = '0') generate
      dma_cpuoff_mask <= X"00";
      dma_scg0_mask <= X"00";
      dma_scg1_mask <= X"00";
      dma_oscoff_mask <= X"00";
    end generate;
  elsif (ASIC_CLOCKING = '0') generate
    divax_mask <= X"30";
    dma_cpuoff_mask <= X"00";
    dma_scg0_mask <= X"00";
    DMA_IF_EN_GENERATING_7 : if (DMA_IF_EN = '1') generate
      dma_oscoff_mask <= X"02";
      dma_scg1_mask <= X"08";
    elsif (DMA_IF_EN = '0') generate
      dma_oscoff_mask <= X"00";
      dma_scg1_mask <= X"00";
    end generate;
  end generate;


  processing_0 : process (dma_mclk, puc_rst)
  begin
    if (puc_rst) then
      bcsctl1 <= X"00";
    elsif (rising_edge(dma_mclk)) then
      if (bcsctl1_wr) then
        bcsctl1 <= bcsctl1_nxt and (divax_mask or dma_cpuoff_mask or dma_oscoff_mask or dma_scg0_mask or dma_scg1_mask);        -- Mask unused bits
      end if;
    end if;
  end process;


  -- BCSCTL2 Register
  ------------------
  bcsctl2_wr <= reg_hi_wr(BCSCTL2)
  when BCSCTL2(0) else reg_lo_wr(BCSCTL2);
  bcsctl2_nxt <= per_din(15 downto 8)
  when BCSCTL2(0) else per_din(7 downto 0);

  MCLK_MUX_GENERATING_8 : if (MCLK_MUX = '1') generate
    selmx_mask <= X"80";
  elsif (MCLK_MUX = '0') generate
    selmx_mask <= X"00";
  end generate;
  MCLK_DIVIDER_GENERATING_9 : if (MCLK_DIVIDER = '1') generate
    divmx_mask <= X"30";
  elsif (MCLK_DIVIDER = '0') generate
    divmx_mask <= X"00";
  end generate;
  ASIC_CLOCKING_GENERATING_10 : if (ASIC_CLOCKING = '1') generate
    SMCLK_MUX_GENERATING_11 : if (SMCLK_MUX = '1') generate
      sels_mask <= X"08";
    elsif (SMCLK_MUX = '0') generate
      sels_mask <= X"00";
    end generate;
    SMCLK_DIVIDER_GENERATING_12 : if (SMCLK_DIVIDER = '1') generate
      divsx_mask <= X"06";
    elsif (SMCLK_DIVIDER = '0') generate
      divsx_mask <= X"00";
    end generate;
  elsif (ASIC_CLOCKING = '0') generate
    sels_mask <= X"08";
    divsx_mask <= X"06";
  end generate;


  processing_1 : process (dma_mclk, puc_rst)
  begin
    if (puc_rst) then
      bcsctl2 <= X"00";
    elsif (rising_edge(dma_mclk)) then
      if (bcsctl2_wr) then
        bcsctl2 <= bcsctl2_nxt and (sels_mask or divsx_mask or selmx_mask or divmx_mask);        -- Mask unused bits
      end if;
    end if;
  end process;


  --============================================================================
  -- 4) DATA OUTPUT GENERATION
  --============================================================================

  -- Data output mux
  bcsctl1_rd <= (X"00" & (bcsctl1 and concatenate(8, reg_rd(BCSCTL1)))) sll (8 and concatenate(4, BCSCTL1(0)));
  bcsctl2_rd <= (X"00" & (bcsctl2 and concatenate(8, reg_rd(BCSCTL2)))) sll (8 and concatenate(4, BCSCTL2(0)));

  per_dout <= bcsctl1_rd or bcsctl2_rd;

  --=============================================================================
  -- 5)  DCO_CLK / LFXT_CLK INTERFACES (WAKEUP, ENABLE, ...)
  --=============================================================================

  ASIC_CLOCKING_GENERATING_13 : if (ASIC_CLOCKING = '1') generate
    CPUOFF_EN_GENERATING_14 : if (CPUOFF_EN = '1') generate
      and_cpuoff_mclk_en : omsp_and_gate
      port map (
        y => cpuoff_and_mclk_enable,
        a => cpuoff,
        b => mclk_enable
      );
      DMA_IF_EN_GENERATING_15 : if (DMA_IF_EN = '1') generate
        and_cpuoff_mclk_dma_en : omsp_and_gate
        port map (
          y => cpuoff_and_mclk_dma_enable,
          a => bcsctl1(DMA_CPUOFF),
          b => mclk_dma_enable
        );
        and_cpuoff_mclk_dma_wkup : omsp_and_gate
        port map (
          y => cpuoff_and_mclk_dma_wkup,
          a => bcsctl1(DMA_CPUOFF),
          b => mclk_dma_wkup
        );
      elsif (DMA_IF_EN = '0') generate
        cpuoff_and_mclk_dma_enable <= '0';
        cpuoff_and_mclk_dma_wkup <= '0';
      end generate;
    elsif (CPUOFF_EN = '0') generate
      cpuoff_and_mclk_enable <= '0';
      cpuoff_and_mclk_dma_enable <= '0';
      cpuoff_and_mclk_dma_wkup <= '0';
      UNUSED_cpuoff <= cpuoff;
    end generate;


    DMA_IF_EN_GENERATING_16 : if (DMA_IF_EN = '1') generate
      SCG0_EN_GENERATING_17 : if (SCG0_EN = '1') generate
        and_scg0_mclk_dma_en : omsp_and_gate
        port map (
          y => scg0_and_mclk_dma_enable,
          a => bcsctl1(DMA_SCG0),
          b => mclk_dma_enable
        );
        and_scg0_mclk_dma_wkup : omsp_and_gate
        port map (
          y => scg0_and_mclk_dma_wkup,
          a => bcsctl1(DMA_SCG0),
          b => mclk_dma_wkup
        );
      elsif (SCG0_EN = '0') generate
        scg0_and_mclk_dma_enable <= '0';
        scg0_and_mclk_dma_wkup <= '0';
        UNUSED_scg0_mclk_dma_wkup <= mclk_dma_wkup;
      end generate;
    elsif (DMA_IF_EN = '0') generate
      scg0_and_mclk_dma_enable <= '0';
      scg0_and_mclk_dma_wkup <= '0';
    end generate;


    DMA_IF_EN_GENERATING_18 : if (DMA_IF_EN = '1') generate
      SCG1_EN_GENERATING_19 : if (SCG1_EN = '1') generate
        and_scg1_mclk_dma_en : omsp_and_gate
        port map (
          y => scg1_and_mclk_dma_enable,
          a => bcsctl1(DMA_SCG1),
          b => mclk_dma_enable
        );
        and_scg1_mclk_dma_wkup : omsp_and_gate
        port map (
          y => scg1_and_mclk_dma_wkup,
          a => bcsctl1(DMA_SCG1),
          b => mclk_dma_wkup
        );
      elsif (SCG1_EN = '0') generate
        scg1_and_mclk_dma_enable <= '0';
        scg1_and_mclk_dma_wkup <= '0';
        UNUSED_scg1_mclk_dma_wkup <= mclk_dma_wkup;
      end generate;
    elsif (DMA_IF_EN = '0') generate
      scg1_and_mclk_dma_enable <= '0';
      scg1_and_mclk_dma_wkup <= '0';
    end generate;


    DMA_IF_EN_GENERATING_20 : if (DMA_IF_EN = '1') generate
      OSCOFF_EN_GENERATING_21 : if (OSCOFF_EN = '1') generate
        and_oscoff_mclk_dma_en : omsp_and_gate
        port map (
          y => oscoff_and_mclk_dma_enable,
          a => bcsctl1(DMA_OSCOFF),
          b => mclk_dma_enable
        );
        and_oscoff_mclk_dma_wkup : omsp_and_gate
        port map (
          y => oscoff_and_mclk_dma_wkup,
          a => bcsctl1(DMA_OSCOFF),
          b => mclk_dma_wkup
        );
      elsif (OSCOFF_EN = '0') generate
        oscoff_and_mclk_dma_enable <= '0';
        oscoff_and_mclk_dma_wkup <= '0';
        UNUSED_oscoff_mclk_dma_wkup <= mclk_dma_wkup;
      end generate;
    elsif (DMA_IF_EN = '0') generate
      oscoff_and_mclk_dma_enable <= '0';
      oscoff_and_mclk_dma_wkup <= '0';
      UNUSED_mclk_dma_wkup <= mclk_dma_wkup;
    end generate;
  elsif (ASIC_CLOCKING = '0') generate
    UNUSED_cpuoff <= cpuoff;
    UNUSED_mclk_enable <= mclk_enable;
    UNUSED_mclk_dma_wkup <= mclk_dma_wkup;
  end generate;


  -------------------------------------------------------------
  -- 5.1) HIGH SPEED SYSTEM CLOCK GENERATOR (DCO_CLK)
  -------------------------------------------------------------
  -- Note1: switching off the DCO osillator is only
  --        supported in ASIC mode with SCG0 low power mode
  --
  -- Note2: unlike the original MSP430 specification,
  --        we allow to switch off the DCO even
  --        if it is selected by MCLK or SMCLK.

  SCG0_EN_GENERATING_22 : if (SCG0_EN = '1') generate

    -- The DCO oscillator is synchronously disabled if:
    --      - the cpu pin is disabled (in that case, wait for mclk_enable==0)
    --      - the debug interface is disabled
    --      - SCG0 is set (in that case, wait for the mclk_enable==0 if selected by SELMx)
    --
    -- Note that we make extensive use of the AND gate module in order
    -- to prevent glitch propagation on the wakeup logic cone.
    and_dco_dis1 : omsp_and_gate
    port map (
      y => cpu_enabled_with_dco,
      a => not bcsctl2(SELMx),
      b => cpuoff_and_mclk_enable
    );
    and_dco_dis2 : omsp_and_gate
    port map (
      y => dco_not_enabled_by_dbg,
      a => not dbg_en_s,
      b => not (cpu_enabled_with_dco or scg0_and_mclk_dma_enable)
    );
    and_dco_dis3 : omsp_and_gate
    port map (
      y => dco_disable_by_scg0,
      a => scg0,
      b => dco_not_enabled_by_dbg
    );
    and_dco_dis4 : omsp_and_gate
    port map (
      y => dco_disable_by_cpu_en,
      a => not cpu_en_s,
      b => not mclk_enable
    );
    and_dco_dis5 : omsp_and_gate
    port map (
      y => dco_enable_nxt,

      a => not dco_disable_by_scg0,
      b => not dco_disable_by_cpu_en
    );
    -- Register to prevent glitch propagation
    processing_2 : process (nodiv_mclk, por)
    begin
      if (por) then
        dco_disable <= '1';
      elsif (rising_edge(nodiv_mclk)) then
        dco_disable <= not dco_enable_nxt or dco_wkup_set_scan_observe;
      end if;
    end process;


    -- Optional scan repair
    SCAN_REPAIR_INV_CLOCKS_GENERATING_23 : if (SCAN_REPAIR_INV_CLOCKS = '1') generate
      scan_mux_repair_dco_clk_n : omsp_scan_mux
      port map (
        scan_mode => scan_mode,
        data_in_scan => dco_clk,
        data_in_func => not dco_clk,
        data_out => dco_clk_n
      );
    elsif (SCAN_REPAIR_INV_CLOCKS = '0') generate
      dco_clk_n <= not dco_clk;
    end generate;


    -- Note that a synchronizer is required if the MCLK mux is included
    MCLK_MUX_GENERATING_24 : if (MCLK_MUX = '1') generate
      sync_cell_dco_disable : omsp_sync_cell
      port map (
        data_out => dco_enable,
        data_in => not dco_disable,
        clk => dco_clk_n,
        rst => por
      );
    elsif (MCLK_MUX = '0') generate
      -- Optional scan repair
      SCAN_REPAIR_INV_CLOCKS_GENERATING_25 : if (SCAN_REPAIR_INV_CLOCKS = '1') generate
        scan_mux_repair_nodiv_mclk_n : omsp_scan_mux
        port map (
          scan_mode => scan_mode,
          data_in_scan => nodiv_mclk,
          data_in_func => not nodiv_mclk,
          data_out => nodiv_mclk_n
        );
      elsif (SCAN_REPAIR_INV_CLOCKS = '0') generate
        nodiv_mclk_n <= not nodiv_mclk;
      end generate;


      -- Re-time DCO enable with MCLK falling edge
      processing_3 : process (nodiv_mclk_n, por)
      begin
        if (por) then
          dco_enable <= '0';
        elsif (rising_edge(nodiv_mclk_n)) then
          dco_enable <= not dco_disable;
        end if;
      end process;
    end generate;


    -- The DCO oscillator will get an asynchronous wakeup if:
    --      - the MCLK  generates a wakeup (only if the MCLK mux selects dco_clk)
    --      - if the DCO wants to be synchronously enabled (i.e dco_enable_nxt=1)
    and_dco_mclk_wkup : omsp_and_gate
    port map (
      y => dco_mclk_wkup,
      a => mclk_wkup,
      b => not bcsctl2(SELMx)
    );
    and_dco_en_wkup : omsp_and_gate
    port map (
      y => dco_en_wkup,

      a => not dco_enable,
      b => dco_enable_nxt
    );
    dco_wkup_set <= dco_mclk_wkup or scg0_and_mclk_dma_wkup or dco_en_wkup or cpu_en_wkup;

    -- Scan MUX for the asynchronous SET
    scan_mux_dco_wkup : omsp_scan_mux
    port map (
      scan_mode => scan_mode,
      data_in_scan => por_a,
      data_in_func => dco_wkup_set or por,
      data_out => dco_wkup_set_scan
    );


    -- Scan MUX to increase coverage
    scan_mux_dco_wkup_observe : omsp_scan_mux
    port map (
      scan_mode => scan_mode,
      data_in_scan => dco_wkup_set,
      data_in_func => '0',
      data_out => dco_wkup_set_scan_observe
    );


    -- The wakeup is asynchronously set, synchronously released
    sync_cell_dco_wkup : omsp_sync_cell
    port map (
      data_out => dco_wkup_n,
      data_in => '1',
      clk => dco_clk_n,
      rst => dco_wkup_set_scan
    );


    and_dco_wkup : omsp_and_gate
    port map (
      y => dco_wkup,

      a => not dco_wkup_n,
      b => cpu_en
    );
  elsif (SCG0_EN = '0') generate
    dco_enable <= '1';
    dco_wkup <= '1';
    UNUSED_scg0 <= scg0;
    UNUSED_cpu_en_wkup1 <= cpu_en_wkup;
  end generate;



  -------------------------------------------------------------
  -- 5.2) LOW FREQUENCY CRYSTAL CLOCK GENERATOR (LFXT_CLK)
  -------------------------------------------------------------

  -- ASIC MODE
  ------------
  -- Note: unlike the original MSP430 specification,
  --       we allow to switch off the LFXT even
  --       if it is selected by MCLK or SMCLK.
  ASIC_CLOCKING_GENERATING_26 : if (ASIC_CLOCKING = '1') generate

    OSCOFF_EN_GENERATING_27 : if (OSCOFF_EN = '1') generate

      -- The LFXT is synchronously disabled if:
      --      - the cpu pin is disabled (in that case, wait for mclk_enable==0)
      --      - the debug interface is disabled
      --      - OSCOFF is set (in that case, wait for the mclk_enable==0 if selected by SELMx)
      and_lfxt_dis1 : omsp_and_gate
      port map (
        y => cpu_enabled_with_lfxt,
        a => bcsctl2(SELMx),
        b => cpuoff_and_mclk_enable
      );
      and_lfxt_dis2 : omsp_and_gate
      port map (
        y => lfxt_not_enabled_by_dbg,
        a => not dbg_en_s,
        b => not (cpu_enabled_with_lfxt or oscoff_and_mclk_dma_enable)
      );
      and_lfxt_dis3 : omsp_and_gate
      port map (
        y => lfxt_disable_by_oscoff,
        a => oscoff,
        b => lfxt_not_enabled_by_dbg
      );
      and_lfxt_dis4 : omsp_and_gate
      port map (
        y => lfxt_disable_by_cpu_en,
        a => not cpu_en_s,
        b => not mclk_enable
      );
      and_lfxt_dis5 : omsp_and_gate
      port map (
        y => lfxt_enable_nxt,

        a => not lfxt_disable_by_oscoff,
        b => not lfxt_disable_by_cpu_en
      );
      -- Register to prevent glitch propagation
      processing_4 : process (nodiv_mclk, por)
      begin
        if (por) then
          lfxt_disable <= '1';
        elsif (rising_edge(nodiv_mclk)) then
          lfxt_disable <= not lfxt_enable_nxt or lfxt_wkup_set_scan_observe;
        end if;
      end process;


      -- Optional scan repair
      SCAN_REPAIR_INV_CLOCKS_GENERATING_28 : if (SCAN_REPAIR_INV_CLOCKS = '1') generate
        scan_mux_repair_lfxt_clk_n : omsp_scan_mux
        port map (
          scan_mode => scan_mode,
          data_in_scan => lfxt_clk,
          data_in_func => not lfxt_clk,
          data_out => lfxt_clk_n
        );
      elsif (SCAN_REPAIR_INV_CLOCKS = '0') generate
        lfxt_clk_n <= not lfxt_clk;
      end generate;


      -- Synchronize the OSCOFF control signal to the LFXT clock domain
      sync_cell_lfxt_disable : omsp_sync_cell
      port map (
        data_out => lfxt_enable,
        data_in => not lfxt_disable,
        clk => lfxt_clk_n,
        rst => por
      );


      -- The LFXT will get an asynchronous wakeup if:
      --      - the MCLK  generates a wakeup (only if the MCLK  mux selects lfxt_clk)
      --      - if the LFXT wants to be synchronously enabled (i.e lfxt_enable_nxt=1)
      and_lfxt_mclk_wkup : omsp_and_gate
      port map (
        y => lfxt_mclk_wkup,
        a => mclk_wkup,
        b => bcsctl2(SELMx)
      );
      and_lfxt_en_wkup : omsp_and_gate
      port map (
        y => lfxt_en_wkup,

        a => not lfxt_enable,
        b => lfxt_enable_nxt
      );
      lfxt_wkup_set <= lfxt_mclk_wkup or oscoff_and_mclk_dma_wkup or lfxt_en_wkup or cpu_en_wkup;

      -- Scan MUX for the asynchronous SET
      scan_mux_lfxt_wkup : omsp_scan_mux
      port map (
        scan_mode => scan_mode,
        data_in_scan => por_a,
        data_in_func => lfxt_wkup_set or por,
        data_out => lfxt_wkup_set_scan
      );


      -- Scan MUX to increase coverage
      scan_mux_lfxt_wkup_observe : omsp_scan_mux
      port map (
        scan_mode => scan_mode,
        data_in_scan => lfxt_wkup_set,
        data_in_func => '0',
        data_out => lfxt_wkup_set_scan_observe
      );


      -- The wakeup is asynchronously set, synchronously released
      sync_cell_lfxt_wkup : omsp_sync_cell
      port map (
        data_out => lfxt_wkup_n,
        data_in => '1',
        clk => lfxt_clk_n,
        rst => lfxt_wkup_set_scan
      );


      and_lfxt_wkup : omsp_and_gate
      port map (
        y => lfxt_wkup,

        a => not lfxt_wkup_n,
        b => cpu_en
      );
    elsif (OSCOFF_EN = '0') generate
      lfxt_enable <= '1';
      lfxt_wkup <= '0';
      UNUSED_oscoff <= oscoff;
      UNUSED_cpuoff_and_mclk_enable <= cpuoff_and_mclk_enable;
      UNUSED_cpu_en_wkup2 <= cpu_en_wkup;
    end generate;
  elsif (ASIC_CLOCKING = '0') generate


    -- FPGA MODE
    ------------

    -- Synchronize LFXT_CLK & edge detection


    sync_cell_lfxt_clk : omsp_sync_cell
    port map (
      data_out => lfxt_clk_s,
      data_in => lfxt_clk,
      clk => nodiv_mclk,
      rst => por
    );


    processing_5 : process (nodiv_mclk, por)
    begin
      if (por) then
        lfxt_clk_dly <= '0';
      elsif (rising_edge(nodiv_mclk)) then
        lfxt_clk_dly <= lfxt_clk_s;
      end if;
    end process;


    lfxt_clk_en <= (lfxt_clk_s and not lfxt_clk_dly) and (not oscoff or (mclk_dma_enable and bcsctl1(DMA_OSCOFF)));
    lfxt_enable <= '1';
    lfxt_wkup <= '0';
  end generate;


  --=============================================================================
  -- 6)  CLOCK GENERATION
  --=============================================================================

  -------------------------------------------------------------
  -- 6.1) GLOBAL CPU ENABLE
  ------------------------------------------------------------
  -- ACLK and SMCLK are directly switched-off
  -- with the cpu_en pin (after synchronization).
  -- MCLK will be switched off once the CPU reaches
  -- its IDLE state (through the mclk_enable signal)


  -- Synchronize CPU_EN signal to the MCLK domain
  ------------------------------------------------
  SYNC_CPU_EN_GENERATING_29 : if (SYNC_CPU_EN = '1') generate
    sync_cell_cpu_en : omsp_sync_cell
    port map (
      data_out => cpu_en_s,
      data_in => cpu_en,
      clk => nodiv_mclk,
      rst => por
    );
    and_cpu_en_wkup : omsp_and_gate
    port map (
      y => cpu_en_wkup,
      a => cpu_en,
      b => not cpu_en_s
    );
  elsif (SYNC_CPU_EN = '0') generate
    cpu_en_s <= cpu_en;
    cpu_en_wkup <= '0';
  end generate;


  -- Synchronize CPU_EN signal to the ACLK domain
  ------------------------------------------------
  LFXT_DOMAIN_GENERATING_30 : if (LFXT_DOMAIN = '1') generate
    sync_cell_cpu_aux_en : omsp_sync_cell
    port map (
      data_out => cpu_en_aux_s,
      data_in => cpu_en,
      clk => lfxt_clk,
      rst => por
    );
  elsif (LFXT_DOMAIN = '0') generate
    cpu_en_aux_s <= cpu_en_s;
  end generate;


  -- Synchronize CPU_EN signal to the SMCLK domain
  ------------------------------------------------
  -- Note: the synchronizer is only required if there is a SMCLK_MUX
  ASIC_CLOCKING_GENERATING_31 : if (ASIC_CLOCKING = '1') generate
    SMCLK_MUX_GENERATING_32 : if (SMCLK_MUX = '1') generate
      sync_cell_cpu_sm_en : omsp_sync_cell
      port map (
        data_out => cpu_en_sm_s,
        data_in => cpu_en,
        clk => nodiv_smclk,
        rst => por
      );
    elsif (SMCLK_MUX = '0') generate
      cpu_en_sm_s <= cpu_en_s;
    end generate;
  end generate;


  -------------------------------------------------------------
  -- 6.2) MCLK GENERATION
  -------------------------------------------------------------

  -- Clock MUX
  ------------------------------
  MCLK_MUX_GENERATING_33 : if (MCLK_MUX = '1') generate
    clock_mux_mclk : omsp_clock_mux
    port map (
      clk_out => nodiv_mclk,
      clk_in0 => dco_clk,
      clk_in1 => lfxt_clk,
      reset => por,
      scan_mode => scan_mode,
      select_in => bcsctl2(SELMx)
    );
  elsif (MCLK_MUX = '0') generate
    nodiv_mclk <= dco_clk;
  end generate;


  -- Wakeup synchronizer
  ----------------------

  CPUOFF_EN_GENERATING_34 : if (CPUOFF_EN = '1') generate
    DMA_IF_EN_GENERATING_35 : if (DMA_IF_EN = '1') generate
      sync_cell_mclk_dma_wkup : omsp_sync_cell
      port map (
        data_out => cpuoff_and_mclk_dma_wkup_s,
        data_in => cpuoff_and_mclk_dma_wkup,
        clk => nodiv_mclk,
        rst => puc_rst
      );
    elsif (DMA_IF_EN = '0') generate
      cpuoff_and_mclk_dma_wkup_s <= '0';
    end generate;
    sync_cell_mclk_wkup : omsp_sync_cell
    port map (
      data_out => mclk_wkup_s,
      data_in => mclk_wkup,
      clk => nodiv_mclk,
      rst => puc_rst
    );
  elsif (CPUOFF_EN = '0') generate
    cpuoff_and_mclk_dma_wkup_s <= '0';
    mclk_wkup_s <= '0';
    UNUSED_mclk_wkup <= mclk_wkup;
  end generate;


  -- Clock Divider
  ------------------------------
  -- No need for extra synchronizer as bcsctl2
  -- comes from the same clock domain.

  CPUOFF_EN_GENERATING_36 : if (CPUOFF_EN = '1') generate
    mclk_active <= mclk_enable or mclk_wkup_s or (dbg_en_s and cpu_en_s);
    mclk_dma_active <= cpuoff_and_mclk_dma_enable or cpuoff_and_mclk_dma_wkup_s or mclk_active;
  elsif (CPUOFF_EN = '0') generate
    mclk_active <= '1';
    mclk_dma_active <= '1';
  end generate;


  MCLK_DIVIDER_GENERATING_37 : if (MCLK_DIVIDER = '1') generate
    processing_6 : process (nodiv_mclk, puc_rst)
    begin
      if (puc_rst) then
        mclk_div <= X"0";
      elsif (rising_edge(nodiv_mclk)) then
        if ((bcsctl2(DIVMx) /= "00")) then
          mclk_div <= mclk_div+X"1";
        end if;
      end if;
    end process;
    mclk_div_sel <= '1'
    when (bcsctl2(DIVMx) = "00") else mclk_div(0)
    when (bcsctl2(DIVMx) = "01") else and mclk_div(1 downto 0)
    when (bcsctl2(DIVMx) = "10") else and mclk_div(2 downto 0);

    mclk_div_en <= mclk_active and mclk_div_sel;
    mclk_dma_div_en <= mclk_dma_active and mclk_div_sel;

  elsif (MCLK_DIVIDER = '0') generate
    mclk_div_en <= mclk_active;
    mclk_dma_div_en <= mclk_dma_active;
  end generate;


  -- Generate main system clock
  ------------------------------
  MCLK_CGATE_GENERATING_38 : if (MCLK_CGATE = '1') generate

    clock_gate_mclk : omsp_clock_gate
    port map (
      gclk => cpu_mclk,
      clk => nodiv_mclk,
      enable => mclk_div_en,
      scan_enable => scan_enable
    );
    DMA_IF_EN_GENERATING_39 : if (DMA_IF_EN = '1') generate
      clock_gate_dma_mclk : omsp_clock_gate
      port map (
        gclk => dma_mclk,
        clk => nodiv_mclk,
        enable => mclk_dma_div_en,
        scan_enable => scan_enable
      );
    elsif (DMA_IF_EN = '0') generate
      dma_mclk <= cpu_mclk;
    end generate;
  elsif (MCLK_CGATE = '0') generate
    cpu_mclk <= nodiv_mclk;
    dma_mclk <= nodiv_mclk;
  end generate;


  -------------------------------------------------------------
  -- 6.3) ACLK GENERATION
  -------------------------------------------------------------

  -- ASIC MODE
  ------------
  ASIC_CLOCKING_GENERATING_40 : if (ASIC_CLOCKING = '1') generate

    ACLK_DIVIDER_GENERATING_41 : if (ACLK_DIVIDER = '1') generate
      LFXT_DOMAIN_GENERATING_42 : if (LFXT_DOMAIN = '1') generate

        nodiv_aclk <= lfxt_clk;

        -- Synchronizers
        --------------------------------------------------------

        -- Local Reset synchronizer
        sync_cell_puc_lfxt : omsp_sync_cell
        port map (
          data_out => puc_lfxt_noscan_n,
          data_in => '1',
          clk => nodiv_aclk,
          rst => puc_rst
        );
        scan_mux_puc_lfxt : omsp_scan_mux
        port map (
          scan_mode => scan_mode,
          data_in_scan => por_a,
          data_in_func => not puc_lfxt_noscan_n,
          data_out => puc_lfxt_rst
        );


        -- If the OSCOFF mode is enabled synchronize OSCOFF signal
        OSCOFF_EN_GENERATING_43 : if (OSCOFF_EN = '1') generate
          sync_cell_oscoff : omsp_sync_cell
          port map (
            data_out => oscoff_s,
            data_in => oscoff,
            clk => nodiv_aclk,
            rst => puc_lfxt_rst
          );
        elsif (OSCOFF_EN = '0') generate
          oscoff_s <= '0';
        end generate;


        -- Local synchronizer for the bcsctl1.DIVAx configuration
        -- (note that we can live with a full bus synchronizer as
        --  it won't hurt if we get a wrong DIVAx value for a single clock cycle)
        processing_7 : process (nodiv_aclk, puc_lfxt_rst)
        begin
          if (puc_lfxt_rst) then
            divax_s <= X"0";
            divax_ss <= X"0";
          elsif (rising_edge(nodiv_aclk)) then
            divax_s <= bcsctl1(DIVAx);
            divax_ss <= divax_s;
          end if;
        end process;
      elsif (LFXT_DOMAIN = '0') generate
        puc_lfxt_rst <= puc_rst;
        nodiv_aclk <= dco_clk;
        divax_ss <= bcsctl1(DIVAx);
        oscoff_s <= oscoff;
      end generate;


      -- Wakeup synchronizer
      ----------------------

      OSCOFF_EN_GENERATING_44 : if (OSCOFF_EN = '1') generate
        DMA_IF_EN_GENERATING_45 : if (DMA_IF_EN = '1') generate
          sync_cell_aclk_dma_wkup : omsp_sync_cell
          port map (
            data_out => oscoff_and_mclk_dma_enable_s,
            data_in => oscoff_and_mclk_dma_wkup or oscoff_and_mclk_dma_enable,
            clk => nodiv_aclk,
            rst => puc_lfxt_rst
          );
        elsif (DMA_IF_EN = '0') generate
          oscoff_and_mclk_dma_enable_s <= '0';
        end generate;
      elsif (OSCOFF_EN = '0') generate
        oscoff_and_mclk_dma_enable_s <= '0';
      end generate;


      -- Clock Divider
      ----------------

      aclk_active <= cpu_en_aux_s and (not oscoff_s or oscoff_and_mclk_dma_enable_s);

      processing_8 : process (nodiv_aclk, puc_lfxt_rst)
      begin
        if (puc_lfxt_rst) then
          aclk_div <= X"0";
        elsif (rising_edge(nodiv_aclk)) then
          if ((divax_ss /= "00")) then
            aclk_div <= aclk_div+X"1";
          end if;
        end if;
      end process;


      aclk_div_sel <= ('1'
      when (divax_ss = "00") else aclk_div(0)
      when (divax_ss = "01") else and aclk_div(1 downto 0)
      when (divax_ss = "10") else and aclk_div(2 downto 0));

      aclk_div_en <= aclk_active and aclk_div_sel;

      -- Clock gate
      clock_gate_aclk : omsp_clock_gate
      port map (
        gclk => aclk,
        clk => nodiv_aclk,
        enable => aclk_div_en,
        scan_enable => scan_enable
      );
    elsif (ACLK_DIVIDER = '0') generate


      LFXT_DOMAIN_GENERATING_46 : if (LFXT_DOMAIN = '1') generate
        aclk <= lfxt_clk;
      elsif (LFXT_DOMAIN = '0') generate
        aclk <= dco_clk;
      end generate;
      UNUSED_cpu_en_aux_s <= cpu_en_aux_s;
    end generate;


    LFXT_DOMAIN_GENERATING_47 : if (LFXT_DOMAIN = '1') generate
    elsif (LFXT_DOMAIN = '0') generate
      UNUSED_lfxt_clk <= lfxt_clk;
    end generate;


    aclk_en <= '1';

  elsif (ASIC_CLOCKING = '0') generate
    -- FPGA MODE
    ------------
    aclk_en_nxt <= lfxt_clk_en and ('1'
    when (bcsctl1(DIVAx) = "00") else aclk_div(0)
    when (bcsctl1(DIVAx) = "01") else and aclk_div(1 downto 0)
    when (bcsctl1(DIVAx) = "10") else and aclk_div(2 downto 0));

    processing_9 : process (nodiv_mclk, puc_rst)
    begin
      if (puc_rst) then
        aclk_div <= X"0";
      elsif (rising_edge(nodiv_mclk)) then
        if ((bcsctl1(DIVAx) /= "00") and lfxt_clk_en) then
          aclk_div <= aclk_div+X"1";
        end if;
      end if;
    end process;


    processing_10 : process (nodiv_mclk, puc_rst)
    begin
      if (puc_rst) then
        aclk_en <= '0';
      elsif (rising_edge(nodiv_mclk)) then
        aclk_en <= aclk_en_nxt and cpu_en_s;
      end if;
    end process;


    aclk <= nodiv_mclk;

    UNUSED_scan_enable <= scan_enable;
    UNUSED_scan_mode <= scan_mode;
  end generate;


  -------------------------------------------------------------
  -- 6.4) SMCLK GENERATION
  -------------------------------------------------------------

  -- Clock MUX
  ------------
  SMCLK_MUX_GENERATING_48 : if (SMCLK_MUX = '1') generate
    clock_mux_smclk : omsp_clock_mux
    port map (
      clk_out => nodiv_smclk,
      clk_in0 => dco_clk,
      clk_in1 => lfxt_clk,
      reset => por,
      scan_mode => scan_mode,
      select_in => bcsctl2(SELS)
    );
  elsif (SMCLK_MUX = '0') generate
    nodiv_smclk <= dco_clk;
  end generate;


  -- ASIC MODE
  ------------
  ASIC_CLOCKING_GENERATING_49 : if (ASIC_CLOCKING = '1') generate
    SMCLK_MUX_GENERATING_50 : if (SMCLK_MUX = '1') generate

      -- SMCLK_MUX Synchronizers
      --------------------------------------------------------
      -- When the SMCLK MUX is enabled, the reset and DIVSx
      -- and SCG1 signals must be synchronized, otherwise not.

      -- Local Reset synchronizer
      sync_cell_puc_sm : omsp_sync_cell
      port map (
        data_out => puc_sm_noscan_n,
        data_in => '1',
        clk => nodiv_smclk,
        rst => puc_rst
      );
      scan_mux_puc_sm : omsp_scan_mux
      port map (
        scan_mode => scan_mode,
        data_in_scan => por_a,
        data_in_func => not puc_sm_noscan_n,
        data_out => puc_sm_rst
      );


      -- SCG1 synchronizer
      SCG1_EN_GENERATING_51 : if (SCG1_EN = '1') generate
        sync_cell_scg1 : omsp_sync_cell
        port map (
          data_out => scg1_s,
          data_in => scg1,
          clk => nodiv_smclk,
          rst => puc_sm_rst
        );
      elsif (SCG1_EN = '0') generate
        scg1_s <= '0';
        UNUSED_scg1 <= scg1;
        UNUSED_puc_sm_rst <= puc_sm_rst;
      end generate;


      SMCLK_DIVIDER_GENERATING_52 : if (SMCLK_DIVIDER = '1') generate
        -- Local synchronizer for the bcsctl2.DIVSx configuration
        -- (note that we can live with a full bus synchronizer as
        --  it won't hurt if we get a wrong DIVSx value for a single clock cycle)
        processing_11 : process (nodiv_smclk, puc_sm_rst)
        begin
          if (puc_sm_rst) then
            divsx_s <= X"0";
            divsx_ss <= X"0";
          elsif (rising_edge(nodiv_smclk)) then
            divsx_s <= bcsctl2(DIVSx);
            divsx_ss <= divsx_s;
          end if;
        end process;
      end generate;
    elsif (SMCLK_MUX = '0') generate


      puc_sm_rst <= puc_rst;
      divsx_ss <= bcsctl2(DIVSx);
      scg1_s <= scg1;
    end generate;


    -- Wakeup synchronizer
    ----------------------

    SCG1_EN_GENERATING_53 : if (SCG1_EN = '1') generate
      DMA_IF_EN_GENERATING_54 : if (DMA_IF_EN = '1') generate
        SMCLK_MUX_GENERATING_55 : if (SMCLK_MUX = '1') generate
          sync_cell_smclk_dma_wkup : omsp_sync_cell
          port map (
            data_out => scg1_and_mclk_dma_enable_s,
            data_in => scg1_and_mclk_dma_wkup or scg1_and_mclk_dma_enable,
            clk => nodiv_smclk,
            rst => puc_sm_rst
          );
        elsif (SMCLK_MUX = '0') generate
          sync_cell_smclk_dma_wkup : omsp_sync_cell
          port map (
            data_out => scg1_and_mclk_dma_wkup_s,
            data_in => scg1_and_mclk_dma_wkup,
            clk => nodiv_smclk,
            rst => puc_sm_rst
          );
          scg1_and_mclk_dma_enable_s <= scg1_and_mclk_dma_wkup_s or scg1_and_mclk_dma_enable;
        end generate;
      elsif (DMA_IF_EN = '0') generate
        scg1_and_mclk_dma_enable_s <= '0';
      end generate;
    elsif (SCG1_EN = '0') generate
      scg1_and_mclk_dma_enable_s <= '0';
    end generate;


    -- Clock Divider
    ----------------
    SCG1_EN_GENERATING_56 : if (SCG1_EN = '1') generate
      smclk_active <= cpu_en_sm_s and (not scg1_s or scg1_and_mclk_dma_enable_s);
    elsif (SCG1_EN = '0') generate
      smclk_active <= cpu_en_sm_s;
    end generate;


    SMCLK_DIVIDER_GENERATING_57 : if (SMCLK_DIVIDER = '1') generate
      processing_12 : process (nodiv_smclk, puc_sm_rst)
      begin
        if (puc_sm_rst) then
          smclk_div <= X"0";
        elsif (rising_edge(nodiv_smclk)) then
          if ((divsx_ss /= "00")) then
            smclk_div <= smclk_div+X"1";
          end if;
        end if;
      end process;


      smclk_div_sel <= ('1'
      when (divsx_ss = "00") else smclk_div(0)
      when (divsx_ss = "01") else and smclk_div(1 downto 0)
      when (divsx_ss = "10") else and smclk_div(2 downto 0));

      smclk_div_en <= smclk_active and smclk_div_sel;
    elsif (SMCLK_DIVIDER = '0') generate
      smclk_div_en <= smclk_active;
    end generate;


    -- Generate sub-system clock
    ----------------------------
    SMCLK_CGATE_GENERATING_58 : if (SMCLK_CGATE = '1') generate
      clock_gate_smclk : omsp_clock_gate
      port map (
        gclk => smclk,
        clk => nodiv_smclk,
        enable => smclk_div_en,
        scan_enable => scan_enable
      );
    elsif (SMCLK_CGATE = '0') generate
      smclk <= nodiv_smclk;
    end generate;


    smclk_en <= '1';

  elsif (ASIC_CLOCKING = '0') generate
    -- FPGA MODE
    ------------
    smclk_in <= '0'
    when (scg1 and not (mclk_dma_enable and bcsctl1(DMA_SCG1))) else lfxt_clk_en
    when bcsctl2(SELS) else '1';

    smclk_en_nxt <= smclk_in and ('1'
    when (bcsctl2(DIVSx) = "00") else smclk_div(0)
    when (bcsctl2(DIVSx) = "01") else and smclk_div(1 downto 0)
    when (bcsctl2(DIVSx) = "10") else and smclk_div(2 downto 0));

    processing_13 : process (nodiv_mclk, puc_rst)
    begin
      if (puc_rst) then
        smclk_en <= '0';
      elsif (rising_edge(nodiv_mclk)) then
        smclk_en <= smclk_en_nxt and cpu_en_s;
      end if;
    end process;


    processing_14 : process (nodiv_mclk, puc_rst)
    begin
      if (puc_rst) then
        smclk_div <= X"0";
      elsif (rising_edge(nodiv_mclk)) then
        if ((bcsctl2(DIVSx) /= "00") and smclk_in) then
          smclk_div <= smclk_div+X"1";
        end if;
      end if;
    end process;


    smclk <= nodiv_mclk;
  end generate;


  -------------------------------------------------------------
  -- 6.5) DEBUG INTERFACE CLOCK GENERATION (DBG_CLK)
  -------------------------------------------------------------

  -- Synchronize DBG_EN signal to MCLK domain
  -------------------------------------------
  DBG_EN_GENERATING_59 : if (DBG_EN = '1') generate
    SYNC_DBG_EN_GENERATING_60 : if (SYNC_DBG_EN = '1') generate
      sync_cell_dbg_en : omsp_sync_cell
      port map (
        data_out => dbg_en_n_s,
        data_in => not dbg_en,
        clk => cpu_mclk,
        rst => por
      );
      dbg_en_s <= not dbg_en_n_s;
      dbg_rst_nxt <= dbg_en_n_s;
    elsif (SYNC_DBG_EN = '0') generate
      dbg_en_s <= dbg_en;
      dbg_rst_nxt <= not dbg_en;
    end generate;
  elsif (DBG_EN = '0') generate
    dbg_en_s <= '0';
    dbg_rst_nxt <= '0';
    UNUSED_dbg_en <= dbg_en;
  end generate;


  -- Serial Debug Interface Clock gate
  ------------------------------------
  DBG_EN_GENERATING_61 : if (DBG_EN = '1') generate
    ASIC_CLOCKING_GENERATING_62 : if (ASIC_CLOCKING = '1') generate
      clock_gate_dbg_clk : omsp_clock_gate
      port map (
        gclk => dbg_clk,
        clk => cpu_mclk,
        enable => dbg_en_s,
        scan_enable => scan_enable
      );
    elsif (ASIC_CLOCKING = '0') generate
      dbg_clk <= dco_clk;
    end generate;
  elsif (DBG_EN = '0') generate
    dbg_clk <= '0';
  end generate;


  --=============================================================================
  -- 7)  RESET GENERATION
  --=============================================================================
  --
  -- Whenever the reset pin (reset_n) is deasserted, the internal resets of the
  -- openMSP430 will be released in the following order:
  --                1- POR
  --                2- DBG_RST (if the sdi interface is enabled, i.e. dbg_en=1)
  --                3- PUC
  --
  -- Note: releasing the DBG_RST before PUC is particularly important in order
  --       to allow the sdi interface to halt the cpu immediately after a PUC.
  --

  -- Generate synchronized POR to MCLK domain
  --------------------------------------------

  -- Asynchronous reset source
  por_a <= not reset_n;

  -- Reset Synchronizer
  sync_reset_por : omsp_sync_reset
  port map (
    rst_s => por_noscan,
    clk => nodiv_mclk,
    rst_a => por_a
  );


  -- Scan Reset Mux
  ASIC_GENERATING_63 : if (ASIC = '1') generate
    scan_mux_por : omsp_scan_mux
    port map (
      scan_mode => scan_mode,
      data_in_scan => por_a,
      data_in_func => por_noscan,
      data_out => por
    );
  elsif (ASIC = '0') generate
    por <= por_noscan;
  end generate;


  -- Generate synchronized reset for the SDI
  ------------------------------------------
  DBG_EN_GENERATING_64 : if (DBG_EN = '1') generate

    -- Reset Generation
    processing_15 : process (cpu_mclk, por)
    begin
      if (por) then
        dbg_rst_noscan <= '1';
      elsif (rising_edge(cpu_mclk)) then
        dbg_rst_noscan <= dbg_rst_nxt;
      end if;
    end process;


    -- Scan Reset Mux
    ASIC_GENERATING_65 : if (ASIC = '1') generate
      scan_mux_dbg_rst : omsp_scan_mux
      port map (
        scan_mode => scan_mode,
        data_in_scan => por_a,
        data_in_func => dbg_rst_noscan,
        data_out => dbg_rst
      );
    elsif (ASIC = '0') generate
      dbg_rst <= dbg_rst_noscan;
    end generate;
  elsif (DBG_EN = '0') generate


    dbg_rst_noscan <= '1';
    dbg_rst <= '1';
  end generate;


  -- Generate main system reset (PUC_RST)
  ---------------------------------------

  -- Asynchronous PUC reset
  puc_a <= por or wdt_reset;

  -- Synchronous PUC reset

  -- With the debug interface command
  -- Sequencing making sure PUC is released
  -- after DBG_RST if the debug interface is
  -- enabled at power-on-reset time
  -- Scan Reset Mux
  puc_s <= dbg_cpu_reset or (dbg_en_s and dbg_rst_noscan and not puc_noscan_n);

  ASIC_GENERATING_66 : if (ASIC = '1') generate
    scan_mux_puc_rst_a : omsp_scan_mux
    port map (
      scan_mode => scan_mode,
      data_in_scan => por_a,
      data_in_func => puc_a,
      data_out => puc_a_scan
    );
  elsif (ASIC = '0') generate
    puc_a_scan <= puc_a;
  end generate;


  -- Reset Synchronizer
  -- (required because of the asynchronous watchdog reset)
  sync_cell_puc : omsp_sync_cell
  port map (
    data_out => puc_noscan_n,
    data_in => not puc_s,
    clk => cpu_mclk,
    rst => puc_a_scan
  );


  -- Scan Reset Mux
  ASIC_GENERATING_67 : if (ASIC = '1') generate
    scan_mux_puc_rst : omsp_scan_mux
    port map (
      scan_mode => scan_mode,
      data_in_scan => por_a,
      data_in_func => not puc_noscan_n,
      data_out => puc_rst
    );
  elsif (ASIC = '0') generate
    puc_rst <= not puc_noscan_n;
  end generate;


  -- PUC pending set the serial debug interface
  puc_pnd_set <= not puc_noscan_n;
end RTL;
