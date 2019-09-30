-- Converted from omsp_sync_reset.v
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
-- *File Name: omsp_sync_reset.v
--
-- *Module Description:
--                       Generic reset synchronizer for the openMSP430
--
-- *Author(s):
--              - Olivier Girard,    olgirard@gmail.com
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity omsp_sync_reset is
  port (
  -- OUTPUTs
  --=========
    rst_s : out std_logic;  -- Synchronized reset

  -- INPUTs
  --=========
    clk : in std_logic   -- Receiving clock
    rst_a : in std_logic  -- Asynchronous reset
  );
end omsp_sync_reset;

architecture RTL of omsp_sync_reset is
  --=============================================================================
  -- 1)  WIRE DECLARATION
  --=============================================================================

  signal data_sync : std_logic_vector(1 downto 0);

begin
  --=============================================================================
  -- 2)  SYNCHRONIZER
  --=============================================================================

  processing_0 : process (clk, rst_a)
  begin
    if (rst_a) then
      data_sync <= "11";
    elsif (rising_edge(clk)) then
      data_sync <= (data_sync(0) & '0');
    end if;
  end process;


  rst_s <= data_sync(1);
end RTL;
