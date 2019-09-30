-- Converted from omsp_multiplier.v
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
-- *File Name: omsp_multiplier.v
--
-- *Module Description:
--                       16x16 Hardware multiplier.
--
-- *Author(s):
--              - Olivier Girard,    olgirard@gmail.com
--

use work."openMSP430_defines.v".all;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity omsp_multiplier is
  port (
  -- OUTPUTs
  --========
    per_dout : out std_logic_vector(15 downto 0);  -- Peripheral data output

  -- INPUTs
  --=======
    mclk : in std_logic;  -- Main system clock
    per_addr : in std_logic_vector(13 downto 0);  -- Peripheral address
    per_din : in std_logic_vector(15 downto 0);  -- Peripheral data input
    per_en : in std_logic;  -- Peripheral enable (high active)
    per_we : in std_logic_vector(1 downto 0);  -- Peripheral write enable (high active)
    puc_rst : in std_logic   -- Main system reset
    scan_enable : in std_logic  -- Scan enable (active during scan shifting)
  );
end omsp_multiplier;

architecture RTL of omsp_multiplier is
  component omsp_clock_gate
  port (
    gclk : std_logic_vector(? downto 0);
    clk : std_logic_vector(? downto 0);
    enable : std_logic_vector(? downto 0);
    scan_enable : std_logic_vector(? downto 0)
  );
  end component;

  --=============================================================================
  -- 1)  PARAMETER/REGISTERS & WIRE DECLARATION
  --=============================================================================

  -- Register base address (must be aligned to decoder bit width)
  constant BASE_ADDR : std_logic_vector(14 downto 0) := X"0130";

  -- Decoder bit width (defines how many bits are considered for address decoding)
  constant DEC_WD : integer := 4;

  -- Register addresses offset
  constant OP1_MPY : std_logic_vector(DEC_WD-1 downto 0) := X"0";
  constant OP1_MPYS : std_logic_vector(DEC_WD-1 downto 0) := X"2";
  constant OP1_MAC : std_logic_vector(DEC_WD-1 downto 0) := X"4";
  constant OP1_MACS : std_logic_vector(DEC_WD-1 downto 0) := X"6";
  constant OP2 : std_logic_vector(DEC_WD-1 downto 0) := X"8";
  constant RESLO : std_logic_vector(DEC_WD-1 downto 0) := X"A";
  constant RESHI : std_logic_vector(DEC_WD-1 downto 0) := X"C";
  constant SUMEXT : std_logic_vector(DEC_WD-1 downto 0) := X"E";

  -- Register one-hot decoder utilities
  constant DEC_SZ : integer := (1 sll DEC_WD);
  constant BASE_REG : std_logic_vector(DEC_SZ-1 downto 0) := (concatenate(DEC_SZ-1, '0') & '1');

  -- Register one-hot decoder
  constant OP1_MPY_D : std_logic_vector(DEC_SZ-1 downto 0) := (BASE_REG sll OP1_MPY);
  constant OP1_MPYS_D : std_logic_vector(DEC_SZ-1 downto 0) := (BASE_REG sll OP1_MPYS);
  constant OP1_MAC_D : std_logic_vector(DEC_SZ-1 downto 0) := (BASE_REG sll OP1_MAC);
  constant OP1_MACS_D : std_logic_vector(DEC_SZ-1 downto 0) := (BASE_REG sll OP1_MACS);
  constant OP2_D : std_logic_vector(DEC_SZ-1 downto 0) := (BASE_REG sll OP2);
  constant RESLO_D : std_logic_vector(DEC_SZ-1 downto 0) := (BASE_REG sll RESLO);
  constant RESHI_D : std_logic_vector(DEC_SZ-1 downto 0) := (BASE_REG sll RESHI);
  constant SUMEXT_D : std_logic_vector(DEC_SZ-1 downto 0) := (BASE_REG sll SUMEXT);

  -- Wire pre-declarations
  signal result_wr : std_logic;
  signal result_clr : std_logic;
  signal early_read : std_logic;

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

  -- Masked input data for byte access
  signal per_din_msk : std_logic_vector(15 downto 0);

  --============================================================================
  -- 3) REGISTERS
  --============================================================================

  -- OP1 Register
  ---------------
  signal op1 : std_logic_vector(15 downto 0);

  signal op1_wr : std_logic;

  signal mclk_op1 : std_logic;

  signal UNUSED_scan_enable : std_logic;

  signal op1_rd : std_logic_vector(15 downto 0);


  -- OP2 Register
  ---------------
  signal op2 : std_logic_vector(15 downto 0);

  signal op2_wr : std_logic;

  signal mclk_op2 : std_logic;

  signal op2_rd : std_logic_vector(15 downto 0);


  -- RESLO Register
  -----------------
  signal reslo : std_logic_vector(15 downto 0);

  signal reslo_nxt : std_logic_vector(15 downto 0);
  signal reslo_wr : std_logic;

  signal reslo_en : std_logic;
  signal mclk_reslo : std_logic;

  signal reslo_rd : std_logic_vector(15 downto 0);

  -- RESHI Register
  -----------------
  signal reshi : std_logic_vector(15 downto 0);

  signal reshi_nxt : std_logic_vector(15 downto 0);
  signal reshi_wr : std_logic;

  signal reshi_en : std_logic;
  signal mclk_reshi : std_logic;

  signal reshi_rd : std_logic_vector(15 downto 0);


  -- SUMEXT Register
  ------------------
  signal sumext_s : std_logic_vector(1 downto 0);

  signal sumext_s_nxt : std_logic_vector(1 downto 0);

  signal sumext_nxt : std_logic_vector(15 downto 0);
  signal sumext : std_logic_vector(15 downto 0);
  signal sumext_rd : std_logic_vector(15 downto 0);


  --============================================================================
  -- 4) DATA OUTPUT GENERATION
  --============================================================================

  -- Data output mux
  signal op1_mux : std_logic_vector(15 downto 0);
  signal op2_mux : std_logic_vector(15 downto 0);
  signal reslo_mux : std_logic_vector(15 downto 0);
  signal reshi_mux : std_logic_vector(15 downto 0);
  signal sumext_mux : std_logic_vector(15 downto 0);

  --============================================================================
  -- 5) HARDWARE MULTIPLIER FUNCTIONAL LOGIC
  --============================================================================

  -- Multiplier configuration
  ---------------------------

  -- Detect signed mode
  signal sign_sel : std_logic;

  -- Detect accumulate mode
  signal acc_sel : std_logic;

  -- Combine RESHI & RESLO
  signal result : std_logic_vector(31 downto 0);


  -- 16x16 Multiplier (result computed in 1 clock cycle)
  ------------------------------------------------------

  -- Detect start of a multiplication
  signal cycle1 : std_logic;

  -- Expand the operands to support signed & unsigned operations
  signal op1_xp1 : std_logic_vector(16 downto 0);  -- signed
  signal op2_xp1 : std_logic_vector(16 downto 0);  -- signed


  -- 17x17 signed multiplication
  signal product1 : std_logic_vector(33 downto 0);  -- signed

  -- Accumulate
  signal result_nxt1 : std_logic_vector(32 downto 0);

  -- 16x8 Multiplier (result computed in 2 clock cycles)
  ------------------------------------------------------

  -- Detect start of a multiplication
  signal cycle2 : std_logic_vector(1 downto 0);


  -- Expand the operands to support signed & unsigned operations
  signal op1_xp2 : std_logic_vector(16 downto 0);  -- signed
  signal op2_hi_xp : std_logic_vector(8 downto 0);  -- signed
  signal op2_lo_xp : std_logic_vector(8 downto 0);  -- signed
  signal op2_xp2 : std_logic_vector(8 downto 0);  -- signed


  -- 17x9 signed multiplication
  signal product2 : std_logic_vector(25 downto 0);  -- signed

  signal product_xp : std_logic_vector(31 downto 0);

  -- Accumulate
  signal result_nxt2 : std_logic_vector(32 downto 0);

begin
  --============================================================================
  -- 2)  REGISTER DECODER
  --============================================================================

  -- Local register selection
  reg_sel <= per_en and (per_addr(13 downto DEC_WD-1) = BASE_ADDR(14 downto DEC_WD));

  -- Register local address
  reg_addr <= (per_addr(DEC_WD-2 downto 0) & '0');

  -- Register address decode
  reg_dec <= (OP1_MPY_D and concatenate(DEC_SZ, (reg_addr = OP1_MPY))) or (OP1_MPYS_D and concatenate(DEC_SZ, (reg_addr = OP1_MPYS))) or (OP1_MAC_D and concatenate(DEC_SZ, (reg_addr = OP1_MAC))) or (OP1_MACS_D and concatenate(DEC_SZ, (reg_addr = OP1_MACS))) or (OP2_D and concatenate(DEC_SZ, (reg_addr = OP2))) or (RESLO_D and concatenate(DEC_SZ, (reg_addr = RESLO))) or (RESHI_D and concatenate(DEC_SZ, (reg_addr = RESHI))) or (SUMEXT_D and concatenate(DEC_SZ, (reg_addr = SUMEXT)));

  -- Read/Write probes
  reg_write <= or per_we and reg_sel;
  reg_read <= nor per_we and reg_sel;

  -- Read/Write vectors
  reg_wr <= reg_dec and concatenate(DEC_SZ, reg_write);
  reg_rd <= reg_dec and concatenate(DEC_SZ, reg_read);

  -- Masked input data for byte access
  per_din_msk <= per_din and (concatenate(8, per_we(1)) & X"ff");

  --============================================================================
  -- 3) REGISTERS
  --============================================================================

  -- OP1 Register
  ---------------
  op1_wr <= reg_wr(OP1_MPY) or reg_wr(OP1_MPYS) or reg_wr(OP1_MAC) or reg_wr(OP1_MACS);

  CLOCK_GATING_GENERATING_0 : if (CLOCK_GATING = '1') generate
    clock_gate_op1 : omsp_clock_gate
    port map (
      gclk => mclk_op1,
      clk => mclk,
      enable => op1_wr,
      scan_enable => scan_enable
    );
  elsif (CLOCK_GATING = '0') generate
    UNUSED_scan_enable <= scan_enable;
    mclk_op1 <= mclk;
  end generate;


  CLOCK_GATING_GENERATING_1 : if (CLOCK_GATING = '1') generate
    processing_0 : process (mclk_op1, puc_rst)
    begin
      if (puc_rst) then
        op1 <= X"0000";
      elsif (rising_edge(mclk_op1)) then
        op1 <= per_din_msk;
      end if;
    end process;
  elsif (CLOCK_GATING = '0') generate
    processing_1 : process (mclk_op1, puc_rst)
    begin
      if (puc_rst) then
        op1 <= X"0000";
      elsif (rising_edge(mclk_op1)) then
        if (op1_wr) then
          op1 <= per_din_msk;
        end if;
      end if;
    end process;
  end generate;


  op1_rd <= op1;

  -- OP2 Register
  ---------------
  op2_wr <= reg_wr(OP2);

  CLOCK_GATING_GENERATING_2 : if (CLOCK_GATING = '1') generate
    clock_gate_op2 : omsp_clock_gate
    port map (
      gclk => mclk_op2,
      clk => mclk,
      enable => op2_wr,
      scan_enable => scan_enable
    );
  elsif (CLOCK_GATING = '0') generate
    mclk_op2 <= mclk;
  end generate;


  CLOCK_GATING_GENERATING_3 : if (CLOCK_GATING = '1') generate
    processing_2 : process (mclk_op2, puc_rst)
    begin
      if (puc_rst) then
        op2 <= X"0000";
      elsif (rising_edge(mclk_op2)) then
        op2 <= per_din_msk;
      end if;
    end process;
  elsif (CLOCK_GATING = '0') generate
    processing_3 : process (mclk_op2, puc_rst)
    begin
      if (puc_rst) then
        op2 <= X"0000";
      elsif (rising_edge(mclk_op2)) then
        if (op2_wr) then
          op2 <= per_din_msk;
        end if;
      end if;
    end process;
  end generate;


  op2_rd <= op2;

  -- RESLO Register
  -----------------
  reslo_wr <= reg_wr(RESLO);

  CLOCK_GATING_GENERATING_4 : if (CLOCK_GATING = '1') generate
    reslo_en <= reslo_wr or result_clr or result_wr;
    clock_gate_reslo : omsp_clock_gate
    port map (
      gclk => mclk_reslo,
      clk => mclk,
      enable => reslo_en,
      scan_enable => scan_enable
    );
  elsif (CLOCK_GATING = '0') generate
    mclk_reslo <= mclk;
  end generate;


  CLOCK_GATING_GENERATING_5 : if (CLOCK_GATING = '1') generate
    processing_4 : process (mclk_reslo, puc_rst)
    begin
      if (puc_rst) then
        reslo <= X"0000";
      elsif (rising_edge(mclk_reslo)) then
        if (reslo_wr) then
          reslo <= per_din_msk;
        elsif (result_clr) then
          reslo <= X"0000";
        else
          reslo <= reslo_nxt;
        end if;
      end if;
    end process;
  elsif (CLOCK_GATING = '0') generate
    processing_5 : process (mclk_reslo, puc_rst)
    begin
      if (puc_rst) then
        reslo <= X"0000";
      elsif (rising_edge(mclk_reslo)) then
        if (reslo_wr) then
          reslo <= per_din_msk;
        elsif (result_clr) then
          reslo <= X"0000";
        elsif (result_wr) then
          reslo <= reslo_nxt;
        end if;
      end if;
    end process;
  end generate;


  reslo_rd <= reslo_nxt
  when early_read else reslo;


  -- RESHI Register
  -----------------
  reshi_wr <= reg_wr(RESHI);

  CLOCK_GATING_GENERATING_6 : if (CLOCK_GATING = '1') generate
    reshi_en <= reshi_wr or result_clr or result_wr;
    clock_gate_reshi : omsp_clock_gate
    port map (
      gclk => mclk_reshi,
      clk => mclk,
      enable => reshi_en,
      scan_enable => scan_enable
    );
  elsif (CLOCK_GATING = '0') generate
    mclk_reshi <= mclk;
  end generate;


  CLOCK_GATING_GENERATING_7 : if (CLOCK_GATING = '1') generate
    processing_6 : process (mclk_reshi, puc_rst)
    begin
      if (puc_rst) then
        reshi <= X"0000";
      elsif (rising_edge(mclk_reshi)) then
        if (reshi_wr) then
          reshi <= per_din_msk;
        elsif (result_clr) then
          reshi <= X"0000";
        else
          reshi <= reshi_nxt;
        end if;
      end if;
    end process;
  elsif (CLOCK_GATING = '0') generate
    processing_7 : process (mclk_reshi, puc_rst)
    begin
      if (puc_rst) then
        reshi <= X"0000";
      elsif (rising_edge(mclk_reshi)) then
        if (reshi_wr) then
          reshi <= per_din_msk;
        elsif (result_clr) then
          reshi <= X"0000";
        elsif (result_wr) then
          reshi <= reshi_nxt;
        end if;
      end if;
    end process;
  end generate;


  reshi_rd <= reshi_nxt
  when early_read else reshi;

  -- SUMEXT Register
  ------------------
  processing_8 : process (mclk, puc_rst)
  begin
    if (puc_rst) then
      sumext_s <= "00";
    elsif (rising_edge(mclk)) then
      if (op2_wr) then
        sumext_s <= "00";
      elsif (result_wr) then
        sumext_s <= sumext_s_nxt;
      end if;
    end if;
  end process;


  sumext_nxt <= (concatenate(14, sumext_s_nxt(1)) & sumext_s_nxt);
  sumext <= (concatenate(14, sumext_s(1)) & sumext_s);
  sumext_rd <= sumext_nxt
  when early_read else sumext;

  --============================================================================
  -- 4) DATA OUTPUT GENERATION
  --============================================================================

  -- Data output mux
  op1_mux <= op1_rd and concatenate(16, reg_rd(OP1_MPY) or reg_rd(OP1_MPYS) or reg_rd(OP1_MAC) or reg_rd(OP1_MACS));
  op2_mux <= op2_rd and concatenate(16, reg_rd(OP2));
  reslo_mux <= reslo_rd and concatenate(16, reg_rd(RESLO));
  reshi_mux <= reshi_rd and concatenate(16, reg_rd(RESHI));
  sumext_mux <= sumext_rd and concatenate(16, reg_rd(SUMEXT));

  per_dout <= op1_mux or op2_mux or reslo_mux or reshi_mux or sumext_mux;

  --============================================================================
  -- 5) HARDWARE MULTIPLIER FUNCTIONAL LOGIC
  --============================================================================

  -- Multiplier configuration
  ----------------------------

  -- Detect signed mode
  CLOCK_GATING_GENERATING_8 : if (CLOCK_GATING = '1') generate
    processing_9 : process (mclk_op1, puc_rst)
    begin
      if (puc_rst) then
        sign_sel <= '0';
      elsif (rising_edge(mclk_op1)) then
        sign_sel <= reg_wr(OP1_MPYS) or reg_wr(OP1_MACS);
      end if;
    end process;
  elsif (CLOCK_GATING = '0') generate
    processing_10 : process (mclk_op1, puc_rst)
    begin
      if (puc_rst) then
        sign_sel <= '0';
      elsif (rising_edge(mclk_op1)) then
        if (op1_wr) then
          sign_sel <= reg_wr(OP1_MPYS) or reg_wr(OP1_MACS);
        end if;
      end if;
    end process;
  end generate;


  -- Detect accumulate mode
  CLOCK_GATING_GENERATING_9 : if (CLOCK_GATING = '1') generate
    processing_11 : process (mclk_op1, puc_rst)
    begin
      if (puc_rst) then
        acc_sel <= '0';
      elsif (rising_edge(mclk_op1)) then
        acc_sel <= reg_wr(OP1_MAC) or reg_wr(OP1_MACS);
      end if;
    end process;
  elsif (CLOCK_GATING = '0') generate
    processing_12 : process (mclk_op1, puc_rst)
    begin
      if (puc_rst) then
        acc_sel <= '0';
      elsif (rising_edge(mclk_op1)) then
        if (op1_wr) then
          acc_sel <= reg_wr(OP1_MAC) or reg_wr(OP1_MACS);
        end if;
      end if;
    end process;
  end generate;


  -- Detect whenever the RESHI and RESLO registers should be cleared
  result_clr <= op2_wr and not acc_sel;

  -- Combine RESHI & RESLO
  result <= (reshi & reslo);

  -- 16x16 Multiplier (result computed in 1 clock cycle)
  -------------------------------------------------------
  MPY_16x16_GENERATING_10 : if (MPY_16x16 = '1') generate

    -- Detect start of a multiplication
    processing_13 : process (mclk, puc_rst)
    begin
      if (puc_rst) then
        cycle1 <= '0';
      elsif (rising_edge(mclk)) then
        cycle1 <= op2_wr;
      end if;
    end process;


    result_wr <= cycle1;

    -- Expand the operands to support signed & unsigned operations
    op1_xp1 <= (sign_sel and op1(15) & op1);
    op2_xp1 <= (sign_sel and op2(15) & op2);


    -- 17x17 signed multiplication
    product1 <= op1_xp1*op2_xp1;

    -- Accumulate
    result_nxt1 <= ('0' & result)+('0' & product(31 downto 0));

    -- Next register values
    reslo_nxt <= result_nxt1(15 downto 0);
    reshi_nxt <= result_nxt1(31 downto 16);
    sumext_s_nxt <= (result_nxt1(31) & result_nxt1(31))
    when sign_sel else ('0' & result_nxt1(32));

    -- Since the MAC is completed within 1 clock cycle,
    -- an early read can't happen.
    early_read <= '0';

  elsif (MPY_16x16 = '0') generate
    -- 16x8 Multiplier (result computed in 2 clock cycles)
    -------------------------------------------------------


    -- Detect start of a multiplication
    processing_14 : process (mclk, puc_rst)
    begin
      if (puc_rst) then
        cycle2 <= "00";
      elsif (rising_edge(mclk)) then
        cycle2 <= (cycle2(0) & op2_wr);
      end if;
    end process;


    result_wr <= or cycle2;

    -- Expand the operands to support signed & unsigned operations
    op1_xp2 <= (sign_sel and op1(15) & op1);
    op2_hi_xp <= (sign_sel and op2(15) & op2(15 downto 8));
    op2_lo_xp <= ('0' & op2(7 downto 0));
    op2_xp2 <= op2_hi_xp
    when cycle2(0) else op2_lo_xp;

    -- 17x9 signed multiplication
    product2 <= op1_xp2*op2_xp2;

    product_xp <= (product2(23 downto 0) & X"00")
    when cycle2(0) else (concatenate(8, sign_sel and product2(23)) & product2(23 downto 0));

    -- Accumulate
    result_nxt2 <= ('0' & result)+('0' & product_xp(31 downto 0));

    -- Next register values
    reslo_nxt <= result_nxt2(15 downto 0);
    reshi_nxt <= result_nxt2(31 downto 16);
    sumext_s_nxt <= (result_nxt2(31) & result_nxt2(31))
    when sign_sel else ('0' & result_nxt2(32) or sumext_s(0));

    -- Since the MAC is completed within 2 clock cycle,
    -- an early read can happen during the second cycle.
    early_read <= cycle2(1);
  end generate;
end RTL;
