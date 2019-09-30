-- Converted from core/memory/riscv_membuf.sv
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
--              Core - Memory Access Buffer                                   //
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

entity riscv_membuf is
  port (
    rst_ni : in std_logic;
    clk_i : in std_logic;

    clr_i : in std_logic;  --clear pending requests
    ena_i : in std_logic;

  --CPU side
    req_i : in std_logic;
    d_i : in std_logic_vector(DBITS-1 downto 0);

  --Memory system side
    req_o : out std_logic;
    ack_i : in std_logic;
    q_o : out std_logic_vector(DBITS-1 downto 0);

    empty_o : out std_logic 
    full_o : out std_logic
  );
  constant DEPTH : integer := 2;
  constant DBITS : integer := 64;
end riscv_membuf;

architecture RTL of riscv_membuf is
  component riscv_ram_queue
  generic (
    ? : std_logic_vector(? downto 0) := ?;
    ? : std_logic_vector(? downto 0) := ?
  );
  port (
    rst_ni : std_logic_vector(? downto 0);
    clk_i : std_logic_vector(? downto 0);
    clr_i : std_logic_vector(? downto 0);
    ena_i : std_logic_vector(? downto 0);
    we_i : std_logic_vector(? downto 0);
    d_i : std_logic_vector(? downto 0);
    re_i : std_logic_vector(? downto 0);
    q_o : std_logic_vector(? downto 0);
    empty_o : std_logic_vector(? downto 0);
    full_o : std_logic_vector(? downto 0);
    almost_empty_o : std_logic_vector(? downto 0);
    almost_full_o : std_logic_vector(? downto 0)
  );
  end component;



  --////////////////////////////////////////////////////////////////
  --
  -- Variables
  --
  signal queue_q : std_logic_vector(DBITS-1 downto 0);
  signal queue_we : std_logic;
  signal queue_re : std_logic;

  signal access_pending : std_logic_vector((null)(DEPTH) downto 0);

begin
  --////////////////////////////////////////////////////////////////
  --
  -- Module Body
  --

  -- Instantiate Queue 
  ram_queue : riscv_ram_queue
  generic map (
    DEPTH, 
    DBITS
  )
  port map (
    rst_ni => rst_ni,
    clk_i => clk_i,
    clr_i => clr_i,
    ena_i => ena_i,
    we_i => queue_we,
    d_i => d_i,
    re_i => queue_re,
    q_o => queue_q,
    empty_o => empty_o,
    full_o => full_o,
    almost_empty_o => open,
    almost_full_o => open,
  );


  --control signals
  processing_0 : process (clk_i, rst_ni)
  begin
    if (not rst_ni) then
      access_pending <= X"0";
    elsif (rising_edge(clk_i)) then
      if (clr_i) then
        access_pending <= X"0";
      elsif (ena_i) then
        case (((req_i & ack_i))) is
        when "01" =>
          access_pending <= access_pending-1;
        when "10" =>
          access_pending <= access_pending+1;
        when others =>
        --do nothing
          null;
        end case;
      end if;
    end if;
  end process;


  queue_we <= or access_pending and (req_i and not (empty_o and ack_i));
  queue_re <= ack_i and not empty_o;

  --queue outputs
  req_o <= req_i and not clr_i
  when nor access_pending else (req_i or not empty_o) and ack_i and ena_i and not clr_i;

  q_o <= d_i
  when empty_o else queue_q;
end RTL;
