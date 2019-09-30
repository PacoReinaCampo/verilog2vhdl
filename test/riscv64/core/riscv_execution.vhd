-- Converted from core/riscv_execution.sv
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
--              Core - Execution Unit                                         //
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

entity riscv_execution is
  port (


    rstn : in std_logic;
    clk : in std_logic;

    wb_stall : in std_logic;
    ex_stall : out std_logic;

  --Program counter
    id_pc : in std_logic_vector(XLEN-1 downto 0);
    ex_pc : out std_logic_vector(XLEN-1 downto 0);
    bu_nxt_pc : out std_logic_vector(XLEN-1 downto 0);
    bu_flush : out std_logic;
    bu_cacheflush : out std_logic;
    id_bp_predict : in std_logic_vector(1 downto 0);
    bu_bp_predict : out std_logic_vector(1 downto 0);
    bu_bp_history : out std_logic_vector(BP_GLOBAL_BITS-1 downto 0);
    bu_bp_btaken : out std_logic;
    bu_bp_update : out std_logic;

  --Instruction
    id_bubble : in std_logic;
    id_instr : in std_logic_vector(ILEN-1 downto 0);
    ex_bubble : out std_logic;
    ex_instr : out std_logic_vector(ILEN-1 downto 0);

    id_exception : in std_logic_vector(EXCEPTION_SIZE-1 downto 0);
    mem_exception : in std_logic_vector(EXCEPTION_SIZE-1 downto 0);
    wb_exception : in std_logic_vector(EXCEPTION_SIZE-1 downto 0);
    ex_exception : out std_logic_vector(EXCEPTION_SIZE-1 downto 0);

  --from ID
    id_userf_opA : in std_logic;
    id_userf_opB : in std_logic;
    id_bypex_opA : in std_logic;
    id_bypex_opB : in std_logic;
    id_bypmem_opA : in std_logic;
    id_bypmem_opB : in std_logic;
    id_bypwb_opA : in std_logic;
    id_bypwb_opB : in std_logic;
    id_opA : in std_logic_vector(XLEN-1 downto 0);
    id_opB : in std_logic_vector(XLEN-1 downto 0);

  --from RF
    rf_srcv1 : in std_logic_vector(XLEN-1 downto 0);
    rf_srcv2 : in std_logic_vector(XLEN-1 downto 0);

  --to MEM
    ex_r : out std_logic_vector(XLEN-1 downto 0);

  --Bypasses
    mem_r : in std_logic_vector(XLEN-1 downto 0);
    wb_r : in std_logic_vector(XLEN-1 downto 0);

  --To State
    ex_csr_reg : out std_logic_vector(11 downto 0);
    ex_csr_wval : out std_logic_vector(XLEN-1 downto 0);
    ex_csr_we : out std_logic;

  --From State
    st_prv : in std_logic_vector(1 downto 0);
    st_xlen : in std_logic_vector(1 downto 0);
    st_flush : in std_logic;
    st_csr_rval : in std_logic_vector(XLEN-1 downto 0);

  --To DCACHE/Memory
    dmem_adr : out std_logic_vector(XLEN-1 downto 0);
    dmem_d : out std_logic_vector(XLEN-1 downto 0);
    dmem_req : out std_logic;
    dmem_we : out std_logic;
    dmem_size : out std_logic_vector(2 downto 0);
    dmem_ack : in std_logic;
    dmem_q : in std_logic_vector(XLEN-1 downto 0);
    dmem_misaligned : in std_logic;
    dmem_page_fault : in std_logic;

  --Debug Unit
    du_stall : in std_logic;
    du_stall_dly : in std_logic;
    du_flush : in std_logic;
    du_we_pc : in std_logic;
    du_dato : in std_logic_vector(XLEN-1 downto 0) 
    du_ie : in std_logic_vector(31 downto 0)
  );
  constant XLEN : integer := 64;
  constant ILEN : integer := 64;
  constant EXCEPTION_SIZE : integer := 16;
  constant BP_GLOBAL_BITS : integer := 2;
  constant HAS_RVC : integer := 1;
  constant HAS_RVA : integer := 1;
  constant HAS_RVM : integer := 1;
  constant MULT_LATENCY : integer := 1;
  constant PC_INIT : std_logic_vector(XLEN-1 downto 0) := X"8000_0000";
end riscv_execution;

architecture RTL of riscv_execution is
  component riscv_alu
  generic (
    ? : std_logic_vector(? downto 0) := ?;
    ? : std_logic_vector(? downto 0) := ?;
    ? : std_logic_vector(? downto 0) := ?
  );
  port (
    rstn : std_logic_vector(? downto 0);
    clk : std_logic_vector(? downto 0);
    ex_stall : std_logic_vector(? downto 0);
    id_pc : std_logic_vector(? downto 0);
    id_bubble : std_logic_vector(? downto 0);
    id_instr : std_logic_vector(? downto 0);
    opA : std_logic_vector(? downto 0);
    opB : std_logic_vector(? downto 0);
    alu_bubble : std_logic_vector(? downto 0);
    alu_r : std_logic_vector(? downto 0);
    ex_csr_reg : std_logic_vector(? downto 0);
    ex_csr_wval : std_logic_vector(? downto 0);
    ex_csr_we : std_logic_vector(? downto 0);
    st_csr_rval : std_logic_vector(? downto 0);
    st_xlen : std_logic_vector(? downto 0)
  );
  end component;

  component riscv_lsu
  generic (
    ? : std_logic_vector(? downto 0) := ?;
    ? : std_logic_vector(? downto 0) := ?;
    ? : std_logic_vector(? downto 0) := ?
  );
  port (
    rstn : std_logic_vector(? downto 0);
    clk : std_logic_vector(? downto 0);
    ex_stall : std_logic_vector(? downto 0);
    lsu_stall : std_logic_vector(? downto 0);
    id_bubble : std_logic_vector(? downto 0);
    id_instr : std_logic_vector(? downto 0);
    lsu_bubble : std_logic_vector(? downto 0);
    lsu_r : std_logic_vector(? downto 0);
    id_exception : std_logic_vector(? downto 0);
    ex_exception : std_logic_vector(? downto 0);
    mem_exception : std_logic_vector(? downto 0);
    wb_exception : std_logic_vector(? downto 0);
    lsu_exception : std_logic_vector(? downto 0);
    opA : std_logic_vector(? downto 0);
    opB : std_logic_vector(? downto 0);
    st_xlen : std_logic_vector(? downto 0);
    dmem_adr : std_logic_vector(? downto 0);
    dmem_d : std_logic_vector(? downto 0);
    dmem_req : std_logic_vector(? downto 0);
    dmem_we : std_logic_vector(? downto 0);
    dmem_size : std_logic_vector(? downto 0);
    dmem_ack : std_logic_vector(? downto 0);
    dmem_q : std_logic_vector(? downto 0);
    dmem_misaligned : std_logic_vector(? downto 0);
    dmem_page_fault : std_logic_vector(? downto 0)
  );
  end component;

  component riscv_bu
  generic (
    ? : std_logic_vector(? downto 0) := ?;
    ? : std_logic_vector(? downto 0) := ?;
    ? : std_logic_vector(? downto 0) := ?;
    ? : std_logic_vector(? downto 0) := ?;
    ? : std_logic_vector(? downto 0) := ?;
    ? : std_logic_vector(? downto 0) := ?
  );
  port (
    rstn : std_logic_vector(? downto 0);
    clk : std_logic_vector(? downto 0);
    ex_stall : std_logic_vector(? downto 0);
    st_flush : std_logic_vector(? downto 0);
    id_pc : std_logic_vector(? downto 0);
    bu_nxt_pc : std_logic_vector(? downto 0);
    bu_flush : std_logic_vector(? downto 0);
    bu_cacheflush : std_logic_vector(? downto 0);
    id_bp_predict : std_logic_vector(? downto 0);
    bu_bp_predict : std_logic_vector(? downto 0);
    bu_bp_history : std_logic_vector(? downto 0);
    bu_bp_btaken : std_logic_vector(? downto 0);
    bu_bp_update : std_logic_vector(? downto 0);
    id_bubble : std_logic_vector(? downto 0);
    id_instr : std_logic_vector(? downto 0);
    id_exception : std_logic_vector(? downto 0);
    ex_exception : std_logic_vector(? downto 0);
    mem_exception : std_logic_vector(? downto 0);
    wb_exception : std_logic_vector(? downto 0);
    bu_exception : std_logic_vector(? downto 0);
    opA : std_logic_vector(? downto 0);
    opB : std_logic_vector(? downto 0);
    du_stall : std_logic_vector(? downto 0);
    du_flush : std_logic_vector(? downto 0);
    du_we_pc : std_logic_vector(? downto 0);
    du_dato : std_logic_vector(? downto 0);
    du_ie : std_logic_vector(? downto 0)
  );
  end component;

  component riscv_mul
  generic (
    ? : std_logic_vector(? downto 0) := ?;
    ? : std_logic_vector(? downto 0) := ?
  );
  port (
    rstn : std_logic_vector(? downto 0);
    clk : std_logic_vector(? downto 0);
    ex_stall : std_logic_vector(? downto 0);
    mul_stall : std_logic_vector(? downto 0);
    id_bubble : std_logic_vector(? downto 0);
    id_instr : std_logic_vector(? downto 0);
    opA : std_logic_vector(? downto 0);
    opB : std_logic_vector(? downto 0);
    st_xlen : std_logic_vector(? downto 0);
    mul_bubble : std_logic_vector(? downto 0);
    mul_r : std_logic_vector(? downto 0)
  );
  end component;

  component riscv_div
  generic (
    ? : std_logic_vector(? downto 0) := ?;
    ? : std_logic_vector(? downto 0) := ?
  );
  port (
    rstn : std_logic_vector(? downto 0);
    clk : std_logic_vector(? downto 0);
    ex_stall : std_logic_vector(? downto 0);
    div_stall : std_logic_vector(? downto 0);
    id_bubble : std_logic_vector(? downto 0);
    id_instr : std_logic_vector(? downto 0);
    opA : std_logic_vector(? downto 0);
    opB : std_logic_vector(? downto 0);
    st_xlen : std_logic_vector(? downto 0);
    div_bubble : std_logic_vector(? downto 0);
    div_r : std_logic_vector(? downto 0)
  );
  end component;



  --//////////////////////////////////////////////////////////////
  --
  -- Variables
  --

  --Operand generation
  signal opA : std_logic_vector(XLEN-1 downto 0);
  signal opB : std_logic_vector(XLEN-1 downto 0);

  signal alu_r : std_logic_vector(XLEN-1 downto 0);
  signal lsu_r : std_logic_vector(XLEN-1 downto 0);
  signal mul_r : std_logic_vector(XLEN-1 downto 0);
  signal div_r : std_logic_vector(XLEN-1 downto 0);

  --Pipeline Bubbles
  signal alu_bubble : std_logic;
  signal lsu_bubble : std_logic;
  signal mul_bubble : std_logic;
  signal div_bubble : std_logic;

  --Pipeline stalls
  signal lsu_stall : std_logic;
  signal mul_stall : std_logic;
  signal div_stall : std_logic;

  --Exceptions
  signal bu_exception : std_logic_vector(EXCEPTION_SIZE-1 downto 0);
  signal lsu_exception : std_logic_vector(EXCEPTION_SIZE-1 downto 0);

begin
  --//////////////////////////////////////////////////////////////
  --
  -- Module Body
  --

  --Program Counter
  processing_0 : process (clk, rstn)
  begin
    if (not rstn) then
      ex_pc <= PC_INIT;
    elsif (rising_edge(clk)) then
      if (not ex_stall and not du_stall) then    --stall during DBG to retain PPC
        ex_pc <= id_pc;
      end if;
    end if;
  end process;


  --Instruction
  processing_1 : process (clk)
  begin
    if (rising_edge(clk)) then
      if (not ex_stall) then
        ex_instr <= id_instr;
      end if;
    end if;
  end process;


  --Bypasses

  --Ignore the bypasses during dbg_stall, use register-file instead
  --use du_stall_dly, because this is combinatorial
  --When the pipeline is longer than the time for the debugger to access the system, this fails
  processing_2 : process
  begin
    case (((id_userf_opA & id_bypwb_opA & id_bypmem_opA & id_bypex_opA))) is
    when "???1" =>
      opA <= rf_srcv1
      when du_stall_dly else ex_r;
    when "??10" =>
      opA <= rf_srcv1
      when du_stall_dly else mem_r;
    when "?100" =>
      opA <= rf_srcv1
      when du_stall_dly else wb_r;
    when "1000" =>
      opA <= rf_srcv1;
    when others =>
      opA <= id_opA;
    end case;
  end process;


  processing_3 : process
  begin
    case (((id_userf_opB & id_bypwb_opB & id_bypmem_opB & id_bypex_opB))) is
    when "???1" =>
      opB <= rf_srcv2
      when du_stall_dly else ex_r;
    when "??10" =>
      opB <= rf_srcv2
      when du_stall_dly else mem_r;
    when "?100" =>
      opB <= rf_srcv2
      when du_stall_dly else wb_r;
    when "1000" =>
      opB <= rf_srcv2;
    when others =>
      opB <= id_opB;
    end case;
  end process;


  --Execution Units
  alu : riscv_alu
  generic map (
    XLEN, 
    ILEN, 
    HAS_RVC
  )
  port map (
    rstn => rstn,
    clk => clk,
    ex_stall => ex_stall,
    id_pc => id_pc,
    id_bubble => id_bubble,
    id_instr => id_instr,
    opA => opA,
    opB => opB,
    alu_bubble => alu_bubble,
    alu_r => alu_r,
    ex_csr_reg => ex_csr_reg,
    ex_csr_wval => ex_csr_wval,
    ex_csr_we => ex_csr_we,
    st_csr_rval => st_csr_rval,
    st_xlen => st_xlen
  );


  -- Load-Store Unit
  lsu : riscv_lsu
  generic map (
    XLEN, 
    ILEN, 
    EXCEPTION_SIZE
  )
  port map (
    rstn => rstn,
    clk => clk,
    ex_stall => ex_stall,
    lsu_stall => lsu_stall,
    id_bubble => id_bubble,
    id_instr => id_instr,
    lsu_bubble => lsu_bubble,
    lsu_r => lsu_r,
    id_exception => id_exception,
    ex_exception => ex_exception,
    mem_exception => mem_exception,
    wb_exception => wb_exception,
    lsu_exception => lsu_exception,
    opA => opA,
    opB => opB,
    st_xlen => st_xlen,
    dmem_adr => dmem_adr,
    dmem_d => dmem_d,
    dmem_req => dmem_req,
    dmem_we => dmem_we,
    dmem_size => dmem_size,
    dmem_ack => dmem_ack,
    dmem_q => dmem_q,
    dmem_misaligned => dmem_misaligned,
    dmem_page_fault => dmem_page_fault
  );


  -- Branch Unit
  bu : riscv_bu
  generic map (
    XLEN, 
    ILEN, 
    EXCEPTION_SIZE, 
    PC_INIT, 
    BP_GLOBAL_BITS, 
    HAS_RVC
  )
  port map (
    rstn => rstn,
    clk => clk,
    ex_stall => ex_stall,
    st_flush => st_flush,
    id_pc => id_pc,
    bu_nxt_pc => bu_nxt_pc,
    bu_flush => bu_flush,
    bu_cacheflush => bu_cacheflush,
    id_bp_predict => id_bp_predict,
    bu_bp_predict => bu_bp_predict,
    bu_bp_history => bu_bp_history,
    bu_bp_btaken => bu_bp_btaken,
    bu_bp_update => bu_bp_update,
    id_bubble => id_bubble,
    id_instr => id_instr,
    id_exception => id_exception,
    ex_exception => ex_exception,
    mem_exception => mem_exception,
    wb_exception => wb_exception,
    bu_exception => ex_exception,
    opA => opA,
    opB => opB,
    du_stall => du_stall,
    du_flush => du_flush,
    du_we_pc => du_we_pc,
    du_dato => du_dato,
    du_ie => du_ie
  );


  if (HAS_RVM) generate
    mul : riscv_mul
    generic map (
      XLEN, 
      ILEN
    )
    port map (
      rstn => rstn,
      clk => clk,
      ex_stall => ex_stall,
      mul_stall => mul_stall,
      id_bubble => id_bubble,
      id_instr => id_instr,
      opA => opA,
      opB => opB,
      st_xlen => st_xlen,
      mul_bubble => mul_bubble,
      mul_r => mul_r
    );


    div : riscv_div
    generic map (
      XLEN, 
      ILEN
    )
    port map (
      rstn => rstn,
      clk => clk,
      ex_stall => ex_stall,
      div_stall => div_stall,
      id_bubble => id_bubble,
      id_instr => id_instr,
      opA => opA,
      opB => opB,
      st_xlen => st_xlen,
      div_bubble => div_bubble,
      div_r => div_r
    );
  else generate
    mul_bubble <= '1';
    mul_r <= X"0";
    mul_stall <= '0';

    div_bubble <= '1';
    div_r <= X"0";
    div_stall <= '0';
  end generate;


  --Combine outputs into 1 single EX output
  ex_bubble <= alu_bubble and lsu_bubble and mul_bubble and div_bubble;
  ex_stall <= wb_stall or lsu_stall or mul_stall or div_stall;

  --result
  processing_4 : process
  begin
    case (((mul_bubble & div_bubble & lsu_bubble))) is
    when "110" =>
      ex_r <= lsu_r;
    when "101" =>
      ex_r <= div_r;
    when "011" =>
      ex_r <= mul_r;
    when others =>
      ex_r <= alu_r;
    end case;
  end process;
end RTL;
