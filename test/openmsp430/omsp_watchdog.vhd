-- Converted from omsp_watchdog.v
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
-- *File Name: omsp_watchdog.v
--
-- *Module Description:
--                       Watchdog Timer
--
-- *Author(s):
--              - Olivier Girard,    olgirard@gmail.com
--

use work."openMSP430_defines.v".all;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity omsp_watchdog is
  port (
  -- OUTPUTs
  --========
    per_dout : out std_logic_vector(15 downto 0);  -- Peripheral data output
    wdt_irq : out std_logic;  -- Watchdog-timer interrupt
    wdt_reset : out std_logic;  -- Watchdog-timer reset
    wdt_wkup : out std_logic;  -- Watchdog Wakeup
    wdtifg : out std_logic;  -- Watchdog-timer interrupt flag
    wdtnmies : out std_logic;  -- Watchdog-timer NMI edge selection

  -- INPUTs
  --=======
    aclk : in std_logic;  -- ACLK
    aclk_en : in std_logic;  -- ACLK enable
    dbg_freeze : in std_logic;  -- Freeze Watchdog counter
    mclk : in std_logic;  -- Main system clock
    per_addr : in std_logic_vector(13 downto 0);  -- Peripheral address
    per_din : in std_logic_vector(15 downto 0);  -- Peripheral data input
    per_en : in std_logic;  -- Peripheral enable (high active)
    per_we : in std_logic_vector(1 downto 0);  -- Peripheral write enable (high active)
    por : in std_logic;  -- Power-on reset
    puc_rst : in std_logic;  -- Main system reset
    scan_enable : in std_logic;  -- Scan enable (active during scan shifting)
    scan_mode : in std_logic;  -- Scan mode
    smclk : in std_logic;  -- SMCLK
    smclk_en : in std_logic;  -- SMCLK enable
    wdtie : in std_logic;  -- Watchdog timer interrupt enable
    wdtifg_irq_clr : in std_logic;  -- Clear Watchdog-timer interrupt flag
    wdtifg_sw_clr : in std_logic   -- Watchdog-timer interrupt flag software clear
    wdtifg_sw_set : in std_logic  -- Watchdog-timer interrupt flag software set
  );
end omsp_watchdog;

architecture RTL of omsp_watchdog is
  component omsp_clock_gate
  port (
    gclk : std_logic_vector(? downto 0);
    clk : std_logic_vector(? downto 0);
    enable : std_logic_vector(? downto 0);
    scan_enable : std_logic_vector(? downto 0)
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

  component omsp_sync_reset
  port (
    rst_s : std_logic_vector(? downto 0);
    clk : std_logic_vector(? downto 0);
    rst_a : std_logic_vector(? downto 0)
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

  component omsp_wakeup_cell
  port (
    wkup_out : std_logic_vector(? downto 0);
    scan_clk : std_logic_vector(? downto 0);
    scan_mode : std_logic_vector(? downto 0);
    scan_rst : std_logic_vector(? downto 0);
    wkup_clear : std_logic_vector(? downto 0);
    wkup_event : std_logic_vector(? downto 0)
  );
  end component;

  component omsp_and_gate
  port (
    y : std_logic_vector(? downto 0);
    a : std_logic_vector(? downto 0);
    b : std_logic_vector(? downto 0)
  );
  end component;

  --=============================================================================
  -- 1)  PARAMETER DECLARATION
  --=============================================================================

  -- Register base address (must be aligned to decoder bit width)
  constant BASE_ADDR : std_logic_vector(14 downto 0) := X"0120";

  -- Decoder bit width (defines how many bits are considered for address decoding)
  constant DEC_WD : integer := 2;

  -- Register addresses offset
  constant WDTCTL : std_logic_vector(DEC_WD-1 downto 0) := X"0";

  -- Register one-hot decoder utilities
  constant DEC_SZ : integer := (1 sll DEC_WD);
  constant BASE_REG : std_logic_vector(DEC_SZ-1 downto 0) := (concatenate(DEC_SZ-1, '0') & '1');

  -- Register one-hot decoder
  constant WDTCTL_D : std_logic_vector(DEC_SZ-1 downto 0) := (BASE_REG sll WDTCTL);

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
  signal reg_write : std_logic;
  signal reg_read : std_logic;

  -- Read/Write vectors
  signal reg_wr : std_logic_vector(DEC_SZ-1 downto 0);
  signal reg_rd : std_logic_vector(DEC_SZ-1 downto 0);

  --============================================================================
  -- 3) REGISTERS
  --============================================================================

  -- WDTCTL Register
  ------------------
  -- WDTNMI is not implemented and therefore masked

  signal wdtctl : std_logic_vector(7 downto 0);

  signal wdtctl_wr : std_logic;

  signal mclk_wdtctl : std_logic;

  constant WDTNMIES_MASK : std_logic_vector(7 downto 0) := X"40";
  constant WDTSSEL_MASK : std_logic_vector(7 downto 0) := X"04";
  constant WDTCTL_MASK : std_logic_vector(7 downto 0) := ("1001_0011" or WDTSSEL_MASK or WDTNMIES_MASK);

  signal wdtpw_error : std_logic;
  signal wdttmsel : std_logic;
  signal wdtnmies : std_logic;

  --============================================================================
  -- 4) DATA OUTPUT GENERATION
  --============================================================================

  constant WDTNMI_RD_MASK : std_logic_vector(7 downto 0) := X"20";
  constant WDTSSEL_RD_MASK : std_logic_vector(7 downto 0) := X"00";
  constant WDTCTL_RD_MASK : std_logic_vector(7 downto 0) := WDTNMI_RD_MASK or WDTSSEL_RD_MASK;

  signal wdtctl_rd : std_logic_vector(15 downto 0);

  --=============================================================================
  -- 5)  WATCHDOG TIMER (ASIC IMPLEMENTATION)
  --=============================================================================

  -- Watchdog clock source selection
  ----------------------------------
  signal wdt_clk : std_logic;

  -- Reset synchronizer for the watchdog local clock domain
  ---------------------------------------------------------

  signal wdt_rst_noscan : std_logic;
  signal wdt_rst : std_logic;

  -- Watchog counter clear (synchronization)
  ------------------------------------------

  -- Toggle bit whenever the watchog needs to be cleared
  signal wdtcnt_clr_toggle : std_logic;
  signal wdtcnt_clr_detect : std_logic;

  -- Synchronization
  signal wdtcnt_clr_sync : std_logic;

  -- Edge detection
  signal wdtcnt_clr_sync_dly : std_logic;

  signal wdtqn_edge : std_logic;
  signal wdtcnt_clr : std_logic;


  -- Watchog counter increment (synchronization)
  ----------------------------------------------
  signal wdtcnt_incr : std_logic;

  -- Watchdog 16 bit counter
  ----------------------------
  signal wdtcnt : std_logic_vector(15 downto 0);

  signal wdtcnt_nxt : std_logic_vector(15 downto 0);

  signal wdtcnt_en : std_logic;
  signal wdt_clk_cnt : std_logic;

  -- Local synchronizer for the wdtctl.WDTISx
  -- configuration (note that we can live with
  -- a full bus synchronizer as it won't hurt
  -- if we get a wrong WDTISx value for a
  -- single clock cycle)
  --------------------------------------------
  signal wdtisx_s : std_logic_vector(1 downto 0);
  signal wdtisx_ss : std_logic_vector(1 downto 0);

  -- Toggle bit for the transmition to the MCLK domain
  signal wdt_evt_toggle : std_logic;

  -- Synchronize in the MCLK domain
  signal wdt_evt_toggle_sync : std_logic;

  -- Delay for edge detection of the toggle bit
  signal wdt_evt_toggle_sync_dly : std_logic;

  signal wdtifg_evt : std_logic;

  -- Watchdog wakeup generation
  -----------------------------

  -- Clear wakeup when the watchdog flag is cleared (glitch free)
  signal wdtifg_clr_reg : std_logic;
  signal wdtifg_clr : std_logic;

  -- Set wakeup when the watchdog event is detected (glitch free)
  signal wdtqn_edge_reg : std_logic;

  -- Watchdog wakeup cell
  signal wdt_wkup_pre : std_logic;

  -- When not in HOLD, the watchdog can generate a wakeup when:
  --     - in interval mode (if interrupts are enabled)
  --     - in reset mode (always)
  signal wdt_wkup_en : std_logic;

  -- Make wakeup when not enabled
  signal wdt_wkup : std_logic;

  -- Watchdog interrupt flag
  --------------------------
  signal wdtifg : std_logic;

  signal wdtifg_set : std_logic;

  -- Watchdog interrupt generation
  --------------------------------
  signal wdt_irq : std_logic;


  -- Watchdog reset generation
  ----------------------------
  signal wdt_reset : std_logic;

  -- LINT cleanup
  signal UNUSED_smclk_en : std_logic;
  signal UNUSED_aclk_en : std_logic;

  --=============================================================================
  -- 6)  WATCHDOG TIMER (FPGA IMPLEMENTATION)
  --=============================================================================

  -- Watchdog clock source selection
  ----------------------------------
  signal clk_src_en : std_logic;

  -- Interval selection mux
  -------------------------
  signal wdtqn : std_logic;

  -- LINT cleanup
  signal UNUSED_scan_mode : std_logic;
  signal UNUSED_smclk : std_logic;
  signal UNUSED_aclk : std_logic;
  signal UNUSED_per_din : std_logic_vector(15 downto 0);

begin
  --============================================================================
  -- 2)  REGISTER DECODER
  --============================================================================

  -- Local register selection
  reg_sel <= per_en and (per_addr(13 downto DEC_WD-1) = BASE_ADDR(14 downto DEC_WD));

  -- Register local address
  reg_addr <= (per_addr(DEC_WD-2 downto 0) & '0');

  -- Register address decode
  reg_dec <= (WDTCTL_D and concatenate(DEC_SZ, (reg_addr = WDTCTL)));

  -- Read/Write probes
  reg_write <= or per_we and reg_sel;
  reg_read <= nor per_we and reg_sel;

  -- Read/Write vectors
  reg_wr <= reg_dec and concatenate(DEC_SZ, reg_write);
  reg_rd <= reg_dec and concatenate(DEC_SZ, reg_read);

  --============================================================================
  -- 3) REGISTERS
  --============================================================================

  -- WDTCTL Register
  ------------------
  -- WDTNMI is not implemented and therefore masked
  wdtctl_wr <= reg_wr(WDTCTL);

  CLOCK_GATING_GENERATING_0 : if (CLOCK_GATING = '1') generate
    clock_gate_wdtctl : omsp_clock_gate
    port map (
      gclk => mclk_wdtctl,
      clk => mclk,
      enable => wdtctl_wr,
      scan_enable => scan_enable
    );
  elsif (CLOCK_GATING = '0') generate
    UNUSED_scan_enable <= scan_enable;
    mclk_wdtctl <= mclk;
  end generate;


  CLOCK_GATING_GENERATING_1 : if (CLOCK_GATING = '1') generate
    processing_0 : process (mclk_wdtctl, puc_rst)
    begin
      if (puc_rst) then
        wdtctl <= X"00";
      elsif (rising_edge(mclk_wdtctl)) then
        wdtctl <= per_din(7 downto 0) and WDTCTL_MASK;
      end if;
    end process;
  elsif (CLOCK_GATING = '0') generate
    processing_1 : process (mclk_wdtctl, puc_rst)
    begin
      if (puc_rst) then
        wdtctl <= X"00";
      elsif (rising_edge(mclk_wdtctl)) then
        if (wdtctl_wr) then
          wdtctl <= per_din(7 downto 0) and WDTCTL_MASK;
        end if;
      end if;
    end process;
  end generate;


  wdtpw_error <= wdtctl_wr and (per_din(15 downto 8) /= X"5a");
  wdttmsel <= wdtctl(4);
  wdtnmies <= wdtctl(6);

  --============================================================================
  -- 4) DATA OUTPUT GENERATION
  --============================================================================

  -- Data output mux
  wdtctl_rd <= (X"69" & wdtctl or WDTCTL_RD_MASK) and concatenate(16, reg_rd(WDTCTL));
  per_dout <= wdtctl_rd;

  --=============================================================================
  -- 5)  WATCHDOG TIMER (ASIC IMPLEMENTATION)
  --=============================================================================
  ASIC_CLOCKING_GENERATING_2 : if (ASIC_CLOCKING = '1') generate

    -- Watchdog clock source selection
    ----------------------------------

    WATCHDOG_MUX_GENERATING_3 : if (WATCHDOG_MUX = '1') generate
      clock_mux_watchdog : omsp_clock_mux
      port map (
        clk_out => wdt_clk,
        clk_in0 => smclk,
        clk_in1 => aclk,
        reset => puc_rst,
        scan_mode => scan_mode,
        select_in => wdtctl(2)
      );
    elsif (WATCHDOG_MUX = '0') generate
      WATCHDOG_NOMUX_ACLK_GENERATING_4 : if (WATCHDOG_NOMUX_ACLK = '1') generate
        wdt_clk <= aclk;
        UNUSED_smclk <= smclk;
      elsif (WATCHDOG_NOMUX_ACLK = '0') generate
        UNUSED_aclk <= aclk;
        wdt_clk <= smclk;
      end generate;
    end generate;


    -- Reset synchronizer for the watchdog local clock domain
    ---------------------------------------------------------

    -- Reset Synchronizer
    sync_reset_por : omsp_sync_reset
    port map (
      rst_s => wdt_rst_noscan,
      clk => wdt_clk,
      rst_a => puc_rst
    );


    -- Scan Reset Mux
    scan_mux_wdt_rst : omsp_scan_mux
    port map (
      scan_mode => scan_mode,
      data_in_scan => puc_rst,
      data_in_func => wdt_rst_noscan,
      data_out => wdt_rst
    );


    -- Watchog counter clear (synchronization)
    -------------------------------------------

    -- Toggle bit whenever the watchog needs to be cleared
    wdtcnt_clr_detect <= (wdtctl_wr and per_din(3));
    processing_2 : process (mclk, puc_rst)
    begin
      if (puc_rst) then
        wdtcnt_clr_toggle <= '0';
      elsif (rising_edge(mclk)) then
        if (wdtcnt_clr_detect) then
          wdtcnt_clr_toggle <= not wdtcnt_clr_toggle;
        end if;
      end if;
    end process;


    -- Synchronization
    sync_cell_wdtcnt_clr : omsp_sync_cell
    port map (
      data_out => wdtcnt_clr_sync,
      data_in => wdtcnt_clr_toggle,
      clk => wdt_clk,
      rst => wdt_rst
    );


    -- Edge detection
    processing_3 : process (wdt_clk, wdt_rst)
    begin
      if (wdt_rst) then
        wdtcnt_clr_sync_dly <= '0';
      elsif (rising_edge(wdt_clk)) then
        wdtcnt_clr_sync_dly <= wdtcnt_clr_sync;
      end if;
    end process;


    wdtcnt_clr <= (wdtcnt_clr_sync xor wdtcnt_clr_sync_dly) or wdtqn_edge;

    -- Watchog counter increment (synchronization)
    ----------------------------------------------
    sync_cell_wdtcnt_incr : omsp_sync_cell
    port map (
      data_out => wdtcnt_incr,
      data_in => not wdtctl(7) and not dbg_freeze,
      clk => wdt_clk,
      rst => wdt_rst
    );


    -- Watchdog 16 bit counter
    --------------------------
    wdtcnt_nxt <= wdtcnt+X"0001";

    CLOCK_GATING_GENERATING_5 : if (CLOCK_GATING = '1') generate
      wdtcnt_en <= wdtcnt_clr or wdtcnt_incr;
      clock_gate_wdtcnt : omsp_clock_gate
      port map (
        gclk => wdt_clk_cnt,
        clk => wdt_clk,
        enable => wdtcnt_en,
        scan_enable => scan_enable
      );
    elsif (CLOCK_GATING = '0') generate
      wdt_clk_cnt <= wdt_clk;
    end generate;


    CLOCK_GATING_GENERATING_6 : if (CLOCK_GATING = '1') generate
      processing_4 : process (wdt_clk_cnt, wdt_rst)
      begin
        if (wdt_rst) then
          wdtcnt <= X"0000";
        elsif (rising_edge(wdt_clk_cnt)) then
          if (wdtcnt_clr) then
            wdtcnt <= X"0000";
          else
            wdtcnt <= wdtcnt_nxt;
          end if;
        end if;
      end process;
    elsif (CLOCK_GATING = '0') generate
      processing_5 : process (wdt_clk_cnt, wdt_rst)
      begin
        if (wdt_rst) then
          wdtcnt <= X"0000";
        elsif (rising_edge(wdt_clk_cnt)) then
          if (wdtcnt_clr) then
            wdtcnt <= X"0000";
          elsif (wdtcnt_incr) then
            wdtcnt <= wdtcnt_nxt;
          end if;
        end if;
      end process;
    end generate;


    -- Local synchronizer for the wdtctl.WDTISx
    -- configuration (note that we can live with
    -- a full bus synchronizer as it won't hurt
    -- if we get a wrong WDTISx value for a
    -- single clock cycle)
    --------------------------------------------
    processing_6 : process (wdt_clk_cnt, wdt_rst)
    begin
      if (wdt_rst) then
        wdtisx_s <= X"0";
        wdtisx_ss <= X"0";
      elsif (rising_edge(wdt_clk_cnt)) then
        wdtisx_s <= wdtctl(1 downto 0);
        wdtisx_ss <= wdtisx_s;
      end if;
    end process;


    -- Interval selection mux
    -------------------------
    processing_7 : process (wdtisx_ss, wdtcnt_nxt)
    begin
      case ((wdtisx_ss)) is
      when "00" =>
        wdtqn <= wdtcnt_nxt(15);
      when "01" =>
        wdtqn <= wdtcnt_nxt(13);
      when "10" =>
        wdtqn <= wdtcnt_nxt(9);
      when others =>
        wdtqn <= wdtcnt_nxt(6);
      end case;
    end process;


    -- Watchdog event detection
    ---------------------------

    -- Interval end detection
    wdtqn_edge <= (wdtqn and wdtcnt_incr);

    -- Toggle bit for the transmition to the MCLK domain
    processing_8 : process (wdt_clk_cnt, wdt_rst)
    begin
      if (wdt_rst) then
        wdt_evt_toggle <= '0';
      elsif (rising_edge(wdt_clk_cnt)) then
        if (wdtqn_edge) then
          wdt_evt_toggle <= not wdt_evt_toggle;
        end if;
      end if;
    end process;


    -- Synchronize in the MCLK domain
    sync_cell_wdt_evt : omsp_sync_cell
    port map (
      data_out => wdt_evt_toggle_sync,
      data_in => wdt_evt_toggle,
      clk => mclk,
      rst => puc_rst
    );


    -- Delay for edge detection of the toggle bit
    processing_9 : process (mclk, puc_rst)
    begin
      if (puc_rst) then
        wdt_evt_toggle_sync_dly <= '0';
      elsif (rising_edge(mclk)) then
        wdt_evt_toggle_sync_dly <= wdt_evt_toggle_sync;
      end if;
    end process;


    wdtifg_evt <= (wdt_evt_toggle_sync_dly xor wdt_evt_toggle_sync) or wdtpw_error;

    -- Watchdog wakeup generation
    -----------------------------

    -- Clear wakeup when the watchdog flag is cleared (glitch free)
    processing_10 : process (mclk, puc_rst)
    begin
      if (puc_rst) then
        wdtifg_clr_reg <= '1';
      elsif (rising_edge(mclk)) then
        wdtifg_clr_reg <= wdtifg_clr;
      end if;
    end process;


    -- Set wakeup when the watchdog event is detected (glitch free)
    processing_11 : process (wdt_clk_cnt, wdt_rst)
    begin
      if (wdt_rst) then
        wdtqn_edge_reg <= '0';
      elsif (rising_edge(wdt_clk_cnt)) then
        wdtqn_edge_reg <= wdtqn_edge;
      end if;
    end process;


    -- Watchdog wakeup cell
    wakeup_cell_wdog : omsp_wakeup_cell
    port map (
      wkup_out => wdt_wkup_pre,    -- Wakup signal (asynchronous)
      scan_clk => mclk,    -- Scan clock
      scan_mode => scan_mode,    -- Scan mode
      scan_rst => puc_rst,    -- Scan reset
      wkup_clear => wdtifg_clr_reg,    -- Glitch free wakeup event clear
      wkup_event => wdtqn_edge_reg    -- Glitch free asynchronous wakeup event
    );


    -- When not in HOLD, the watchdog can generate a wakeup when:
    --     - in interval mode (if interrupts are enabled)
    --     - in reset mode (always)
    processing_12 : process (mclk, puc_rst)
    begin
      if (puc_rst) then
        wdt_wkup_en <= '0';
      elsif (rising_edge(mclk)) then
        wdt_wkup_en <= not wdtctl(7) and (not wdttmsel or (wdttmsel and wdtie));
      end if;
    end process;


    -- Make wakeup when not enabled
    and_wdt_wkup : omsp_and_gate
    port map (
      y => wdt_wkup,
      a => wdt_wkup_pre,
      b => wdt_wkup_en
    );


    -- Watchdog interrupt flag
    --------------------------
    wdtifg_set <= wdtifg_evt or wdtifg_sw_set;
    wdtifg_clr <= (wdtifg_irq_clr and wdttmsel) or wdtifg_sw_clr;

    processing_13 : process (mclk, por)
    begin
      if (por) then
        wdtifg <= '0';
      elsif (rising_edge(mclk)) then
        if (wdtifg_set) then
          wdtifg <= '1';
        elsif (wdtifg_clr) then
          wdtifg <= '0';
        end if;
      end if;
    end process;


    -- Watchdog interrupt generation
    --------------------------------
    wdt_irq <= wdttmsel and wdtifg and wdtie;

    -- Watchdog reset generation
    ----------------------------
    processing_14 : process (mclk, por)
    begin
      if (por) then
        wdt_reset <= '0';
      elsif (rising_edge(mclk)) then
        wdt_reset <= wdtpw_error or (wdtifg_set and not wdttmsel);
      end if;
    end process;


    -- LINT cleanup
    UNUSED_smclk_en <= smclk_en;
    UNUSED_aclk_en <= aclk_en;

  elsif (ASIC_CLOCKING = '0') generate
    --=============================================================================
    -- 6)  WATCHDOG TIMER (FPGA IMPLEMENTATION)
    --=============================================================================


    -- Watchdog clock source selection
    ----------------------------------
    clk_src_en <= aclk_en
    when wdtctl(2) else smclk_en;

    -- Watchdog 16 bit counter
    --------------------------
    wdtcnt_clr <= (wdtctl_wr and per_din(3)) or wdtifg_evt;
    wdtcnt_incr <= not wdtctl(7) and clk_src_en and not dbg_freeze;

    wdtcnt_nxt <= wdtcnt+X"0001";

    processing_15 : process (mclk, puc_rst)
    begin
      if (puc_rst) then
        wdtcnt <= X"0000";
      elsif (rising_edge(mclk)) then
        if (wdtcnt_clr) then
          wdtcnt <= X"0000";
        elsif (wdtcnt_incr) then
          wdtcnt <= wdtcnt_nxt;
        end if;
      end if;
    end process;


    -- Interval selection mux
    -------------------------
    processing_16 : process (wdtctl, wdtcnt_nxt)
    begin
      case ((wdtctl(1 downto 0))) is
      when "00" =>
        wdtqn <= wdtcnt_nxt(15);
      when "01" =>
        wdtqn <= wdtcnt_nxt(13);
      when "10" =>
        wdtqn <= wdtcnt_nxt(9);
      when others =>
        wdtqn <= wdtcnt_nxt(6);
      end case;
    end process;


    -- Watchdog event detection
    ---------------------------
    wdtifg_evt <= (wdtqn and wdtcnt_incr) or wdtpw_error;

    -- Watchdog interrupt flag
    --------------------------
    wdtifg_set <= wdtifg_evt or wdtifg_sw_set;
    wdtifg_clr <= (wdtifg_irq_clr and wdttmsel) or wdtifg_sw_clr;

    processing_17 : process (mclk, por)
    begin
      if (por) then
        wdtifg <= '0';
      elsif (rising_edge(mclk)) then
        if (wdtifg_set) then
          wdtifg <= '1';
        elsif (wdtifg_clr) then
          wdtifg <= '0';
        end if;
      end if;
    end process;


    -- Watchdog interrupt generation
    -----------------------------------
    wdt_irq <= wdttmsel and wdtifg and wdtie;
    wdt_wkup <= '0';

    -- Watchdog reset generation
    ----------------------------

    processing_18 : process (mclk, por)
    begin
      if (por) then
        wdt_reset <= '0';
      elsif (rising_edge(mclk)) then
        wdt_reset <= wdtpw_error or (wdtifg_set and not wdttmsel);
      end if;
    end process;


    -- LINT cleanup
    UNUSED_scan_mode <= scan_mode;
    UNUSED_smclk <= smclk;
    UNUSED_aclk <= aclk;
  end generate;
  UNUSED_per_din <= per_din;
end RTL;
