-- Converted from core/memory/riscv_imem_ctrl.sv
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
--              Core - Instruction Memory Access Block                        //
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

entity riscv_imem_ctrl is
  port (










    rst_ni : in std_logic;
    clk_i : in std_logic;

  --Configuration
    pma_cfg_i : in std_logic_vector(13 downto 0);
    pma_adr_i : in std_logic_vector(XLEN-1 downto 0);

  --CPU side
    nxt_pc_i : in std_logic_vector(XLEN-1 downto 0);
    stall_nxt_pc_o : out std_logic;
    stall_i : in std_logic;
    flush_i : in std_logic;
    parcel_pc_o : out std_logic_vector(XLEN-1 downto 0);
    parcel_o : out std_logic_vector(PARCEL_SIZE-1 downto 0);
    parcel_valid_o : out std_logic_vector(PARCEL_SIZE/16-1 downto 0);
    err_o : out std_logic;
    misaligned_o : out std_logic;
    page_fault_o : out std_logic;
    cache_flush_i : in std_logic;
    dcflush_rdy_i : in std_logic;

    st_pmpcfg_i : in std_logic_vector(7 downto 0);
    st_pmpaddr_i : in std_logic_vector(XLEN-1 downto 0);
    st_prv_i : in std_logic_vector(1 downto 0);

  --BIU ports
    biu_stb_o : out std_logic;
    biu_stb_ack_i : in std_logic;
    biu_d_ack_i : in std_logic;
    biu_adri_o : out std_logic_vector(PLEN-1 downto 0);
    biu_adro_i : in std_logic_vector(PLEN-1 downto 0);
    biu_size_o : out std_logic_vector(2 downto 0);
    biu_type_o : out std_logic_vector(2 downto 0);
    biu_we_o : out std_logic;
    biu_lock_o : out std_logic;
    biu_prot_o : out std_logic_vector(2 downto 0);
    biu_d_o : out std_logic_vector(XLEN-1 downto 0);
    biu_q_i : in std_logic_vector(XLEN-1 downto 0);
    biu_ack_i : in std_logic 
    biu_err_i : in std_logic
  );
  constant XLEN : integer := 64;
  constant PLEN : integer := 64;
  constant PARCEL_SIZE : integer := 64;
  constant HAS_RVC : integer := 1;
  constant PMA_CNT : integer := 4;
  constant PMP_CNT : integer := 16;
  constant ICACHE_SIZE : integer := 64;
  constant ICACHE_BLOCK_SIZE : integer := 64;
  constant ICACHE_WAYS : integer := 2;
  constant ICACHE_REPLACE_ALG : integer := 2;
  constant ITCM_SIZE : integer := 0;
  constant TECHNOLOGY : integer := "GENERIC";
end riscv_imem_ctrl;

architecture RTL of riscv_imem_ctrl is
  component riscv_membuf
  generic (
    ? : std_logic_vector(? downto 0) := ?;
    ? : std_logic_vector(? downto 0) := ?
  );
  port (
    rst_ni : std_logic_vector(? downto 0);
    clk_i : std_logic_vector(? downto 0);
    clr_i : std_logic_vector(? downto 0);
    ena_i : std_logic_vector(? downto 0);
    req_i : std_logic_vector(? downto 0);
    d_i : std_logic_vector(? downto 0);
    req_o : std_logic_vector(? downto 0);
    q_o : std_logic_vector(? downto 0);
    ack_i : std_logic_vector(? downto 0);
    empty_o : std_logic_vector(? downto 0);
    full_o : std_logic_vector(? downto 0)
  );
  end component;

  component riscv_memmisaligned
  generic (
    ? : std_logic_vector(? downto 0) := ?;
    ? : std_logic_vector(? downto 0) := ?
  );
  port (
    clk_i : std_logic_vector(? downto 0);
    instruction_i : std_logic_vector(? downto 0);
    req_i : std_logic_vector(? downto 0);
    adr_i : std_logic_vector(? downto 0);
    size_i : std_logic_vector(? downto 0);
    misaligned_o : std_logic_vector(? downto 0)
  );
  end component;

  component riscv_mmu
  generic (
    ? : std_logic_vector(? downto 0) := ?;
    ? : std_logic_vector(? downto 0) := ?
  );
  port (
    rst_ni : std_logic_vector(? downto 0);
    clk_i : std_logic_vector(? downto 0);
    clr_i : std_logic_vector(? downto 0);
    vreq_i : std_logic_vector(? downto 0);
    vadr_i : std_logic_vector(? downto 0);
    vsize_i : std_logic_vector(? downto 0);
    vlock_i : std_logic_vector(? downto 0);
    vprot_i : std_logic_vector(? downto 0);
    vwe_i : std_logic_vector(? downto 0);
    vd_i : std_logic_vector(? downto 0);
    preq_o : std_logic_vector(? downto 0);
    padr_o : std_logic_vector(? downto 0);
    psize_o : std_logic_vector(? downto 0);
    plock_o : std_logic_vector(? downto 0);
    pprot_o : std_logic_vector(? downto 0);
    pwe_o : std_logic_vector(? downto 0);
    pd_o : std_logic_vector(? downto 0);
    pq_i : std_logic_vector(? downto 0);
    pack_i : std_logic_vector(? downto 0);
    page_fault_o : std_logic_vector(? downto 0)
  );
  end component;

  component riscv_pmachk
  generic (
    ? : std_logic_vector(? downto 0) := ?;
    ? : std_logic_vector(? downto 0) := ?;
    ? : std_logic_vector(? downto 0) := ?
  );
  port (
    pma_cfg_i : std_logic_vector(? downto 0);
    pma_adr_i : std_logic_vector(? downto 0);
    misaligned_i : std_logic_vector(? downto 0);
    instruction_i : std_logic_vector(? downto 0);
    req_i : std_logic_vector(? downto 0);
    adr_i : std_logic_vector(? downto 0);
    size_i : std_logic_vector(? downto 0);
    lock_i : std_logic_vector(? downto 0);
    we_i : std_logic_vector(? downto 0);
    pma_o : std_logic_vector(? downto 0);
    exception_o : std_logic_vector(? downto 0);
    misaligned_o : std_logic_vector(? downto 0);
    is_cache_access_o : std_logic_vector(? downto 0);
    is_ext_access_o : std_logic_vector(? downto 0);
    is_tcm_access_o : std_logic_vector(? downto 0)
  );
  end component;

  component riscv_pmpchk
  generic (
    ? : std_logic_vector(? downto 0) := ?;
    ? : std_logic_vector(? downto 0) := ?;
    ? : std_logic_vector(? downto 0) := ?
  );
  port (
    st_pmpcfg_i : std_logic_vector(? downto 0);
    st_pmpaddr_i : std_logic_vector(? downto 0);
    st_prv_i : std_logic_vector(? downto 0);
    instruction_i : std_logic_vector(? downto 0);
    req_i : std_logic_vector(? downto 0);
    adr_i : std_logic_vector(? downto 0);
    size_i : std_logic_vector(? downto 0);
    we_i : std_logic_vector(? downto 0);
    exception_o : std_logic_vector(? downto 0)
  );
  end component;

  component riscv_icache_core
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
    rst_ni : std_logic_vector(? downto 0);
    clk_i : std_logic_vector(? downto 0);
    clr_i : std_logic_vector(? downto 0);
    mem_vreq_i : std_logic_vector(? downto 0);
    mem_preq_i : std_logic_vector(? downto 0);
    mem_vadr_i : std_logic_vector(? downto 0);
    mem_padr_i : std_logic_vector(? downto 0);
    mem_size_i : std_logic_vector(? downto 0);
    mem_lock_i : std_logic_vector(? downto 0);
    mem_prot_i : std_logic_vector(? downto 0);
    mem_q_o : std_logic_vector(? downto 0);
    mem_ack_o : std_logic_vector(? downto 0);
    mem_err_o : std_logic_vector(? downto 0);
    flush_i : std_logic_vector(? downto 0);
    flushrdy_i : std_logic_vector(? downto 0);
    biu_stb_o : std_logic_vector(? downto 0);
    biu_stb_ack_i : std_logic_vector(? downto 0);
    biu_d_ack_i : std_logic_vector(? downto 0);
    biu_adri_o : std_logic_vector(? downto 0);
    biu_adro_i : std_logic_vector(? downto 0);
    biu_size_o : std_logic_vector(? downto 0);
    biu_type_o : std_logic_vector(? downto 0);
    biu_lock_o : std_logic_vector(? downto 0);
    biu_prot_o : std_logic_vector(? downto 0);
    biu_we_o : std_logic_vector(? downto 0);
    biu_d_o : std_logic_vector(? downto 0);
    biu_q_i : std_logic_vector(? downto 0);
    biu_ack_i : std_logic_vector(? downto 0);
    biu_err_i : std_logic_vector(? downto 0)
  );
  end component;

  component riscv_dext
  generic (
    ? : std_logic_vector(? downto 0) := ?;
    ? : std_logic_vector(? downto 0) := ?;
    ? : std_logic_vector(? downto 0) := ?
  );
  port (
    rst_ni : std_logic_vector(? downto 0);
    clk_i : std_logic_vector(? downto 0);
    clr_i : std_logic_vector(? downto 0);
    mem_req_i : std_logic_vector(? downto 0);
    mem_adr_i : std_logic_vector(? downto 0);
    mem_size_i : std_logic_vector(? downto 0);
    mem_type_i : std_logic_vector(? downto 0);
    mem_lock_i : std_logic_vector(? downto 0);
    mem_prot_i : std_logic_vector(? downto 0);
    mem_we_i : std_logic_vector(? downto 0);
    mem_d_i : std_logic_vector(? downto 0);
    mem_adr_ack_o : std_logic_vector(? downto 0);
    mem_adr_o : std_logic_vector(? downto 0);
    mem_q_o : std_logic_vector(? downto 0);
    mem_ack_o : std_logic_vector(? downto 0);
    mem_err_o : std_logic_vector(? downto 0);
    biu_stb_o : std_logic_vector(? downto 0);
    biu_stb_ack_i : std_logic_vector(? downto 0);
    biu_adri_o : std_logic_vector(? downto 0);
    biu_adro_i : std_logic_vector(? downto 0);
    biu_size_o : std_logic_vector(? downto 0);
    biu_type_o : std_logic_vector(? downto 0);
    biu_lock_o : std_logic_vector(? downto 0);
    biu_prot_o : std_logic_vector(? downto 0);
    biu_we_o : std_logic_vector(? downto 0);
    biu_d_o : std_logic_vector(? downto 0);
    biu_q_i : std_logic_vector(? downto 0);
    biu_ack_i : std_logic_vector(? downto 0);
    biu_err_i : std_logic_vector(? downto 0)
  );
  end component;

  component riscv_ram_queue
  generic (
    ? : std_logic_vector(? downto 0) := ?;
    ? : std_logic_vector(? downto 0) := ?;
    ? : std_logic_vector(? downto 0) := ?;
    ? : std_logic_vector(? downto 0) := ?
  );
  port (
    rst_ni : std_logic_vector(? downto 0);
    clk_i : std_logic_vector(? downto 0);
    clr_i : std_logic_vector(? downto 0);
    ena_i : std_logic_vector(? downto 0);
    we_i : std_logic_vector(? downto 0);
    d_i : std_logic_vector(? downto 0);
    re_i : std_logic_vector(? downto 0);
    q_o : std_logic_vector(? downto 0);
    almost_empty_o : std_logic_vector(? downto 0);
    almost_full_o : std_logic_vector(? downto 0);
    empty_o : std_logic_vector(? downto 0);
    full_o : std_logic_vector(? downto 0)
  );
  end component;

  component riscv_mux
  generic (
    ? : std_logic_vector(? downto 0) := ?;
    ? : std_logic_vector(? downto 0) := ?;
    ? : std_logic_vector(? downto 0) := ?
  );
  port (
    rst_ni : std_logic_vector(? downto 0);
    clk_i : std_logic_vector(? downto 0);
    biu_req_i : std_logic_vector(? downto 0);
    biu_req_ack_o : std_logic_vector(? downto 0);
    biu_d_ack_o : std_logic_vector(? downto 0);
    biu_adri_i : std_logic_vector(? downto 0);
    biu_adro_o : std_logic_vector(? downto 0);
    biu_size_i : std_logic_vector(? downto 0);
    biu_type_i : std_logic_vector(? downto 0);
    biu_lock_i : std_logic_vector(? downto 0);
    biu_prot_i : std_logic_vector(? downto 0);
    biu_we_i : std_logic_vector(? downto 0);
    biu_d_i : std_logic_vector(? downto 0);
    biu_q_o : std_logic_vector(? downto 0);
    biu_ack_o : std_logic_vector(? downto 0);
    biu_err_o : std_logic_vector(? downto 0);
    biu_req_o : std_logic_vector(? downto 0);
    biu_req_ack_i : std_logic_vector(? downto 0);
    biu_d_ack_i : std_logic_vector(? downto 0);
    biu_adri_o : std_logic_vector(? downto 0);
    biu_adro_i : std_logic_vector(? downto 0);
    biu_size_o : std_logic_vector(? downto 0);
    biu_type_o : std_logic_vector(? downto 0);
    biu_lock_o : std_logic_vector(? downto 0);
    biu_prot_o : std_logic_vector(? downto 0);
    biu_we_o : std_logic_vector(? downto 0);
    biu_d_o : std_logic_vector(? downto 0);
    biu_q_i : std_logic_vector(? downto 0);
    biu_ack_i : std_logic_vector(? downto 0);
    biu_err_i : std_logic_vector(? downto 0)
  );
  end component;



  --////////////////////////////////////////////////////////////////
  --
  -- Constants
  --

  constant TID_SIZE : integer := 3;

  constant MUX_PORTS : integer := 2
  when (ICACHE_SIZE > 0) else 1;

  constant EXT : integer := 0;
  constant CACHE : integer := 1;
  constant TCM : integer := 2;
  constant SEL_EXT : integer := (1 sll EXT);
  constant SEL_CACHE : integer := (1 sll CACHE);
  constant SEL_TCM : integer := (1 sll TCM);

  --////////////////////////////////////////////////////////////////
  --
  -- Variables
  --

  --Buffered memory request signals
  --Virtual memory access signals
  signal buf_req : std_logic;
  signal buf_ack : std_logic;
  signal buf_adr : std_logic_vector(XLEN-1 downto 0);
  signal buf_adr_dly : std_logic_vector(XLEN-1 downto 0);
  signal buf_size : std_logic_vector(2 downto 0);
  signal buf_lock : std_logic;
  signal buf_prot : std_logic_vector(2 downto 0);

  signal nxt_pc_queue_req : std_logic;
  signal nxt_pc_queue_empty : std_logic;
  signal nxt_pc_queue_full : std_logic;

  --Misalignment check
  signal misaligned : std_logic;

  --MMU signals
  --Physical memory access signals
  signal preq : std_logic;
  signal padr : std_logic_vector(PLEN-1 downto 0);
  signal psize : std_logic_vector(2 downto 0);
  signal plock : std_logic;
  signal pprot : std_logic_vector(2 downto 0);
  signal page_fault : std_logic;

  --from PMA check
  signal pma_exception : std_logic;
  signal pma_misaligned : std_logic;
  signal is_cache_access : std_logic;
  signal is_ext_access : std_logic;
  signal ext_access_req : std_logic;
  signal is_tcm_access : std_logic;

  --from PMP check
  signal pmp_exception : std_logic;

  --From Cache Controller Core
  signal cache_q : std_logic_vector(PARCEL_SIZE-1 downto 0);
  signal cache_ack : std_logic;
  signal cache_err : std_logic;

  --From TCM
  signal tcm_q : std_logic_vector(XLEN-1 downto 0);
  signal tcm_ack : std_logic;

  --From IO
  signal ext_vadr : std_logic_vector(XLEN-1 downto 0);
  signal ext_q : std_logic_vector(XLEN-1 downto 0);
  signal ext_access_ack : std_logic;  --address transfer acknowledge
  signal ext_ack : std_logic;  --data transfer acknowledge
  signal ext_err : std_logic;

  --BIU ports
  signal biu_stb : std_logic_vector(MUX_PORTS-1 downto 0);
  signal biu_stb_ack : std_logic_vector(MUX_PORTS-1 downto 0);
  signal biu_d_ack : std_logic_vector(MUX_PORTS-1 downto 0);
  signal biu_adro : std_logic_vector(PLEN-1 downto 0);
  signal biu_adri : std_logic_vector(PLEN-1 downto 0);
  signal biu_size : std_logic_vector(2 downto 0);
  signal biu_type : std_logic_vector(2 downto 0);
  signal biu_we : std_logic_vector(MUX_PORTS-1 downto 0);
  signal biu_lock : std_logic_vector(MUX_PORTS-1 downto 0);
  signal biu_prot : std_logic_vector(2 downto 0);
  signal biu_d : std_logic_vector(XLEN-1 downto 0);
  signal biu_q : std_logic_vector(XLEN-1 downto 0);
  signal biu_ack : std_logic_vector(MUX_PORTS-1 downto 0);
  signal biu_err : std_logic_vector(MUX_PORTS-1 downto 0);

  --to CPU
  signal parcel_valid : std_logic_vector(PARCEL_SIZE/16-1 downto 0);

  signal parcel_queue_d_pc : std_logic_vector(XLEN-1 downto 0);
  signal parcel_queue_d_parcel : std_logic_vector(PARCEL_SIZE-1 downto 0);
  signal parcel_queue_d_valid : std_logic_vector(PARCEL_SIZE/16-1 downto 0);
  signal parcel_queue_d_misaligned : std_logic;
  signal parcel_queue_d_page_fault : std_logic;
  signal parcel_queue_d_error : std_logic;

  signal parcel_queue_q_pc : std_logic_vector(XLEN-1 downto 0);
  signal parcel_queue_q_parcel : std_logic_vector(PARCEL_SIZE-1 downto 0);
  signal parcel_queue_q_valid : std_logic_vector(PARCEL_SIZE/16-1 downto 0);
  signal parcel_queue_q_misaligned : std_logic;
  signal parcel_queue_q_page_fault : std_logic;
  signal parcel_queue_q_error : std_logic;

  signal parcel_queue_d : std_logic_vector(XLEN+PARCEL_SIZE*(1+1/16)+3-1 downto 0);
  signal parcel_queue_q : std_logic_vector(XLEN+PARCEL_SIZE*(1+1/16)+3-1 downto 0);

  signal parcel_queue_empty : std_logic;
  signal parcel_queue_full : std_logic;

begin
  parcel_queue_d <= (parcel_queue_d_pc & parcel_queue_d_parcel & parcel_queue_d_valid & parcel_queue_d_misaligned & parcel_queue_d_page_fault & parcel_queue_d_error);

  (parcel_queue_q_pc & parcel_queue_q_parcel & parcel_queue_q_valid & parcel_queue_q_misaligned & parcel_queue_q_page_fault & parcel_queue_q_error) <= parcel_queue_q;

  --////////////////////////////////////////////////////////////////
  --
  -- Module Body
  --

  --
--
--  // For debugging
--  int fd;
--  initial fd = $fopen("memtrace.dat");
--
--  logic [XLEN-1:0] adr_dly, d_dly;
--  logic            we_dly;
--  int n = 0;
--
--  always @(posedge clk_i) begin
--    if (buf_req) begin
--      adr_dly <= buf_adr;
--    end
--
--    else if (mem_ack_o) begin
--      n++;
--      if (we_dly) $fdisplay (fd, "%0d, [%0x] <= %x", n, adr_dly, d_dly);
--      else        $fdisplay (fd, "%0d, [%0x] == %x", n, adr_dly, mem_q_o);
--    end
--  end
--
--   */

  --Hookup Access Buffer
  nxt_pc_queue_inst : riscv_membuf
  generic map (
    DEPTH, 
    DBITS
  )
  port map (
    rst_ni => rst_ni,
    clk_i => clk_i,

    clr_i => flush_i,
    ena_i => '1',

    req_i => not stall_nxt_pc_o,
    d_i => nxt_pc_i,

    req_o => buf_req,
    q_o => buf_adr,
    ack_i => buf_ack,

    empty_o => open,
    full_o => nxt_pc_queue_full
  );


  --stall nxt_pc when queues full, or when DCACHE is flushing
  stall_nxt_pc_o <= nxt_pc_queue_full or parcel_queue_full or not dcflush_rdy_i;

  buf_ack <= ext_access_ack or cache_ack or tcm_ack;
  buf_size <= WORD;
  buf_lock <= '0';
  buf_prot <= (PROT_USER
  when PROT_DATA or st_prv_i = PRV_U else PROT_PRIVILEGED);

  --Hookup misalignment check
  misaligned_inst : riscv_memmisaligned
  generic map (
    XLEN, 
    HAS_RVC
  )
  port map (
    clk_i => clk_i,
    instruction_i => '1',  --instruction access
    req_i => buf_req,
    adr_i => buf_adr,
    size_i => buf_size,
    misaligned_o => misaligned
  );


  -- Hookup MMU
--   * TODO
--   */

  mmu_inst : riscv_mmu
  generic map (
    XLEN, 
    PLEN
  )
  port map (
    rst_ni => rst_ni,
    clk_i => clk_i,
    clr_i => flush_i,

    vreq_i => buf_req,
    vadr_i => buf_adr,
    vsize_i => buf_size,
    vlock_i => buf_lock,
    vprot_i => buf_prot,
    vwe_i => '0',  --instructions only read
    vd_i => concatenate(XLEN, '0'),  --no write data

    preq_o => preq,
    padr_o => padr,
    psize_o => psize,
    plock_o => plock,
    pprot_o => pprot,
    pwe_o => open,
    pd_o => open,
    pq_i => concatenate(XLEN, '0'),
    pack_i => '0',

    page_fault_o => page_fault
  );


  --Hookup Physical Memory Atrributes Unit
  pmachk_inst : riscv_pmachk
  generic map (
    XLEN, 
    PLEN, 
    PMA_CNT
  )
  port map (
    --Configuration
    pma_cfg_i => pma_cfg_i,
    pma_adr_i => pma_adr_i,

    --misaligned
    misaligned_i => misaligned,

    --Memory Access
    instruction_i => '1',  --Instruction access
    req_i => preq,
    adr_i => padr,
    size_i => psize,
    lock_i => plock,
    we_i => '0',

    --Output
    pma_o => open,
    exception_o => pma_exception,
    misaligned_o => pma_misaligned,
    is_cache_access_o => is_cache_access,
    is_ext_access_o => is_ext_access,
    is_tcm_access_o => is_tcm_access
  );


  --Hookup Physical Memory Protection Unit
  pmpchk_inst : riscv_pmpchk
  generic map (
    XLEN, 
    PLEN, 
    PMP_CNT
  )
  port map (
    st_pmpcfg_i => st_pmpcfg_i,
    st_pmpaddr_i => st_pmpaddr_i,
    st_prv_i => st_prv_i,

    instruction_i => '1',  --Instruction access
    req_i => preq,  --Memory access request
    adr_i => padr,  --Physical Memory address (i.e. after translation)
    size_i => psize,  --Transfer size
    we_i => '0',  --Read/Write enable

    exception_o => pmp_exception
  );


  --Hookup Cache, TCM, external-interface
  if (ICACHE_SIZE > 0) generate
    --Instantiate Data Cache Core
    icache_inst : riscv_icache_core
    generic map (
      XLEN, 
      PLEN, 

      ICACHE_SIZE, 
      ICACHE_BLOCK_SIZE, 
      ICACHE_WAYS, 
      ICACHE_REPLACE_ALG, 

      TECHNOLOGY
    )
    port map (
      --common signals
      rst_ni => rst_ni,
      clk_i => clk_i,
      clr_i => flush_i,

      --from MMU/PMA
      mem_vreq_i => buf_req,
      mem_preq_i => is_cache_access,
      mem_vadr_i => buf_adr,
      mem_padr_i => padr,
      mem_size_i => buf_size,
      mem_lock_i => buf_lock,
      mem_prot_i => buf_prot,
      mem_q_o => cache_q,
      mem_ack_o => cache_ack,
      mem_err_o => cache_err,
      flush_i => cache_flush_i,
      flushrdy_i => '1',    --handled by stall_nxt_pc

      --To BIU
      biu_stb_o => biu_stb(CACHE),
      biu_stb_ack_i => biu_stb_ack(CACHE),
      biu_d_ack_i => biu_d_ack(CACHE),
      biu_adri_o => biu_adri(CACHE),
      biu_adro_i => biu_adro(CACHE),
      biu_size_o => biu_size(CACHE),
      biu_type_o => biu_type(CACHE),
      biu_lock_o => biu_lock(CACHE),
      biu_prot_o => biu_prot(CACHE),
      biu_we_o => biu_we(CACHE),
      biu_d_o => biu_d(CACHE),
      biu_q_i => biu_q(CACHE),
      biu_ack_i => biu_ack(CACHE),
      biu_err_i => biu_err(CACHE)
    );
  else generate  --No cache
    cache_q <= X"0";
    cache_ack <= '0';
    cache_err <= '0';
  end generate;


  --Instantiate TCM block
  if (ITCM_SIZE > 0) generate
    null;
  else generate  --No TCM
    tcm_q <= X"0";
    tcm_ack <= '0';
  end generate;


  --Instantiate EXT block
  if (ICACHE_SIZE > 0) generate
    if (ITCM_SIZE > 0) generate
      ext_access_req <= is_ext_access;
    else generate
      ext_access_req <= is_ext_access or is_tcm_access;
    end generate;
  elsif (ITCM_SIZE > 0) generate
    ext_access_req <= is_ext_access or is_cache_access;
  else generate
    ext_access_req <= is_ext_access or is_cache_access or is_tcm_access;
  end generate;


  dext_inst : riscv_dext
  generic map (
    XLEN, 
    PLEN, 
    DEPTH
  )
  port map (
    rst_ni => rst_ni,
    clk_i => clk_i,
    clr_i => flush_i,

    mem_req_i => ext_access_req,
    mem_adr_i => padr,
    mem_size_i => psize,
    mem_type_i => SINGLE,
    mem_lock_i => plock,
    mem_prot_i => pprot,
    mem_we_i => '0',
    mem_d_i => concatenate(XLEN, '0'),
    mem_adr_ack_o => ext_access_ack,
    mem_adr_o => open,
    mem_q_o => ext_q,
    mem_ack_o => ext_ack,
    mem_err_o => ext_err,

    biu_stb_o => biu_stb(EXT),
    biu_stb_ack_i => biu_stb_ack(EXT),
    biu_adri_o => biu_adri(EXT),
    biu_adro_i => open,
    biu_size_o => biu_size(EXT),
    biu_type_o => biu_type(EXT),
    biu_lock_o => biu_lock(EXT),
    biu_prot_o => biu_prot(EXT),
    biu_we_o => biu_we(EXT),
    biu_d_o => biu_d(EXT),
    biu_q_i => biu_q(EXT),
    biu_ack_i => biu_ack(EXT),
    biu_err_i => biu_err(EXT)
  );


  --store virtual addresses for external access
  ext_vadr_queue_inst : riscv_ram_queue
  generic map (
    DEPTH, 
    DBITS, 
    ALMOST_FULL_THRESHOLD, 
    ALMOST_EMPTY_THRESHOLD
  )
  port map (
    rst_ni => rst_ni,
    clk_i => clk_i,

    clr_i => flush_i,
    ena_i => '1',

    we_i => ext_access_req,
    d_i => buf_adr_dly,

    re_i => ext_ack,
    q_o => ext_vadr,

    almost_empty_o => open,
    almost_full_o => open,
    empty_o => open,
    full_o => open,
  );
  --stall access requests when full (AXI bus ...)


  --Hookup BIU mux
  riscv_mux_inst : riscv_mux
  generic map (
    XLEN, 
    PLEN, 
    PORTS
  )
  port map (
    rst_ni => rst_ni,
    clk_i => clk_i,

    biu_req_i => biu_stb,  --access request
    biu_req_ack_o => biu_stb_ack,  --access request acknowledge
    biu_d_ack_o => biu_d_ack,
    biu_adri_i => biu_adri,  --access start address
    biu_adro_o => biu_adro,  --transfer addresss
    biu_size_i => biu_size,  --access data size
    biu_type_i => biu_type,  --access burst type
    biu_lock_i => biu_lock,  --access locked access
    biu_prot_i => biu_prot,  --access protection bits
    biu_we_i => biu_we,  --access write enable
    biu_d_i => biu_d,  --access write data
    biu_q_o => biu_q,  --access read data
    biu_ack_o => biu_ack,  --transfer acknowledge
    biu_err_o => biu_err,  --transfer error

    biu_req_o => biu_stb_o,
    biu_req_ack_i => biu_stb_ack_i,
    biu_d_ack_i => biu_d_ack_i,
    biu_adri_o => biu_adri_o,
    biu_adro_i => biu_adro_i,
    biu_size_o => biu_size_o,
    biu_type_o => biu_type_o,
    biu_lock_o => biu_lock_o,
    biu_prot_o => biu_prot_o,
    biu_we_o => biu_we_o,
    biu_d_o => biu_d_o,
    biu_q_i => biu_q_i,
    biu_ack_i => biu_ack_i,
    biu_err_i => biu_err_i
  );


  --Results back to CPU
  parcel_valid <= (ext_ack or cache_ack or tcm_ack & ext_ack or cache_ack or tcm_ack);

  --Instruction Queue
  processing_0 : process (clk_i)
  begin
    if (rising_edge(clk_i)) then
      if (buf_req) then
        buf_adr_dly <= buf_adr;
      end if;
    end if;
  end process;


  parcel_queue_d_pc <= ext_vadr
  when ext_ack else buf_adr_dly;

  processing_1 : process
  begin
    case (((ext_ack & cache_ack & tcm_ack))) is
    when "001" =>
      parcel_queue_d_parcel <= tcm_q;
    when "010" =>
      parcel_queue_d_parcel <= cache_q;
    when others =>
      parcel_queue_d_parcel <= ext_q srl (16*parcel_queue_d_pc(1+(null)(XLEN/16)));
    end case;
  end process;


  parcel_queue_d_valid <= parcel_valid;
  parcel_queue_d_misaligned <= pma_misaligned;
  parcel_queue_d_page_fault <= page_fault;
  parcel_queue_d_error <= ext_err or cache_err or pma_exception or pmp_exception;

  --Instruction queue
  --Add some extra words for inflight instructions
  parcel_queue_inst : riscv_ram_queue
  generic map (
    DEPTH, 
    DBITS, 
    ALMOST_FULL_THRESHOLD, 
    ALMOST_EMPTY_THRESHOLD
  )
  port map (
    rst_ni => rst_ni,
    clk_i => clk_i,

    clr_i => flush_i,
    ena_i => '1',

    we_i => or parcel_valid,
    d_i => parcel_queue_d,

    re_i => not parcel_queue_empty and not stall_i,
    q_o => parcel_queue_q,

    almost_empty_o => open,
    almost_full_o => parcel_queue_full,
    empty_o => parcel_queue_empty,
    full_o => open,
  );


  --CPU signals
  parcel_pc_o <= parcel_queue_q_pc;
  parcel_o <= parcel_queue_q_parcel;
  parcel_valid_o <= parcel_queue_q_valid and not concatenate(PARCEL_SIZE/16, parcel_queue_empty);
  misaligned_o <= parcel_queue_q_misaligned;
  page_fault_o <= parcel_queue_q_page_fault;
  err_o <= parcel_queue_q_error;
end RTL;
