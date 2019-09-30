-- Converted from omsp_clock_gate.v
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
-- *File Name: omsp_clock_gate.v
--
-- *Module Description:
--                       Generic clock gate cell for the openMSP430
--
-- *Author(s):
--              - Olivier Girard,    olgirard@gmail.com
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity omsp_clock_gate is
  port (
  -- OUTPUTs
  --========
    gclk : out std_logic;  -- Gated clock

  -- INPUTs
  --=======
    clk : in std_logic;  -- Clock
    enable : in std_logic   -- Clock enable
    scan_enable : in std_logic  -- Scan enable (active during scan shifting)
  );
end omsp_clock_gate;

architecture RTL of omsp_clock_gate is
  --=============================================================================
  -- CLOCK GATE: LATCH + AND
  --=============================================================================

  -- Enable clock gate during scan shift
  -- (the gate itself is checked with the scan capture cycle)
  signal enable_in : std_logic;

  -- LATCH the enable signal
  signal enable_latch : std_logic;

begin
  --=============================================================================
  -- CLOCK GATE: LATCH + AND
  --=============================================================================

  -- Enable clock gate during scan shift
  -- (the gate itself is checked with the scan capture cycle)
  enable_in <= (enable or scan_enable);

  -- LATCH the enable signal
  processing_0 : process (clk, enable_in)
  begin
    if (not clk) then
      enable_latch <= enable_in;
    end if;
  end process;


  -- AND gate
  gclk <= (clk and enable_latch);
end RTL;
