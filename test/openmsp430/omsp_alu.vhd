-- Converted from omsp_alu.v
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
-- *File Name: omsp_alu.v
--
-- *Module Description:
--                       openMSP430 ALU
--
-- *Author(s):
--              - Olivier Girard,    olgirard@gmail.com
--

use work."openMSP430_defines.v".all;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity omsp_alu is
  port (
  -- OUTPUTs
  --========
    alu_out : out std_logic_vector(15 downto 0);  -- ALU output value
    alu_out_add : out std_logic_vector(15 downto 0);  -- ALU adder output value
    alu_stat : out std_logic_vector(3 downto 0);  -- ALU Status {V,N,Z,C}
    alu_stat_wr : out std_logic_vector(3 downto 0);  -- ALU Status write {V,N,Z,C}

  -- INPUTs
  --=======
    dbg_halt_st : in std_logic;  -- Halt/Run status from CPU
    exec_cycle : in std_logic;  -- Instruction execution cycle
    inst_alu : in std_logic_vector(11 downto 0);  -- ALU control signals
    inst_bw : in std_logic;  -- Decoded Inst: byte width
    inst_jmp : in std_logic_vector(7 downto 0);  -- Decoded Inst: Conditional jump
    inst_so : in std_logic_vector(7 downto 0);  -- Single-operand arithmetic
    op_dst : in std_logic_vector(15 downto 0);  -- Destination operand
    op_src : in std_logic_vector(15 downto 0)   -- Source operand
    status : in std_logic_vector(3 downto 0)  -- R2 Status {V,N,Z,C}
  );
end omsp_alu;

architecture RTL of omsp_alu is
  --=============================================================================
  -- 2)  INSTRUCTION FETCH/DECODE CONTROL STATE MACHINE
  --=============================================================================
  -- SINGLE-OPERAND ARITHMETIC:
  -------------------------------------------------------------------------------
  --   Mnemonic   S-Reg,   Operation                               Status bits
  --              D-Reg,                                            V  N  Z  C
  --
  --   RRC         dst     C->MSB->...LSB->C                        *  *  *  *
  --   RRA         dst     MSB->MSB->...LSB->C                      0  *  *  *
  --   SWPB        dst     Swap bytes                               -  -  -  -
  --   SXT         dst     Bit7->Bit8...Bit15                       0  *  *  *
  --   PUSH        src     SP-2->SP, src->@SP                       -  -  -  -
  --   CALL        dst     SP-2->SP, PC+2->@SP, dst->PC             -  -  -  -
  --   RETI                TOS->SR, SP+2->SP, TOS->PC, SP+2->SP     *  *  *  *
  --
  -------------------------------------------------------------------------------
  -- TWO-OPERAND ARITHMETIC:
  -------------------------------------------------------------------------------
  --   Mnemonic   S-Reg,   Operation                               Status bits
  --              D-Reg,                                            V  N  Z  C
  --
  --   MOV       src,dst    src            -> dst                   -  -  -  -
  --   ADD       src,dst    src +  dst     -> dst                   *  *  *  *
  --   ADDC      src,dst    src +  dst + C -> dst                   *  *  *  *
  --   SUB       src,dst    dst + ~src + 1 -> dst                   *  *  *  *
  --   SUBC      src,dst    dst + ~src + C -> dst                   *  *  *  *
  --   CMP       src,dst    dst + ~src + 1                          *  *  *  *
  --   DADD      src,dst    src +  dst + C -> dst (decimaly)        *  *  *  *
  --   BIT       src,dst    src &  dst                              0  *  *  *
  --   BIC       src,dst   ~src &  dst     -> dst                   -  -  -  -
  --   BIS       src,dst    src |  dst     -> dst                   -  -  -  -
  --   XOR       src,dst    src ^  dst     -> dst                   *  *  *  *
  --   AND       src,dst    src &  dst     -> dst                   0  *  *  *
  --
  -------------------------------------------------------------------------------
  -- * the status bit is affected
  -- - the status bit is not affected
  -- 0 the status bit is cleared
  -- 1 the status bit is set
  -------------------------------------------------------------------------------

  -- Invert source for substract and compare instructions.
  signal op_src_inv_cmd : std_logic;
  signal op_src_inv : std_logic_vector(15 downto 0);

  -- Mask the bit 8 for the Byte instructions for correct flags generation
  signal op_bit8_msk : std_logic;
  signal op_src_in : std_logic_vector(16 downto 0);
  signal op_dst_in : std_logic_vector(16 downto 0);

  -- Clear the source operand (= jump offset) for conditional jumps
  signal jmp_not_taken : std_logic;
  signal op_src_in_jmp : std_logic_vector(16 downto 0);

  -- Adder / AND / OR / XOR
  signal alu_add : std_logic_vector(16 downto 0);
  signal alu_and : std_logic_vector(16 downto 0);
  signal alu_or : std_logic_vector(16 downto 0);
  signal alu_xor : std_logic_vector(16 downto 0);

  -- Incrementer
  signal alu_inc : std_logic;
  signal alu_add_inc : std_logic_vector(16 downto 0);

  -- Decimal adder (DADD)
  signal alu_dadd0 : std_logic_vector(4 downto 0);
  signal alu_dadd1 : std_logic_vector(4 downto 0);
  signal alu_dadd2 : std_logic_vector(4 downto 0);
  signal alu_dadd3 : std_logic_vector(4 downto 0);
  signal alu_dadd : std_logic_vector(16 downto 0);

  -- Shifter for rotate instructions (RRC & RRA)
  signal alu_shift_msb : std_logic;
  signal alu_shift_7 : std_logic;
  signal alu_shift : std_logic_vector(16 downto 0);

  -- Swap bytes / Extend Sign
  signal alu_swpb : std_logic_vector(16 downto 0);
  signal alu_sxt : std_logic_vector(16 downto 0);

  -- Combine short paths toghether to simplify final ALU mux
  signal alu_short_thro : std_logic;

  signal alu_short : std_logic_vector(16 downto 0);

  -- ALU output mux
  signal alu_out_nxt : std_logic_vector(16 downto 0);

  -------------------------------------------------------------------------------
  -- STATUS FLAG GENERATION
  -------------------------------------------------------------------------------

  signal V_xor : std_logic;

  signal V : std_logic;

  signal N : std_logic;
  signal Z : std_logic;
  signal C : std_logic;

  -- LINT cleanup
  signal UNUSED_inst_so_rra : std_logic;
  signal UNUSED_inst_so_push : std_logic;
  signal UNUSED_inst_so_call : std_logic;
  signal UNUSED_inst_so_reti : std_logic;
  signal UNUSED_inst_jmp : std_logic;
  signal UNUSED_inst_alu : std_logic;

  --=============================================================================
  -- 1)  FUNCTIONS
  --=============================================================================



  function bcd_add (
    X : std_logic_vector(3 downto 0);
    Y : std_logic_vector(3 downto 0);
    C_V2V : std_logic;

    signal Z_V2V : std_logic_vector(4 downto 0);
  ) return std_logic_vector is
    variable bcd_add_return : std_logic_vector (4 downto 0);
  begin
    Z_V2V <= ('0' & X)+('0' & Y)+("0000" & C_V2V);
    if (Z_V2V < CONV_STD_LOGIC_VECTOR(10,5)) then
      bcd_add_return <= Z_V2V;
    else
      bcd_add_return <= Z_V2V+CONV_STD_LOGIC_VECTOR(6,5);
    end if;
    return bcd_add_return;
  end bcd_add;

begin


  --=============================================================================
  -- 2)  INSTRUCTION FETCH/DECODE CONTROL STATE MACHINE
  --=============================================================================
  -- SINGLE-OPERAND ARITHMETIC:
  -------------------------------------------------------------------------------
  --   Mnemonic   S-Reg,   Operation                               Status bits
  --              D-Reg,                                            V  N  Z  C
  --
  --   RRC         dst     C->MSB->...LSB->C                        *  *  *  *
  --   RRA         dst     MSB->MSB->...LSB->C                      0  *  *  *
  --   SWPB        dst     Swap bytes                               -  -  -  -
  --   SXT         dst     Bit7->Bit8...Bit15                       0  *  *  *
  --   PUSH        src     SP-2->SP, src->@SP                       -  -  -  -
  --   CALL        dst     SP-2->SP, PC+2->@SP, dst->PC             -  -  -  -
  --   RETI                TOS->SR, SP+2->SP, TOS->PC, SP+2->SP     *  *  *  *
  --
  -------------------------------------------------------------------------------
  -- TWO-OPERAND ARITHMETIC:
  -------------------------------------------------------------------------------
  --   Mnemonic   S-Reg,   Operation                               Status bits
  --              D-Reg,                                            V  N  Z  C
  --
  --   MOV       src,dst    src            -> dst                   -  -  -  -
  --   ADD       src,dst    src +  dst     -> dst                   *  *  *  *
  --   ADDC      src,dst    src +  dst + C -> dst                   *  *  *  *
  --   SUB       src,dst    dst + ~src + 1 -> dst                   *  *  *  *
  --   SUBC      src,dst    dst + ~src + C -> dst                   *  *  *  *
  --   CMP       src,dst    dst + ~src + 1                          *  *  *  *
  --   DADD      src,dst    src +  dst + C -> dst (decimaly)        *  *  *  *
  --   BIT       src,dst    src &  dst                              0  *  *  *
  --   BIC       src,dst   ~src &  dst     -> dst                   -  -  -  -
  --   BIS       src,dst    src |  dst     -> dst                   -  -  -  -
  --   XOR       src,dst    src ^  dst     -> dst                   *  *  *  *
  --   AND       src,dst    src &  dst     -> dst                   0  *  *  *
  --
  -------------------------------------------------------------------------------
  -- * the status bit is affected
  -- - the status bit is not affected
  -- 0 the status bit is cleared
  -- 1 the status bit is set
  -------------------------------------------------------------------------------

  -- Invert source for substract and compare instructions.
  op_src_inv_cmd <= exec_cycle and (inst_alu(ALU_SRC_INV));
  op_src_inv <= concatenate(16, op_src_inv_cmd) xor op_src;

  -- Mask the bit 8 for the Byte instructions for correct flags generation
  op_bit8_msk <= not exec_cycle or not inst_bw;
  op_src_in <= ('0' & (op_src_inv(15 downto 8) and concatenate(8, op_bit8_msk)) & op_src_inv(7 downto 0));
  op_dst_in <= ('0' & (op_dst(15 downto 8) and concatenate(8, op_bit8_msk)) & op_dst(7 downto 0));

  -- Clear the source operand (= jump offset) for conditional jumps
  jmp_not_taken <= (inst_jmp(JL) and not (status(3) xor status(2))) or (inst_jmp(JGE) and (status(3) xor status(2))) or (inst_jmp(JN) and not status(2)) or (inst_jmp(JC) and not status(0)) or (inst_jmp(JNC) and status(0)) or (inst_jmp(JEQ) and not status(1)) or (inst_jmp(JNE) and status(1));
  op_src_in_jmp <= op_src_in and concatenate(17, not jmp_not_taken);

  -- Adder / AND / OR / XOR
  alu_add <= op_src_in_jmp+op_dst_in;
  alu_and <= op_src_in and op_dst_in;
  alu_or <= op_src_in or op_dst_in;
  alu_xor <= op_src_in xor op_dst_in;

  -- Incrementer
  alu_inc <= exec_cycle and ((inst_alu(ALU_INC_C) and status(0)) or inst_alu(ALU_INC));
  alu_add_inc <= alu_add+(X"0000" & alu_inc);

  -- Decimal adder (DADD)
  alu_dadd0 <= (null)(op_src_in(3 downto 0), op_dst_in(3 downto 0), status(0));
  alu_dadd1 <= (null)(op_src_in(7 downto 4), op_dst_in(7 downto 4), alu_dadd0(4));
  alu_dadd2 <= (null)(op_src_in(11 downto 8), op_dst_in(11 downto 8), alu_dadd1(4));
  alu_dadd3 <= (null)(op_src_in(15 downto 12), op_dst_in(15 downto 12), alu_dadd2(4));
  alu_dadd <= (alu_dadd3 & alu_dadd2(3 downto 0) & alu_dadd1(3 downto 0) & alu_dadd0(3 downto 0));

  -- Shifter for rotate instructions (RRC & RRA)
  alu_shift_msb <= status(0)
  when inst_so(RRC) else op_src(7)
  when inst_bw else op_src(15);
  alu_shift_7 <= alu_shift_msb
  when inst_bw else op_src(8);
  alu_shift <= ('0' & alu_shift_msb & op_src(15 downto 9) & alu_shift_7 & op_src(7 downto 1));

  -- Swap bytes / Extend Sign
  alu_swpb <= ('0' & op_src(7 downto 0) & op_src(15 downto 8));
  alu_sxt <= ('0' & concatenate(8, op_src(7)) & op_src(7 downto 0));

  -- Combine short paths toghether to simplify final ALU mux
  alu_short_thro <= not (inst_alu(ALU_AND) or inst_alu(ALU_OR) or inst_alu(ALU_XOR) or inst_alu(ALU_SHIFT) or inst_so(SWPB) or inst_so(SXT));

  alu_short <= (concatenate(17, inst_alu(ALU_AND)) and alu_and) or (concatenate(17, inst_alu(ALU_OR)) and alu_or) or (concatenate(17, inst_alu(ALU_XOR)) and alu_xor) or (concatenate(17, inst_alu(ALU_SHIFT)) and alu_shift) or (concatenate(17, inst_so(SWPB)) and alu_swpb) or (concatenate(17, inst_so(SXT)) and alu_sxt) or (concatenate(17, alu_short_thro) and op_src_in);

  -- ALU output mux
  alu_out_nxt <= alu_add_inc
  when (inst_so(IRQ) or dbg_halt_st or inst_alu(ALU_ADD)) else alu_dadd
  when inst_alu(ALU_DADD) else alu_short;

  alu_out <= alu_out_nxt(15 downto 0);
  alu_out_add <= alu_add(15 downto 0);

  -------------------------------------------------------------------------------
  -- STATUS FLAG GENERATION
  -------------------------------------------------------------------------------

  V_xor <= (op_src_in(7) and op_dst_in(7))
  when inst_bw else (op_src_in(15) and op_dst_in(15));

  V <= ((not op_src_in(7) and not op_dst_in(7) and alu_out(7)) or (op_src_in(7) and op_dst_in(7) and not alu_out(7)))
  when inst_bw else ((not op_src_in(15) and not op_dst_in(15) and alu_out(15)) or (op_src_in(15) and op_dst_in(15) and not alu_out(15)));

  N <= alu_out(7)
  when inst_bw else alu_out(15);
  Z <= (alu_out(7 downto 0) = 0)
  when inst_bw else (alu_out = 0);
  C <= alu_out(8)
  when inst_bw else alu_out_nxt(16);

  alu_stat <= ('0' & N & Z & op_src_in(0))
  when inst_alu(ALU_SHIFT) else ('0' & N & Z & not Z)
  when inst_alu(ALU_STAT_7) else (V_xor & N & Z & not Z)
  when inst_alu(ALU_XOR) else (V & N & Z & C);

  alu_stat_wr <= "1111"
  when (inst_alu(ALU_STAT_F) and exec_cycle) else "0000";

  -- LINT cleanup
  UNUSED_inst_so_rra <= inst_so(RRA);
  UNUSED_inst_so_push <= inst_so(PUSH);
  UNUSED_inst_so_call <= inst_so(CALL);
  UNUSED_inst_so_reti <= inst_so(RETI);
  UNUSED_inst_jmp <= inst_jmp(JMP);
  UNUSED_inst_alu <= inst_alu(EXEC_NO_WR);
end RTL;
