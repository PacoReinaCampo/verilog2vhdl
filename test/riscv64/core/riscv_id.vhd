-- Converted from core/riscv_id.sv
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
--              Core - Instruction Decoder                                    //
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

entity riscv_id is
  port (
    rstn : in std_logic;
    clk : in std_logic;

    id_stall : out std_logic;
    ex_stall : in std_logic;
    du_stall : in std_logic;

    bu_flush : in std_logic;
    st_flush : in std_logic;
    du_flush : in std_logic;

    bu_nxt_pc : in std_logic_vector(XLEN-1 downto 0);
    st_nxt_pc : in std_logic_vector(XLEN-1 downto 0);

  --Program counter
    if_pc : in std_logic_vector(XLEN-1 downto 0);
    id_pc : out std_logic_vector(XLEN-1 downto 0);
    if_bp_predict : in std_logic_vector(1 downto 0);
    id_bp_predict : out std_logic_vector(1 downto 0);

  --Instruction
    if_instr : in std_logic_vector(ILEN-1 downto 0);
    if_bubble : in std_logic;
    id_instr : out std_logic_vector(ILEN-1 downto 0);
    id_bubble : out std_logic;
    ex_instr : in std_logic_vector(ILEN-1 downto 0);
    ex_bubble : in std_logic;
    mem_instr : in std_logic_vector(ILEN-1 downto 0);
    mem_bubble : in std_logic;
    wb_instr : in std_logic_vector(ILEN-1 downto 0);
    wb_bubble : in std_logic;

  --Exceptions
    if_exception : in std_logic_vector(EXCEPTION_SIZE-1 downto 0);
    ex_exception : in std_logic_vector(EXCEPTION_SIZE-1 downto 0);
    mem_exception : in std_logic_vector(EXCEPTION_SIZE-1 downto 0);
    wb_exception : in std_logic_vector(EXCEPTION_SIZE-1 downto 0);
    id_exception : out std_logic_vector(EXCEPTION_SIZE-1 downto 0);

  --From State
    st_prv : in std_logic_vector(1 downto 0);
    st_xlen : in std_logic_vector(1 downto 0);
    st_tvm : in std_logic;
    st_tw : in std_logic;
    st_tsr : in std_logic;
    st_mcounteren : in std_logic_vector(XLEN-1 downto 0);
    st_scounteren : in std_logic_vector(XLEN-1 downto 0);

  --To RF
    id_src1 : out std_logic_vector(4 downto 0);
    id_src2 : out std_logic_vector(4 downto 0);

  --To execution units
    id_opA : out std_logic_vector(XLEN-1 downto 0);
    id_opB : out std_logic_vector(XLEN-1 downto 0);

    id_userf_opA : out std_logic;
    id_userf_opB : out std_logic;
    id_bypex_opA : out std_logic;
    id_bypex_opB : out std_logic;
    id_bypmem_opA : out std_logic;
    id_bypmem_opB : out std_logic;
    id_bypwb_opA : out std_logic;
    id_bypwb_opB : out std_logic;

  --from MEM/WB
    mem_r : in std_logic_vector(XLEN-1 downto 0) 
    wb_r : in std_logic_vector(XLEN-1 downto 0)
  );
  constant XLEN : integer := 64;
  constant ILEN : integer := 64;
  constant EXCEPTION_SIZE : integer := 16;
end riscv_id;

architecture RTL of riscv_id is


  --////////////////////////////////////////////////////////////////
  --
  -- Variables
  --
  signal id_bubble_r : std_logic;
  signal multi_cycle_instruction : std_logic;
  signal stall : std_logic;

  --Immediates
  signal immI : std_logic_vector(XLEN-1 downto 0);
  signal immU : std_logic_vector(XLEN-1 downto 0);

  --Opcodes
  signal if_opcode : std_logic_vector(6 downto 2);
  signal id_opcode : std_logic_vector(6 downto 2);
  signal ex_opcode : std_logic_vector(6 downto 2);
  signal mem_opcode : std_logic_vector(6 downto 2);
  signal wb_opcode : std_logic_vector(6 downto 2);

  signal if_func3 : std_logic_vector(2 downto 0);
  signal if_func7 : std_logic_vector(6 downto 0);

  signal xlen : std_logic;  --Current CPU state XLEN
  signal xlen64 : std_logic;  --Is the CPU state set to RV64?
  signal xlen32 : std_logic;  --Is the CPU state set to RV32?
  signal has_fpu : std_logic;
  signal has_muldiv : std_logic;
  signal has_amo : std_logic;
  signal has_u : std_logic;
  signal has_s : std_logic;
  signal has_h : std_logic;

  signal if_src1 : std_logic_vector(4 downto 0);
  signal if_src2 : std_logic_vector(4 downto 0);
  signal id_dst : std_logic_vector(4 downto 0);
  signal ex_dst : std_logic_vector(4 downto 0);
  signal mem_dst : std_logic_vector(4 downto 0);
  signal wb_dst : std_logic_vector(4 downto 0);

  signal can_bypex : std_logic;
  signal can_bypmem : std_logic;
  signal can_bypwb : std_logic;
  signal can_ldwb : std_logic;

  signal illegal_instr : std_logic;
  signal illegal_alu_instr : std_logic;
  signal illegal_lsu_instr : std_logic;
  signal illegal_muldiv_instr : std_logic;
  signal illegal_csr_rd : std_logic;
  signal illegal_csr_wr : std_logic;

begin
  --////////////////////////////////////////////////////////////////
  --
  -- Module Body
  --

  --Program Counter
  processing_0 : process (clk, rstn)
  begin
    if (not rstn) then
      id_pc <= PC_INIT;
    elsif (rising_edge(clk)) then
      if (st_flush) then
        id_pc <= st_nxt_pc;
      elsif (bu_flush or du_flush) then    --Is this required?! 
        id_pc <= bu_nxt_pc;
      elsif (not stall and not id_stall) then
        id_pc <= if_pc;
      end if;
    end if;
  end process;


  --
--   * Instruction
--   *
--   * TODO: push if-instr upon illegal-instruction
--   */

  processing_1 : process (clk)
  begin
    if (rising_edge(clk)) then
      if (not stall) then
        id_instr <= if_instr;
      end if;
    end if;
  end process;


  processing_2 : process (clk, rstn)
  begin
    if (not rstn) then
      id_bubble_r <= '1';
    elsif (rising_edge(clk)) then
      if (bu_flush or st_flush or du_flush) then
        id_bubble_r <= '1';
      elsif (not stall) then
        if (id_stall) then
          id_bubble_r <= '1';
        else
          id_bubble_r <= if_bubble;
        end if;
      end if;
    end if;
  end process;


  --local stall
  stall <= ex_stall or (du_stall and nor wb_exception);
  id_bubble <= stall or bu_flush or st_flush or or ex_exception or or mem_exception or or wb_exception or id_bubble_r;

  if_opcode <= if_instr(6 downto 2);
  if_func7 <= if_instr(31 downto 25);
  if_func3 <= if_instr(14 downto 12);

  id_opcode <= id_instr(6 downto 2);
  ex_opcode <= ex_instr(6 downto 2);
  mem_opcode <= mem_instr(6 downto 2);
  wb_opcode <= wb_instr(6 downto 2);
  id_dst <= id_instr(11 downto 7);
  ex_dst <= ex_instr(11 downto 7);
  mem_dst <= mem_instr(11 downto 7);
  wb_dst <= wb_instr(11 downto 7);

  has_fpu <= (HAS_FPU /= 0);
  has_muldiv <= (HAS_RVM /= 0);
  has_amo <= (HAS_RVA /= 0);
  has_u <= (HAS_USER /= 0);
  has_s <= (HAS_SUPER /= 0);
  has_h <= (HAS_HYPER /= 0);

  xlen64 <= st_xlen = RV64I;
  xlen32 <= st_xlen = RV32I;

  processing_3 : process (clk)
  begin
    if (rising_edge(clk)) then
      if (not stall and not id_stall) then
        id_bp_predict <= if_bp_predict;
      end if;
    end if;
  end process;


  --Exceptions
  processing_4 : process (clk, rstn)
  begin
    if (not rstn) then
      id_exception <= X"0";
    elsif (rising_edge(clk)) then
      if (bu_flush or st_flush) then
        id_exception <= X"0";
      elsif (not stall) then
        if (id_stall) then
          id_exception <= X"0";
        else
          id_exception <= if_exception;
          id_exception(CAUSE_ILLEGAL_INSTRUCTION) <= not if_bubble and illegal_instr;
          id_exception(CAUSE_BREAKPOINT) <= not if_bubble and (if_instr = EBREAK);
          id_exception(CAUSE_UMODE_ECALL) <= not if_bubble and (if_instr = ECALL) and (st_prv = PRV_U) and has_u;
          id_exception(CAUSE_SMODE_ECALL) <= not if_bubble and (if_instr = ECALL) and (st_prv = PRV_S) and has_s;
          id_exception(CAUSE_HMODE_ECALL) <= not if_bubble and (if_instr = ECALL) and (st_prv = PRV_H) and has_h;
          id_exception(CAUSE_MMODE_ECALL) <= not if_bubble and (if_instr = ECALL) and (st_prv = PRV_M);
        end if;
      end if;
    end if;
  end process;


  --To Register File

  --address into register file. Gets registered in memory
  --Should the hold be handled by the memory?!
  id_src1 <= if_instr(19 downto 15)
  when not (du_stall or ex_stall) else id_instr(19 downto 15);
  id_src2 <= if_instr(24 downto 20)
  when not (du_stall or ex_stall) else id_instr(24 downto 20);

  if_src1 <= if_instr(19 downto 15);
  if_src2 <= if_instr(24 downto 20);

  --
--   * Decode Immediates
--   *
--   *                                 31    30          12           11  10           5  4            1            0
--   */

  immI <= (concatenate(XLEN-11, if_instr(31)) & if_instr(30 downto 25) & if_instr(24 downto 21) & if_instr(20));
  immU <= (concatenate(XLEN-31, if_instr(31)) & if_instr(30 downto 12) & '0');

  --Create ALU operands

  --generate Load-WB-result
  --result might fall inbetween wb_r and data available in Register File
  processing_5 : process
  begin
    case ((wb_opcode)) is
    when OPC_LOAD =>
      can_ldwb <= not wb_bubble;
    when OPC_OP_IMM =>
      can_ldwb <= not wb_bubble;
    when OPC_AUIPC =>
      can_ldwb <= not wb_bubble;
    when OPC_OP_IMM32 =>
      can_ldwb <= not wb_bubble;
    when OPC_AMO =>
      can_ldwb <= not wb_bubble;
    when OPC_OP =>
      can_ldwb <= not wb_bubble;
    when OPC_LUI =>
      can_ldwb <= not wb_bubble;
    when OPC_OP32 =>
      can_ldwb <= not wb_bubble;
    when OPC_JALR =>
      can_ldwb <= not wb_bubble;
    when OPC_JAL =>
      can_ldwb <= not wb_bubble;
    when OPC_SYSTEM =>
    --TODO not ALL SYSTEM
      can_ldwb <= not wb_bubble;
    when others =>
      can_ldwb <= '0';
    end case;
  end process;


  processing_6 : process (clk)
  begin
    if (rising_edge(clk)) then
      if (not stall) then
        case ((if_opcode)) is
        when OPC_OP_IMM =>
          id_userf_opA <= not ((if_src1 = wb_dst) and or wb_dst and can_ldwb);
          id_userf_opB <= '0';
        when OPC_AUIPC =>
          id_userf_opA <= '0';
          id_userf_opB <= '0';
        when OPC_OP_IMM32 =>
          id_userf_opA <= not ((if_src1 = wb_dst) and or wb_dst and can_ldwb);
          id_userf_opB <= '0';
        when OPC_OP =>
          id_userf_opA <= not ((if_src1 = wb_dst) and or wb_dst and can_ldwb);
          id_userf_opB <= not ((if_src2 = wb_dst) and or wb_dst and can_ldwb);
        when OPC_LUI =>
          id_userf_opA <= '0';
          id_userf_opB <= '0';
        when OPC_OP32 =>
          id_userf_opA <= not ((if_src1 = wb_dst) and or wb_dst and can_ldwb);
          id_userf_opB <= not ((if_src2 = wb_dst) and or wb_dst and can_ldwb);
        when OPC_BRANCH =>
          id_userf_opA <= not ((if_src1 = wb_dst) and or wb_dst and can_ldwb);
          id_userf_opB <= not ((if_src2 = wb_dst) and or wb_dst and can_ldwb);
        when OPC_JALR =>
          id_userf_opA <= not ((if_src1 = wb_dst) and or wb_dst and can_ldwb);
          id_userf_opB <= '0';
        when OPC_LOAD =>
          id_userf_opA <= not ((if_src1 = wb_dst) and or wb_dst and can_ldwb);
          id_userf_opB <= '0';
        when OPC_STORE =>
          id_userf_opA <= not ((if_src1 = wb_dst) and or wb_dst and can_ldwb);
          id_userf_opB <= not ((if_src2 = wb_dst) and or wb_dst and can_ldwb);
        when OPC_SYSTEM =>
          id_userf_opA <= not ((if_src1 = wb_dst) and or wb_dst and can_ldwb);
          id_userf_opB <= '0';
        when others =>
          id_userf_opA <= '1';
          id_userf_opB <= '1';
        end case;
      end if;
    end if;
  end process;


  processing_7 : process (clk)
  begin
    if (rising_edge(clk)) then
      if (not stall) then
        case ((if_opcode)) is
        when OPC_LOAD_FP =>
          null;
        when OPC_MISC_MEM =>
          null;
        when OPC_OP_IMM =>
          id_opA <= wb_r;
          id_opB <= immI;
        when OPC_AUIPC =>
          id_opA <= if_pc;
          id_opB <= immU;
        when OPC_OP_IMM32 =>
          id_opA <= wb_r;
          id_opB <= immI;
        when OPC_LOAD =>
          id_opA <= wb_r;
          id_opB <= immI;
        when OPC_STORE =>
          id_opA <= wb_r;
          id_opB <= wb_r;
        when OPC_STORE_FP =>
          null;
        when OPC_AMO =>
          null;
        when OPC_OP =>
          id_opA <= wb_r;
          id_opB <= wb_r;
        when OPC_LUI =>
          id_opA <= 0;
          id_opB <= immU;
        when OPC_OP32 =>
          id_opA <= wb_r;
          id_opB <= wb_r;
        when OPC_MADD =>
          null;
        when OPC_MSUB =>
          null;
        when OPC_NMSUB =>
          null;
        when OPC_NMADD =>
          null;
        when OPC_OP_FP =>
          null;
        when OPC_BRANCH =>
          id_opA <= wb_r;
          id_opB <= wb_r;
        when OPC_JALR =>
          id_opA <= wb_r;
          id_opB <= immI;
        when OPC_SYSTEM =>
        --for CSRxx
          id_opA <= wb_r;
          id_opB <= (concatenate(XLEN-5, '0') & if_src1);          --for CSRxxI
        when others =>
          id_opA <= X"x";
          id_opB <= X"x";
        end case;
      end if;
    end if;
  end process;


  --Bypasses
  processing_8 : process (clk, rstn)
  begin
    if (not rstn) then
      multi_cycle_instruction <= '0';
    elsif (rising_edge(clk)) then
      if (not stall) then
        case (((xlen32 & if_func7 & if_func3 & if_opcode))) is
        when ('?' & MUL) =>
          multi_cycle_instruction <= has_muldiv
          when MULT_LATENCY > 0 else '0';
        when ('?' & MULH) =>
          multi_cycle_instruction <= has_muldiv
          when MULT_LATENCY > 0 else '0';
        when ('0' & MULW) =>
          multi_cycle_instruction <= has_muldiv
          when MULT_LATENCY > 0 else '0';
        when ('?' & MULHSU) =>
          multi_cycle_instruction <= has_muldiv
          when MULT_LATENCY > 0 else '0';
        when ('?' & MULHU) =>
          multi_cycle_instruction <= has_muldiv
          when MULT_LATENCY > 0 else '0';
        when ('?' & DIV) =>
          multi_cycle_instruction <= has_muldiv;
        when ('0' & DIVW) =>
          multi_cycle_instruction <= has_muldiv;
        when ('?' & DIVU) =>
          multi_cycle_instruction <= has_muldiv;
        when ('0' & DIVUW) =>
          multi_cycle_instruction <= has_muldiv;
        when ('?' & REM) =>
          multi_cycle_instruction <= has_muldiv;
        when ('0' & REMW) =>
          multi_cycle_instruction <= has_muldiv;
        when ('?' & REMU) =>
          multi_cycle_instruction <= has_muldiv;
        when ('0' & REMUW) =>
          multi_cycle_instruction <= has_muldiv;
        when others =>
          multi_cycle_instruction <= '0';
        end case;
      end if;
    end if;
  end process;


  --Check for each stage if the result should be used
  processing_9 : process
  begin
    case ((id_opcode)) is
    when OPC_LOAD =>
      can_bypex <= not id_bubble;
    when OPC_OP_IMM =>
      can_bypex <= not id_bubble;
    when OPC_AUIPC =>
      can_bypex <= not id_bubble;
    when OPC_OP_IMM32 =>
      can_bypex <= not id_bubble;
    when OPC_AMO =>
      can_bypex <= not id_bubble;
    when OPC_OP =>
      can_bypex <= not id_bubble;
    when OPC_LUI =>
      can_bypex <= not id_bubble;
    when OPC_OP32 =>
      can_bypex <= not id_bubble;
    when OPC_JALR =>
      can_bypex <= not id_bubble;
    when OPC_JAL =>
      can_bypex <= not id_bubble;
    when OPC_SYSTEM =>
    --TODO not ALL SYSTEM
      can_bypex <= not id_bubble;
    when others =>
      can_bypex <= '0';
    end case;
  end process;


  processing_10 : process
  begin
    case ((ex_opcode)) is
    when OPC_LOAD =>
      can_bypmem <= not ex_bubble and not multi_cycle_instruction;
    when OPC_OP_IMM =>
      can_bypmem <= not ex_bubble and not multi_cycle_instruction;
    when OPC_AUIPC =>
      can_bypmem <= not ex_bubble and not multi_cycle_instruction;
    when OPC_OP_IMM32 =>
      can_bypmem <= not ex_bubble and not multi_cycle_instruction;
    when OPC_AMO =>
      can_bypmem <= not ex_bubble and not multi_cycle_instruction;
    when OPC_OP =>
      can_bypmem <= not ex_bubble and not multi_cycle_instruction;
    when OPC_LUI =>
      can_bypmem <= not ex_bubble and not multi_cycle_instruction;
    when OPC_OP32 =>
      can_bypmem <= not ex_bubble and not multi_cycle_instruction;
    when OPC_JALR =>
      can_bypmem <= not ex_bubble and not multi_cycle_instruction;
    when OPC_JAL =>
      can_bypmem <= not ex_bubble and not multi_cycle_instruction;
    when OPC_SYSTEM =>
    --TODO not ALL SYSTEM
      can_bypmem <= not ex_bubble and not multi_cycle_instruction;
    when others =>
      can_bypmem <= '0';
    end case;
  end process;


  processing_11 : process
  begin
    case ((mem_opcode)) is
    when OPC_LOAD =>
      can_bypwb <= not mem_bubble and not multi_cycle_instruction;
    when OPC_OP_IMM =>
      can_bypwb <= not mem_bubble and not multi_cycle_instruction;
    when OPC_AUIPC =>
      can_bypwb <= not mem_bubble and not multi_cycle_instruction;
    when OPC_OP_IMM32 =>
      can_bypwb <= not mem_bubble and not multi_cycle_instruction;
    when OPC_AMO =>
      can_bypwb <= not mem_bubble and not multi_cycle_instruction;
    when OPC_OP =>
      can_bypwb <= not mem_bubble and not multi_cycle_instruction;
    when OPC_LUI =>
      can_bypwb <= not mem_bubble and not multi_cycle_instruction;
    when OPC_OP32 =>
      can_bypwb <= not mem_bubble and not multi_cycle_instruction;
    when OPC_JALR =>
      can_bypwb <= not mem_bubble and not multi_cycle_instruction;
    when OPC_JAL =>
      can_bypwb <= not mem_bubble and not multi_cycle_instruction;
    when OPC_SYSTEM =>
    --TODO not ALL SYSTEM
      can_bypwb <= not mem_bubble and not multi_cycle_instruction;
    when others =>
      can_bypwb <= '0';
    end case;
  end process;


  --
--   set bypass switches.
--   'x0' is used as a black hole. It should always be zero, but may contain other values in the pipeline
--   therefore we check if dst is non-zero
--   */

  processing_12 : process (clk)
  begin
    if (rising_edge(clk)) then
      if (not stall) then
        case ((if_opcode)) is
        when OPC_OP_IMM =>
          id_bypex_opA <= (if_src1 = id_dst) and or id_dst and can_bypex;
          id_bypex_opB <= '0';

          id_bypmem_opA <= (if_src1 = ex_dst) and or ex_dst and can_bypmem;
          id_bypmem_opB <= '0';

          id_bypwb_opA <= (if_src1 = mem_dst) and or mem_dst and can_bypwb;
          id_bypwb_opB <= '0';
        when OPC_OP_IMM32 =>
          id_bypex_opA <= (if_src1 = id_dst) and or id_dst and can_bypex;
          id_bypex_opB <= '0';

          id_bypmem_opA <= (if_src1 = ex_dst) and or ex_dst and can_bypmem;
          id_bypmem_opB <= '0';

          id_bypwb_opA <= (if_src1 = mem_dst) and or mem_dst and can_bypwb;
          id_bypwb_opB <= '0';
        when OPC_OP =>
          id_bypex_opA <= (if_src1 = id_dst) and or id_dst and can_bypex;
          id_bypex_opB <= (if_src2 = id_dst) and or id_dst and can_bypex;

          id_bypmem_opA <= (if_src1 = ex_dst) and or ex_dst and can_bypmem;
          id_bypmem_opB <= (if_src2 = ex_dst) and or ex_dst and can_bypmem;

          id_bypwb_opA <= (if_src1 = mem_dst) and or mem_dst and can_bypwb;
          id_bypwb_opB <= (if_src2 = mem_dst) and or mem_dst and can_bypwb;
        when OPC_OP32 =>
          id_bypex_opA <= (if_src1 = id_dst) and or id_dst and can_bypex;
          id_bypex_opB <= (if_src2 = id_dst) and or id_dst and can_bypex;

          id_bypmem_opA <= (if_src1 = ex_dst) and or ex_dst and can_bypmem;
          id_bypmem_opB <= (if_src2 = ex_dst) and or ex_dst and can_bypmem;

          id_bypwb_opA <= (if_src1 = mem_dst) and or mem_dst and can_bypwb;
          id_bypwb_opB <= (if_src2 = mem_dst) and or mem_dst and can_bypwb;
        when OPC_BRANCH =>
          id_bypex_opA <= (if_src1 = id_dst) and or id_dst and can_bypex;
          id_bypex_opB <= (if_src2 = id_dst) and or id_dst and can_bypex;

          id_bypmem_opA <= (if_src1 = ex_dst) and or ex_dst and can_bypmem;
          id_bypmem_opB <= (if_src2 = ex_dst) and or ex_dst and can_bypmem;

          id_bypwb_opA <= (if_src1 = mem_dst) and or mem_dst and can_bypwb;
          id_bypwb_opB <= (if_src2 = mem_dst) and or mem_dst and can_bypwb;
        when OPC_JALR =>
          id_bypex_opA <= (if_src1 = id_dst) and or id_dst and can_bypex;
          id_bypex_opB <= '0';

          id_bypmem_opA <= (if_src1 = ex_dst) and or ex_dst and can_bypmem;
          id_bypmem_opB <= '0';

          id_bypwb_opA <= (if_src1 = mem_dst) and or mem_dst and can_bypwb;
          id_bypwb_opB <= '0';
        when OPC_LOAD =>
          id_bypex_opA <= (if_src1 = id_dst) and or id_dst and can_bypex;
          id_bypex_opB <= '0';

          id_bypmem_opA <= (if_src1 = ex_dst) and or ex_dst and can_bypmem;
          id_bypmem_opB <= '0';

          id_bypwb_opA <= (if_src1 = mem_dst) and or mem_dst and can_bypwb;
          id_bypwb_opB <= '0';
        when OPC_STORE =>
          id_bypex_opA <= (if_src1 = id_dst) and or id_dst and can_bypex;
          id_bypex_opB <= (if_src2 = id_dst) and or id_dst and can_bypex;

          id_bypmem_opA <= (if_src1 = ex_dst) and or ex_dst and can_bypmem;
          id_bypmem_opB <= (if_src2 = ex_dst) and or ex_dst and can_bypmem;

          id_bypwb_opA <= (if_src1 = mem_dst) and or mem_dst and can_bypwb;
          id_bypwb_opB <= (if_src2 = mem_dst) and or mem_dst and can_bypwb;
        when OPC_SYSTEM =>
          id_bypex_opA <= (if_src1 = id_dst) and or id_dst and can_bypex;
          id_bypex_opB <= '0';

          id_bypmem_opA <= (if_src1 = ex_dst) and or ex_dst and can_bypmem;
          id_bypmem_opB <= '0';

          id_bypwb_opA <= (if_src1 = mem_dst) and or mem_dst and can_bypwb;
          id_bypwb_opB <= '0';
        when others =>
          id_bypex_opA <= '0';
          id_bypex_opB <= '0';

          id_bypmem_opA <= '0';
          id_bypmem_opB <= '0';

          id_bypwb_opA <= '0';
          id_bypwb_opB <= '0';
        end case;
      end if;
    end if;
  end process;


  --Generate STALL

  --rih: todo
  processing_13 : process
  begin
    if (bu_flush or st_flush or du_flush) then  --flush overrules stall
      id_stall <= '0';
    elsif (stall) then  --ignore NOPs e.g. after flush or IF-stall
      id_stall <= not if_bubble;
    elsif (id_opcode = OPC_LOAD and not id_bubble) then
      case ((if_opcode)) is
      when OPC_OP_IMM =>
        id_stall <= (if_src1 = id_dst);
      when OPC_OP_IMM32 =>
        id_stall <= (if_src1 = id_dst);
      when OPC_OP =>
        id_stall <= (if_src1 = id_dst) or (if_src2 = id_dst);
      when OPC_OP32 =>
        id_stall <= (if_src1 = id_dst) or (if_src2 = id_dst);
      when OPC_BRANCH =>
        id_stall <= (if_src1 = id_dst) or (if_src2 = id_dst);
      when OPC_JALR =>
        id_stall <= (if_src1 = id_dst);
      when OPC_LOAD =>
        id_stall <= (if_src1 = id_dst);
      when OPC_STORE =>
        id_stall <= (if_src1 = id_dst) or (if_src2 = id_dst);
      when OPC_SYSTEM =>
        id_stall <= (if_src1 = id_dst);
      when others =>
        id_stall <= '0';
      end case;
    elsif (ex_opcode = OPC_LOAD and not ex_bubble) then
      case ((if_opcode)) is
      when OPC_OP_IMM =>
        id_stall <= (if_src1 = ex_dst);
      when OPC_OP_IMM32 =>
        id_stall <= (if_src1 = ex_dst);
      when OPC_OP =>
        id_stall <= (if_src1 = ex_dst) or (if_src2 = ex_dst);
      when OPC_OP32 =>
        id_stall <= (if_src1 = ex_dst) or (if_src2 = ex_dst);
      when OPC_BRANCH =>
        id_stall <= (if_src1 = ex_dst) or (if_src2 = ex_dst);
      when OPC_JALR =>
        id_stall <= (if_src1 = ex_dst);
      when OPC_LOAD =>
        id_stall <= (if_src1 = ex_dst);
      when OPC_STORE =>
        id_stall <= (if_src1 = ex_dst) or (if_src2 = ex_dst);
      when OPC_SYSTEM =>
        id_stall <= (if_src1 = ex_dst);
      when others =>
        id_stall <= '0';
      end case;
    else

    --
--    else if (mem_opcode == `OPC_LOAD)
--      casex (if_opcode)
--        `OPC_OP_IMM  : id_stall = (if_src1 == mem_dst);
--        `OPC_OP_IMM32: id_stall = (if_src1 == mem_dst);
--        `OPC_OP      : id_stall = (if_src1 == mem_dst) | (if_src2 == mem_dst);
--        `OPC_OP32    : id_stall = (if_src1 == mem_dst) | (if_src2 == mem_dst);
--        `OPC_BRANCH  : id_stall = (if_src1 == mem_dst) | (if_src2 == mem_dst);
--        `OPC_JALR    : id_stall = (if_src1 == mem_dst);
--        `OPC_LOAD    : id_stall = (if_src1 == mem_dst);
--        `OPC_STORE   : id_stall = (if_src1 == mem_dst) | (if_src2 == mem_dst);
--        `OPC_SYSTEM  : id_stall = (if_src1 == mem_dst);
--        default     : id_stall = 'b0;
--      endcase
-- */

      id_stall <= '0';
    end if;
  end process;


  --Generate Illegal Instruction
  processing_14 : process
  begin
    case ((if_opcode)) is
    when OPC_LOAD =>
      illegal_instr <= illegal_lsu_instr;
    when OPC_STORE =>
      illegal_instr <= illegal_lsu_instr;
    when others =>
      illegal_instr <= illegal_alu_instr and (illegal_muldiv_instr
      when has_muldiv else '1');
    end case;
  end process;


  --ALU
  processing_15 : process
  begin
    case ((if_instr)) is
    when FENCE =>
      illegal_alu_instr <= '0';
    when FENCE_I =>
      illegal_alu_instr <= '0';
    when ECALL =>
      illegal_alu_instr <= '0';
    when EBREAK =>
      illegal_alu_instr <= '0';
    when URET =>
      illegal_alu_instr <= not has_u;
    when SRET =>
      illegal_alu_instr <= not has_s or st_prv < PRV_S or (st_prv = PRV_S and st_tsr);
    when MRET =>
      illegal_alu_instr <= st_prv /= PRV_M;
    when others =>
      case (((xlen32 & if_func7 & if_func3 & if_opcode))) is
      when ('?' & LUI) =>
        illegal_alu_instr <= '0';
      when ('?' & AUIPC) =>
        illegal_alu_instr <= '0';
      when ('?' & JAL) =>
        illegal_alu_instr <= '0';
      when ('?' & JALR) =>
        illegal_alu_instr <= '0';
      when ('?' & BEQ) =>
        illegal_alu_instr <= '0';
      when ('?' & BNE) =>
        illegal_alu_instr <= '0';
      when ('?' & BLT) =>
        illegal_alu_instr <= '0';
      when ('?' & BGE) =>
        illegal_alu_instr <= '0';
      when ('?' & BLTU) =>
        illegal_alu_instr <= '0';
      when ('?' & BGEU) =>
        illegal_alu_instr <= '0';
      when ('?' & ADDI) =>
        illegal_alu_instr <= '0';
      when ('?' & ADD) =>
        illegal_alu_instr <= '0';
      when ('0' & ADDIW) =>
      --RV64
        illegal_alu_instr <= '0';
      when ('0' & ADDW) =>
      --RV64
        illegal_alu_instr <= '0';
      when ('?' & SUB) =>
        illegal_alu_instr <= '0';
      when ('0' & SUBW) =>
      --RV64
        illegal_alu_instr <= '0';
      when ('?' & XORI) =>
        illegal_alu_instr <= '0';
      when ('?' & XORX) =>
        illegal_alu_instr <= '0';
      when ('?' & ORI) =>
        illegal_alu_instr <= '0';
      when ('?' & ORX) =>
        illegal_alu_instr <= '0';
      when ('?' & ANDI) =>
        illegal_alu_instr <= '0';
      when ('?' & ANDX) =>
        illegal_alu_instr <= '0';
      when ('?' & SLLI) =>
      --shamt[5] illegal for RV32
        illegal_alu_instr <= xlen32 and if_func7(0);
      when ('?' & SLLX) =>
        illegal_alu_instr <= '0';
      when ('0' & SLLIW) =>
      --RV64
        illegal_alu_instr <= '0';
      when ('0' & SLLW) =>
      --RV64
        illegal_alu_instr <= '0';
      when ('?' & SLTI) =>
        illegal_alu_instr <= '0';
      when ('?' & SLT) =>
        illegal_alu_instr <= '0';
      when ('?' & SLTIU) =>
        illegal_alu_instr <= '0';
      when ('?' & SLTU) =>
        illegal_alu_instr <= '0';
      when ('?' & SRLI) =>
      --shamt[5] illegal for RV32
        illegal_alu_instr <= xlen32 and if_func7(0);
      when ('?' & SRLX) =>
        illegal_alu_instr <= '0';
      when ('0' & SRLIW) =>
      --RV64
        illegal_alu_instr <= '0';
      when ('0' & SRLW) =>
      --RV64
        illegal_alu_instr <= '0';
      when ('?' & SRAI) =>
      --shamt[5] illegal for RV32
        illegal_alu_instr <= xlen32 and if_func7(0);
      when ('?' & SRAX) =>
        illegal_alu_instr <= '0';
      when ('0' & SRAIW) =>
        illegal_alu_instr <= '0';
      when ('?' & SRAW) =>


        illegal_alu_instr <= '0';
      --system
      when ('?' & CSRRW) =>
        illegal_alu_instr <= illegal_csr_rd or illegal_csr_wr;
      when ('?' & CSRRS) =>
        illegal_alu_instr <= illegal_csr_rd or (or if_src1 and illegal_csr_wr);
      when ('?' & CSRRC) =>
        illegal_alu_instr <= illegal_csr_rd or (or if_src1 and illegal_csr_wr);
      when ('?' & CSRRWI) =>
        illegal_alu_instr <= illegal_csr_rd or (or if_src1 and illegal_csr_wr);
      when ('?' & CSRRSI) =>
        illegal_alu_instr <= illegal_csr_rd or (or if_src1 and illegal_csr_wr);
      when ('?' & CSRRCI) =>


        illegal_alu_instr <= illegal_csr_rd or (or if_src1 and illegal_csr_wr);
      when others =>
        illegal_alu_instr <= '1';
      end case;
    end case;
  end process;


  --LSU
  processing_16 : process
  begin
    case (((xlen32 & has_amo & if_func7 & if_func3 & if_opcode))) is
    when ('?' & '?' & LB) =>
      illegal_lsu_instr <= '0';
    when ('?' & '?' & LH) =>
      illegal_lsu_instr <= '0';
    when ('?' & '?' & LW) =>
      illegal_lsu_instr <= '0';
    when ('0' & '?' & LD) =>
    --RV64
      illegal_lsu_instr <= '0';
    when ('?' & '?' & LBU) =>
      illegal_lsu_instr <= '0';
    when ('?' & '?' & LHU) =>
      illegal_lsu_instr <= '0';
    when ('0' & '?' & LWU) =>
    --RV64
      illegal_lsu_instr <= '0';
    when ('?' & '?' & SB) =>
      illegal_lsu_instr <= '0';
    when ('?' & '?' & SH) =>
      illegal_lsu_instr <= '0';
    when ('?' & '?' & SW) =>
      illegal_lsu_instr <= '0';
    when ('0' & '?' & SD) =>
    --RV64

      illegal_lsu_instr <= '0';
    --AMO
    when others =>
      illegal_lsu_instr <= '1';
    end case;
  end process;


  --MULDIV
  processing_17 : process
  begin
    case (((xlen32 & if_func7 & if_func3 & if_opcode))) is
    when ('?' & MUL) =>
      illegal_muldiv_instr <= '0';
    when ('?' & MULH) =>
      illegal_muldiv_instr <= '0';
    when ('0' & MULW) =>
    --RV64
      illegal_muldiv_instr <= '0';
    when ('?' & MULHSU) =>
      illegal_muldiv_instr <= '0';
    when ('?' & MULHU) =>
      illegal_muldiv_instr <= '0';
    when ('?' & DIV) =>
      illegal_muldiv_instr <= '0';
    when ('0' & DIVW) =>
    --RV64
      illegal_muldiv_instr <= '0';
    when ('?' & DIVU) =>
      illegal_muldiv_instr <= '0';
    when ('0' & DIVUW) =>
    --RV64
      illegal_muldiv_instr <= '0';
    when ('?' & REM) =>
      illegal_muldiv_instr <= '0';
    when ('0' & REMW) =>
    --RV64
      illegal_muldiv_instr <= '0';
    when ('?' & REMU) =>
      illegal_muldiv_instr <= '0';
    when ('0' & REMUW) =>
      illegal_muldiv_instr <= '0';
    when others =>
      illegal_muldiv_instr <= '1';
    end case;
  end process;


  --Check CSR accesses
  processing_18 : process
  begin
    case ((if_instr(31 downto 20))) is
    --User
    when USTATUS =>
      illegal_csr_rd <= not has_u;
    when UIE =>
      illegal_csr_rd <= not has_u;
    when UTVEC =>
      illegal_csr_rd <= not has_u;
    when USCRATCH =>
      illegal_csr_rd <= not has_u;
    when UEPC =>
      illegal_csr_rd <= not has_u;
    when UCAUSE =>
      illegal_csr_rd <= not has_u;
    when UTVAL =>
      illegal_csr_rd <= not has_u;
    when UIP =>
      illegal_csr_rd <= not has_u;
    when FFLAGS =>
      illegal_csr_rd <= not has_fpu;
    when FRM =>
      illegal_csr_rd <= not has_fpu;
    when FCSR =>
      illegal_csr_rd <= not has_fpu;
    when CYCLE =>
      illegal_csr_rd <= not has_u or (not has_s and st_prv = PRV_U and not st_mcounteren(CY)) or (has_s and st_prv = PRV_S and not st_mcounteren(CY)) or (has_s and st_prv = PRV_U and st_mcounteren(CY) and st_scounteren(CY));
    when TIMEX =>
    --trap on reading TIME. Machine mode must access external timer
      illegal_csr_rd <= '1';
    when INSTRET =>
      illegal_csr_rd <= not has_u or (not has_s and st_prv = PRV_U and not st_mcounteren(IR)) or (has_s and st_prv = PRV_S and not st_mcounteren(IR)) or (has_s and st_prv = PRV_U and st_mcounteren(IR) and st_scounteren(IR));
    when CYCLEH =>
      illegal_csr_rd <= not has_u or not xlen32 or (not has_s and st_prv = PRV_U and not st_mcounteren(CY)) or (has_s and st_prv = PRV_S and not st_mcounteren(CY)) or (has_s and st_prv = PRV_U and st_mcounteren(CY) and st_scounteren(CY));
    when TIMEH =>
    --trap on reading TIMEH. Machine mode must access external timer
      illegal_csr_rd <= '1';
    when INSTRETH =>
      illegal_csr_rd <= not has_u or not xlen32 or (not has_s and st_prv = PRV_U and not st_mcounteren(IR)) or (has_s and st_prv = PRV_S and not st_mcounteren(IR)) or (has_s and st_prv = PRV_U and st_mcounteren(IR) and st_scounteren(IR));
    --TODO: hpmcounters

    --Supervisor
    when SSTATUS =>
      illegal_csr_rd <= not has_s or (st_prv < PRV_S);
    when SEDELEG =>
      illegal_csr_rd <= not has_s or (st_prv < PRV_S);
    when SIDELEG =>
      illegal_csr_rd <= not has_s or (st_prv < PRV_S);
    when SIE =>
      illegal_csr_rd <= not has_s or (st_prv < PRV_S);
    when STVEC =>
      illegal_csr_rd <= not has_s or (st_prv < PRV_S);
    when SSCRATCH =>
      illegal_csr_rd <= not has_s or (st_prv < PRV_S);
    when SEPC =>
      illegal_csr_rd <= not has_s or (st_prv < PRV_S);
    when SCAUSE =>
      illegal_csr_rd <= not has_s or (st_prv < PRV_S);
    when STVAL =>
      illegal_csr_rd <= not has_s or (st_prv < PRV_S);
    when SIP =>
      illegal_csr_rd <= not has_s or (st_prv < PRV_S);
    when SATP =>


      illegal_csr_rd <= not has_s or (st_prv < PRV_S) or (st_prv = PRV_S and st_tvm);
    --Hypervisor
    --
--      HSTATUS   : illegal_csr_rd = (`HAS_HYPER == 0)               | (st_prv < PRV_H);
--      HEDELEG   : illegal_csr_rd = (`HAS_HYPER == 0)               | (st_prv < PRV_H);
--      HIDELEG   : illegal_csr_rd = (`HAS_HYPER == 0)               | (st_prv < PRV_H);
--      HIE       : illegal_csr_rd = (`HAS_HYPER == 0)               | (st_prv < PRV_H);
--      HTVEC     : illegal_csr_rd = (`HAS_HYPER == 0)               | (st_prv < PRV_H);
--      HSCRATCH  : illegal_csr_rd = (`HAS_HYPER == 0)               | (st_prv < PRV_H);
--      HEPC      : illegal_csr_rd = (`HAS_HYPER == 0)               | (st_prv < PRV_H);
--      HCAUSE    : illegal_csr_rd = (`HAS_HYPER == 0)               | (st_prv < PRV_H);
--      HTVAL     : illegal_csr_rd = (`HAS_HYPER == 0)               | (st_prv < PRV_H);
--      HIP       : illegal_csr_rd = (`HAS_HYPER == 0)               | (st_prv < PRV_H);
-- */
    --Machine
    when MVENDORID =>
      illegal_csr_rd <= (st_prv < PRV_M);
    when MARCHID =>
      illegal_csr_rd <= (st_prv < PRV_M);
    when MIMPID =>
      illegal_csr_rd <= (st_prv < PRV_M);
    when MHARTID =>
      illegal_csr_rd <= (st_prv < PRV_M);
    when MSTATUS =>
      illegal_csr_rd <= (st_prv < PRV_M);
    when MISA =>
      illegal_csr_rd <= (st_prv < PRV_M);
    when MEDELEG =>
      illegal_csr_rd <= (st_prv < PRV_M);
    when MIDELEG =>
      illegal_csr_rd <= (st_prv < PRV_M);
    when MIE =>
      illegal_csr_rd <= (st_prv < PRV_M);
    when MTVEC =>
      illegal_csr_rd <= (st_prv < PRV_M);
    when MCOUNTEREN =>
      illegal_csr_rd <= (st_prv < PRV_M);
    when MSCRATCH =>
      illegal_csr_rd <= (st_prv < PRV_M);
    when MEPC =>
      illegal_csr_rd <= (st_prv < PRV_M);
    when MCAUSE =>
      illegal_csr_rd <= (st_prv < PRV_M);
    when MTVAL =>
      illegal_csr_rd <= (st_prv < PRV_M);
    when MIP =>
      illegal_csr_rd <= (st_prv < PRV_M);
    when PMPCFG0 =>
      illegal_csr_rd <= (st_prv < PRV_M);
    when PMPCFG1 =>
      illegal_csr_rd <= (XLEN > 32) or (st_prv < PRV_M);
    when PMPCFG2 =>
      illegal_csr_rd <= (XLEN > 64) or (st_prv < PRV_M);
    when PMPCFG3 =>
      illegal_csr_rd <= (XLEN > 32) or (st_prv < PRV_M);
    when PMPADDR0 =>
      illegal_csr_rd <= (st_prv < PRV_M);
    when PMPADDR1 =>
      illegal_csr_rd <= (st_prv < PRV_M);
    when PMPADDR2 =>
      illegal_csr_rd <= (st_prv < PRV_M);
    when PMPADDR3 =>
      illegal_csr_rd <= (st_prv < PRV_M);
    when PMPADDR4 =>
      illegal_csr_rd <= (st_prv < PRV_M);
    when PMPADDR5 =>
      illegal_csr_rd <= (st_prv < PRV_M);
    when PMPADDR6 =>
      illegal_csr_rd <= (st_prv < PRV_M);
    when PMPADDR7 =>
      illegal_csr_rd <= (st_prv < PRV_M);
    when PMPADDR8 =>
      illegal_csr_rd <= (st_prv < PRV_M);
    when PMPADDR9 =>
      illegal_csr_rd <= (st_prv < PRV_M);
    when PMPADDR10 =>
      illegal_csr_rd <= (st_prv < PRV_M);
    when PMPADDR11 =>
      illegal_csr_rd <= (st_prv < PRV_M);
    when PMPADDR12 =>
      illegal_csr_rd <= (st_prv < PRV_M);
    when PMPADDR13 =>
      illegal_csr_rd <= (st_prv < PRV_M);
    when PMPADDR14 =>
      illegal_csr_rd <= (st_prv < PRV_M);
    when PMPADDR15 =>
      illegal_csr_rd <= (st_prv < PRV_M);
    when MCYCLE =>
      illegal_csr_rd <= (st_prv < PRV_M);
    when MINSTRET =>
      illegal_csr_rd <= (st_prv < PRV_M);
    --TODO: performance counters
    when MCYCLEH =>
      illegal_csr_rd <= (XLEN > 32) or (st_prv < PRV_M);
    when MINSTRETH =>


      illegal_csr_rd <= (XLEN > 32) or (st_prv < PRV_M);
    when others =>
      illegal_csr_rd <= '1';
    end case;
  end process;


  processing_19 : process
  begin
    case ((if_instr(31 downto 20))) is
    when USTATUS =>
      illegal_csr_wr <= not has_u;
    when UIE =>
      illegal_csr_wr <= not has_u;
    when UTVEC =>
      illegal_csr_wr <= not has_u;
    when USCRATCH =>
      illegal_csr_wr <= not has_u;
    when UEPC =>
      illegal_csr_wr <= not has_u;
    when UCAUSE =>
      illegal_csr_wr <= not has_u;
    when UTVAL =>
      illegal_csr_wr <= not has_u;
    when UIP =>
      illegal_csr_wr <= not has_u;
    when FFLAGS =>
      illegal_csr_wr <= not has_fpu;
    when FRM =>
      illegal_csr_wr <= not has_fpu;
    when FCSR =>
      illegal_csr_wr <= not has_fpu;
    when CYCLE =>
      illegal_csr_wr <= '1';
    when TIMEX =>
      illegal_csr_wr <= '1';
    when INSTRET =>
      illegal_csr_wr <= '1';
    --TODO:hpmcounters
    when CYCLEH =>
      illegal_csr_wr <= '1';
    when TIMEH =>
      illegal_csr_wr <= '1';
    when INSTRETH =>
      illegal_csr_wr <= '1';
    --Supervisor
    when SSTATUS =>
      illegal_csr_wr <= not has_s or (st_prv < PRV_S);
    when SEDELEG =>
      illegal_csr_wr <= not has_s or (st_prv < PRV_S);
    when SIDELEG =>
      illegal_csr_wr <= not has_s or (st_prv < PRV_S);
    when SIE =>
      illegal_csr_wr <= not has_s or (st_prv < PRV_S);
    when STVEC =>
      illegal_csr_wr <= not has_s or (st_prv < PRV_S);
    when SCOUNTEREN =>
      illegal_csr_wr <= not has_s or (st_prv < PRV_S);
    when SSCRATCH =>
      illegal_csr_wr <= not has_s or (st_prv < PRV_S);
    when SEPC =>
      illegal_csr_wr <= not has_s or (st_prv < PRV_S);
    when SCAUSE =>
      illegal_csr_wr <= not has_s or (st_prv < PRV_S);
    when STVAL =>
      illegal_csr_wr <= not has_s or (st_prv < PRV_S);
    when SIP =>
      illegal_csr_wr <= not has_s or (st_prv < PRV_S);
    when SATP =>


      illegal_csr_wr <= not has_s or (st_prv < PRV_S) or (st_prv = PRV_S and st_tvm);
    --Hypervisor
    --
--      HSTATUS   : illegal_csr_wr = (`HAS_HYPER == 0)               | (st_prv < PRV_H);
--      HEDELEG   : illegal_csr_wr = (`HAS_HYPER == 0)               | (st_prv < PRV_H);
--      HIDELEG   : illegal_csr_wr = (`HAS_HYPER == 0)               | (st_prv < PRV_H);
--      HIE       : illegal_csr_wr = (`HAS_HYPER == 0)               | (st_prv < PRV_H);
--      HTVEC     : illegal_csr_wr = (`HAS_HYPER == 0)               | (st_prv < PRV_H);
--      HSCRATCH  : illegal_csr_wr = (`HAS_HYPER == 0)               | (st_prv < PRV_H);
--      HEPC      : illegal_csr_wr = (`HAS_HYPER == 0)               | (st_prv < PRV_H);
--      HCAUSE    : illegal_csr_wr = (`HAS_HYPER == 0)               | (st_prv < PRV_H);
--      HBADADDR  : illegal_csr_wr = (`HAS_HYPER == 0)               | (st_prv < PRV_H);
--      HIP       : illegal_csr_wr = (`HAS_HYPER == 0)               | (st_prv < PRV_H);
-- */
    --Machine
    when MVENDORID =>
      illegal_csr_wr <= '1';
    when MARCHID =>
      illegal_csr_wr <= '1';
    when MIMPID =>
      illegal_csr_wr <= '1';
    when MHARTID =>
      illegal_csr_wr <= '1';
    when MSTATUS =>
      illegal_csr_wr <= (st_prv < PRV_M);
    when MISA =>
      illegal_csr_wr <= (st_prv < PRV_M);
    when MEDELEG =>
      illegal_csr_wr <= (st_prv < PRV_M);
    when MIDELEG =>
      illegal_csr_wr <= (st_prv < PRV_M);
    when MIE =>
      illegal_csr_wr <= (st_prv < PRV_M);
    when MTVEC =>
      illegal_csr_wr <= (st_prv < PRV_M);
    when MNMIVEC =>
      illegal_csr_wr <= (st_prv < PRV_M);
    when MCOUNTEREN =>
      illegal_csr_wr <= (st_prv < PRV_M);
    when MSCRATCH =>
      illegal_csr_wr <= (st_prv < PRV_M);
    when MEPC =>
      illegal_csr_wr <= (st_prv < PRV_M);
    when MCAUSE =>
      illegal_csr_wr <= (st_prv < PRV_M);
    when MTVAL =>
      illegal_csr_wr <= (st_prv < PRV_M);
    when MIP =>
      illegal_csr_wr <= (st_prv < PRV_M);
    when PMPCFG0 =>
      illegal_csr_wr <= (st_prv < PRV_M);
    when PMPCFG1 =>
      illegal_csr_wr <= (XLEN > 32) or (st_prv < PRV_M);
    when PMPCFG2 =>
      illegal_csr_wr <= (XLEN > 64) or (st_prv < PRV_M);
    when PMPCFG3 =>
      illegal_csr_wr <= (XLEN > 32) or (st_prv < PRV_M);
    when PMPADDR0 =>
      illegal_csr_wr <= (st_prv < PRV_M);
    when PMPADDR1 =>
      illegal_csr_wr <= (st_prv < PRV_M);
    when PMPADDR2 =>
      illegal_csr_wr <= (st_prv < PRV_M);
    when PMPADDR3 =>
      illegal_csr_wr <= (st_prv < PRV_M);
    when PMPADDR4 =>
      illegal_csr_wr <= (st_prv < PRV_M);
    when PMPADDR5 =>
      illegal_csr_wr <= (st_prv < PRV_M);
    when PMPADDR6 =>
      illegal_csr_wr <= (st_prv < PRV_M);
    when PMPADDR7 =>
      illegal_csr_wr <= (st_prv < PRV_M);
    when PMPADDR8 =>
      illegal_csr_wr <= (st_prv < PRV_M);
    when PMPADDR9 =>
      illegal_csr_wr <= (st_prv < PRV_M);
    when PMPADDR10 =>
      illegal_csr_wr <= (st_prv < PRV_M);
    when PMPADDR11 =>
      illegal_csr_wr <= (st_prv < PRV_M);
    when PMPADDR12 =>
      illegal_csr_wr <= (st_prv < PRV_M);
    when PMPADDR13 =>
      illegal_csr_wr <= (st_prv < PRV_M);
    when PMPADDR14 =>
      illegal_csr_wr <= (st_prv < PRV_M);
    when PMPADDR15 =>
      illegal_csr_wr <= (st_prv < PRV_M);
    when MCYCLE =>
      illegal_csr_wr <= (st_prv < PRV_M);
    when MINSTRET =>
      illegal_csr_wr <= (st_prv < PRV_M);
    --TODO: performance counters
    when MCYCLEH =>
      illegal_csr_wr <= (XLEN > 32) or (st_prv < PRV_M);
    when MINSTRETH =>


      illegal_csr_wr <= (XLEN > 32) or (st_prv < PRV_M);
    when others =>
      illegal_csr_wr <= '1';
    end case;
  end process;
end RTL;
