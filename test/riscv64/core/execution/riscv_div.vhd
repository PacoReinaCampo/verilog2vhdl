-- Converted from core/execution/riscv_div.sv
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
--              Core - Division Unit                                          //
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

entity riscv_div is
  port (
    rstn : in std_logic;
    clk : in std_logic;

    ex_stall : in std_logic;
    div_stall : out std_logic;

  --Instruction
    id_bubble : in std_logic;
    id_instr : in std_logic_vector(ILEN-1 downto 0);

  --Operands
    opA : in std_logic_vector(XLEN-1 downto 0);
    opB : in std_logic_vector(XLEN-1 downto 0);

  --From State
    st_xlen : in std_logic_vector(1 downto 0);

  --To WB
    div_bubble : out std_logic 
    div_r : out std_logic_vector(XLEN-1 downto 0)
  );
  constant XLEN : integer := 64;
  constant ILEN : integer := 64;
end riscv_div;

architecture RTL of riscv_div is


  --//////////////////////////////////////////////////////////////
  --
  -- functions
  --
  function sext32 (
    operand : std_logic_vector(31 downto 0);
    signal sign : std_logic;

  ) return std_logic_vector is
    variable sext32_return : std_logic_vector (XLEN-1 downto 0);
  begin
    sign <= operand(31);
    sext32_return <= (concatenate(XLEN-32, sign) & operand);
    return sext32_return;
  end sext32;



  function twos (
    a : std_logic_vector(XLEN-1 downto 0)

  ) return std_logic_vector is
    variable twos_return : std_logic_vector (XLEN-1 downto 0);
  begin
    twos_return <= not a+X"1";
    return twos_return;
  end twos;



  function abs (
    a : std_logic_vector(XLEN-1 downto 0)

  ) return std_logic_vector is
    variable abs_return : std_logic_vector (XLEN-1 downto 0);
  begin
    abs_return <= (null)(a)
    when a(XLEN-1) else a;
    return abs_return;
  end abs;



  --//////////////////////////////////////////////////////////////
  --
  -- Constants
  --

  constant ST_CHK : std_logic_vector(1 downto 0) := "00";
  constant ST_DIV : std_logic_vector(1 downto 0) := "01";
  constant ST_RES : std_logic_vector(1 downto 0) := "10";

  --//////////////////////////////////////////////////////////////
  --
  -- Variables
  --
  signal xlen32 : std_logic;
  signal div_instr : std_logic_vector(ILEN-1 downto 0);

  signal opcode : std_logic_vector(6 downto 2);
  signal div_opcode : std_logic_vector(6 downto 2);
  signal func3 : std_logic_vector(2 downto 0);
  signal div_func3 : std_logic_vector(2 downto 0);
  signal func7 : std_logic_vector(6 downto 0);
  signal div_func7 : std_logic_vector(6 downto 0);

  --Operand generation
  signal opA32 : std_logic_vector(31 downto 0);
  signal opB32 : std_logic_vector(31 downto 0);

  signal cnt : std_logic_vector((null)(XLEN)-1 downto 0);
  signal neg_q : std_logic;  --negate quotient
  signal neg_s : std_logic;  --negate remainder

  --divider internals
  signal pa_p : std_logic_vector(XLEN-1 downto 0);
  signal pa_a : std_logic_vector(XLEN-1 downto 0);
  signal pa_shifted_p : std_logic_vector(XLEN-1 downto 0);
  signal pa_shifted_a : std_logic_vector(XLEN-1 downto 0);

  signal p_minus_b : std_logic_vector(XLEN downto 0);
  signal b : std_logic_vector(XLEN-1 downto 0);

  --FSM
  signal state : std_logic_vector(1 downto 0);

begin
  --//////////////////////////////////////////////////////////////
  --
  -- Module Body
  --

  --Instruction
  func7 <= id_instr(31 downto 25);
  func3 <= id_instr(14 downto 12);
  opcode <= id_instr(6 downto 2);

  div_func7 <= div_instr(31 downto 25);
  div_func3 <= div_instr(14 downto 12);
  div_opcode <= div_instr(6 downto 2);

  xlen32 <= st_xlen = RV32I;

  --retain instruction
  processing_0 : process (clk)
  begin
    if (rising_edge(clk)) then
      if (not ex_stall) then
        div_instr <= id_instr;
      end if;
    end if;
  end process;


  --32bit operands
  opA32 <= opA(31 downto 0);
  opB32 <= opB(31 downto 0);

  --Divide operations
  (pa_shifted_p & pa_shifted_a) <= (pa_p & pa_a) sll 1;
  p_minus_b <= pa_shifted_p-b;

  --Division: bit-serial. Max XLEN cycles
  -- q = z/d + s
  -- z: Dividend
  -- d: Divisor
  -- q: Quotient
  -- s: Remainder
  processing_1 : process (clk, rstn)
  begin
    if (not rstn) then
      state <= ST_CHK;
      div_bubble <= '1';
      div_stall <= '0';

      div_r <= X"x";

      pa_p <= X"x";
      pa_a <= X"x";
      b <= X"x";
      neg_q <= 'x';
      neg_s <= 'x';
    elsif (rising_edge(clk)) then
      div_bubble <= '1';

      case ((state)) is

      --
--         * Check for exceptions (divide by zero, signed overflow)
--         * Setup dividor registers
--         */

      when ST_CHK =>
        if (not ex_stall and not id_bubble) then
          case (((xlen32 & func7 & func3 & opcode))) is
          when ('?' & DIV) =>
          --signed divide by zero
            if (nor opB) then
              div_r <= concatenate(XLEN, '1');              --=-1
              div_bubble <= '0';
            elsif (opA = ('1' & concatenate(XLEN-1, '0')) and and opB) then          -- signed overflow (Dividend=-2^(XLEN-1), Divisor=-1)
              div_r <= ('1' & concatenate(XLEN-1, '0'));
              div_bubble <= '0';
            else
              cnt <= concatenate((null)(cnt), '1');
              state <= ST_DIV;
              div_stall <= '1';

              neg_q <= opA(XLEN-1) xor opB(XLEN-1);
              neg_s <= opA(XLEN-1);

              pa_p <= X"0";
              pa_a <= (null)(opA);
              b <= (null)(opB);
            end if;
          when ('0' & DIVW) =>
          --signed divide by zero
            if (nor opB32) then
              div_r <= concatenate(XLEN, '1');              --=-1
              div_bubble <= '0';
            elsif (opA32 = ('1' & concatenate(31, '0')) and and opB32) then          -- signed overflow (Dividend=-2^(XLEN-1), Divisor=-1)
              div_r <= (null)(('1' & concatenate(31, '0')));
              div_bubble <= '0';
            else
              cnt <= ('0' & concatenate((null)(cnt)-1, '1'));
              state <= ST_DIV;
              div_stall <= '1';

              neg_q <= opA32(31) xor opB32(31);
              neg_s <= opA32(31);

              pa_p <= X"0";
              pa_a <= ((null)((null)(opA32)) & concatenate(XLEN-32, '0'));
              b <= (null)((null)(opB32));
            end if;


          when ('?' & DIVU) =>
          --unsigned divide by zero
            if (nor opB) then
              div_r <= concatenate(XLEN, '1');              --= 2^XLEN -1
              div_bubble <= '0';
            else
              cnt <= concatenate((null)(cnt), '1');
              state <= ST_DIV;
              div_stall <= '1';

              neg_q <= '0';
              neg_s <= '0';

              pa_p <= X"0";
              pa_a <= opA;
              b <= opB;
            end if;
          when ('0' & DIVUW) =>
          --unsigned divide by zero
            if (nor opB32) then
              div_r <= concatenate(XLEN, '1');              --= 2^XLEN -1
              div_bubble <= '0';
            else
              cnt <= ('0' & concatenate((null)(cnt)-1, '1'));
              state <= ST_DIV;
              div_stall <= '1';

              neg_q <= '0';
              neg_s <= '0';

              pa_p <= X"0";
              pa_a <= (opA32 & concatenate(XLEN-32, '0'));
              b <= (concatenate(XLEN-32, '0') & opB32);
            end if;
          when ('?' & REM) =>
          --signed divide by zero
            if (nor opB) then
              div_r <= opA;
              div_bubble <= '0';
            elsif (opA = ('1' & concatenate(XLEN-1, '0')) and and opB) then          -- signed overflow (Dividend=-2^(XLEN-1), Divisor=-1)
              div_r <= X"0";
              div_bubble <= '0';
            else
              cnt <= concatenate((null)(cnt), '1');
              state <= ST_DIV;
              div_stall <= '1';

              neg_q <= opA(XLEN-1) xor opB(XLEN-1);
              neg_s <= opA(XLEN-1);

              pa_p <= X"0";
              pa_a <= (null)(opA);
              b <= (null)(opB);
            end if;
          when ('0' & REMW) =>
          --signed divide by zero
            if (nor opB32) then
              div_r <= (null)(opA32);
              div_bubble <= '0';
            elsif (opA32 = ('1' & concatenate(31, '0')) and and opB32) then          -- signed overflow (Dividend=-2^(XLEN-1), Divisor=-1)
              div_r <= X"0";
              div_bubble <= '0';
            else
              cnt <= ('0' & concatenate((null)(cnt)-1, '1'));
              state <= ST_DIV;
              div_stall <= '1';

              neg_q <= opA32(31) xor opB32(31);
              neg_s <= opA32(31);

              pa_p <= X"0";
              pa_a <= ((null)((null)(opA32)) & concatenate(XLEN-32, '0'));
              b <= (null)((null)(opB32));
            end if;
          when ('?' & REMU) =>
          --unsigned divide by zero
            if (nor opB) then
              div_r <= opA;
              div_bubble <= '0';
            else
              cnt <= concatenate((null)(cnt), '1');
              state <= ST_DIV;
              div_stall <= '1';

              neg_q <= '0';
              neg_s <= '0';

              pa_p <= X"0";
              pa_a <= opA;
              b <= opB;
            end if;
          when ('0' & REMUW) =>
            if (nor opB32) then
              div_r <= (null)(opA32);
              div_bubble <= '0';
            else
              cnt <= ('0' & concatenate((null)(cnt)-1, '1'));
              state <= ST_DIV;
              div_stall <= '1';

              neg_q <= '0';
              neg_s <= '0';

              pa_p <= X"0";
              pa_a <= (opA32 & concatenate(XLEN-32, '0'));
              b <= (concatenate(XLEN-32, '0') & opB32);
            end if;
          when others =>
            null;
          end case;
        end if;


      --actual division loop
      when ST_DIV =>
        cnt <= cnt-1;
        if (nor cnt) then
          state <= ST_RES;
        end if;
        --restoring divider section
        if (p_minus_b(XLEN)) then      --sub gave negative result
          pa_p <= pa_shifted_p;          --restore
          pa_a <= (pa_shifted_a(XLEN-1 downto 1) & '0');          --shift in '0' for Q
        else        --sub gave positive result
        --store sub result
          pa_p <= p_minus_b(XLEN-1 downto 0);
          pa_a <= (pa_shifted_a(XLEN-1 downto 1) & '1');          --shift in '1' for Q
        end if;
      --Result
      when ST_RES =>
        state <= ST_CHK;
        div_bubble <= '0';
        div_stall <= '0';
        case (((div_func7 & div_func3 & div_opcode))) is
        when DIV =>
          div_r <= (null)(pa_a)
          when neg_q else pa_a;
        when DIVW =>
          div_r <= (null)((null)(pa_a)
            when neg_q else pa_a);
        when DIVU =>
          div_r <= pa_a;
        when DIVUW =>
          div_r <= (null)(pa_a);
        when REM =>
          div_r <= (null)(pa_p)
          when neg_s else pa_p;
        when REMW =>
          div_r <= (null)((null)(pa_p)
            when neg_s else pa_p);
        when REMU =>
          div_r <= pa_p;
        when REMUW =>
          div_r <= (null)(pa_p);
        when others =>
          div_r <= X"x";
        end case;
      end case;
    end if;
  end process;
end RTL;
