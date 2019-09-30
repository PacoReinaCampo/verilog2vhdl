-- Converted from core/riscv_bp.sv
-- by verilog2vhdl - QueenField

--//////////////////////////////////////////////////////////////////////////////
--                                            __ _      _     _               //
--                                           / _(_)    | |   | |              //
--                __ _ _   _  ___  ___ _ __ | |_ _  ___| | __| |              //
--               / _` | | | |/ _ \/ _ \ '_ \|  _| |/ _ \ |/ _` |              //
--              | (_| | |_| |  __/  __/ | | | | | |  __/ | (_| |              //
--               \__, |\__,_|\___|\___|_| |_|_| |_|\___|_|\__,_|              //
--                  | |                                                       //
--                  |_|                                                       //
--                                                                            //
--                                                                            //
--              MPSoC-RISCV CPU                                               //
--              Core - Correlating Branch Prediction Unit                     //
--              AMBA3 AHB-Lite Bus Interface                                  //
--                                                                            //
--//////////////////////////////////////////////////////////////////////////////

-- Copyright (c) 2017-2018 by the author(s)
-- *
-- * Permission is hereby granted, free of charge, to any person obtaining a copy
-- * of this software and associated documentation files (the "Software"), to deal
-- * in the Software without restriction, including without limitation the rights
-- * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- * copies of the Software, and to permit persons to whom the Software is
-- * furnished to do so, subject to the following conditions:
-- *
-- * The above copyright notice and this permission notice shall be included in
-- * all copies or substantial portions of the Software.
-- *
-- * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- * THE SOFTWARE.
-- *
-- * =============================================================================
-- * Author(s):
-- *   Francisco Javier Reina Campo <frareicam@gmail.com>
-- */

use work."riscv_mpsoc_pkg.sv".all;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity riscv_bp is
  port (










    rst_ni : in std_logic;
    clk_i : in std_logic;

  --Read side
    id_stall_i : in std_logic;
    if_parcel_pc_i : in std_logic_vector(XLEN-1 downto 0);
    bp_bp_predict_o : out std_logic_vector(1 downto 0);

  --Write side
    ex_pc_i : in std_logic_vector(XLEN-1 downto 0);
    bu_bp_history_i : in std_logic_vector(BP_GLOBAL_BITS-1 downto 0);  --branch history
    bu_bp_predict_i : in std_logic_vector(1 downto 0);  --prediction bits for branch
    bu_bp_btaken_i : in std_logic 
    bu_bp_update_i : in std_logic
  );
  constant XLEN : integer := 64;
  constant HAS_BPU : integer := 1;
  constant BP_GLOBAL_BITS : integer := 2;
  constant BP_LOCAL_BITS : integer := 10;
  constant BP_LOCAL_BITS_LSB : integer := 2;
  constant TECHNOLOGY : integer := "GENERIC";
  constant AVOID_X : integer := 0;
  constant PC_INIT : std_logic_vector(XLEN-1 downto 0) := X"8000_0000";
end riscv_bp;

architecture RTL of riscv_bp is
  component riscv_ram_1r1w
  generic (
    ? : std_logic_vector(? downto 0) := ?;
    ? : std_logic_vector(? downto 0) := ?;
    ? : std_logic_vector(? downto 0) := ?
  );
  port (
    rst_ni : std_logic_vector(? downto 0);
    clk_i : std_logic_vector(? downto 0);
    waddr_i : std_logic_vector(? downto 0);
    din_i : std_logic_vector(? downto 0);
    we_i : std_logic_vector(? downto 0);
    be_i : std_logic_vector(? downto 0);
    raddr_i : std_logic_vector(? downto 0);
    re_i : std_logic_vector(? downto 0);
    dout_o : std_logic_vector(? downto 0)
  );
  end component;



  --////////////////////////////////////////////////////////////////
  --
  -- Constants
  --
  constant ADR_BITS : integer := BP_GLOBAL_BITS+BP_LOCAL_BITS;
  constant MEMORY_DEPTH : integer := 1 sll ADR_BITS;

  --////////////////////////////////////////////////////////////////
  --
  -- Variables
  --
  signal radr : std_logic_vector(ADR_BITS-1 downto 0);
  signal wadr : std_logic_vector(ADR_BITS-1 downto 0);

  signal if_parcel_pc_dly : std_logic_vector(XLEN-1 downto 0);

  signal new_prediction : std_logic_vector(1 downto 0);
  signal old_prediction : std_logic_vector(1 downto 0);

begin
  --////////////////////////////////////////////////////////////////
  --
  -- Module Body
  --
  processing_0 : process (clk_i, rst_ni)
  begin
    if (not rst_ni) then
      if_parcel_pc_dly <= PC_INIT;
    elsif (rising_edge(clk_i)) then
      if (not id_stall_i) then
        if_parcel_pc_dly <= if_parcel_pc_i;
      end if;
    end if;
  end process;


  radr <= (bu_bp_history_i & if_parcel_pc_dly(BP_LOCAL_BITS_LSB+BP_LOCAL_BITS))
  when id_stall_i else (bu_bp_history_i & if_parcel_pc_i(BP_LOCAL_BITS_LSB+BP_LOCAL_BITS));
  wadr <= (bu_bp_history_i & ex_pc_i(BP_LOCAL_BITS_LSB+BP_LOCAL_BITS));

  --
--   *  Calculate new prediction bits
--   *
--   *  00<-->01<-->11<-->10
--   */

  new_prediction(0) <= bu_bp_predict_i(1) xor bu_bp_btaken_i;
  new_prediction(1) <= (bu_bp_predict_i(1) and not bu_bp_predict_i(0)) or (bu_bp_btaken_i and bu_bp_predict_i(0));

  -- Hookup 1R1W memory
  ram_1r1w : riscv_ram_1r1w
  generic map (
    ABITS, 
    DBITS, 
    TECHNOLOGY
  )
  port map (
    rst_ni => rst_ni,
    clk_i => clk_i,

    --Write side
    waddr_i => wadr,
    din_i => new_prediction,
    we_i => bu_bp_update_i,
    be_i => '1',

    --Read side
    raddr_i => radr,
    re_i => '1',
    dout_o => old_prediction
  );


  if (AVOID_X) generate
    bp_bp_predict_o <= random
    when (old_prediction = "xx") else old_prediction;
  else generate
    bp_bp_predict_o <= old_prediction;
  end generate;
end RTL;
