-- Converted from omsp_wakeup_cell.v
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
-- *File Name: omsp_wakeup_cell.v
--
-- *Module Description:
--                       Generic Wakeup cell
--
-- *Author(s):
--              - Olivier Girard,    olgirard@gmail.com
--

use work."openMSP430_defines.v".all;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity omsp_wakeup_cell is
  port (
  -- OUTPUTs
  --========
    wkup_out : out std_logic;  -- Wakup signal (asynchronous)

  -- INPUTs
  --=======
    scan_clk : in std_logic;  -- Scan clock
    scan_mode : in std_logic;  -- Scan mode
    scan_rst : in std_logic;  -- Scan reset
    wkup_clear : in std_logic   -- Glitch free wakeup event clear
    wkup_event : in std_logic  -- Glitch free asynchronous wakeup event
  );
end omsp_wakeup_cell;

architecture RTL of omsp_wakeup_cell is
  component omsp_scan_mux
  port (
    scan_mode : std_logic_vector(? downto 0);
    data_in_scan : std_logic_vector(? downto 0);
    data_in_func : std_logic_vector(? downto 0);
    data_out : std_logic_vector(? downto 0)
  );
  end component;

  --=============================================================================
  -- 1)  AND GATE
  --=============================================================================

  -- Scan stuff for the ASIC mode
  signal wkup_rst : std_logic;

  signal wkup_clk : std_logic;

  -- Wakeup capture
  signal wkup_out : std_logic;

begin
  --=============================================================================
  -- 1)  AND GATE
  --=============================================================================

  -- Scan stuff for the ASIC mode
  scan_mux_rst : omsp_scan_mux
  port map (
    scan_mode => scan_mode,
    data_in_scan => scan_rst,
    data_in_func => wkup_clear,
    data_out => wkup_rst
  );


  scan_mux_clk : omsp_scan_mux
  port map (
    scan_mode => scan_mode,
    data_in_scan => scan_clk,
    data_in_func => wkup_event,
    data_out => wkup_clk
  );


  -- Wakeup capture
  processing_0 : process (wkup_clk, wkup_rst)
  begin
    if (wkup_rst) then
      wkup_out <= '0';
    elsif (rising_edge(wkup_clk)) then
      wkup_out <= '1';
    end if;
  end process;
end RTL;
