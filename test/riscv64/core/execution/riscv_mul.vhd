-- Converted from core/execution/riscv_mul.sv
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
--              Core - Multiplier Unit                                        //
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

entity riscv_mul is
  port (
    rstn : in std_logic;
    clk : in std_logic;

    ex_stall : in std_logic;
    mul_stall : out std_logic;

  --Instruction
    id_bubble : in std_logic;
    id_instr : in std_logic_vector(ILEN-1 downto 0);

  --Operands
    opA : in std_logic_vector(XLEN-1 downto 0);
    opB : in std_logic_vector(XLEN-1 downto 0);

  --from State
    st_xlen : in std_logic_vector(1 downto 0);

  --to WB
    mul_bubble : out std_logic 
    mul_r : out std_logic_vector(XLEN-1 downto 0)
  );
  constant XLEN : integer := 64;
  constant ILEN : integer := 64;
end riscv_mul;

architecture RTL of riscv_mul is


  --//////////////////////////////////////////////////////////////
  --
  -- Constants
  --

  constant DXLEN : integer := 2*XLEN;

  constant MAX_LATENCY : integer := 3;
  constant LATENCY : integer := MAX_LATENCY
  when MULT_LATENCY > MAX_LATENCY else MULT_LATENCY;

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



  function twos_dxlen (
    a : std_logic_vector(DXLEN-1 downto 0)

  ) return std_logic_vector is
    variable twos_dxlen_return : std_logic_vector (DXLEN-1 downto 0);
  begin
    twos_dxlen_return <= not a+X"1";
    return twos_dxlen_return;
  end twos_dxlen;



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

  constant ST_IDLE : std_logic := '0';
  constant ST_WAIT : std_logic := '1';

  --//////////////////////////////////////////////////////////////
  --
  -- Variables
  --

  signal xlen32 : std_logic;
  signal mul_instr : std_logic_vector(ILEN-1 downto 0);

  signal opcode : std_logic_vector(6 downto 2);
  signal mul_opcode : std_logic_vector(6 downto 2);
  signal func3 : std_logic_vector(2 downto 0);
  signal mul_func3 : std_logic_vector(2 downto 0);
  signal func7 : std_logic_vector(6 downto 0);
  signal mul_func7 : std_logic_vector(6 downto 0);

  --Operand generation
  signal opA32 : std_logic_vector(31 downto 0);
  signal opB32 : std_logic_vector(31 downto 0);

  signal mult_neg : std_logic;
  signal mult_neg_reg : std_logic;
  signal mult_opA : std_logic_vector(XLEN-1 downto 0);
  signal mult_opA_reg : std_logic_vector(XLEN-1 downto 0);
  signal mult_opB : std_logic_vector(XLEN-1 downto 0);
  signal mult_opB_reg : std_logic_vector(XLEN-1 downto 0);
  signal mult_r : std_logic_vector(DXLEN-1 downto 0);
  signal mult_r_reg : std_logic_vector(DXLEN-1 downto 0);
  signal mult_r_signed : std_logic_vector(DXLEN-1 downto 0);
  signal mult_r_signed_reg : std_logic_vector(DXLEN-1 downto 0);

  --FSM (bubble, stall generation)
  signal is_mul : std_logic;
  signal cnt : std_logic_vector(1 downto 0);
  signal state : std_logic;

begin
  --//////////////////////////////////////////////////////////////
  --
  -- Module Body
  --

  --Instruction
  func7 <= id_instr(31 downto 25);
  func3 <= id_instr(14 downto 12);
  opcode <= id_instr(6 downto 2);

  mul_func7 <= mul_instr(31 downto 25);
  mul_func3 <= mul_instr(14 downto 12);
  mul_opcode <= mul_instr(6 downto 2);

  xlen32 <= st_xlen = RV32I;

  --32bit operands
  opA32 <= opA(31 downto 0);
  opB32 <= opB(31 downto 0);

  --
--   *  Multiply operations
--   *
--   * Transform all multiplications into 1 unsigned multiplication
--   * This avoids building multiple multipliers (signed x signed, signed x unsigned, unsigned x unsigned)
--   *   at the expense of potentially making the path slower
--   */

  --multiplier operand-A
  processing_0 : process
  begin
    case (((func7 & func3 & opcode))) is
    when MULW =>
    --RV64
      mult_opA <= (null)((null)(opA32));
    when MULHU =>
      mult_opA <= opA;
    when others =>
      mult_opA <= (null)(opA);
    end case;
  end process;


  --multiplier operand-B
  processing_1 : process
  begin
    case (((func7 & func3 & opcode))) is
    when MULW =>
    --RV64
      mult_opB <= (null)((null)(opB32));
    when MULHSU =>
      mult_opB <= opB;
    when MULHU =>
      mult_opB <= opB;
    when others =>
      mult_opB <= (null)(opB);
    end case;
  end process;


  --negate multiplier output?
  processing_2 : process
  begin
    case (((func7 & func3 & opcode))) is
    when MUL =>
      mult_neg <= opA(XLEN-1) xor opB(XLEN-1);
    when MULH =>
      mult_neg <= opA(XLEN-1) xor opB(XLEN-1);
    when MULHSU =>
      mult_neg <= opA(XLEN-1);
    when MULHU =>
      mult_neg <= '0';
    when MULW =>
    --RV64
      mult_neg <= opA32(31) xor opB32(31);
    when others =>
      mult_neg <= X"x";
    end case;
  end process;


  --Actual multiplier
  mult_r <= (null)(mult_opA_reg)*(null)(mult_opB_reg);

  --Correct sign
  mult_r_signed <= (null)(mult_r_reg)
  when mult_neg_reg else mult_r_reg;

  if (LATENCY = 0) generate

    --
--       * Single cycle multiplier
--       *
--       * Registers at: - output
--       */

    --Register holding instruction for multiplier-output-selector
    mul_instr <= id_instr;

    --Registers holding multiplier operands
    mult_opA_reg <= mult_opA;
    mult_opB_reg <= mult_opB;
    mult_neg_reg <= mult_neg;

    --Register holding multiplier output
    mult_r_reg <= mult_r;

    --Register holding sign correction
    mult_r_signed_reg <= mult_r_signed;
  else generate

  --
--       * Multi cycle multiplier
--       *
--       * Registers at: - input
--       *               - output
--       */

  --Register holding instruction for multiplier-output-selector
    processing_3 : process (clk)
    begin
      if (rising_edge(clk)) then
        if (not ex_stall) then
          mul_instr <= id_instr;
        end if;
      end if;
    end process;


    --Registers holding multiplier operands
    processing_4 : process (clk)
    begin
      if (rising_edge(clk)) then
        if (not ex_stall) then
          mult_opA_reg <= mult_opA;
          mult_opB_reg <= mult_opB;
          mult_neg_reg <= mult_neg;
        end if;
      end if;
    end process;


    if (LATENCY = 1) generate
      --Register holding multiplier output
      mult_r_reg <= mult_r;

      --Register holding sign correction
      mult_r_signed_reg <= mult_r_signed;
    elsif (LATENCY = 2) generate
      --Register holding multiplier output
      processing_5 : process (clk)
      begin
        if (rising_edge(clk)) then
          mult_r_reg <= mult_r;
        end if;
      end process;


      --Register holding sign correction
      mult_r_signed_reg <= mult_r_signed;
    else generate    --Register holding multiplier output
      processing_6 : process (clk)
      begin
        if (rising_edge(clk)) then
          mult_r_reg <= mult_r;
        end if;
      end process;


      --Register holding sign correction
      processing_7 : process (clk)
      begin
        if (rising_edge(clk)) then
          mult_r_signed_reg <= mult_r_signed;
        end if;
      end process;
    end generate;
  end generate;


  --Final output register
  processing_8 : process (clk)
  begin
    if (rising_edge(clk)) then
      case (((mul_func7 & mul_func3 & mul_opcode))) is
      when MUL =>
        mul_r <= mult_r_signed_reg(XLEN-1 downto 0);
      when MULW =>
      --RV64
        mul_r <= (null)(mult_r_signed_reg(31 downto 0));
      when others =>
        mul_r <= mult_r_signed_reg(DXLEN-1 downto XLEN);
      end case;
    end if;
  end process;


  --Stall / Bubble generation
  processing_9 : process
  begin
    case (((func7 & func3 & opcode))) is
    when MUL =>
      is_mul <= '1';
    when MULH =>
      is_mul <= '1';
    when MULW =>
      is_mul <= not xlen32;
    when MULHSU =>
      is_mul <= '1';
    when MULHU =>
      is_mul <= '1';
    when others =>
      is_mul <= '0';
    end case;
  end process;


  processing_10 : process (clk, rstn)
  begin
    if (not rstn) then
      state <= ST_IDLE;
      cnt <= LATENCY;

      mul_bubble <= '1';
      mul_stall <= '0';
    elsif (rising_edge(clk)) then
      mul_bubble <= '1';
      case ((state)) is
      when ST_IDLE =>
        if (not ex_stall) then
          if (not id_bubble and is_mul) then
            if (LATENCY = 0) then
              mul_bubble <= '0';
              mul_stall <= '0';
            else
              state <= ST_WAIT;
              cnt <= cnt-1;

              mul_bubble <= '1';
              mul_stall <= '1';
            end if;
          end if;
        end if;
      when ST_WAIT =>
        if (or cnt) then
          cnt <= cnt-1;
        else
          state <= ST_IDLE;
          cnt <= LATENCY;

          mul_bubble <= '0';
          mul_stall <= '0';
        end if;
      end case;
    end if;
  end process;
end RTL;
