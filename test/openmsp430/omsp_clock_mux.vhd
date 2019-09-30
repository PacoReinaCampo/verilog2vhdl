-- Converted from omsp_clock_mux.v
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
-- *File Name: omsp_clock_mux.v
--
-- *Module Description:
--                       Standard clock mux for the openMSP430
--
-- *Author(s):
--              - Olivier Girard,    olgirard@gmail.com
--
------------------------------------------------------------------------------
-- $Rev: 103 $
-- $LastChangedBy: olivier.girard $
-- $LastChangedDate: 2011-03-05 15:44:48 +0100 (Sat, 05 Mar 2011) $
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity omsp_clock_mux is
  port (
  -- OUTPUTs
  --========
    clk_out : out std_logic;  -- Clock output

  -- INPUTs
  --=======
    clk_in0 : in std_logic;  -- Clock input 0
    clk_in1 : in std_logic;  -- Clock input 1
    reset : in std_logic;  -- Reset
    scan_mode : in std_logic   -- Scan mode (clk_in0 is selected in scan mode)
    select_in : in std_logic  -- Clock selection
  );
end omsp_clock_mux;

architecture RTL of omsp_clock_mux is
  component omsp_scan_mux
  port (
    scan_mode : std_logic_vector(? downto 0);
    data_in_scan : std_logic_vector(? downto 0);
    data_in_func : std_logic_vector(? downto 0);
    data_out : std_logic_vector(? downto 0)
  );
  end component;

  --===========================================================================================================================//
  -- 1)  CLOCK MUX                                                                                                             //
  --===========================================================================================================================//
  --                                                                                                                           //
  --    The following (glitch free) clock mux is implemented as following:                                                     //
  --                                                                                                                           //
  --                                                                                                                           //
  --                                                                                                                           //
  --                                                                                                                           //
  --                                   +-----.     +--------+   +--------+                                                     //
  --    select_in >>----+-------------O|      \    |        |   |        |          +-----.                                    //
  --                    |              |       |---| D    Q |---| D    Q |--+-------|      \                                   //
  --                    |     +-------O|      /    |        |   |        |  |       |       |O-+                               //
  --                    |     |        +-----'     |        |   |        |  |   +--O|      /   |                               //
  --                    |     |                    |   /\   |   |   /\   |  |   |   +-----'    |                               //
  --                    |     |                    +--+--+--+   +--+--+--+  |   |              |                               //
  --                    |     |                        O            |       |   |              |                               //
  --                    |     |                        |            |       |   |              |  +-----.                      //
  --       clk_in0 >>----------------------------------+------------+-----------+              +--|      \                     //
  --                    |     |                                             |                     |       |----<< clk_out      //
  --                    |     |     +---------------------------------------+                  +--|      /                     //
  --                    |     |     |                                                          |  +-----'                      //
  --                    |     +---------------------------------------------+                  |                               //
  --                    |           |                                       |                  |                               //
  --                    |           |  +-----.     +--------+   +--------+  |                  |                               //
  --                    |           +-O|      \    |        |   |        |  |       +-----.    |                               //
  --                    |              |       |---| D    Q |---| D    Q |--+-------|      \   |                               //
  --                    +--------------|      /    |        |   |        |          |       |O-+                               //
  --                                   +-----'     |        |   |        |      +--O|      /                                   //
  --                                               |   /\   |   |   /\   |      |   +-----'                                    //
  --                                               +--+--+--+   +--+--+--+      |                                              //
  --                                                   O            |           |                                              //
  --                                                   |            |           |                                              //
  --       clk_in1 >>----------------------------------+------------+-----------+                                              //
  --                                                                                                                           //
  --                                                                                                                           //
  --===========================================================================================================================//

  -------------------------------------------------------------------------------
  -- Wire declarations
  -------------------------------------------------------------------------------

  signal in0_select : std_logic;
  signal in0_select_s : std_logic;
  signal in0_select_ss : std_logic;
  signal in0_enable : std_logic;

  signal in1_select : std_logic;
  signal in1_select_s : std_logic;
  signal in1_select_ss : std_logic;
  signal in1_enable : std_logic;

  signal clk_in0_inv : std_logic;
  signal clk_in1_inv : std_logic;
  signal clk_in0_scan_fix_inv : std_logic;
  signal clk_in1_scan_fix_inv : std_logic;
  signal gated_clk_in0 : std_logic;
  signal gated_clk_in1 : std_logic;

begin
  -------------------------------------------------------------------------------
  -- Optional scan repair for neg-edge clocked FF
  -------------------------------------------------------------------------------
  scan_mux_repair_clk_in0_inv : omsp_scan_mux
  port map (
    scan_mode => scan_mode,
    data_in_scan => clk_in0,
    data_in_func => not clk_in0,
    data_out => clk_in0_scan_fix_inv
  );


  scan_mux_repair_clk_in1_inv : omsp_scan_mux
  port map (
    scan_mode => scan_mode,
    data_in_scan => clk_in1,
    data_in_func => not clk_in1,
    data_out => clk_in1_scan_fix_inv
  );


  -------------------------------------------------------------------------------
  -- CLK_IN0 Selection
  -------------------------------------------------------------------------------

  in0_select <= not select_in and not in1_select_ss;

  processing_0 : process (clk_in0_scan_fix_inv, reset)
  begin
    if (reset) then
      in0_select_s <= '1';
    elsif (rising_edge(clk_in0_scan_fix_inv)) then
      in0_select_s <= in0_select;
    end if;
  end process;


  processing_1 : process (clk_in0, reset)
  begin
    if (reset) then
      in0_select_ss <= '1';
    elsif (rising_edge(clk_in0)) then
      in0_select_ss <= in0_select_s;
    end if;
  end process;


  in0_enable <= in0_select_ss or scan_mode;

  -------------------------------------------------------------------------------
  -- CLK_IN1 Selection
  -------------------------------------------------------------------------------

  in1_select <= select_in and not in0_select_ss;

  processing_2 : process (clk_in1_scan_fix_inv, reset)
  begin
    if (reset) then
      in1_select_s <= '0';
    elsif (rising_edge(clk_in1_scan_fix_inv)) then
      in1_select_s <= in1_select;
    end if;
  end process;


  processing_3 : process (clk_in1, reset)
  begin
    if (reset) then
      in1_select_ss <= '0';
    elsif (rising_edge(clk_in1)) then
      in1_select_ss <= in1_select_s;
    end if;
  end process;


  in1_enable <= in1_select_ss and not scan_mode;

  -------------------------------------------------------------------------------
  -- Clock MUX
  -------------------------------------------------------------------------------
  --
  -- IMPORTANT NOTE:
  --                  Because the clock network is a critical part of the design,
  --                 the following combinatorial logic should be replaced with
  --                 direct instanciation of standard cells from target library.
  --                  Don't forget the "dont_touch" attribute to make sure
  --                 synthesis won't mess it up.
  --

  -- Replace with standard cell INVERTER
  clk_in0_inv <= not clk_in0;
  clk_in1_inv <= not clk_in1;

  -- Replace with standard cell NAND2
  gated_clk_in0 <= not (clk_in0_inv and in0_enable);
  gated_clk_in1 <= not (clk_in1_inv and in1_enable);

  -- Replace with standard cell AND2
  clk_out <= (gated_clk_in0 and gated_clk_in1);
end RTL;
