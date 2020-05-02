-- Converted from riscv/pu/riscv_module.sv
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
--              Processing Unit                                               //
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

entity riscv_module is
  port (




  --Number of hardware breakpoints

  --Number of Physical Memory Protection entries



  --in KBytes
  --in Bytes
  --'n'-way set associative


  --in KBytes
  --in Bytes
  --'n'-way set associative










  --AHB interfaces
    HRESETn : in std_logic;
    HCLK : in std_logic;

    pma_cfg_i : in std_logic_vector(13 downto 0);
    pma_adr_i : in std_logic_vector(XLEN-1 downto 0);

    ins_HSEL : out std_logic;
    ins_HADDR : out std_logic_vector(PLEN-1 downto 0);
    ins_HWDATA : out std_logic_vector(XLEN-1 downto 0);
    ins_HRDATA : in std_logic_vector(XLEN-1 downto 0);
    ins_HWRITE : out std_logic;
    ins_HSIZE : out std_logic_vector(2 downto 0);
    ins_HBURST : out std_logic_vector(2 downto 0);
    ins_HPROT : out std_logic_vector(3 downto 0);
    ins_HTRANS : out std_logic_vector(1 downto 0);
    ins_HMASTLOCK : out std_logic;
    ins_HREADY : in std_logic;
    ins_HRESP : in std_logic;

    dat_HSEL : out std_logic;
    dat_HADDR : out std_logic_vector(PLEN-1 downto 0);
    dat_HWDATA : out std_logic_vector(XLEN-1 downto 0);
    dat_HRDATA : in std_logic_vector(XLEN-1 downto 0);
    dat_HWRITE : out std_logic;
    dat_HSIZE : out std_logic_vector(2 downto 0);
    dat_HBURST : out std_logic_vector(2 downto 0);
    dat_HPROT : out std_logic_vector(3 downto 0);
    dat_HTRANS : out std_logic_vector(1 downto 0);
    dat_HMASTLOCK : out std_logic;
    dat_HREADY : in std_logic;
    dat_HRESP : in std_logic;

  --Interrupts
    ext_nmi, ext_tint, ext_sint : in std_logic;
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
  constant XLEN : integer := 32;
  constant PLEN : integer := 32;
  constant PC_INIT : std_logic_vector(XLEN-1 downto 0) := X"8000_0000";
  constant HAS_USER : integer := 1;
  constant HAS_SUPER : integer := 1;
  constant HAS_HYPER : integer := 1;
  constant HAS_BPU : integer := 1;
  constant HAS_FPU : integer := 1;
  constant HAS_MMU : integer := 1;
  constant HAS_RVM : integer := 1;
  constant HAS_RVA : integer := 1;
  constant HAS_RVC : integer := 1;
  constant IS_RV32E : integer := 0;
  constant MULT_LATENCY : integer := 1;
  constant BREAKPOINTS : integer := 8;
  constant PMA_CNT : integer := 4;
  constant PMP_CNT : integer := 16;
  constant BP_GLOBAL_BITS : integer := 2;
  constant BP_LOCAL_BITS : integer := 10;
  constant BP_LOCAL_BITS_LSB : integer := 2;
  constant ICACHE_SIZE : integer := 32;
  constant ICACHE_BLOCK_SIZE : integer := 32;
  constant ICACHE_WAYS : integer := 2;
  constant ICACHE_REPLACE_ALG : integer := 0;
  constant ITCM_SIZE : integer := 0;
  constant DCACHE_SIZE : integer := 32;
  constant DCACHE_BLOCK_SIZE : integer := 32;
  constant DCACHE_WAYS : integer := 2;
  constant DCACHE_REPLACE_ALG : integer := 0;
  constant DTCM_SIZE : integer := 0;
  constant WRITEBUFFER_SIZE : integer := 8;
  constant TECHNOLOGY : integer := "GENERIC";
  constant MNMIVEC_DEFAULT : std_logic_vector(XLEN-1 downto 0) := PC_INIT-X"004";
  constant MTVEC_DEFAULT : std_logic_vector(XLEN-1 downto 0) := PC_INIT-X"040";
  constant HTVEC_DEFAULT : std_logic_vector(XLEN-1 downto 0) := PC_INIT-X"080";
  constant STVEC_DEFAULT : std_logic_vector(XLEN-1 downto 0) := PC_INIT-X"0C0";
  constant UTVEC_DEFAULT : std_logic_vector(XLEN-1 downto 0) := PC_INIT-X"100";
  constant JEDEC_BANK : integer := 10;
  constant JEDEC_MANUFACTURER_ID : integer := X"6e";
  constant HARTID : integer := 0;
  constant PARCEL_SIZE : integer := 32;
end riscv_module;

architecture RTL of riscv_module is
  component riscv_pu
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
    HRESETn : std_logic_vector(? downto 0);
    HCLK : std_logic_vector(? downto 0);
    pma_cfg_i : std_logic_vector(? downto 0);
    pma_adr_i : std_logic_vector(? downto 0);
    ins_HSEL : std_logic_vector(? downto 0);
    ins_HADDR : std_logic_vector(? downto 0);
    ins_HWDATA : std_logic_vector(? downto 0);
    ins_HRDATA : std_logic_vector(? downto 0);
    ins_HWRITE : std_logic_vector(? downto 0);
    ins_HSIZE : std_logic_vector(? downto 0);
    ins_HBURST : std_logic_vector(? downto 0);
    ins_HPROT : std_logic_vector(? downto 0);
    ins_HTRANS : std_logic_vector(? downto 0);
    ins_HMASTLOCK : std_logic_vector(? downto 0);
    ins_HREADY : std_logic_vector(? downto 0);
    ins_HRESP : std_logic_vector(? downto 0);
    dat_HSEL : std_logic_vector(? downto 0);
    dat_HADDR : std_logic_vector(? downto 0);
    dat_HWDATA : std_logic_vector(? downto 0);
    dat_HRDATA : std_logic_vector(? downto 0);
    dat_HWRITE : std_logic_vector(? downto 0);
    dat_HSIZE : std_logic_vector(? downto 0);
    dat_HBURST : std_logic_vector(? downto 0);
    dat_HPROT : std_logic_vector(? downto 0);
    dat_HTRANS : std_logic_vector(? downto 0);
    dat_HMASTLOCK : std_logic_vector(? downto 0);
    dat_HREADY : std_logic_vector(? downto 0);
    dat_HRESP : std_logic_vector(? downto 0);
    ext_nmi : std_logic_vector(? downto 0);
    ext_tint : std_logic_vector(? downto 0);
    ext_sint : std_logic_vector(? downto 0);
    ext_int : std_logic_vector(? downto 0);
    dbg_stall : std_logic_vector(? downto 0);
    dbg_strb : std_logic_vector(? downto 0);
    dbg_we : std_logic_vector(? downto 0);
    dbg_addr : std_logic_vector(? downto 0);
    dbg_dati : std_logic_vector(? downto 0);
    dbg_dato : std_logic_vector(? downto 0);
    dbg_ack : std_logic_vector(? downto 0);
    dbg_bp : std_logic_vector(? downto 0)
  );
  end component;

begin


  --//////////////////////////////////////////////////////////////
  --
  -- Module Body
  --

  --Instantiate RISC-V PU
  pu : riscv_pu
  generic map (
    XLEN, 
    PLEN, 
    PC_INIT, 
    HAS_USER, 
    HAS_SUPER, 
    HAS_HYPER, 
    HAS_BPU, 
    HAS_FPU, 
    HAS_MMU, 
    HAS_RVM, 
    HAS_RVA, 
    HAS_RVC, 
    IS_RV32E, 

    MULT_LATENCY, 

    BREAKPOINTS,     --Number of hardware breakpoints

    PMA_CNT, 
    PMP_CNT,     --Number of Physical Memory Protection entries

    BP_GLOBAL_BITS, 
    BP_LOCAL_BITS, 
    BP_LOCAL_BITS_LSB, 

    ICACHE_SIZE,     --in KBytes
    ICACHE_BLOCK_SIZE,     --in Bytes
    ICACHE_WAYS,     --'n'-way set associative
    ICACHE_REPLACE_ALG, 
    ITCM_SIZE, 

    DCACHE_SIZE,     --in KBytes
    DCACHE_BLOCK_SIZE,     --in Bytes
    DCACHE_WAYS,     --'n'-way set associative
    DCACHE_REPLACE_ALG, 
    DTCM_SIZE, 
    WRITEBUFFER_SIZE, 

    TECHNOLOGY, 

    MNMIVEC_DEFAULT, 
    MTVEC_DEFAULT, 
    HTVEC_DEFAULT, 
    STVEC_DEFAULT, 
    UTVEC_DEFAULT, 

    JEDEC_BANK, 
    JEDEC_MANUFACTURER_ID, 

    HARTID, 

    PARCEL_SIZE
  )
  port map (
    --AHB interfaces
    HRESETn => HRESETn,
    HCLK => HCLK,

    pma_cfg_i => pma_cfg_i,
    pma_adr_i => pma_adr_i,

    ins_HSEL => ins_HSEL,
    ins_HADDR => ins_HADDR,
    ins_HWDATA => ins_HWDATA,
    ins_HRDATA => ins_HRDATA,
    ins_HWRITE => ins_HWRITE,
    ins_HSIZE => ins_HSIZE,
    ins_HBURST => ins_HBURST,
    ins_HPROT => ins_HPROT,
    ins_HTRANS => ins_HTRANS,
    ins_HMASTLOCK => ins_HMASTLOCK,
    ins_HREADY => ins_HREADY,
    ins_HRESP => ins_HRESP,

    dat_HSEL => dat_HSEL,
    dat_HADDR => dat_HADDR,
    dat_HWDATA => dat_HWDATA,
    dat_HRDATA => dat_HRDATA,
    dat_HWRITE => dat_HWRITE,
    dat_HSIZE => dat_HSIZE,
    dat_HBURST => dat_HBURST,
    dat_HPROT => dat_HPROT,
    dat_HTRANS => dat_HTRANS,
    dat_HMASTLOCK => dat_HMASTLOCK,
    dat_HREADY => dat_HREADY,
    dat_HRESP => dat_HRESP,

    --Interrupts
    ext_nmi => ext_nmi,
    ext_tint => ext_tint,
    ext_sint => ext_sint,
    ext_int => ext_int,

    --Debug Interface
    dbg_stall => dbg_stall,
    dbg_strb => dbg_strb,
    dbg_we => dbg_we,
    dbg_addr => dbg_addr,
    dbg_dati => dbg_dati,
    dbg_dato => dbg_dato,
    dbg_ack => dbg_ack,
    dbg_bp => dbg_bp
  );
end RTL;
