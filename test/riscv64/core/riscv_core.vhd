-- Converted from core/riscv_core.sv
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
--              Core - Core                                                   //
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

entity riscv_core is
  port (




















    rstn : in std_logic;  --Reset
    clk : in std_logic;  --Clock

  --Instruction Memory Access bus
    if_stall_nxt_pc : in std_logic;
    if_nxt_pc : out std_logic_vector(XLEN-1 downto 0);
    if_stall : out std_logic;
    if_flush : out std_logic;
    if_parcel : in std_logic_vector(PARCEL_SIZE-1 downto 0);
    if_parcel_pc : in std_logic_vector(XLEN-1 downto 0);
    if_parcel_valid : in std_logic_vector(PARCEL_SIZE/16-1 downto 0);
    if_parcel_misaligned : in std_logic;
    if_parcel_page_fault : in std_logic;

  --Data Memory Access bus
    dmem_adr, dmem_d : out std_logic_vector(XLEN-1 downto 0);
    dmem_q : in std_logic_vector(XLEN-1 downto 0);
    dmem_we : out std_logic;
    dmem_size : out std_logic_vector(2 downto 0);
    dmem_req : out std_logic;
    dmem_ack : in std_logic;
    dmem_err : in std_logic;
    dmem_misaligned : in std_logic;
    dmem_page_fault : in std_logic;

  --cpu state
    st_prv : out std_logic_vector(1 downto 0);
    st_pmpcfg : out std_logic_vector(7 downto 0);
    st_pmpaddr : out std_logic_vector(XLEN-1 downto 0);

    bu_cacheflush : out std_logic;

  --Interrupts
    ext_nmi : in std_logic;
    ext_tint : in std_logic;
    ext_sint : in std_logic;
    ext_int : in std_logic_vector(3 downto 0);

  --Debug Interface
    dbg_stall : in std_logic;
    dbg_strb : in std_logic;
    dbg_we : in std_logic;
    dbg_addr : in std_logic_vector(PLEN-1 downto 0);
    dbg_dati : in std_logic_vector(XLEN-1 downto 0);
    dbg_dato : out std_logic_vector(XLEN-1 downto 0);
    dbg_ack : out std_logic 
    dbg_bp : out std_logic
  );
  constant XLEN : integer := 64;
  constant PLEN : integer := 64;
  constant ILEN : integer := 64;
  constant EXCEPTION_SIZE : integer := 16;
  constant PC_INIT : std_logic_vector(XLEN-1 downto 0) := X"200";
  constant HAS_USER : integer := 1;
  constant HAS_SUPER : integer := 1;
  constant HAS_HYPER : integer := 1;
  constant HAS_BPU : integer := 1;
  constant HAS_FPU : integer := 1;
  constant HAS_MMU : integer := 1;
  constant HAS_RVA : integer := 1;
  constant HAS_RVM : integer := 1;
  constant HAS_RVC : integer := 1;
  constant IS_RV32E : integer := 1;
  constant MULT_LATENCY : integer := 1;
  constant BREAKPOINTS : integer := 8;
  constant PMA_CNT : integer := 4;
  constant PMP_CNT : integer := 16;
  constant BP_GLOBAL_BITS : integer := 2;
  constant BP_LOCAL_BITS : integer := 10;
  constant BP_LOCAL_BITS_LSB : integer := 2;
  constant DU_ADDR_SIZE : integer := 12;
  constant MAX_BREAKPOINTS : integer := 8;
  constant TECHNOLOGY : integer := "GENERIC";
  constant MNMIVEC_DEFAULT : integer := PC_INIT-X"004";
  constant MTVEC_DEFAULT : integer := PC_INIT-X"040";
  constant HTVEC_DEFAULT : integer := PC_INIT-X"080";
  constant STVEC_DEFAULT : integer := PC_INIT-X"0C0";
  constant UTVEC_DEFAULT : integer := PC_INIT-X"100";
  constant JEDEC_BANK : integer := 10;
  constant JEDEC_MANUFACTURER_ID : integer := X"6e";
  constant HARTID : integer := 0;
  constant PARCEL_SIZE : integer := 64;
end riscv_core;

architecture RTL of riscv_core is
  component riscv_if
  generic (
    ? : std_logic_vector(? downto 0) := ?;
    ? : std_logic_vector(? downto 0) := ?;
    ? : std_logic_vector(? downto 0) := ?;
    ? : std_logic_vector(? downto 0) := ?
  );
  port (
    rstn : std_logic_vector(? downto 0);
    clk : std_logic_vector(? downto 0);
    id_stall : std_logic_vector(? downto 0);
    if_stall_nxt_pc : std_logic_vector(? downto 0);
    if_parcel : std_logic_vector(? downto 0);
    if_parcel_pc : std_logic_vector(? downto 0);
    if_parcel_valid : std_logic_vector(? downto 0);
    if_parcel_misaligned : std_logic_vector(? downto 0);
    if_parcel_page_fault : std_logic_vector(? downto 0);
    if_instr : std_logic_vector(? downto 0);
    if_bubble : std_logic_vector(? downto 0);
    if_exception : std_logic_vector(? downto 0);
    bp_bp_predict : std_logic_vector(? downto 0);
    if_bp_predict : std_logic_vector(? downto 0);
    bu_flush : std_logic_vector(? downto 0);
    st_flush : std_logic_vector(? downto 0);
    du_flush : std_logic_vector(? downto 0);
    bu_nxt_pc : std_logic_vector(? downto 0);
    st_nxt_pc : std_logic_vector(? downto 0);
    if_nxt_pc : std_logic_vector(? downto 0);
    if_stall : std_logic_vector(? downto 0);
    if_flush : std_logic_vector(? downto 0);
    if_pc : std_logic_vector(? downto 0)
  );
  end component;

  component riscv_id
  generic (
    ? : std_logic_vector(? downto 0) := ?;
    ? : std_logic_vector(? downto 0) := ?;
    ? : std_logic_vector(? downto 0) := ?
  );
  port (
    rstn : std_logic_vector(? downto 0);
    clk : std_logic_vector(? downto 0);
    id_stall : std_logic_vector(? downto 0);
    ex_stall : std_logic_vector(? downto 0);
    du_stall : std_logic_vector(? downto 0);
    bu_flush : std_logic_vector(? downto 0);
    st_flush : std_logic_vector(? downto 0);
    du_flush : std_logic_vector(? downto 0);
    bu_nxt_pc : std_logic_vector(? downto 0);
    st_nxt_pc : std_logic_vector(? downto 0);
    if_pc : std_logic_vector(? downto 0);
    id_pc : std_logic_vector(? downto 0);
    if_bp_predict : std_logic_vector(? downto 0);
    id_bp_predict : std_logic_vector(? downto 0);
    if_instr : std_logic_vector(? downto 0);
    if_bubble : std_logic_vector(? downto 0);
    id_instr : std_logic_vector(? downto 0);
    id_bubble : std_logic_vector(? downto 0);
    ex_instr : std_logic_vector(? downto 0);
    ex_bubble : std_logic_vector(? downto 0);
    mem_instr : std_logic_vector(? downto 0);
    mem_bubble : std_logic_vector(? downto 0);
    wb_instr : std_logic_vector(? downto 0);
    wb_bubble : std_logic_vector(? downto 0);
    if_exception : std_logic_vector(? downto 0);
    ex_exception : std_logic_vector(? downto 0);
    mem_exception : std_logic_vector(? downto 0);
    wb_exception : std_logic_vector(? downto 0);
    id_exception : std_logic_vector(? downto 0);
    st_prv : std_logic_vector(? downto 0);
    st_xlen : std_logic_vector(? downto 0);
    st_tvm : std_logic_vector(? downto 0);
    st_tw : std_logic_vector(? downto 0);
    st_tsr : std_logic_vector(? downto 0);
    st_mcounteren : std_logic_vector(? downto 0);
    st_scounteren : std_logic_vector(? downto 0);
    id_src1 : std_logic_vector(? downto 0);
    id_src2 : std_logic_vector(? downto 0);
    id_opA : std_logic_vector(? downto 0);
    id_opB : std_logic_vector(? downto 0);
    id_userf_opA : std_logic_vector(? downto 0);
    id_userf_opB : std_logic_vector(? downto 0);
    id_bypex_opA : std_logic_vector(? downto 0);
    id_bypex_opB : std_logic_vector(? downto 0);
    id_bypmem_opA : std_logic_vector(? downto 0);
    id_bypmem_opB : std_logic_vector(? downto 0);
    id_bypwb_opA : std_logic_vector(? downto 0);
    id_bypwb_opB : std_logic_vector(? downto 0);
    mem_r : std_logic_vector(? downto 0);
    wb_r : std_logic_vector(? downto 0)
  );
  end component;

  component riscv_execution
  generic (
    ? : std_logic_vector(? downto 0) := ?;
    ? : std_logic_vector(? downto 0) := ?;
    ? : std_logic_vector(? downto 0) := ?;
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
    wb_stall : std_logic_vector(? downto 0);
    ex_stall : std_logic_vector(? downto 0);
    id_pc : std_logic_vector(? downto 0);
    ex_pc : std_logic_vector(? downto 0);
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
    ex_bubble : std_logic_vector(? downto 0);
    ex_instr : std_logic_vector(? downto 0);
    id_exception : std_logic_vector(? downto 0);
    mem_exception : std_logic_vector(? downto 0);
    wb_exception : std_logic_vector(? downto 0);
    ex_exception : std_logic_vector(? downto 0);
    id_userf_opA : std_logic_vector(? downto 0);
    id_userf_opB : std_logic_vector(? downto 0);
    id_bypex_opA : std_logic_vector(? downto 0);
    id_bypex_opB : std_logic_vector(? downto 0);
    id_bypmem_opA : std_logic_vector(? downto 0);
    id_bypmem_opB : std_logic_vector(? downto 0);
    id_bypwb_opA : std_logic_vector(? downto 0);
    id_bypwb_opB : std_logic_vector(? downto 0);
    id_opA : std_logic_vector(? downto 0);
    id_opB : std_logic_vector(? downto 0);
    rf_srcv1 : std_logic_vector(? downto 0);
    rf_srcv2 : std_logic_vector(? downto 0);
    ex_r : std_logic_vector(? downto 0);
    mem_r : std_logic_vector(? downto 0);
    wb_r : std_logic_vector(? downto 0);
    ex_csr_reg : std_logic_vector(? downto 0);
    ex_csr_wval : std_logic_vector(? downto 0);
    ex_csr_we : std_logic_vector(? downto 0);
    st_prv : std_logic_vector(? downto 0);
    st_xlen : std_logic_vector(? downto 0);
    st_flush : std_logic_vector(? downto 0);
    st_csr_rval : std_logic_vector(? downto 0);
    dmem_adr : std_logic_vector(? downto 0);
    dmem_d : std_logic_vector(? downto 0);
    dmem_req : std_logic_vector(? downto 0);
    dmem_we : std_logic_vector(? downto 0);
    dmem_size : std_logic_vector(? downto 0);
    dmem_ack : std_logic_vector(? downto 0);
    dmem_q : std_logic_vector(? downto 0);
    dmem_misaligned : std_logic_vector(? downto 0);
    dmem_page_fault : std_logic_vector(? downto 0);
    du_stall : std_logic_vector(? downto 0);
    du_stall_dly : std_logic_vector(? downto 0);
    du_flush : std_logic_vector(? downto 0);
    du_we_pc : std_logic_vector(? downto 0);
    du_dato : std_logic_vector(? downto 0);
    du_ie : std_logic_vector(? downto 0)
  );
  end component;

  component riscv_memory
  generic (
    ? : std_logic_vector(? downto 0) := ?;
    ? : std_logic_vector(? downto 0) := ?;
    ? : std_logic_vector(? downto 0) := ?;
    ? : std_logic_vector(? downto 0) := ?
  );
  port (
    rstn : std_logic_vector(? downto 0);
    clk : std_logic_vector(? downto 0);
    wb_stall : std_logic_vector(? downto 0);
    ex_pc : std_logic_vector(? downto 0);
    mem_pc : std_logic_vector(? downto 0);
    ex_bubble : std_logic_vector(? downto 0);
    ex_instr : std_logic_vector(? downto 0);
    mem_bubble : std_logic_vector(? downto 0);
    mem_instr : std_logic_vector(? downto 0);
    ex_exception : std_logic_vector(? downto 0);
    wb_exception : std_logic_vector(? downto 0);
    mem_exception : std_logic_vector(? downto 0);
    ex_r : std_logic_vector(? downto 0);
    dmem_adr : std_logic_vector(? downto 0);
    mem_r : std_logic_vector(? downto 0);
    mem_memadr : std_logic_vector(? downto 0)
  );
  end component;

  component riscv_wb
  generic (
    ? : std_logic_vector(? downto 0) := ?;
    ? : std_logic_vector(? downto 0) := ?;
    ? : std_logic_vector(? downto 0) := ?;
    ? : std_logic_vector(? downto 0) := ?
  );
  port (
    rst_ni : std_logic_vector(? downto 0);
    clk_i : std_logic_vector(? downto 0);
    mem_pc_i : std_logic_vector(? downto 0);
    mem_instr_i : std_logic_vector(? downto 0);
    mem_bubble_i : std_logic_vector(? downto 0);
    mem_r_i : std_logic_vector(? downto 0);
    mem_exception_i : std_logic_vector(? downto 0);
    mem_memadr_i : std_logic_vector(? downto 0);
    wb_pc_o : std_logic_vector(? downto 0);
    wb_stall_o : std_logic_vector(? downto 0);
    wb_instr_o : std_logic_vector(? downto 0);
    wb_bubble_o : std_logic_vector(? downto 0);
    wb_exception_o : std_logic_vector(? downto 0);
    wb_badaddr_o : std_logic_vector(? downto 0);
    dmem_ack_i : std_logic_vector(? downto 0);
    dmem_err_i : std_logic_vector(? downto 0);
    dmem_q_i : std_logic_vector(? downto 0);
    dmem_misaligned_i : std_logic_vector(? downto 0);
    dmem_page_fault_i : std_logic_vector(? downto 0);
    wb_dst_o : std_logic_vector(? downto 0);
    wb_r_o : std_logic_vector(? downto 0);
    wb_we_o : std_logic_vector(? downto 0)
  );
  end component;

  component riscv_state
  generic (
    ? : std_logic_vector(? downto 0) := ?;
    ? : std_logic_vector(? downto 0) := ?;
    ? : std_logic_vector(? downto 0) := ?;
    ? : std_logic_vector(? downto 0) := ?;
    ? : std_logic_vector(? downto 0) := ?;
    ? : std_logic_vector(? downto 0) := ?;
    ? : std_logic_vector(? downto 0) := ?;
    ? : std_logic_vector(? downto 0) := ?;
    ? : std_logic_vector(? downto 0) := ?;
    ? : std_logic_vector(? downto 0) := ?;
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
    id_pc : std_logic_vector(? downto 0);
    id_bubble : std_logic_vector(? downto 0);
    id_instr : std_logic_vector(? downto 0);
    id_stall : std_logic_vector(? downto 0);
    bu_flush : std_logic_vector(? downto 0);
    bu_nxt_pc : std_logic_vector(? downto 0);
    st_flush : std_logic_vector(? downto 0);
    st_nxt_pc : std_logic_vector(? downto 0);
    wb_pc : std_logic_vector(? downto 0);
    wb_bubble : std_logic_vector(? downto 0);
    wb_instr : std_logic_vector(? downto 0);
    wb_exception : std_logic_vector(? downto 0);
    wb_badaddr : std_logic_vector(? downto 0);
    st_interrupt : std_logic_vector(? downto 0);
    st_prv : std_logic_vector(? downto 0);
    st_xlen : std_logic_vector(? downto 0);
    st_tvm : std_logic_vector(? downto 0);
    st_tw : std_logic_vector(? downto 0);
    st_tsr : std_logic_vector(? downto 0);
    st_mcounteren : std_logic_vector(? downto 0);
    st_scounteren : std_logic_vector(? downto 0);
    st_pmpcfg : std_logic_vector(? downto 0);
    st_pmpaddr : std_logic_vector(? downto 0);
    ext_int : std_logic_vector(? downto 0);
    ext_tint : std_logic_vector(? downto 0);
    ext_sint : std_logic_vector(? downto 0);
    ext_nmi : std_logic_vector(? downto 0);
    ex_csr_reg : std_logic_vector(? downto 0);
    ex_csr_we : std_logic_vector(? downto 0);
    ex_csr_wval : std_logic_vector(? downto 0);
    st_csr_rval : std_logic_vector(? downto 0);
    du_stall : std_logic_vector(? downto 0);
    du_flush : std_logic_vector(? downto 0);
    du_we_csr : std_logic_vector(? downto 0);
    du_dato : std_logic_vector(? downto 0);
    du_addr : std_logic_vector(? downto 0);
    du_ie : std_logic_vector(? downto 0);
    du_exceptions : std_logic_vector(? downto 0)
  );
  end component;

  component riscv_rf
  generic (
    ? : std_logic_vector(? downto 0) := ?;
    ? : std_logic_vector(? downto 0) := ?;
    ? : std_logic_vector(? downto 0) := ?;
    ? : std_logic_vector(? downto 0) := ?
  );
  port (
    rstn : std_logic_vector(? downto 0);
    clk : std_logic_vector(? downto 0);
    rf_src1 : std_logic_vector(? downto 0);
    rf_src2 : std_logic_vector(? downto 0);
    rf_srcv1 : std_logic_vector(? downto 0);
    rf_srcv2 : std_logic_vector(? downto 0);
    rf_dst : std_logic_vector(? downto 0);
    rf_dstv : std_logic_vector(? downto 0);
    rf_we : std_logic_vector(? downto 0);
    du_stall : std_logic_vector(? downto 0);
    du_we_rf : std_logic_vector(? downto 0);
    du_dato : std_logic_vector(? downto 0);
    du_dati_rf : std_logic_vector(? downto 0);
    du_addr : std_logic_vector(? downto 0)
  );
  end component;

  component riscv_bp
  generic (
    ? : std_logic_vector(? downto 0) := ?;
    ? : std_logic_vector(? downto 0) := ?;
    ? : std_logic_vector(? downto 0) := ?;
    ? : std_logic_vector(? downto 0) := ?;
    ? : std_logic_vector(? downto 0) := ?;
    ? : std_logic_vector(? downto 0) := ?
  );
  port (
    rst_ni : std_logic_vector(? downto 0);
    clk_i : std_logic_vector(? downto 0);
    id_stall_i : std_logic_vector(? downto 0);
    if_parcel_pc_i : std_logic_vector(? downto 0);
    bp_bp_predict_o : std_logic_vector(? downto 0);
    ex_pc_i : std_logic_vector(? downto 0);
    bu_bp_history_i : std_logic_vector(? downto 0);
    bu_bp_predict_i : std_logic_vector(? downto 0);
    bu_bp_btaken_i : std_logic_vector(? downto 0);
    bu_bp_update_i : std_logic_vector(? downto 0)
  );
  end component;

  component riscv_du
  generic (
    ? : std_logic_vector(? downto 0) := ?;
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
    dbg_stall : std_logic_vector(? downto 0);
    dbg_strb : std_logic_vector(? downto 0);
    dbg_we : std_logic_vector(? downto 0);
    dbg_addr : std_logic_vector(? downto 0);
    dbg_dati : std_logic_vector(? downto 0);
    dbg_dato : std_logic_vector(? downto 0);
    dbg_ack : std_logic_vector(? downto 0);
    dbg_bp : std_logic_vector(? downto 0);
    du_stall : std_logic_vector(? downto 0);
    du_stall_dly : std_logic_vector(? downto 0);
    du_flush : std_logic_vector(? downto 0);
    du_we_rf : std_logic_vector(? downto 0);
    du_we_frf : std_logic_vector(? downto 0);
    du_we_csr : std_logic_vector(? downto 0);
    du_we_pc : std_logic_vector(? downto 0);
    du_addr : std_logic_vector(? downto 0);
    du_dato : std_logic_vector(? downto 0);
    du_ie : std_logic_vector(? downto 0);
    du_dati_rf : std_logic_vector(? downto 0);
    du_dati_frf : std_logic_vector(? downto 0);
    st_csr_rval : std_logic_vector(? downto 0);
    if_pc : std_logic_vector(? downto 0);
    id_pc : std_logic_vector(? downto 0);
    ex_pc : std_logic_vector(? downto 0);
    bu_nxt_pc : std_logic_vector(? downto 0);
    bu_flush : std_logic_vector(? downto 0);
    st_flush : std_logic_vector(? downto 0);
    if_instr : std_logic_vector(? downto 0);
    mem_instr : std_logic_vector(? downto 0);
    if_bubble : std_logic_vector(? downto 0);
    mem_bubble : std_logic_vector(? downto 0);
    mem_exception : std_logic_vector(? downto 0);
    mem_memadr : std_logic_vector(? downto 0);
    dmem_ack : std_logic_vector(? downto 0);
    ex_stall : std_logic_vector(? downto 0);
    du_exceptions : std_logic_vector(? downto 0)
  );
  end component;



  --//////////////////////////////////////////////////////////////
  --
  -- Variables
  --

  signal bu_nxt_pc : std_logic_vector(XLEN-1 downto 0);
  signal st_nxt_pc : std_logic_vector(XLEN-1 downto 0);
  signal if_pc : std_logic_vector(XLEN-1 downto 0);
  signal id_pc : std_logic_vector(XLEN-1 downto 0);
  signal ex_pc : std_logic_vector(XLEN-1 downto 0);
  signal mem_pc : std_logic_vector(XLEN-1 downto 0);
  signal wb_pc : std_logic_vector(XLEN-1 downto 0);

  signal if_instr : std_logic_vector(ILEN-1 downto 0);
  signal id_instr : std_logic_vector(ILEN-1 downto 0);
  signal ex_instr : std_logic_vector(ILEN-1 downto 0);
  signal mem_instr : std_logic_vector(ILEN-1 downto 0);
  signal wb_instr : std_logic_vector(ILEN-1 downto 0);

  signal if_bubble : std_logic;
  signal id_bubble : std_logic;
  signal ex_bubble : std_logic;
  signal mem_bubble : std_logic;
  signal wb_bubble : std_logic;

  signal bu_flush : std_logic;
  signal st_flush : std_logic;
  signal du_flush : std_logic;

  signal id_stall : std_logic;
  signal ex_stall : std_logic;
  signal wb_stall : std_logic;
  signal du_stall : std_logic;
  signal du_stall_dly : std_logic;

  --Branch Prediction
  signal bp_bp_predict : std_logic_vector(1 downto 0);
  signal if_bp_predict : std_logic_vector(1 downto 0);
  signal id_bp_predict : std_logic_vector(1 downto 0);
  signal bu_bp_predict : std_logic_vector(1 downto 0);

  signal bu_bp_history : std_logic_vector(BP_GLOBAL_BITS-1 downto 0);
  signal bu_bp_btaken : std_logic;
  signal bu_bp_update : std_logic;


  --Exceptions
  signal if_exception : std_logic_vector(EXCEPTION_SIZE-1 downto 0);
  signal id_exception : std_logic_vector(EXCEPTION_SIZE-1 downto 0);
  signal ex_exception : std_logic_vector(EXCEPTION_SIZE-1 downto 0);
  signal mem_exception : std_logic_vector(EXCEPTION_SIZE-1 downto 0);
  signal wb_exception : std_logic_vector(EXCEPTION_SIZE-1 downto 0);

  --RF access
  constant AR_BITS : integer := 5;
  constant RDPORTS : integer := 2;
  constant WRPORTS : integer := 1;

  signal id_srcv2 : std_logic_vector(XLEN-1 downto 0);
  signal rf_src1 : std_logic_vector(AR_BITS-1 downto 0);
  signal rf_src2 : std_logic_vector(AR_BITS-1 downto 0);
  signal rf_dst : std_logic_vector(AR_BITS-1 downto 0);
  signal rf_srcv1 : std_logic_vector(XLEN-1 downto 0);
  signal rf_srcv2 : std_logic_vector(XLEN-1 downto 0);
  signal rf_dstv : std_logic_vector(XLEN-1 downto 0);
  signal rf_we : std_logic_vector(WRPORTS-1 downto 0);

  --ALU signals
  signal id_opA : std_logic_vector(XLEN-1 downto 0);
  signal id_opB : std_logic_vector(XLEN-1 downto 0);
  signal ex_r : std_logic_vector(XLEN-1 downto 0);
  signal ex_memadr : std_logic_vector(XLEN-1 downto 0);
  signal mem_r : std_logic_vector(XLEN-1 downto 0);
  signal mem_memadr : std_logic_vector(XLEN-1 downto 0);

  signal id_userf_opA : std_logic;
  signal id_userf_opB : std_logic;
  signal id_bypex_opA : std_logic;
  signal id_bypex_opB : std_logic;
  signal id_bypmem_opA : std_logic;
  signal id_bypmem_opB : std_logic;
  signal id_bypwb_opA : std_logic;
  signal id_bypwb_opB : std_logic;

  --CPU state
  signal st_xlen : std_logic_vector(1 downto 0);
  signal st_tvm : std_logic;
  signal st_tw : std_logic;
  signal st_tsr : std_logic;
  signal st_mcounteren : std_logic_vector(XLEN-1 downto 0);
  signal st_scounteren : std_logic_vector(XLEN-1 downto 0);
  signal st_interrupt : std_logic;
  signal ex_csr_reg : std_logic_vector(11 downto 0);
  signal ex_csr_wval : std_logic_vector(XLEN-1 downto 0);
  signal st_csr_rval : std_logic_vector(XLEN-1 downto 0);
  signal ex_csr_we : std_logic;

  --Write back
  signal wb_dst : std_logic_vector(4 downto 0);
  signal wb_r : std_logic_vector(XLEN-1 downto 0);
  signal wb_we : std_logic_vector(0 downto 0);
  signal wb_badaddr : std_logic_vector(XLEN-1 downto 0);

  --Debug
  signal du_we_rf : std_logic;
  signal du_we_frf : std_logic;
  signal du_we_csr : std_logic;
  signal du_we_pc : std_logic;
  signal du_addr : std_logic_vector(DU_ADDR_SIZE-1 downto 0);
  signal du_dato : std_logic_vector(XLEN-1 downto 0);
  signal du_dati_rf : std_logic_vector(XLEN-1 downto 0);
  signal du_dati_frf : std_logic_vector(XLEN-1 downto 0);
  signal du_dati_csr : std_logic_vector(XLEN-1 downto 0);
  signal du_ie : std_logic_vector(31 downto 0);
  signal du_exceptions : std_logic_vector(31 downto 0);

begin
  --//////////////////////////////////////////////////////////////
  --
  -- Module Body
  --

  --
--   * Instruction Fetch
--   *
--   * Calculate next Program Counter
--   * Fetch next instruction
--   */

  if_unit : riscv_if
  generic map (
    XLEN, 
    ILEN, 

    PARCEL_SIZE, 
    EXCEPTION_SIZE
  )
  port map (
    rstn => rstn,
    clk => clk,
    id_stall => id_stall,
    if_stall_nxt_pc => if_stall_nxt_pc,
    if_parcel => if_parcel,
    if_parcel_pc => if_parcel_pc,
    if_parcel_valid => if_parcel_valid,
    if_parcel_misaligned => if_parcel_misaligned,
    if_parcel_page_fault => if_parcel_page_fault,
    if_instr => if_instr,
    if_bubble => if_bubble,
    if_exception => if_exception,
    bp_bp_predict => bp_bp_predict,
    if_bp_predict => if_bp_predict,
    bu_flush => bu_flush,
    st_flush => st_flush,
    du_flush => du_flush,
    bu_nxt_pc => bu_nxt_pc,
    st_nxt_pc => st_nxt_pc,
    if_nxt_pc => if_nxt_pc,
    if_stall => if_stall,
    if_flush => if_flush,
    if_pc => if_pc
  );


  --
--   * Instruction Decoder
--   *
--   * Data from RF/ROB is available here
--   */

  id_unit : riscv_id
  generic map (
    XLEN, 
    ILEN, 

    EXCEPTION_SIZE
  )
  port map (
    rstn => rstn,
    clk => clk,
    id_stall => id_stall,
    ex_stall => ex_stall,
    du_stall => du_stall,
    bu_flush => bu_flush,
    st_flush => st_flush,
    du_flush => du_flush,
    bu_nxt_pc => bu_nxt_pc,
    st_nxt_pc => st_nxt_pc,
    if_pc => if_pc,
    id_pc => id_pc,
    if_bp_predict => if_bp_predict,
    id_bp_predict => id_bp_predict,
    if_instr => if_instr,
    if_bubble => if_bubble,
    id_instr => id_instr,
    id_bubble => id_bubble,
    ex_instr => ex_instr,
    ex_bubble => ex_bubble,
    mem_instr => mem_instr,
    mem_bubble => mem_bubble,
    wb_instr => wb_instr,
    wb_bubble => wb_bubble,
    if_exception => if_exception,
    ex_exception => ex_exception,
    mem_exception => mem_exception,
    wb_exception => wb_exception,
    id_exception => id_exception,
    st_prv => st_prv,
    st_xlen => st_xlen,
    st_tvm => st_tvm,
    st_tw => st_tw,
    st_tsr => st_tsr,
    st_mcounteren => st_mcounteren,
    st_scounteren => st_scounteren,

    id_src1 => rf_src1(0),
    id_src2 => rf_src2(0),

    id_opA => id_opA,
    id_opB => id_opB,
    id_userf_opA => id_userf_opA,
    id_userf_opB => id_userf_opB,
    id_bypex_opA => id_bypex_opA,
    id_bypex_opB => id_bypex_opB,
    id_bypmem_opA => id_bypmem_opA,
    id_bypmem_opB => id_bypmem_opB,
    id_bypwb_opA => id_bypwb_opA,
    id_bypwb_opB => id_bypwb_opB,
    mem_r => mem_r,
    wb_r => wb_r
  );


  --Execution units
  execution_unit : riscv_execution
  generic map (
    XLEN, 
    ILEN, 

    EXCEPTION_SIZE, 
    BP_GLOBAL_BITS, 

    HAS_RVC, 
    HAS_RVA, 
    HAS_RVM, 

    MULT_LATENCY, 

    PC_INIT

  )
  port map (
    rstn => rstn,
    clk => clk,
    wb_stall => wb_stall,
    ex_stall => ex_stall,
    id_pc => id_pc,
    ex_pc => ex_pc,
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
    ex_bubble => ex_bubble,
    ex_instr => ex_instr,
    id_exception => id_exception,
    mem_exception => mem_exception,
    wb_exception => wb_exception,
    ex_exception => ex_exception,
    id_userf_opA => id_userf_opA,
    id_userf_opB => id_userf_opB,
    id_bypex_opA => id_bypex_opA,
    id_bypex_opB => id_bypex_opB,
    id_bypmem_opA => id_bypmem_opA,
    id_bypmem_opB => id_bypmem_opB,
    id_bypwb_opA => id_bypwb_opA,
    id_bypwb_opB => id_bypwb_opB,
    id_opA => id_opA,
    id_opB => id_opB,

    rf_srcv1 => rf_srcv1(0),
    rf_srcv2 => rf_srcv2(0),

    ex_r => ex_r,
    mem_r => mem_r,
    wb_r => wb_r,
    ex_csr_reg => ex_csr_reg,
    ex_csr_wval => ex_csr_wval,
    ex_csr_we => ex_csr_we,
    st_prv => st_prv,
    st_xlen => st_xlen,
    st_flush => st_flush,
    st_csr_rval => st_csr_rval,
    dmem_adr => dmem_adr,
    dmem_d => dmem_d,
    dmem_req => dmem_req,
    dmem_we => dmem_we,
    dmem_size => dmem_size,
    dmem_ack => dmem_ack,
    dmem_q => dmem_q,
    dmem_misaligned => dmem_misaligned,
    dmem_page_fault => dmem_page_fault,
    du_stall => du_stall,
    du_stall_dly => du_stall_dly,
    du_flush => du_flush,
    du_we_pc => du_we_pc,
    du_dato => du_dato,
    du_ie => du_ie
  );


  --Memory access
  memory_unit : riscv_memory
  generic map (
    XLEN, 
    ILEN, 

    EXCEPTION_SIZE, 

    PC_INIT

  )
  port map (
    rstn => rstn,
    clk => clk,
    wb_stall => wb_stall,
    ex_pc => ex_pc,
    mem_pc => mem_pc,
    ex_bubble => ex_bubble,
    ex_instr => ex_instr,
    mem_bubble => mem_bubble,
    mem_instr => mem_instr,
    ex_exception => ex_exception,
    wb_exception => wb_exception,
    mem_exception => mem_exception,
    ex_r => ex_r,
    dmem_adr => dmem_adr,
    mem_r => mem_r,
    mem_memadr => mem_memadr
  );


  --Memory acknowledge + Write Back unit
  wb_unit : riscv_wb
  generic map (
    XLEN, 
    ILEN, 

    EXCEPTION_SIZE, 

    PC_INIT

  )
  port map (
    rst_ni => rstn,
    clk_i => clk,
    mem_pc_i => mem_pc,
    mem_instr_i => mem_instr,
    mem_bubble_i => mem_bubble,
    mem_r_i => mem_r,
    mem_exception_i => mem_exception,
    mem_memadr_i => mem_memadr,
    wb_pc_o => wb_pc,
    wb_stall_o => wb_stall,
    wb_instr_o => wb_instr,
    wb_bubble_o => wb_bubble,
    wb_exception_o => wb_exception,
    wb_badaddr_o => wb_badaddr,
    dmem_ack_i => dmem_ack,
    dmem_err_i => dmem_err,
    dmem_q_i => dmem_q,
    dmem_misaligned_i => dmem_misaligned,
    dmem_page_fault_i => dmem_page_fault,
    wb_dst_o => wb_dst,
    wb_r_o => wb_r,
    wb_we_o => wb_we
  );


  rf_dst(0) <= wb_dst;
  rf_dstv(0) <= wb_r;
  rf_we(0) <= wb_we;

  --Thread state
  cpu_state : riscv_state
  generic map (
    XLEN, 
    PC_INIT, 
    HAS_FPU, 
    HAS_MMU, 
    HAS_USER, 
    HAS_SUPER, 
    HAS_HYPER, 

    MNMIVEC_DEFAULT, 
    MTVEC_DEFAULT, 
    HTVEC_DEFAULT, 
    STVEC_DEFAULT, 
    UTVEC_DEFAULT, 

    JEDEC_BANK, 
    JEDEC_MANUFACTURER_ID, 

    PMP_CNT, 
    HARTID
  )
  port map (
    rstn => rstn,
    clk => clk,
    id_pc => id_pc,
    id_bubble => id_bubble,
    id_instr => id_instr,
    id_stall => id_stall,
    bu_flush => bu_flush,
    bu_nxt_pc => bu_nxt_pc,
    st_flush => st_flush,
    st_nxt_pc => st_nxt_pc,
    wb_pc => wb_pc,
    wb_bubble => wb_bubble,
    wb_instr => wb_instr,
    wb_exception => wb_exception,
    wb_badaddr => wb_badaddr,
    st_interrupt => st_interrupt,
    st_prv => st_prv,
    st_xlen => st_xlen,
    st_tvm => st_tvm,
    st_tw => st_tw,
    st_tsr => st_tsr,
    st_mcounteren => st_mcounteren,
    st_scounteren => st_scounteren,
    st_pmpcfg => st_pmpcfg,
    st_pmpaddr => st_pmpaddr,
    ext_int => ext_int,
    ext_tint => ext_tint,
    ext_sint => ext_sint,
    ext_nmi => ext_nmi,
    ex_csr_reg => ex_csr_reg,
    ex_csr_we => ex_csr_we,
    ex_csr_wval => ex_csr_wval,
    st_csr_rval => st_csr_rval,
    du_stall => du_stall,
    du_flush => du_flush,
    du_we_csr => du_we_csr,
    du_dato => du_dato,
    du_addr => du_addr,
    du_ie => du_ie,
    du_exceptions => du_exceptions
  );


  --Integer Register File
  rf_unit : riscv_rf
  generic map (
    XLEN, 

    AR_BITS, 

    RDPORTS, 
    WRPORTS
  )
  port map (
    rstn => rstn,
    clk => clk,
    rf_src1 => rf_src1,
    rf_src2 => rf_src2,
    rf_srcv1 => rf_srcv1,
    rf_srcv2 => rf_srcv2,
    rf_dst => rf_dst,
    rf_dstv => rf_dstv,
    rf_we => rf_we,
    du_stall => du_stall,
    du_we_rf => du_we_rf,
    du_dato => du_dato,
    du_dati_rf => du_dati_rf,
    du_addr => du_addr
  );


  --Branch Prediction Unit

  --Get Branch Prediction for Next Program Counter
  if (HAS_BPU = 0) generate
    bp_bp_predict <= "00";
  else generate
    bp_unit : riscv_bp
    generic map (
      XLEN, 

      BP_GLOBAL_BITS, 
      BP_LOCAL_BITS, 
      BP_LOCAL_BITS_LSB, 

      TECHNOLOGY, 

      PC_INIT
    )
    port map (
      rst_ni => rstn,
      clk_i => clk,

      id_stall_i => id_stall,
      if_parcel_pc_i => if_parcel_pc,
      bp_bp_predict_o => bp_bp_predict,

      ex_pc_i => ex_pc,
      bu_bp_history_i => bu_bp_history,
      bu_bp_predict_i => bu_bp_predict,    --prediction bits for branch
      bu_bp_btaken_i => bu_bp_btaken,
      bu_bp_update_i => bu_bp_update
    );
  end generate;


  --Debug Unit
  du_unit : riscv_du
  generic map (
    XLEN, 
    PLEN, 
    ILEN, 

    EXCEPTION_SIZE, 

    DU_ADDR_SIZE, 
    MAX_BREAKPOINTS, 

    BREAKPOINTS
  )
  port map (
    rstn => rstn,
    clk => clk,
    dbg_stall => dbg_stall,
    dbg_strb => dbg_strb,
    dbg_we => dbg_we,
    dbg_addr => dbg_addr,
    dbg_dati => dbg_dati,
    dbg_dato => dbg_dato,
    dbg_ack => dbg_ack,
    dbg_bp => dbg_bp,
    du_stall => du_stall,
    du_stall_dly => du_stall_dly,
    du_flush => du_flush,
    du_we_rf => du_we_rf,
    du_we_frf => du_we_frf,
    du_we_csr => du_we_csr,
    du_we_pc => du_we_pc,
    du_addr => du_addr,
    du_dato => du_dato,
    du_ie => du_ie,
    du_dati_rf => du_dati_rf,
    du_dati_frf => du_dati_frf,
    st_csr_rval => st_csr_rval,
    if_pc => if_pc,
    id_pc => id_pc,
    ex_pc => ex_pc,
    bu_nxt_pc => bu_nxt_pc,
    bu_flush => bu_flush,
    st_flush => st_flush,
    if_instr => if_instr,
    mem_instr => mem_instr,
    if_bubble => if_bubble,
    mem_bubble => mem_bubble,
    mem_exception => mem_exception,
    mem_memadr => mem_memadr,
    dmem_ack => dmem_ack,
    ex_stall => ex_stall,
    du_exceptions => du_exceptions
  );
end RTL;
