-- Converted from periph/template_periph_8b.v
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
-- *File Name: template_periph_8b.v
--
-- *Module Description:
--                       8 bit peripheral template.
--
-- *Author(s):
--              - Olivier Girard,    olgirard@gmail.com
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity template_periph_8b is
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
    per_we : in std_logic_vector(1 downto 0)   -- Peripheral write enable (high active)
    puc_rst : in std_logic  -- Main system reset
  );
end template_periph_8b;

architecture RTL of template_periph_8b is
  --=============================================================================
  -- 1)  PARAMETER DECLARATION
  --=============================================================================

  -- Register base address (must be aligned to decoder bit width)
  constant BASE_ADDR : std_logic_vector(14 downto 0) := X"0090";

  -- Decoder bit width (defines how many bits are considered for address decoding)
  constant DEC_WD : integer := 2;

  -- Register addresses offset
  constant CNTRL1 : std_logic_vector(DEC_WD-1 downto 0) := X"0";
  constant CNTRL2 : std_logic_vector(DEC_WD-1 downto 0) := X"1";
  constant CNTRL3 : std_logic_vector(DEC_WD-1 downto 0) := X"2";
  constant CNTRL4 : std_logic_vector(DEC_WD-1 downto 0) := X"3";

  -- Register one-hot decoder utilities
  constant DEC_SZ : integer := (1 sll DEC_WD);
  constant BASE_REG : std_logic_vector(DEC_SZ-1 downto 0) := (concatenate(DEC_SZ-1, '0') & '1');

  -- Register one-hot decoder
  constant CNTRL1_D : std_logic_vector(DEC_SZ-1 downto 0) := (BASE_REG sll CNTRL1);
  constant CNTRL2_D : std_logic_vector(DEC_SZ-1 downto 0) := (BASE_REG sll CNTRL2);
  constant CNTRL3_D : std_logic_vector(DEC_SZ-1 downto 0) := (BASE_REG sll CNTRL3);
  constant CNTRL4_D : std_logic_vector(DEC_SZ-1 downto 0) := (BASE_REG sll CNTRL4);

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

  -- CNTRL1 Register
  -------------------
  signal cntrl1 : std_logic_vector(7 downto 0);

  signal cntrl1_wr : std_logic;
  signal cntrl1_nxt : std_logic_vector(7 downto 0);

  -- CNTRL2 Register
  ------------------
  signal cntrl2 : std_logic_vector(7 downto 0);

  signal cntrl2_wr : std_logic;
  signal cntrl2_nxt : std_logic_vector(7 downto 0);

  -- CNTRL3 Register
  ------------------
  signal cntrl3 : std_logic_vector(7 downto 0);

  signal cntrl3_wr : std_logic;
  signal cntrl3_nxt : std_logic_vector(7 downto 0);

  -- CNTRL4 Register
  ------------------
  signal cntrl4 : std_logic_vector(7 downto 0);

  signal cntrl4_wr : std_logic;
  signal cntrl4_nxt : std_logic_vector(7 downto 0);

  --============================================================================
  -- 4) DATA OUTPUT GENERATION
  --============================================================================

  -- Data output mux
  signal cntrl1_rd : std_logic_vector(15 downto 0);
  signal cntrl2_rd : std_logic_vector(15 downto 0);
  signal cntrl3_rd : std_logic_vector(15 downto 0);
  signal cntrl4_rd : std_logic_vector(15 downto 0);

begin
  --============================================================================
  -- 2)  REGISTER DECODER
  --============================================================================

  -- Local register selection
  reg_sel <= per_en and (per_addr(13 downto DEC_WD-1) = BASE_ADDR(14 downto DEC_WD));

  -- Register local address
  reg_addr <= ('0' & per_addr(DEC_WD-2 downto 0));

  -- Register address decode
  reg_dec <= (CNTRL1_D and concatenate(DEC_SZ, (reg_addr = (CNTRL1 srl 1)))) or (CNTRL2_D and concatenate(DEC_SZ, (reg_addr = (CNTRL2 srl 1)))) or (CNTRL3_D and concatenate(DEC_SZ, (reg_addr = (CNTRL3 srl 1)))) or (CNTRL4_D and concatenate(DEC_SZ, (reg_addr = (CNTRL4 srl 1))));

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

  -- CNTRL1 Register
  ------------------
  cntrl1_wr <= reg_hi_wr(CNTRL1)
  when CNTRL1(0) else reg_lo_wr(CNTRL1);
  cntrl1_nxt <= per_din(15 downto 8)
  when CNTRL1(0) else per_din(7 downto 0);

  processing_0 : process (mclk, puc_rst)
  begin
    if (puc_rst) then
      cntrl1 <= X"00";
    elsif (rising_edge(mclk)) then
      if (cntrl1_wr) then
        cntrl1 <= cntrl1_nxt;
      end if;
    end if;
  end process;


  -- CNTRL2 Register
  ------------------
  cntrl2_wr <= reg_hi_wr(CNTRL2)
  when CNTRL2(0) else reg_lo_wr(CNTRL2);
  cntrl2_nxt <= per_din(15 downto 8)
  when CNTRL2(0) else per_din(7 downto 0);

  processing_1 : process (mclk, puc_rst)
  begin
    if (puc_rst) then
      cntrl2 <= X"00";
    elsif (rising_edge(mclk)) then
      if (cntrl2_wr) then
        cntrl2 <= cntrl2_nxt;
      end if;
    end if;
  end process;


  -- CNTRL3 Register
  ------------------
  cntrl3_wr <= reg_hi_wr(CNTRL3)
  when CNTRL3(0) else reg_lo_wr(CNTRL3);
  cntrl3_nxt <= per_din(15 downto 8)
  when CNTRL3(0) else per_din(7 downto 0);

  processing_2 : process (mclk, puc_rst)
  begin
    if (puc_rst) then
      cntrl3 <= X"00";
    elsif (rising_edge(mclk)) then
      if (cntrl3_wr) then
        cntrl3 <= cntrl3_nxt;
      end if;
    end if;
  end process;


  -- CNTRL4 Register
  ------------------
  cntrl4_wr <= reg_hi_wr(CNTRL4)
  when CNTRL4(0) else reg_lo_wr(CNTRL4);
  cntrl4_nxt <= per_din(15 downto 8)
  when CNTRL4(0) else per_din(7 downto 0);

  processing_3 : process (mclk, puc_rst)
  begin
    if (puc_rst) then
      cntrl4 <= X"00";
    elsif (rising_edge(mclk)) then
      if (cntrl4_wr) then
        cntrl4 <= cntrl4_nxt;
      end if;
    end if;
  end process;


  --============================================================================
  -- 4) DATA OUTPUT GENERATION
  --============================================================================

  -- Data output mux
  cntrl1_rd <= (X"00" & (cntrl1 and concatenate(8, reg_rd(CNTRL1)))) sll (8 and concatenate(4, CNTRL1(0)));
  cntrl2_rd <= (X"00" & (cntrl2 and concatenate(8, reg_rd(CNTRL2)))) sll (8 and concatenate(4, CNTRL2(0)));
  cntrl3_rd <= (X"00" & (cntrl3 and concatenate(8, reg_rd(CNTRL3)))) sll (8 and concatenate(4, CNTRL3(0)));
  cntrl4_rd <= (X"00" & (cntrl4 and concatenate(8, reg_rd(CNTRL4)))) sll (8 and concatenate(4, CNTRL4(0)));

  per_dout <= cntrl1_rd or cntrl2_rd or cntrl3_rd or cntrl4_rd;
end RTL;
