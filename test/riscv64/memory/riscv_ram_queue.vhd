-- Converted from memory/riscv_ram_queue.sv
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
--              Core - Fall-through Queue                                     //
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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity riscv_ram_queue is
  port (
    rst_ni : in std_logic;  --asynchronous, active low reset
    clk_i : in std_logic;  --rising edge triggered clock

    clr_i : in std_logic;  --clear all queue entries (synchronous reset)
    ena_i : in std_logic;  --clock enable

  --Queue Write
    we_i : in std_logic;  --Queue write enable
    d_i : in std_logic_vector(DBITS-1 downto 0);  --Queue write data

  --Queue Read
    re_i : in std_logic;  --Queue read enable
    q_o : out std_logic_vector(DBITS-1 downto 0);  --Queue read data

  --Status signals
    empty_o : out std_logic;  --Queue is empty
    full_o : out std_logic;  --Queue is full
    almost_empty_o : out std_logic   --Programmable almost empty
    almost_full_o : out std_logic  --Programmable almost full
  );
  constant DEPTH : integer := 8;
  constant DBITS : integer := 64;
  constant ALMOST_FULL_THRESHOLD : integer := 4;
  constant ALMOST_EMPTY_THRESHOLD : integer := 0;
end riscv_ram_queue;

architecture RTL of riscv_ram_queue is


  --////////////////////////////////////////////////////////////////
  --
  -- Constants
  --
  constant EMPTY_THRESHOLD : integer := 1;
  constant FULL_THRESHOLD : integer := DEPTH-2;
  constant ALMOST_EMPTY_THRESHOLD_CHECK : integer := EMPTY_THRESHOLD
  when ALMOST_EMPTY_THRESHOLD <= 0 else ALMOST_EMPTY_THRESHOLD+1;
  constant ALMOST_FULL_THRESHOLD_CHECK : integer := FULL_THRESHOLD
  when ALMOST_FULL_THRESHOLD >= DEPTH else ALMOST_FULL_THRESHOLD-2;

  --////////////////////////////////////////////////////////////////
  --
  -- Variables
  --
  signal queue_data : array (DEPTH) of std_logic_vector(DBITS-1 downto 0);
  signal queue_xadr : std_logic_vector((null)(DEPTH)-1 downto 0);
  signal queue_wadr : std_logic_vector((null)(DEPTH)-1 downto 0);

  signal n : std_logic;

begin
  --////////////////////////////////////////////////////////////////
  --
  -- Module Body
  --

  --Write Address
  processing_0 : process (clk_i, rst_ni)
  begin
    if (not rst_ni) then
      queue_wadr <= X"0";
    elsif (rising_edge(clk_i)) then
      if (clr_i) then
        queue_wadr <= X"0";
      elsif (ena_i) then
        case (((we_i & re_i))) is
        when "01" =>
          queue_wadr <= queue_wadr-1;
        when "10" =>
          queue_wadr <= queue_wadr+1;
        when others =>
          null;
        end case;
      end if;
    end if;
  end process;


  queue_xadr <= DEPTH-1
  when nor queue_wadr else queue_wadr-1;

  --Queue Data
  for n in 0 to DEPTH-1 - 1 generate
    processing_1 : process (clk_i, rst_ni)
    begin
      if (not rst_ni) then
        queue_data(n) <= X"0";
        queue_data(DEPTH-1) <= X"0";
      elsif (rising_edge(clk_i)) then
        if (clr_i) then
          queue_data(n) <= X"0";
          queue_data(DEPTH-1) <= X"0";
        elsif (ena_i) then
          case (((we_i & re_i))) is
          when "01" =>
            queue_data(n) <= queue_data(n+1);
            queue_data(DEPTH-1) <= X"0";
          when "10" =>
            queue_data(queue_wadr) <= d_i;
          when "11" =>
            queue_data(n) <= queue_data(n+1);
            queue_data(DEPTH-1) <= X"0";
            queue_data(queue_xadr) <= d_i;
          when others =>
            null;
          end case;
        end if;
      end if;
    end process;
  end generate;


  --Queue Almost Empty
  processing_2 : process (clk_i, rst_ni)
  begin
    if (not rst_ni) then
      almost_empty_o <= '1';
    elsif (rising_edge(clk_i)) then
      if (clr_i) then
        almost_empty_o <= '1';
      elsif (ena_i) then
        case (((we_i & re_i))) is
        when "01" =>
          almost_empty_o <= (queue_wadr <= ALMOST_EMPTY_THRESHOLD_CHECK);
        when "10" =>
          almost_empty_o <= not (queue_wadr > ALMOST_EMPTY_THRESHOLD_CHECK);
        when others =>
          null;
        end case;
      end if;
    end if;
  end process;


  --Queue Empty
  processing_3 : process (clk_i, rst_ni)
  begin
    if (not rst_ni) then
      empty_o <= '1';
    elsif (rising_edge(clk_i)) then
      if (clr_i) then
        empty_o <= '1';
      elsif (ena_i) then
        case (((we_i & re_i))) is
        when "01" =>
          empty_o <= (queue_wadr = EMPTY_THRESHOLD);
        when "10" =>
          empty_o <= '0';
        when others =>
          null;
        end case;
      end if;
    end if;
  end process;


  --Queue Almost Full
  processing_4 : process (clk_i, rst_ni)
  begin
    if (not rst_ni) then
      almost_full_o <= '0';
    elsif (rising_edge(clk_i)) then
      if (clr_i) then
        almost_full_o <= '0';
      elsif (ena_i) then
        case (((we_i & re_i))) is
        when "01" =>
          almost_full_o <= not (queue_wadr < ALMOST_FULL_THRESHOLD_CHECK);
        when "10" =>
          almost_full_o <= (queue_wadr >= ALMOST_FULL_THRESHOLD_CHECK);
        when others =>
          null;
        end case;
      end if;
    end if;
  end process;


  --Queue Full
  processing_5 : process (clk_i, rst_ni)
  begin
    if (not rst_ni) then
      full_o <= '0';
    elsif (rising_edge(clk_i)) then
      if (clr_i) then
        full_o <= '0';
      elsif (ena_i) then
        case (((we_i & re_i))) is
        when "01" =>
          full_o <= '0';
        when "10" =>
          full_o <= (queue_wadr = FULL_THRESHOLD);
        when others =>
          null;
        end case;
      end if;
    end if;
  end process;


  --Queue output data
  q_o <= queue_data(0);

  rl_ram_queue_WARNINGS_GENERATING_0 : if (rl_ram_queue_WARNINGS = '1') generate
    processing_6 : process (clk_i)
    begin
      if (rising_edge(clk_i)) then
        if (empty_o and not we_i and re_i) then
          (null)("rl_ram_queue (%m): underflow @%0t", timing());
        end if;
        if (full_o and we_i and not re_i) then
          (null)("rl_ram_queue (%m): overflow @%0t", timing());
        end if;
      end if;
    end process;
  end generate;
end RTL;
