-- Converted from periph/omsp_gpio.v
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
-- *File Name: omsp_gpio.v
--
-- *Module Description:
--                       Digital I/O interface
--
-- *Author(s):
--              - Olivier Girard,    olgirard@gmail.com
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity omsp_gpio is
  port (
  -- PARAMETERs
  --===========
  -- Enable Port 1
  -- Enable Port 2
  -- Enable Port 3
  -- Enable Port 4
  -- Enable Port 5
  -- Enable Port 6
  -- OUTPUTs
  --========
    irq_port1 : out std_logic;  -- Port 1 interrupt
    irq_port2 : out std_logic;  -- Port 2 interrupt
    p1_dout : out std_logic_vector(7 downto 0);  -- Port 1 data output
    p1_dout_en : out std_logic_vector(7 downto 0);  -- Port 1 data output enable
    p1_sel : out std_logic_vector(7 downto 0);  -- Port 1 function select
    p2_dout : out std_logic_vector(7 downto 0);  -- Port 2 data output
    p2_dout_en : out std_logic_vector(7 downto 0);  -- Port 2 data output enable
    p2_sel : out std_logic_vector(7 downto 0);  -- Port 2 function select
    p3_dout : out std_logic_vector(7 downto 0);  -- Port 3 data output
    p3_dout_en : out std_logic_vector(7 downto 0);  -- Port 3 data output enable
    p3_sel : out std_logic_vector(7 downto 0);  -- Port 3 function select
    p4_dout : out std_logic_vector(7 downto 0);  -- Port 4 data output
    p4_dout_en : out std_logic_vector(7 downto 0);  -- Port 4 data output enable
    p4_sel : out std_logic_vector(7 downto 0);  -- Port 4 function select
    p5_dout : out std_logic_vector(7 downto 0);  -- Port 5 data output
    p5_dout_en : out std_logic_vector(7 downto 0);  -- Port 5 data output enable
    p5_sel : out std_logic_vector(7 downto 0);  -- Port 5 function select
    p6_dout : out std_logic_vector(7 downto 0);  -- Port 6 data output
    p6_dout_en : out std_logic_vector(7 downto 0);  -- Port 6 data output enable
    p6_sel : out std_logic_vector(7 downto 0);  -- Port 6 function select
    per_dout : out std_logic_vector(15 downto 0);  -- Peripheral data output

  -- INPUTs
  --=======
    mclk : in std_logic;  -- Main system clock
    p1_din : in std_logic_vector(7 downto 0);  -- Port 1 data input
    p2_din : in std_logic_vector(7 downto 0);  -- Port 2 data input
    p3_din : in std_logic_vector(7 downto 0);  -- Port 3 data input
    p4_din : in std_logic_vector(7 downto 0);  -- Port 4 data input
    p5_din : in std_logic_vector(7 downto 0);  -- Port 5 data input
    p6_din : in std_logic_vector(7 downto 0);  -- Port 6 data input
    per_addr : in std_logic_vector(13 downto 0);  -- Peripheral address
    per_din : in std_logic_vector(15 downto 0);  -- Peripheral data input
    per_en : in std_logic;  -- Peripheral enable (high active)
    per_we : in std_logic_vector(1 downto 0)   -- Peripheral write enable (high active)
    puc_rst : in std_logic  -- Main system reset
  );
  constant P1_EN : std_logic := '1';
  constant P2_EN : std_logic := '1';
  constant P3_EN : std_logic := '0';
  constant P4_EN : std_logic := '0';
  constant P5_EN : std_logic := '0';
  constant P6_EN : std_logic := '0';
end omsp_gpio;

architecture RTL of omsp_gpio is
  component omsp_sync_cell
  port (
    data_out : std_logic_vector(? downto 0);
    data_in : std_logic_vector(? downto 0);
    clk : std_logic_vector(? downto 0);
    rst : std_logic_vector(? downto 0)
  );
  end component;

  --=============================================================================
  -- 1)  PARAMETER DECLARATION
  --=============================================================================

  -- Masks
  constant P1_EN_MSK : integer := concatenate(8, P1_EN(0));
  constant P2_EN_MSK : integer := concatenate(8, P2_EN(0));
  constant P3_EN_MSK : integer := concatenate(8, P3_EN(0));
  constant P4_EN_MSK : integer := concatenate(8, P4_EN(0));
  constant P5_EN_MSK : integer := concatenate(8, P5_EN(0));
  constant P6_EN_MSK : integer := concatenate(8, P6_EN(0));

  -- Register base address (must be aligned to decoder bit width)
  constant BASE_ADDR : std_logic_vector(14 downto 0) := X"0000";

  -- Decoder bit width (defines how many bits are considered for address decoding)
  constant DEC_WD : integer := 6;

  -- Register addresses offset
  -- Port 1
  -- Port 2
  -- Port 3
  -- Port 4
  -- Port 5
  -- Port 6
  constant P1IN : std_logic_vector(DEC_WD-1 downto 0) := X"20";
  constant P1OUT : std_logic_vector(DEC_WD-1 downto 0) := X"21";
  constant P1DIR : std_logic_vector(DEC_WD-1 downto 0) := X"22";
  constant P1IFG : std_logic_vector(DEC_WD-1 downto 0) := X"23";
  constant P1IES : std_logic_vector(DEC_WD-1 downto 0) := X"24";
  constant P1IE : std_logic_vector(DEC_WD-1 downto 0) := X"25";
  constant P1SEL : std_logic_vector(DEC_WD-1 downto 0) := X"26";
  constant P2IN : std_logic_vector(DEC_WD-1 downto 0) := X"28";
  constant P2OUT : std_logic_vector(DEC_WD-1 downto 0) := X"29";
  constant P2DIR : std_logic_vector(DEC_WD-1 downto 0) := X"2A";
  constant P2IFG : std_logic_vector(DEC_WD-1 downto 0) := X"2B";
  constant P2IES : std_logic_vector(DEC_WD-1 downto 0) := X"2C";
  constant P2IE : std_logic_vector(DEC_WD-1 downto 0) := X"2D";
  constant P2SEL : std_logic_vector(DEC_WD-1 downto 0) := X"2E";
  constant P3IN : std_logic_vector(DEC_WD-1 downto 0) := X"18";
  constant P3OUT : std_logic_vector(DEC_WD-1 downto 0) := X"19";
  constant P3DIR : std_logic_vector(DEC_WD-1 downto 0) := X"1A";
  constant P3SEL : std_logic_vector(DEC_WD-1 downto 0) := X"1B";
  constant P4IN : std_logic_vector(DEC_WD-1 downto 0) := X"1C";
  constant P4OUT : std_logic_vector(DEC_WD-1 downto 0) := X"1D";
  constant P4DIR : std_logic_vector(DEC_WD-1 downto 0) := X"1E";
  constant P4SEL : std_logic_vector(DEC_WD-1 downto 0) := X"1F";
  constant P5IN : std_logic_vector(DEC_WD-1 downto 0) := X"30";
  constant P5OUT : std_logic_vector(DEC_WD-1 downto 0) := X"31";
  constant P5DIR : std_logic_vector(DEC_WD-1 downto 0) := X"32";
  constant P5SEL : std_logic_vector(DEC_WD-1 downto 0) := X"33";
  constant P6IN : std_logic_vector(DEC_WD-1 downto 0) := X"34";
  constant P6OUT : std_logic_vector(DEC_WD-1 downto 0) := X"35";
  constant P6DIR : std_logic_vector(DEC_WD-1 downto 0) := X"36";
  constant P6SEL : std_logic_vector(DEC_WD-1 downto 0) := X"37";

  -- Register one-hot decoder utilities
  constant DEC_SZ : integer := (1 sll DEC_WD);
  constant BASE_REG : std_logic_vector(DEC_SZ-1 downto 0) := (concatenate(DEC_SZ-1, '0') & '1');

  -- Register one-hot decoder
  -- Port 1
  -- Port 2
  -- Port 3
  -- Port 4
  -- Port 5
  -- Port 6
  constant P1IN_D : std_logic_vector(DEC_SZ-1 downto 0) := (BASE_REG sll P1IN);
  constant P1OUT_D : std_logic_vector(DEC_SZ-1 downto 0) := (BASE_REG sll P1OUT);
  constant P1DIR_D : std_logic_vector(DEC_SZ-1 downto 0) := (BASE_REG sll P1DIR);
  constant P1IFG_D : std_logic_vector(DEC_SZ-1 downto 0) := (BASE_REG sll P1IFG);
  constant P1IES_D : std_logic_vector(DEC_SZ-1 downto 0) := (BASE_REG sll P1IES);
  constant P1IE_D : std_logic_vector(DEC_SZ-1 downto 0) := (BASE_REG sll P1IE);
  constant P1SEL_D : std_logic_vector(DEC_SZ-1 downto 0) := (BASE_REG sll P1SEL);
  constant P2IN_D : std_logic_vector(DEC_SZ-1 downto 0) := (BASE_REG sll P2IN);
  constant P2OUT_D : std_logic_vector(DEC_SZ-1 downto 0) := (BASE_REG sll P2OUT);
  constant P2DIR_D : std_logic_vector(DEC_SZ-1 downto 0) := (BASE_REG sll P2DIR);
  constant P2IFG_D : std_logic_vector(DEC_SZ-1 downto 0) := (BASE_REG sll P2IFG);
  constant P2IES_D : std_logic_vector(DEC_SZ-1 downto 0) := (BASE_REG sll P2IES);
  constant P2IE_D : std_logic_vector(DEC_SZ-1 downto 0) := (BASE_REG sll P2IE);
  constant P2SEL_D : std_logic_vector(DEC_SZ-1 downto 0) := (BASE_REG sll P2SEL);
  constant P3IN_D : std_logic_vector(DEC_SZ-1 downto 0) := (BASE_REG sll P3IN);
  constant P3OUT_D : std_logic_vector(DEC_SZ-1 downto 0) := (BASE_REG sll P3OUT);
  constant P3DIR_D : std_logic_vector(DEC_SZ-1 downto 0) := (BASE_REG sll P3DIR);
  constant P3SEL_D : std_logic_vector(DEC_SZ-1 downto 0) := (BASE_REG sll P3SEL);
  constant P4IN_D : std_logic_vector(DEC_SZ-1 downto 0) := (BASE_REG sll P4IN);
  constant P4OUT_D : std_logic_vector(DEC_SZ-1 downto 0) := (BASE_REG sll P4OUT);
  constant P4DIR_D : std_logic_vector(DEC_SZ-1 downto 0) := (BASE_REG sll P4DIR);
  constant P4SEL_D : std_logic_vector(DEC_SZ-1 downto 0) := (BASE_REG sll P4SEL);
  constant P5IN_D : std_logic_vector(DEC_SZ-1 downto 0) := (BASE_REG sll P5IN);
  constant P5OUT_D : std_logic_vector(DEC_SZ-1 downto 0) := (BASE_REG sll P5OUT);
  constant P5DIR_D : std_logic_vector(DEC_SZ-1 downto 0) := (BASE_REG sll P5DIR);
  constant P5SEL_D : std_logic_vector(DEC_SZ-1 downto 0) := (BASE_REG sll P5SEL);
  constant P6IN_D : std_logic_vector(DEC_SZ-1 downto 0) := (BASE_REG sll P6IN);
  constant P6OUT_D : std_logic_vector(DEC_SZ-1 downto 0) := (BASE_REG sll P6OUT);
  constant P6DIR_D : std_logic_vector(DEC_SZ-1 downto 0) := (BASE_REG sll P6DIR);
  constant P6SEL_D : std_logic_vector(DEC_SZ-1 downto 0) := (BASE_REG sll P6SEL);

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

  -- P1IN Register
  -----------------
  signal p1in : std_logic_vector(7 downto 0);

  -- P1OUT Register
  -----------------
  signal p1out : std_logic_vector(7 downto 0);

  signal p1out_wr : std_logic;
  signal p1out_nxt : std_logic_vector(7 downto 0);

  -- P1DIR Register
  -----------------
  signal p1dir : std_logic_vector(7 downto 0);

  signal p1dir_wr : std_logic;
  signal p1dir_nxt : std_logic_vector(7 downto 0);

  -- P1IFG Register
  -----------------
  signal p1ifg : std_logic_vector(7 downto 0);

  signal p1ifg_wr : std_logic;
  signal p1ifg_nxt : std_logic_vector(7 downto 0);
  signal p1ifg_set : std_logic_vector(7 downto 0);

  -- P1IES Register
  -----------------
  signal p1ies : std_logic_vector(7 downto 0);

  signal p1ies_wr : std_logic;
  signal p1ies_nxt : std_logic_vector(7 downto 0);

  -- P1IE Register
  ------------------
  signal p1ie : std_logic_vector(7 downto 0);

  signal p1ie_wr : std_logic;
  signal p1ie_nxt : std_logic_vector(7 downto 0);
  -- P1SEL Register
  -----------------
  signal p1sel : std_logic_vector(7 downto 0);

  signal p1sel_wr : std_logic;
  signal p1sel_nxt : std_logic_vector(7 downto 0);

  -- P2IN Register
  ----------------
  signal p2in : std_logic_vector(7 downto 0);

  -- P2OUT Register
  -----------------
  signal p2out : std_logic_vector(7 downto 0);

  signal p2out_wr : std_logic;
  signal p2out_nxt : std_logic_vector(7 downto 0);

  -- P2DIR Register
  -----------------
  signal p2dir : std_logic_vector(7 downto 0);

  signal p2dir_wr : std_logic;
  signal p2dir_nxt : std_logic_vector(7 downto 0);

  -- P2IFG Register
  -----------------
  signal p2ifg : std_logic_vector(7 downto 0);

  signal p2ifg_wr : std_logic;
  signal p2ifg_nxt : std_logic_vector(7 downto 0);
  signal p2ifg_set : std_logic_vector(7 downto 0);

  -- P2IES Register
  -----------------
  signal p2ies : std_logic_vector(7 downto 0);

  signal p2ies_wr : std_logic;
  signal p2ies_nxt : std_logic_vector(7 downto 0);

  -- P2IE Register
  ----------------
  signal p2ie : std_logic_vector(7 downto 0);

  signal p2ie_wr : std_logic;
  signal p2ie_nxt : std_logic_vector(7 downto 0);

  -- P2SEL Register
  ------------------
  signal p2sel : std_logic_vector(7 downto 0);

  signal p2sel_wr : std_logic;
  signal p2sel_nxt : std_logic_vector(7 downto 0);

  -- P3IN Register
  ----------------
  signal p3in : std_logic_vector(7 downto 0);

  -- P3OUT Register
  -----------------
  signal p3out : std_logic_vector(7 downto 0);

  signal p3out_wr : std_logic;
  signal p3out_nxt : std_logic_vector(7 downto 0);

  -- P3DIR Register
  -----------------
  signal p3dir : std_logic_vector(7 downto 0);

  signal p3dir_wr : std_logic;
  signal p3dir_nxt : std_logic_vector(7 downto 0);

  -- P3SEL Register
  -----------------
  signal p3sel : std_logic_vector(7 downto 0);

  signal p3sel_wr : std_logic;
  signal p3sel_nxt : std_logic_vector(7 downto 0);

  -- P4IN Register
  ----------------
  signal p4in : std_logic_vector(7 downto 0);

  -- P4OUT Register
  -----------------
  signal p4out : std_logic_vector(7 downto 0);

  signal p4out_wr : std_logic;
  signal p4out_nxt : std_logic_vector(7 downto 0);

  -- P4DIR Register
  -----------------
  signal p4dir : std_logic_vector(7 downto 0);

  signal p4dir_wr : std_logic;
  signal p4dir_nxt : std_logic_vector(7 downto 0);

  -- P4SEL Register
  -----------------
  signal p4sel : std_logic_vector(7 downto 0);

  signal p4sel_wr : std_logic;
  signal p4sel_nxt : std_logic_vector(7 downto 0);

  -- P5IN Register
  ----------------
  signal p5in : std_logic_vector(7 downto 0);

  -- P5OUT Register
  -----------------
  signal p5out : std_logic_vector(7 downto 0);

  signal p5out_wr : std_logic;
  signal p5out_nxt : std_logic_vector(7 downto 0);

  -- P5DIR Register
  -----------------
  signal p5dir : std_logic_vector(7 downto 0);

  signal p5dir_wr : std_logic;
  signal p5dir_nxt : std_logic_vector(7 downto 0);

  -- P5SEL Register
  -----------------
  signal p5sel : std_logic_vector(7 downto 0);

  signal p5sel_wr : std_logic;
  signal p5sel_nxt : std_logic_vector(7 downto 0);

  -- P6IN Register
  ----------------
  signal p6in : std_logic_vector(7 downto 0);

  -- P6OUT Register
  -----------------
  signal p6out : std_logic_vector(7 downto 0);

  signal p6out_wr : std_logic;
  signal p6out_nxt : std_logic_vector(7 downto 0);

  -- P6DIR Register
  -----------------
  signal p6dir : std_logic_vector(7 downto 0);

  signal p6dir_wr : std_logic;
  signal p6dir_nxt : std_logic_vector(7 downto 0);

  -- P6SEL Register
  -----------------
  signal p6sel : std_logic_vector(7 downto 0);

  signal p6sel_wr : std_logic;
  signal p6sel_nxt : std_logic_vector(7 downto 0);

  --============================================================================
  -- 4) INTERRUPT GENERATION
  --============================================================================

  -- Port 1 interrupt
  -------------------

  -- Delay input
  signal p1in_dly : std_logic_vector(7 downto 0);

  -- Edge detection
  signal p1in_re : std_logic_vector(7 downto 0);
  signal p1in_fe : std_logic_vector(7 downto 0);


  -- Port 1 interrupt
  -------------------

  -- Delay input
  signal p2in_dly : std_logic_vector(7 downto 0);

  -- Edge detection
  signal p2in_re : std_logic_vector(7 downto 0);
  signal p2in_fe : std_logic_vector(7 downto 0);

  --============================================================================
  -- 5) DATA OUTPUT GENERATION
  --============================================================================

  -- Data output mux
  signal p1in_rd : std_logic_vector(15 downto 0);
  signal p1out_rd : std_logic_vector(15 downto 0);
  signal p1dir_rd : std_logic_vector(15 downto 0);
  signal p1ifg_rd : std_logic_vector(15 downto 0);
  signal p1ies_rd : std_logic_vector(15 downto 0);
  signal p1ie_rd : std_logic_vector(15 downto 0);
  signal p1sel_rd : std_logic_vector(15 downto 0);
  signal p2in_rd : std_logic_vector(15 downto 0);
  signal p2out_rd : std_logic_vector(15 downto 0);
  signal p2dir_rd : std_logic_vector(15 downto 0);
  signal p2ifg_rd : std_logic_vector(15 downto 0);
  signal p2ies_rd : std_logic_vector(15 downto 0);
  signal p2ie_rd : std_logic_vector(15 downto 0);
  signal p2sel_rd : std_logic_vector(15 downto 0);
  signal p3in_rd : std_logic_vector(15 downto 0);
  signal p3out_rd : std_logic_vector(15 downto 0);
  signal p3dir_rd : std_logic_vector(15 downto 0);
  signal p3sel_rd : std_logic_vector(15 downto 0);
  signal p4in_rd : std_logic_vector(15 downto 0);
  signal p4out_rd : std_logic_vector(15 downto 0);
  signal p4dir_rd : std_logic_vector(15 downto 0);
  signal p4sel_rd : std_logic_vector(15 downto 0);
  signal p5in_rd : std_logic_vector(15 downto 0);
  signal p5out_rd : std_logic_vector(15 downto 0);
  signal p5dir_rd : std_logic_vector(15 downto 0);
  signal p5sel_rd : std_logic_vector(15 downto 0);
  signal p6in_rd : std_logic_vector(15 downto 0);
  signal p6out_rd : std_logic_vector(15 downto 0);
  signal p6dir_rd : std_logic_vector(15 downto 0);
  signal p6sel_rd : std_logic_vector(15 downto 0);

begin
  --============================================================================
  -- 2)  REGISTER DECODER
  --============================================================================

  -- Local register selection
  reg_sel <= per_en and (per_addr(13 downto DEC_WD-1) = BASE_ADDR(14 downto DEC_WD));

  -- Register local address
  reg_addr <= ('0' & per_addr(DEC_WD-2 downto 0));

  -- Register address decode
  reg_dec <= (P1IN_D and concatenate(DEC_SZ, (reg_addr = (P1IN srl 1)) and P1_EN(0))) or (P1OUT_D and concatenate(DEC_SZ, (reg_addr = (P1OUT srl 1)) and P1_EN(0))) or (P1DIR_D and concatenate(DEC_SZ, (reg_addr = (P1DIR srl 1)) and P1_EN(0))) or (P1IFG_D and concatenate(DEC_SZ, (reg_addr = (P1IFG srl 1)) and P1_EN(0))) or (P1IES_D and concatenate(DEC_SZ, (reg_addr = (P1IES srl 1)) and P1_EN(0))) or (P1IE_D and concatenate(DEC_SZ, (reg_addr = (P1IE srl 1)) and P1_EN(0))) or (P1SEL_D and concatenate(DEC_SZ, (reg_addr = (P1SEL srl 1)) and P1_EN(0))) or (P2IN_D and concatenate(DEC_SZ, (reg_addr = (P2IN srl 1)) and P2_EN(0))) or (P2OUT_D and concatenate(DEC_SZ, (reg_addr = (P2OUT srl 1)) and P2_EN(0))) or (P2DIR_D and concatenate(DEC_SZ, (reg_addr = (P2DIR srl 1)) and P2_EN(0))) or (P2IFG_D and concatenate(DEC_SZ, (reg_addr = (P2IFG srl 1)) and P2_EN(0))) or (P2IES_D and concatenate(DEC_SZ, (reg_addr = (P2IES srl 1)) and P2_EN(0))) or (P2IE_D and concatenate(DEC_SZ, (reg_addr = (P2IE srl 1)) and P2_EN(0))) or (P2SEL_D and concatenate(DEC_SZ, (reg_addr = (P2SEL srl 1)) and P2_EN(0))) or (P3IN_D and concatenate(DEC_SZ, (reg_addr = (P3IN srl 1)) and P3_EN(0))) or (P3OUT_D and concatenate(DEC_SZ, (reg_addr = (P3OUT srl 1)) and P3_EN(0))) or (P3DIR_D and concatenate(DEC_SZ, (reg_addr = (P3DIR srl 1)) and P3_EN(0))) or (P3SEL_D and concatenate(DEC_SZ, (reg_addr = (P3SEL srl 1)) and P3_EN(0))) or (P4IN_D and concatenate(DEC_SZ, (reg_addr = (P4IN srl 1)) and P4_EN(0))) or (P4OUT_D and concatenate(DEC_SZ, (reg_addr = (P4OUT srl 1)) and P4_EN(0))) or (P4DIR_D and concatenate(DEC_SZ, (reg_addr = (P4DIR srl 1)) and P4_EN(0))) or (P4SEL_D and concatenate(DEC_SZ, (reg_addr = (P4SEL srl 1)) and P4_EN(0))) or (P5IN_D and concatenate(DEC_SZ, (reg_addr = (P5IN srl 1)) and P5_EN(0))) or (P5OUT_D and concatenate(DEC_SZ, (reg_addr = (P5OUT srl 1)) and P5_EN(0))) or (P5DIR_D and concatenate(DEC_SZ, (reg_addr = (P5DIR srl 1)) and P5_EN(0))) or (P5SEL_D and concatenate(DEC_SZ, (reg_addr = (P5SEL srl 1)) and P5_EN(0))) or (P6IN_D and concatenate(DEC_SZ, (reg_addr = (P6IN srl 1)) and P6_EN(0))) or (P6OUT_D and concatenate(DEC_SZ, (reg_addr = (P6OUT srl 1)) and P6_EN(0))) or (P6DIR_D and concatenate(DEC_SZ, (reg_addr = (P6DIR srl 1)) and P6_EN(0))) or (P6SEL_D and concatenate(DEC_SZ, (reg_addr = (P6SEL srl 1)) and P6_EN(0)));

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

  -- P1IN Register
  ----------------
  sync_cell_p1in_0 : omsp_sync_cell
  port map (
    data_out => p1in(0),
    data_in => p1_din(0) and P1_EN(0),
    clk => mclk,
    rst => puc_rst
  );
  sync_cell_p1in_1 : omsp_sync_cell
  port map (
    data_out => p1in(1),
    data_in => p1_din(1) and P1_EN(0),
    clk => mclk,
    rst => puc_rst
  );
  sync_cell_p1in_2 : omsp_sync_cell
  port map (
    data_out => p1in(2),
    data_in => p1_din(2) and P1_EN(0),
    clk => mclk,
    rst => puc_rst
  );
  sync_cell_p1in_3 : omsp_sync_cell
  port map (
    data_out => p1in(3),
    data_in => p1_din(3) and P1_EN(0),
    clk => mclk,
    rst => puc_rst
  );
  sync_cell_p1in_4 : omsp_sync_cell
  port map (
    data_out => p1in(4),
    data_in => p1_din(4) and P1_EN(0),
    clk => mclk,
    rst => puc_rst
  );
  sync_cell_p1in_5 : omsp_sync_cell
  port map (
    data_out => p1in(5),
    data_in => p1_din(5) and P1_EN(0),
    clk => mclk,
    rst => puc_rst
  );
  sync_cell_p1in_6 : omsp_sync_cell
  port map (
    data_out => p1in(6),
    data_in => p1_din(6) and P1_EN(0),
    clk => mclk,
    rst => puc_rst
  );
  sync_cell_p1in_7 : omsp_sync_cell
  port map (
    data_out => p1in(7),

    data_in => p1_din(7) and P1_EN(0),
    clk => mclk,
    rst => puc_rst
  );
  -- P1OUT Register
  -----------------
  p1out_wr <= reg_hi_wr(P1OUT)
  when P1OUT(0) else reg_lo_wr(P1OUT);
  p1out_nxt <= per_din(15 downto 8)
  when P1OUT(0) else per_din(7 downto 0);

  processing_0 : process (mclk, puc_rst)
  begin
    if (puc_rst) then
      p1out <= X"00";
    elsif (rising_edge(mclk)) then
      if (p1out_wr) then
        p1out <= p1out_nxt and P1_EN_MSK;
      end if;
    end if;
  end process;


  p1_dout <= p1out;

  -- P1DIR Register
  -----------------
  p1dir_wr <= reg_hi_wr(P1DIR)
  when P1DIR(0) else reg_lo_wr(P1DIR);
  p1dir_nxt <= per_din(15 downto 8)
  when P1DIR(0) else per_din(7 downto 0);

  processing_1 : process (mclk, puc_rst)
  begin
    if (puc_rst) then
      p1dir <= X"00";
    elsif (rising_edge(mclk)) then
      if (p1dir_wr) then
        p1dir <= p1dir_nxt and P1_EN_MSK;
      end if;
    end if;
  end process;


  p1_dout_en <= p1dir;

  -- P1IFG Register
  -----------------
  p1ifg_wr <= reg_hi_wr(P1IFG)
  when P1IFG(0) else reg_lo_wr(P1IFG);
  p1ifg_nxt <= per_din(15 downto 8)
  when P1IFG(0) else per_din(7 downto 0);

  processing_2 : process (mclk, puc_rst)
  begin
    if (puc_rst) then
      p1ifg <= X"00";
    elsif (rising_edge(mclk)) then
      if (p1ifg_wr) then
        p1ifg <= (p1ifg_nxt or p1ifg_set) and P1_EN_MSK;
      else
        p1ifg <= (p1ifg or p1ifg_set) and P1_EN_MSK;
      end if;
    end if;
  end process;


  -- P1IES Register
  -----------------
  p1ies_wr <= reg_hi_wr(P1IES)
  when P1IES(0) else reg_lo_wr(P1IES);
  p1ies_nxt <= per_din(15 downto 8)
  when P1IES(0) else per_din(7 downto 0);

  processing_3 : process (mclk, puc_rst)
  begin
    if (puc_rst) then
      p1ies <= X"00";
    elsif (rising_edge(mclk)) then
      if (p1ies_wr) then
        p1ies <= p1ies_nxt and P1_EN_MSK;
      end if;
    end if;
  end process;


  -- P1IE Register
  ------------------
  p1ie_wr <= reg_hi_wr(P1IE)
  when P1IE(0) else reg_lo_wr(P1IE);
  p1ie_nxt <= per_din(15 downto 8)
  when P1IE(0) else per_din(7 downto 0);

  processing_4 : process (mclk, puc_rst)
  begin
    if (puc_rst) then
      p1ie <= X"00";
    elsif (rising_edge(mclk)) then
      if (p1ie_wr) then
        p1ie <= p1ie_nxt and P1_EN_MSK;
      end if;
    end if;
  end process;


  -- P1SEL Register
  -----------------
  p1sel_wr <= reg_hi_wr(P1SEL)
  when P1SEL(0) else reg_lo_wr(P1SEL);
  p1sel_nxt <= per_din(15 downto 8)
  when P1SEL(0) else per_din(7 downto 0);

  processing_5 : process (mclk, puc_rst)
  begin
    if (puc_rst) then
      p1sel <= X"00";
    elsif (rising_edge(mclk)) then
      if (p1sel_wr) then
        p1sel <= p1sel_nxt and P1_EN_MSK;
      end if;
    end if;
  end process;


  p1_sel <= p1sel;

  -- P2IN Register
  ----------------
  sync_cell_p2in_0 : omsp_sync_cell
  port map (
    data_out => p2in(0),
    data_in => p2_din(0) and P2_EN(0),
    clk => mclk,
    rst => puc_rst
  );
  sync_cell_p2in_1 : omsp_sync_cell
  port map (
    data_out => p2in(1),
    data_in => p2_din(1) and P2_EN(0),
    clk => mclk,
    rst => puc_rst
  );
  sync_cell_p2in_2 : omsp_sync_cell
  port map (
    data_out => p2in(2),
    data_in => p2_din(2) and P2_EN(0),
    clk => mclk,
    rst => puc_rst
  );
  sync_cell_p2in_3 : omsp_sync_cell
  port map (
    data_out => p2in(3),
    data_in => p2_din(3) and P2_EN(0),
    clk => mclk,
    rst => puc_rst
  );
  sync_cell_p2in_4 : omsp_sync_cell
  port map (
    data_out => p2in(4),
    data_in => p2_din(4) and P2_EN(0),
    clk => mclk,
    rst => puc_rst
  );
  sync_cell_p2in_5 : omsp_sync_cell
  port map (
    data_out => p2in(5),
    data_in => p2_din(5) and P2_EN(0),
    clk => mclk,
    rst => puc_rst
  );
  sync_cell_p2in_6 : omsp_sync_cell
  port map (
    data_out => p2in(6),
    data_in => p2_din(6) and P2_EN(0),
    clk => mclk,
    rst => puc_rst
  );
  sync_cell_p2in_7 : omsp_sync_cell
  port map (
    data_out => p2in(7),

    data_in => p2_din(7) and P2_EN(0),
    clk => mclk,
    rst => puc_rst
  );
  -- P2OUT Register
  -----------------
  p2out_wr <= reg_hi_wr(P2OUT)
  when P2OUT(0) else reg_lo_wr(P2OUT);
  p2out_nxt <= per_din(15 downto 8)
  when P2OUT(0) else per_din(7 downto 0);

  processing_6 : process (mclk, puc_rst)
  begin
    if (puc_rst) then
      p2out <= X"00";
    elsif (rising_edge(mclk)) then
      if (p2out_wr) then
        p2out <= p2out_nxt and P2_EN_MSK;
      end if;
    end if;
  end process;


  p2_dout <= p2out;

  -- P2DIR Register
  -----------------
  p2dir_wr <= reg_hi_wr(P2DIR)
  when P2DIR(0) else reg_lo_wr(P2DIR);
  p2dir_nxt <= per_din(15 downto 8)
  when P2DIR(0) else per_din(7 downto 0);

  processing_7 : process (mclk, puc_rst)
  begin
    if (puc_rst) then
      p2dir <= X"00";
    elsif (rising_edge(mclk)) then
      if (p2dir_wr) then
        p2dir <= p2dir_nxt and P2_EN_MSK;
      end if;
    end if;
  end process;


  p2_dout_en <= p2dir;

  -- P2IFG Register
  -----------------
  p2ifg_wr <= reg_hi_wr(P2IFG)
  when P2IFG(0) else reg_lo_wr(P2IFG);
  p2ifg_nxt <= per_din(15 downto 8)
  when P2IFG(0) else per_din(7 downto 0);

  processing_8 : process (mclk, puc_rst)
  begin
    if (puc_rst) then
      p2ifg <= X"00";
    elsif (rising_edge(mclk)) then
      if (p2ifg_wr) then
        p2ifg <= (p2ifg_nxt or p2ifg_set) and P2_EN_MSK;
      else
        p2ifg <= (p2ifg or p2ifg_set) and P2_EN_MSK;
      end if;
    end if;
  end process;


  -- P2IES Register
  -----------------
  p2ies_wr <= reg_hi_wr(P2IES)
  when P2IES(0) else reg_lo_wr(P2IES);
  p2ies_nxt <= per_din(15 downto 8)
  when P2IES(0) else per_din(7 downto 0);

  processing_9 : process (mclk, puc_rst)
  begin
    if (puc_rst) then
      p2ies <= X"00";
    elsif (rising_edge(mclk)) then
      if (p2ies_wr) then
        p2ies <= p2ies_nxt and P2_EN_MSK;
      end if;
    end if;
  end process;


  -- P2IE Register
  ----------------
  p2ie_wr <= reg_hi_wr(P2IE)
  when P2IE(0) else reg_lo_wr(P2IE);
  p2ie_nxt <= per_din(15 downto 8)
  when P2IE(0) else per_din(7 downto 0);

  processing_10 : process (mclk, puc_rst)
  begin
    if (puc_rst) then
      p2ie <= X"00";
    elsif (rising_edge(mclk)) then
      if (p2ie_wr) then
        p2ie <= p2ie_nxt and P2_EN_MSK;
      end if;
    end if;
  end process;


  -- P2SEL Register
  ------------------
  p2sel_wr <= reg_hi_wr(P2SEL)
  when P2SEL(0) else reg_lo_wr(P2SEL);
  p2sel_nxt <= per_din(15 downto 8)
  when P2SEL(0) else per_din(7 downto 0);

  processing_11 : process (mclk, puc_rst)
  begin
    if (puc_rst) then
      p2sel <= X"00";
    elsif (rising_edge(mclk)) then
      if (p2sel_wr) then
        p2sel <= p2sel_nxt and P2_EN_MSK;
      end if;
    end if;
  end process;


  p2_sel <= p2sel;

  -- P3IN Register
  ----------------
  sync_cell_p3in_0 : omsp_sync_cell
  port map (
    data_out => p3in(0),
    data_in => p3_din(0) and P3_EN(0),
    clk => mclk,
    rst => puc_rst
  );
  sync_cell_p3in_1 : omsp_sync_cell
  port map (
    data_out => p3in(1),
    data_in => p3_din(1) and P3_EN(0),
    clk => mclk,
    rst => puc_rst
  );
  sync_cell_p3in_2 : omsp_sync_cell
  port map (
    data_out => p3in(2),
    data_in => p3_din(2) and P3_EN(0),
    clk => mclk,
    rst => puc_rst
  );
  sync_cell_p3in_3 : omsp_sync_cell
  port map (
    data_out => p3in(3),
    data_in => p3_din(3) and P3_EN(0),
    clk => mclk,
    rst => puc_rst
  );
  sync_cell_p3in_4 : omsp_sync_cell
  port map (
    data_out => p3in(4),
    data_in => p3_din(4) and P3_EN(0),
    clk => mclk,
    rst => puc_rst
  );
  sync_cell_p3in_5 : omsp_sync_cell
  port map (
    data_out => p3in(5),
    data_in => p3_din(5) and P3_EN(0),
    clk => mclk,
    rst => puc_rst
  );
  sync_cell_p3in_6 : omsp_sync_cell
  port map (
    data_out => p3in(6),
    data_in => p3_din(6) and P3_EN(0),
    clk => mclk,
    rst => puc_rst
  );
  sync_cell_p3in_7 : omsp_sync_cell
  port map (
    data_out => p3in(7),

    data_in => p3_din(7) and P3_EN(0),
    clk => mclk,
    rst => puc_rst
  );
  -- P3OUT Register
  -----------------
  p3out_wr <= reg_hi_wr(P3OUT)
  when P3OUT(0) else reg_lo_wr(P3OUT);
  p3out_nxt <= per_din(15 downto 8)
  when P3OUT(0) else per_din(7 downto 0);

  processing_12 : process (mclk, puc_rst)
  begin
    if (puc_rst) then
      p3out <= X"00";
    elsif (rising_edge(mclk)) then
      if (p3out_wr) then
        p3out <= p3out_nxt and P3_EN_MSK;
      end if;
    end if;
  end process;


  p3_dout <= p3out;

  -- P3DIR Register
  -----------------
  p3dir_wr <= reg_hi_wr(P3DIR)
  when P3DIR(0) else reg_lo_wr(P3DIR);
  p3dir_nxt <= per_din(15 downto 8)
  when P3DIR(0) else per_din(7 downto 0);

  processing_13 : process (mclk, puc_rst)
  begin
    if (puc_rst) then
      p3dir <= X"00";
    elsif (rising_edge(mclk)) then
      if (p3dir_wr) then
        p3dir <= p3dir_nxt and P3_EN_MSK;
      end if;
    end if;
  end process;


  p3_dout_en <= p3dir;

  -- P3SEL Register
  -----------------
  p3sel_wr <= reg_hi_wr(P3SEL)
  when P3SEL(0) else reg_lo_wr(P3SEL);
  p3sel_nxt <= per_din(15 downto 8)
  when P3SEL(0) else per_din(7 downto 0);

  processing_14 : process (mclk, puc_rst)
  begin
    if (puc_rst) then
      p3sel <= X"00";
    elsif (rising_edge(mclk)) then
      if (p3sel_wr) then
        p3sel <= p3sel_nxt and P3_EN_MSK;
      end if;
    end if;
  end process;


  p3_sel <= p3sel;

  -- P4IN Register
  ----------------
  sync_cell_p4in_0 : omsp_sync_cell
  port map (
    data_out => p4in(0),
    data_in => p4_din(0) and P4_EN(0),
    clk => mclk,
    rst => puc_rst
  );
  sync_cell_p4in_1 : omsp_sync_cell
  port map (
    data_out => p4in(1),
    data_in => p4_din(1) and P4_EN(0),
    clk => mclk,
    rst => puc_rst
  );
  sync_cell_p4in_2 : omsp_sync_cell
  port map (
    data_out => p4in(2),
    data_in => p4_din(2) and P4_EN(0),
    clk => mclk,
    rst => puc_rst
  );
  sync_cell_p4in_3 : omsp_sync_cell
  port map (
    data_out => p4in(3),
    data_in => p4_din(3) and P4_EN(0),
    clk => mclk,
    rst => puc_rst
  );
  sync_cell_p4in_4 : omsp_sync_cell
  port map (
    data_out => p4in(4),
    data_in => p4_din(4) and P4_EN(0),
    clk => mclk,
    rst => puc_rst
  );
  sync_cell_p4in_5 : omsp_sync_cell
  port map (
    data_out => p4in(5),
    data_in => p4_din(5) and P4_EN(0),
    clk => mclk,
    rst => puc_rst
  );
  sync_cell_p4in_6 : omsp_sync_cell
  port map (
    data_out => p4in(6),
    data_in => p4_din(6) and P4_EN(0),
    clk => mclk,
    rst => puc_rst
  );
  sync_cell_p4in_7 : omsp_sync_cell
  port map (
    data_out => p4in(7),

    data_in => p4_din(7) and P4_EN(0),
    clk => mclk,
    rst => puc_rst
  );
  -- P4OUT Register
  -----------------
  p4out_wr <= reg_hi_wr(P4OUT)
  when P4OUT(0) else reg_lo_wr(P4OUT);
  p4out_nxt <= per_din(15 downto 8)
  when P4OUT(0) else per_din(7 downto 0);

  processing_15 : process (mclk, puc_rst)
  begin
    if (puc_rst) then
      p4out <= X"00";
    elsif (rising_edge(mclk)) then
      if (p4out_wr) then
        p4out <= p4out_nxt and P4_EN_MSK;
      end if;
    end if;
  end process;


  p4_dout <= p4out;

  -- P4DIR Register
  -----------------
  p4dir_wr <= reg_hi_wr(P4DIR)
  when P4DIR(0) else reg_lo_wr(P4DIR);
  p4dir_nxt <= per_din(15 downto 8)
  when P4DIR(0) else per_din(7 downto 0);

  processing_16 : process (mclk, puc_rst)
  begin
    if (puc_rst) then
      p4dir <= X"00";
    elsif (rising_edge(mclk)) then
      if (p4dir_wr) then
        p4dir <= p4dir_nxt and P4_EN_MSK;
      end if;
    end if;
  end process;


  p4_dout_en <= p4dir;

  -- P4SEL Register
  -----------------
  p4sel_wr <= reg_hi_wr(P4SEL)
  when P4SEL(0) else reg_lo_wr(P4SEL);
  p4sel_nxt <= per_din(15 downto 8)
  when P4SEL(0) else per_din(7 downto 0);

  processing_17 : process (mclk, puc_rst)
  begin
    if (puc_rst) then
      p4sel <= X"00";
    elsif (rising_edge(mclk)) then
      if (p4sel_wr) then
        p4sel <= p4sel_nxt and P4_EN_MSK;
      end if;
    end if;
  end process;


  p4_sel <= p4sel;

  -- P5IN Register
  ----------------
  sync_cell_p5in_0 : omsp_sync_cell
  port map (
    data_out => p5in(0),
    data_in => p5_din(0) and P5_EN(0),
    clk => mclk,
    rst => puc_rst
  );
  sync_cell_p5in_1 : omsp_sync_cell
  port map (
    data_out => p5in(1),
    data_in => p5_din(1) and P5_EN(0),
    clk => mclk,
    rst => puc_rst
  );
  sync_cell_p5in_2 : omsp_sync_cell
  port map (
    data_out => p5in(2),
    data_in => p5_din(2) and P5_EN(0),
    clk => mclk,
    rst => puc_rst
  );
  sync_cell_p5in_3 : omsp_sync_cell
  port map (
    data_out => p5in(3),
    data_in => p5_din(3) and P5_EN(0),
    clk => mclk,
    rst => puc_rst
  );
  sync_cell_p5in_4 : omsp_sync_cell
  port map (
    data_out => p5in(4),
    data_in => p5_din(4) and P5_EN(0),
    clk => mclk,
    rst => puc_rst
  );
  sync_cell_p5in_5 : omsp_sync_cell
  port map (
    data_out => p5in(5),
    data_in => p5_din(5) and P5_EN(0),
    clk => mclk,
    rst => puc_rst
  );
  sync_cell_p5in_6 : omsp_sync_cell
  port map (
    data_out => p5in(6),
    data_in => p5_din(6) and P5_EN(0),
    clk => mclk,
    rst => puc_rst
  );
  sync_cell_p5in_7 : omsp_sync_cell
  port map (
    data_out => p5in(7),

    data_in => p5_din(7) and P5_EN(0),
    clk => mclk,
    rst => puc_rst
  );
  -- P5OUT Register
  -----------------
  p5out_wr <= reg_hi_wr(P5OUT)
  when P5OUT(0) else reg_lo_wr(P5OUT);
  p5out_nxt <= per_din(15 downto 8)
  when P5OUT(0) else per_din(7 downto 0);

  processing_18 : process (mclk, puc_rst)
  begin
    if (puc_rst) then
      p5out <= X"00";
    elsif (rising_edge(mclk)) then
      if (p5out_wr) then
        p5out <= p5out_nxt and P5_EN_MSK;
      end if;
    end if;
  end process;


  p5_dout <= p5out;

  -- P5DIR Register
  -----------------
  p5dir_wr <= reg_hi_wr(P5DIR)
  when P5DIR(0) else reg_lo_wr(P5DIR);
  p5dir_nxt <= per_din(15 downto 8)
  when P5DIR(0) else per_din(7 downto 0);

  processing_19 : process (mclk, puc_rst)
  begin
    if (puc_rst) then
      p5dir <= X"00";
    elsif (rising_edge(mclk)) then
      if (p5dir_wr) then
        p5dir <= p5dir_nxt and P5_EN_MSK;
      end if;
    end if;
  end process;


  p5_dout_en <= p5dir;

  -- P5SEL Register
  -----------------
  p5sel_wr <= reg_hi_wr(P5SEL)
  when P5SEL(0) else reg_lo_wr(P5SEL);
  p5sel_nxt <= per_din(15 downto 8)
  when P5SEL(0) else per_din(7 downto 0);

  processing_20 : process (mclk, puc_rst)
  begin
    if (puc_rst) then
      p5sel <= X"00";
    elsif (rising_edge(mclk)) then
      if (p5sel_wr) then
        p5sel <= p5sel_nxt and P5_EN_MSK;
      end if;
    end if;
  end process;


  p5_sel <= p5sel;

  -- P6IN Register
  ----------------
  sync_cell_p6in_0 : omsp_sync_cell
  port map (
    data_out => p6in(0),
    data_in => p6_din(0) and P6_EN(0),
    clk => mclk,
    rst => puc_rst
  );
  sync_cell_p6in_1 : omsp_sync_cell
  port map (
    data_out => p6in(1),
    data_in => p6_din(1) and P6_EN(0),
    clk => mclk,
    rst => puc_rst
  );
  sync_cell_p6in_2 : omsp_sync_cell
  port map (
    data_out => p6in(2),
    data_in => p6_din(2) and P6_EN(0),
    clk => mclk,
    rst => puc_rst
  );
  sync_cell_p6in_3 : omsp_sync_cell
  port map (
    data_out => p6in(3),
    data_in => p6_din(3) and P6_EN(0),
    clk => mclk,
    rst => puc_rst
  );
  sync_cell_p6in_4 : omsp_sync_cell
  port map (
    data_out => p6in(4),
    data_in => p6_din(4) and P6_EN(0),
    clk => mclk,
    rst => puc_rst
  );
  sync_cell_p6in_5 : omsp_sync_cell
  port map (
    data_out => p6in(5),
    data_in => p6_din(5) and P6_EN(0),
    clk => mclk,
    rst => puc_rst
  );
  sync_cell_p6in_6 : omsp_sync_cell
  port map (
    data_out => p6in(6),
    data_in => p6_din(6) and P6_EN(0),
    clk => mclk,
    rst => puc_rst
  );
  sync_cell_p6in_7 : omsp_sync_cell
  port map (
    data_out => p6in(7),

    data_in => p6_din(7) and P6_EN(0),
    clk => mclk,
    rst => puc_rst
  );
  -- P6OUT Register
  -----------------
  p6out_wr <= reg_hi_wr(P6OUT)
  when P6OUT(0) else reg_lo_wr(P6OUT);
  p6out_nxt <= per_din(15 downto 8)
  when P6OUT(0) else per_din(7 downto 0);

  processing_21 : process (mclk, puc_rst)
  begin
    if (puc_rst) then
      p6out <= X"00";
    elsif (rising_edge(mclk)) then
      if (p6out_wr) then
        p6out <= p6out_nxt and P6_EN_MSK;
      end if;
    end if;
  end process;


  p6_dout <= p6out;

  -- P6DIR Register
  -----------------
  p6dir_wr <= reg_hi_wr(P6DIR)
  when P6DIR(0) else reg_lo_wr(P6DIR);
  p6dir_nxt <= per_din(15 downto 8)
  when P6DIR(0) else per_din(7 downto 0);

  processing_22 : process (mclk, puc_rst)
  begin
    if (puc_rst) then
      p6dir <= X"00";
    elsif (rising_edge(mclk)) then
      if (p6dir_wr) then
        p6dir <= p6dir_nxt and P6_EN_MSK;
      end if;
    end if;
  end process;


  p6_dout_en <= p6dir;

  -- P6SEL Register
  -----------------
  p6sel_wr <= reg_hi_wr(P6SEL)
  when P6SEL(0) else reg_lo_wr(P6SEL);
  p6sel_nxt <= per_din(15 downto 8)
  when P6SEL(0) else per_din(7 downto 0);

  processing_23 : process (mclk, puc_rst)
  begin
    if (puc_rst) then
      p6sel <= X"00";
    elsif (rising_edge(mclk)) then
      if (p6sel_wr) then
        p6sel <= p6sel_nxt and P6_EN_MSK;
      end if;
    end if;
  end process;


  p6_sel <= p6sel;

  --============================================================================
  -- 4) INTERRUPT GENERATION
  --============================================================================

  -- Port 1 interrupt
  -------------------

  -- Delay input
  processing_24 : process (mclk, puc_rst)
  begin
    if (puc_rst) then
      p1in_dly <= X"00";
    elsif (rising_edge(mclk)) then
      p1in_dly <= p1in and P1_EN_MSK;
    end if;
  end process;


  -- Edge detection
  p1in_re <= p1in and not p1in_dly;
  p1in_fe <= not p1in and p1in_dly;

  -- Set interrupt flag
  p1ifg_set <= (p1in_fe(7)
  when p1ies(7) else p1in_re(7) & p1in_fe(6)
  when p1ies(6) else p1in_re(6) & p1in_fe(5)
  when p1ies(5) else p1in_re(5) & p1in_fe(4)
  when p1ies(4) else p1in_re(4) & p1in_fe(3)
  when p1ies(3) else p1in_re(3) & p1in_fe(2)
  when p1ies(2) else p1in_re(2) & p1in_fe(1)
  when p1ies(1) else p1in_re(1) & p1in_fe(0)
  when p1ies(0) else p1in_re(0)) and P1_EN_MSK;

  -- Generate CPU interrupt
  irq_port1 <= or (p1ie and p1ifg) and P1_EN(0);


  -- Port 2 interrupt
  -------------------

  -- Delay input
  processing_25 : process (mclk, puc_rst)
  begin
    if (puc_rst) then
      p2in_dly <= X"00";
    elsif (rising_edge(mclk)) then
      p2in_dly <= p2in and P2_EN_MSK;
    end if;
  end process;


  -- Edge detection
  p2in_re <= p2in and not p2in_dly;
  p2in_fe <= not p2in and p2in_dly;

  -- Set interrupt flag
  p2ifg_set <= (p2in_fe(7)
  when p2ies(7) else p2in_re(7) & p2in_fe(6)
  when p2ies(6) else p2in_re(6) & p2in_fe(5)
  when p2ies(5) else p2in_re(5) & p2in_fe(4)
  when p2ies(4) else p2in_re(4) & p2in_fe(3)
  when p2ies(3) else p2in_re(3) & p2in_fe(2)
  when p2ies(2) else p2in_re(2) & p2in_fe(1)
  when p2ies(1) else p2in_re(1) & p2in_fe(0)
  when p2ies(0) else p2in_re(0)) and P2_EN_MSK;

  -- Generate CPU interrupt
  irq_port2 <= or (p2ie and p2ifg) and P2_EN(0);

  --============================================================================
  -- 5) DATA OUTPUT GENERATION
  --============================================================================

  -- Data output mux
  p1in_rd <= (X"00" & (p1in and concatenate(8, reg_rd(P1IN)))) sll (8 and concatenate(4, P1IN(0)));
  p1out_rd <= (X"00" & (p1out and concatenate(8, reg_rd(P1OUT)))) sll (8 and concatenate(4, P1OUT(0)));
  p1dir_rd <= (X"00" & (p1dir and concatenate(8, reg_rd(P1DIR)))) sll (8 and concatenate(4, P1DIR(0)));
  p1ifg_rd <= (X"00" & (p1ifg and concatenate(8, reg_rd(P1IFG)))) sll (8 and concatenate(4, P1IFG(0)));
  p1ies_rd <= (X"00" & (p1ies and concatenate(8, reg_rd(P1IES)))) sll (8 and concatenate(4, P1IES(0)));
  p1ie_rd <= (X"00" & (p1ie and concatenate(8, reg_rd(P1IE)))) sll (8 and concatenate(4, P1IE(0)));
  p1sel_rd <= (X"00" & (p1sel and concatenate(8, reg_rd(P1SEL)))) sll (8 and concatenate(4, P1SEL(0)));
  p2in_rd <= (X"00" & (p2in and concatenate(8, reg_rd(P2IN)))) sll (8 and concatenate(4, P2IN(0)));
  p2out_rd <= (X"00" & (p2out and concatenate(8, reg_rd(P2OUT)))) sll (8 and concatenate(4, P2OUT(0)));
  p2dir_rd <= (X"00" & (p2dir and concatenate(8, reg_rd(P2DIR)))) sll (8 and concatenate(4, P2DIR(0)));
  p2ifg_rd <= (X"00" & (p2ifg and concatenate(8, reg_rd(P2IFG)))) sll (8 and concatenate(4, P2IFG(0)));
  p2ies_rd <= (X"00" & (p2ies and concatenate(8, reg_rd(P2IES)))) sll (8 and concatenate(4, P2IES(0)));
  p2ie_rd <= (X"00" & (p2ie and concatenate(8, reg_rd(P2IE)))) sll (8 and concatenate(4, P2IE(0)));
  p2sel_rd <= (X"00" & (p2sel and concatenate(8, reg_rd(P2SEL)))) sll (8 and concatenate(4, P2SEL(0)));
  p3in_rd <= (X"00" & (p3in and concatenate(8, reg_rd(P3IN)))) sll (8 and concatenate(4, P3IN(0)));
  p3out_rd <= (X"00" & (p3out and concatenate(8, reg_rd(P3OUT)))) sll (8 and concatenate(4, P3OUT(0)));
  p3dir_rd <= (X"00" & (p3dir and concatenate(8, reg_rd(P3DIR)))) sll (8 and concatenate(4, P3DIR(0)));
  p3sel_rd <= (X"00" & (p3sel and concatenate(8, reg_rd(P3SEL)))) sll (8 and concatenate(4, P3SEL(0)));
  p4in_rd <= (X"00" & (p4in and concatenate(8, reg_rd(P4IN)))) sll (8 and concatenate(4, P4IN(0)));
  p4out_rd <= (X"00" & (p4out and concatenate(8, reg_rd(P4OUT)))) sll (8 and concatenate(4, P4OUT(0)));
  p4dir_rd <= (X"00" & (p4dir and concatenate(8, reg_rd(P4DIR)))) sll (8 and concatenate(4, P4DIR(0)));
  p4sel_rd <= (X"00" & (p4sel and concatenate(8, reg_rd(P4SEL)))) sll (8 and concatenate(4, P4SEL(0)));
  p5in_rd <= (X"00" & (p5in and concatenate(8, reg_rd(P5IN)))) sll (8 and concatenate(4, P5IN(0)));
  p5out_rd <= (X"00" & (p5out and concatenate(8, reg_rd(P5OUT)))) sll (8 and concatenate(4, P5OUT(0)));
  p5dir_rd <= (X"00" & (p5dir and concatenate(8, reg_rd(P5DIR)))) sll (8 and concatenate(4, P5DIR(0)));
  p5sel_rd <= (X"00" & (p5sel and concatenate(8, reg_rd(P5SEL)))) sll (8 and concatenate(4, P5SEL(0)));
  p6in_rd <= (X"00" & (p6in and concatenate(8, reg_rd(P6IN)))) sll (8 and concatenate(4, P6IN(0)));
  p6out_rd <= (X"00" & (p6out and concatenate(8, reg_rd(P6OUT)))) sll (8 and concatenate(4, P6OUT(0)));
  p6dir_rd <= (X"00" & (p6dir and concatenate(8, reg_rd(P6DIR)))) sll (8 and concatenate(4, P6DIR(0)));
  p6sel_rd <= (X"00" & (p6sel and concatenate(8, reg_rd(P6SEL)))) sll (8 and concatenate(4, P6SEL(0)));

  per_dout <= p1in_rd or p1out_rd or p1dir_rd or p1ifg_rd or p1ies_rd or p1ie_rd or p1sel_rd or p2in_rd or p2out_rd or p2dir_rd or p2ifg_rd or p2ies_rd or p2ie_rd or p2sel_rd or p3in_rd or p3out_rd or p3dir_rd or p3sel_rd or p4in_rd or p4out_rd or p4dir_rd or p4sel_rd or p5in_rd or p5out_rd or p5dir_rd or p5sel_rd or p6in_rd or p6out_rd or p6dir_rd or p6sel_rd;
end RTL;
