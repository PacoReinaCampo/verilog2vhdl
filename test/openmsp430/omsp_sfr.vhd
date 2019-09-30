-- Converted from omsp_sfr.v
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
-- *File Name: omsp_sfr.v
--
-- *Module Description:
--                       Processor Special function register
--                       Non-Maskable Interrupt generation
--
-- *Author(s):
--              - Olivier Girard,    olgirard@gmail.com
--

use work."openMSP430_defines.v".all;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity omsp_sfr is
  port (
  -- OUTPUTs
  --========
    cpu_id : out std_logic_vector(31 downto 0);  -- CPU ID
    nmi_pnd : out std_logic;  -- NMI Pending
    nmi_wkup : out std_logic;  -- NMI Wakeup
    per_dout : out std_logic_vector(15 downto 0);  -- Peripheral data output
    wdtie : out std_logic;  -- Watchdog-timer interrupt enable
    wdtifg_sw_clr : out std_logic;  -- Watchdog-timer interrupt flag software clear
    wdtifg_sw_set : out std_logic;  -- Watchdog-timer interrupt flag software set

  -- INPUTs
  --=======
    cpu_nr_inst : in std_logic_vector(7 downto 0);  -- Current oMSP instance number
    cpu_nr_total : in std_logic_vector(7 downto 0);  -- Total number of oMSP instances-1
    mclk : in std_logic;  -- Main system clock
    nmi : in std_logic;  -- Non-maskable interrupt (asynchronous)
    nmi_acc : in std_logic;  -- Non-Maskable interrupt request accepted
    per_addr : in std_logic_vector(13 downto 0);  -- Peripheral address
    per_din : in std_logic_vector(15 downto 0);  -- Peripheral data input
    per_en : in std_logic;  -- Peripheral enable (high active)
    per_we : in std_logic_vector(1 downto 0);  -- Peripheral write enable (high active)
    puc_rst : in std_logic;  -- Main system reset
    scan_mode : in std_logic;  -- Scan mode
    wdtifg : in std_logic   -- Watchdog-timer interrupt flag
    wdtnmies : in std_logic  -- Watchdog-timer NMI edge selection
  );
end omsp_sfr;

architecture RTL of omsp_sfr is
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

  component omsp_sync_cell
  port (
    data_out : std_logic_vector(? downto 0);
    data_in : std_logic_vector(? downto 0);
    clk : std_logic_vector(? downto 0);
    rst : std_logic_vector(? downto 0)
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
  constant BASE_ADDR : std_logic_vector(14 downto 0) := X"0000";

  -- Decoder bit width (defines how many bits are considered for address decoding)
  constant DEC_WD : integer := 4;

  -- Register addresses offset
  constant IE1 : std_logic_vector(DEC_WD-1 downto 0) := X"0";
  constant IFG1 : std_logic_vector(DEC_WD-1 downto 0) := X"2";
  constant CPU_ID_LO : std_logic_vector(DEC_WD-1 downto 0) := X"4";
  constant CPU_ID_HI : std_logic_vector(DEC_WD-1 downto 0) := X"6";
  constant CPU_NR : std_logic_vector(DEC_WD-1 downto 0) := X"8";

  -- Register one-hot decoder utilities
  constant DEC_SZ : integer := (1 sll DEC_WD);
  constant BASE_REG : std_logic_vector(DEC_SZ-1 downto 0) := (concatenate(DEC_SZ-1, '0') & '1');

  -- Register one-hot decoder
  constant IE1_D : std_logic_vector(DEC_SZ-1 downto 0) := (BASE_REG sll IE1);
  constant IFG1_D : std_logic_vector(DEC_SZ-1 downto 0) := (BASE_REG sll IFG1);
  constant CPU_ID_LO_D : std_logic_vector(DEC_SZ-1 downto 0) := (BASE_REG sll CPU_ID_LO);
  constant CPU_ID_HI_D : std_logic_vector(DEC_SZ-1 downto 0) := (BASE_REG sll CPU_ID_HI);
  constant CPU_NR_D : std_logic_vector(DEC_SZ-1 downto 0) := (BASE_REG sll CPU_NR);

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

  -- IE1 Register
  ---------------
  signal ie1 : std_logic_vector(7 downto 0);
  signal ie1_wr : std_logic;
  signal ie1_nxt : std_logic_vector(7 downto 0);

  signal nmie : std_logic;

  signal wdtie : std_logic;

  -- IFG1 Register
  ----------------
  signal ifg1 : std_logic_vector(7 downto 0);

  signal ifg1_wr : std_logic;
  signal ifg1_nxt : std_logic_vector(7 downto 0);

  signal nmiifg : std_logic;
  signal nmi_edge : std_logic;

  -- CPU_ID Register (READ ONLY)
  -------------------------------
  --              -------------------------------------------------------------------
  -- CPU_ID_LO:  | 15  14  13  12  11  10  9  |  8  7  6  5  4  |  3   |   2  1  0   |
  --             |----------------------------+-----------------+------+-------------|
  --             |        PER_SPACE           |   USER_VERSION  | ASIC | CPU_VERSION |
  --              --------------------------------------------------------------------
  -- CPU_ID_HI:  |   15  14  13  12  11  10   |   9  8  7  6  5  4  3  2  1   |   0  |
  --             |----------------------------+-------------------------------+------|
  --             |         PMEM_SIZE          |            DMEM_SIZE          |  MPY |
  --              -------------------------------------------------------------------

  signal cpu_version : std_logic_vector(2 downto 0);

  signal cpu_asic : std_logic;

  signal user_version : std_logic_vector(4 downto 0);
  signal per_space : std_logic_vector(6 downto 0);  -- cpu_id_per  *  512 = peripheral space size

  signal mpy_info : std_logic;

  signal dmem_size : std_logic_vector(8 downto 0);  -- cpu_id_dmem *  128 = data memory size
  signal pmem_size : std_logic_vector(5 downto 0);  -- cpu_id_pmem * 1024 = program memory size

  -- CPU_NR Register (READ ONLY)
  -------------------------------
  --    -------------------------------------------------------------------
  --   | 15  14  13  12  11  10   9   8  |  7   6   5   4   3   2   1   0  |
  --   |---------------------------------+---------------------------------|
  --   |            CPU_TOTAL_NR         |           CPU_INST_NR           |
  --    -------------------------------------------------------------------

  signal cpu_nr : std_logic_vector(15 downto 0);

  --============================================================================
  -- 4) DATA OUTPUT GENERATION
  --============================================================================

  -- Data output mux
  signal ie1_rd : std_logic_vector(15 downto 0);
  signal ifg1_rd : std_logic_vector(15 downto 0);
  signal cpu_id_lo_rd : std_logic_vector(15 downto 0);
  signal cpu_id_hi_rd : std_logic_vector(15 downto 0);
  signal cpu_nr_rd : std_logic_vector(15 downto 0);

  --=============================================================================
  -- 5)  NMI GENERATION
  --=============================================================================

  -------------------------------------
  -- Edge selection
  -------------------------------------
  signal nmi_pol : std_logic;

  -------------------------------------
  -- Pulse capture and synchronization
  -------------------------------------
  signal nmi_capture_rst : std_logic;

  -- NMI event capture
  signal nmi_capture : std_logic;

  signal UNUSED_scan_mode : std_logic;

  -- Synchronization
  signal nmi_s : std_logic;

  -------------------------------------
  -- NMI Pending flag
  -------------------------------------

  -- Delay
  signal nmi_dly : std_logic;

  -- NMI pending
  signal nmi_pnd : std_logic;

  -- NMI wakeup
  signal nmi_wkup : std_logic;
  signal UNUSED_nmi : std_logic;
  signal UNUSED_nmi_acc : std_logic;
  signal UNUSED_wdtnmies : std_logic;

  -- LINT cleanup
  signal UNUSED_per_din_15_8 : std_logic_vector(7 downto 0);

begin
  --============================================================================
  -- 2)  REGISTER DECODER
  --============================================================================

  -- Local register selection
  reg_sel <= per_en and (per_addr(13 downto DEC_WD-1) = BASE_ADDR(14 downto DEC_WD));

  -- Register local address
  reg_addr <= ('0' & per_addr(DEC_WD-2 downto 0));

  -- Register address decode
  reg_dec <= (IE1_D and concatenate(DEC_SZ, (reg_addr = (IE1 srl 1)))) or (IFG1_D and concatenate(DEC_SZ, (reg_addr = (IFG1 srl 1)))) or (CPU_ID_LO_D and concatenate(DEC_SZ, (reg_addr = (CPU_ID_LO srl 1)))) or (CPU_ID_HI_D and concatenate(DEC_SZ, (reg_addr = (CPU_ID_HI srl 1)))) or (CPU_NR_D and concatenate(DEC_SZ, (reg_addr = (CPU_NR srl 1))));

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

  -- IE1 Register
  ---------------
  ie1_wr <= reg_hi_wr(IE1)
  when IE1(0) else reg_lo_wr(IE1);
  ie1_nxt <= per_din(15 downto 8)
  when IE1(0) else per_din(7 downto 0);

  NMI_GENERATING_0 : if (NMI = '1') generate
    processing_0 : process (mclk, puc_rst)
    begin
      if (puc_rst) then
        nmie <= '0';
      elsif (rising_edge(mclk)) then
        if (nmi_acc) then
          nmie <= '0';
        elsif (ie1_wr) then
          nmie <= ie1_nxt(4);
        end if;
      end if;
    end process;
  elsif (NMI = '0') generate
    nmie <= '0';
  end generate;


  WATCHDOG_GENERATING_1 : if (WATCHDOG = '1') generate
    processing_1 : process (mclk, puc_rst)
    begin
      if (puc_rst) then
        wdtie <= '0';
      elsif (rising_edge(mclk)) then
        if (ie1_wr) then
          wdtie <= ie1_nxt(0);
        end if;
      end if;
    end process;
  elsif (WATCHDOG = '0') generate
    wdtie <= '0';
  end generate;


  ie1 <= ("000" & nmie & "000" & wdtie);

  -- IFG1 Register
  ----------------
  ifg1_wr <= reg_hi_wr(IFG1)
  when IFG1(0) else reg_lo_wr(IFG1);
  ifg1_nxt <= per_din(15 downto 8)
  when IFG1(0) else per_din(7 downto 0);

  NMI_GENERATING_2 : if (NMI = '1') generate
    processing_2 : process (mclk, puc_rst)
    begin
      if (puc_rst) then
        nmiifg <= '0';
      elsif (rising_edge(mclk)) then
        if (nmi_edge) then
          nmiifg <= '1';
        elsif (ifg1_wr) then
          nmiifg <= ifg1_nxt(4);
        end if;
      end if;
    end process;
  elsif (NMI = '0') generate
    nmiifg <= '0';
  end generate;


  WATCHDOG_GENERATING_3 : if (WATCHDOG = '1') generate
    wdtifg_sw_clr <= ifg1_wr and not ifg1_nxt(0);
    wdtifg_sw_set <= ifg1_wr and ifg1_nxt(0);
  elsif (WATCHDOG = '0') generate
    wdtifg_sw_clr <= '0';
    wdtifg_sw_set <= '0';
  end generate;


  ifg1 <= ("000" & nmiifg & "000" & wdtifg);

  -- CPU_ID Register (READ ONLY)
  -------------------------------
  --              -------------------------------------------------------------------
  -- CPU_ID_LO:  | 15  14  13  12  11  10  9  |  8  7  6  5  4  |  3   |   2  1  0   |
  --             |----------------------------+-----------------+------+-------------|
  --             |        PER_SPACE           |   USER_VERSION  | ASIC | CPU_VERSION |
  --              --------------------------------------------------------------------
  -- CPU_ID_HI:  |   15  14  13  12  11  10   |   9  8  7  6  5  4  3  2  1   |   0  |
  --             |----------------------------+-------------------------------+------|
  --             |         PMEM_SIZE          |            DMEM_SIZE          |  MPY |
  --              -------------------------------------------------------------------

  cpu_version <= CPU_VERSION;
  ASIC_GENERATING_4 : if (ASIC = '1') generate
    cpu_asic <= '1';
  elsif (ASIC = '0') generate
    cpu_asic <= '0';
  end generate;
  user_version <= USER_VERSION;
  per_space <= (PER_SIZE srl 9);  -- cpu_id_per  *  512 = peripheral space size
  MULTIPLIER_GENERATING_5 : if (MULTIPLIER = '1') generate
    mpy_info <= '1';
  elsif (MULTIPLIER = '0') generate
    mpy_info <= '0';
  end generate;
  dmem_size <= (DMEM_SIZE srl 7);  -- cpu_id_dmem *  128 = data memory size
  pmem_size <= (PMEM_SIZE srl 10);  -- cpu_id_pmem * 1024 = program memory size

  cpu_id <= (pmem_size & dmem_size & mpy_info & per_space & user_version & cpu_asic & cpu_version);

  -- CPU_NR Register (READ ONLY)
  -------------------------------
  --    -------------------------------------------------------------------
  --   | 15  14  13  12  11  10   9   8  |  7   6   5   4   3   2   1   0  |
  --   |---------------------------------+---------------------------------|
  --   |            CPU_TOTAL_NR         |           CPU_INST_NR           |
  --    -------------------------------------------------------------------

  cpu_nr <= (cpu_nr_total & cpu_nr_inst);

  --============================================================================
  -- 4) DATA OUTPUT GENERATION
  --============================================================================

  -- Data output mux
  ie1_rd <= (X"00" & (ie1 and concatenate(8, reg_rd(IE1)))) sll (8 and concatenate(4, IE1(0)));
  ifg1_rd <= (X"00" & (ifg1 and concatenate(8, reg_rd(IFG1)))) sll (8 and concatenate(4, IFG1(0)));
  cpu_id_lo_rd <= cpu_id(15 downto 0) and concatenate(16, reg_rd(CPU_ID_LO));
  cpu_id_hi_rd <= cpu_id(31 downto 16) and concatenate(16, reg_rd(CPU_ID_HI));
  cpu_nr_rd <= cpu_nr and concatenate(16, reg_rd(CPU_NR));

  per_dout <= ie1_rd or ifg1_rd or cpu_id_lo_rd or cpu_id_hi_rd or cpu_nr_rd;

  --=============================================================================
  -- 5)  NMI GENERATION
  --=============================================================================
  -- NOTE THAT THE NMI INPUT IS ASSUMED TO BE NON-GLITCHY
  NMI_GENERATING_6 : if (NMI = '1') generate

    -------------------------------------
    -- Edge selection
    -------------------------------------
    nmi_pol <= nmi xor wdtnmies;

    -------------------------------------
    -- Pulse capture and synchronization
    -------------------------------------
    SYNC_NMI_GENERATING_7 : if (SYNC_NMI = '1') generate
      ASIC_CLOCKING_GENERATING_8 : if (ASIC_CLOCKING = '1') generate
        -- Glitch free reset for the event capture
        processing_3 : process (mclk, puc_rst)
        begin
          if (puc_rst) then
            nmi_capture_rst <= '1';
          elsif (rising_edge(mclk)) then
            nmi_capture_rst <= ifg1_wr and not ifg1_nxt(4);
          end if;
        end process;


        -- NMI event capture
        wakeup_cell_nmi : omsp_wakeup_cell
        port map (
          wkup_out => nmi_capture,        -- Wakup signal (asynchronous)
          scan_clk => mclk,        -- Scan clock
          scan_mode => scan_mode,        -- Scan mode
          scan_rst => puc_rst,        -- Scan reset
          wkup_clear => nmi_capture_rst,        -- Glitch free wakeup event clear
          wkup_event => nmi_pol        -- Glitch free asynchronous wakeup event
        );
      elsif (ASIC_CLOCKING = '0') generate
        UNUSED_scan_mode <= scan_mode;
        nmi_capture <= nmi_pol;
      end generate;


      -- Synchronization
      sync_cell_nmi : omsp_sync_cell
      port map (
        data_out => nmi_s,
        data_in => nmi_capture,
        clk => mclk,
        rst => puc_rst
      );
    elsif (SYNC_NMI = '0') generate


      UNUSED_scan_mode <= scan_mode;
      nmi_capture <= nmi_pol;
      nmi_s <= nmi_pol;
    end generate;


    -------------------------------------
    -- NMI Pending flag
    -------------------------------------

    -- Delay
    processing_4 : process (mclk, puc_rst)
    begin
      if (puc_rst) then
        nmi_dly <= '0';
      elsif (rising_edge(mclk)) then
        nmi_dly <= nmi_s;
      end if;
    end process;


    -- Edge detection
    nmi_edge <= not nmi_dly and nmi_s;

    -- NMI pending
    nmi_pnd <= nmiifg and nmie;

    -- NMI wakeup
    ASIC_CLOCKING_GENERATING_9 : if (ASIC_CLOCKING = '1') generate
      and_nmi_wkup : omsp_and_gate
      port map (
        y => nmi_wkup,
        a => nmi_capture xor nmi_dly,
        b => nmie
      );
    elsif (ASIC_CLOCKING = '0') generate
      nmi_wkup <= '0';
    end generate;
  elsif (NMI = '0') generate


    nmi_pnd <= '0';
    nmi_wkup <= '0';
    UNUSED_scan_mode <= scan_mode;
    UNUSED_nmi <= nmi;
    UNUSED_nmi_acc <= nmi_acc;
    UNUSED_wdtnmies <= wdtnmies;
  end generate;


  -- LINT cleanup
  UNUSED_per_din_15_8 <= per_din(15 downto 8);
end RTL;
