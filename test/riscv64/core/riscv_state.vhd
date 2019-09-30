-- Converted from core/riscv_state.sv
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
--              Core - State Unit                                             //
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

entity riscv_state is
  port (










  --number of PMP CSR blocks (max.16)
  --hardware thread-id
    rstn : in std_logic;
    clk : in std_logic;

    id_pc : in std_logic_vector(XLEN-1 downto 0);
    id_bubble : in std_logic;
    id_instr : in std_logic_vector(ILEN-1 downto 0);
    id_stall : in std_logic;

    bu_flush : in std_logic;
    bu_nxt_pc : in std_logic_vector(XLEN-1 downto 0);
    st_flush : out std_logic;
    st_nxt_pc : out std_logic_vector(XLEN-1 downto 0);

    wb_pc : in std_logic_vector(XLEN-1 downto 0);
    wb_bubble : in std_logic;
    wb_instr : in std_logic_vector(ILEN-1 downto 0);
    wb_exception : in std_logic_vector(EXCEPTION_SIZE-1 downto 0);
    wb_badaddr : in std_logic_vector(XLEN-1 downto 0);

    st_interrupt : out std_logic;
    st_prv : out std_logic_vector(1 downto 0);  --Privilege level
    st_xlen : out std_logic_vector(1 downto 0);  --Active Architecture
    st_tvm : out std_logic;  --trap on satp access or SFENCE.VMA
    st_tw : out std_logic;  --trap on WFI (after time >=0)
    st_tsr : out std_logic;  --trap SRET
    st_mcounteren : out std_logic_vector(XLEN-1 downto 0);
    st_scounteren : out std_logic_vector(XLEN-1 downto 0);
    st_pmpcfg : out std_logic_vector(7 downto 0);
    st_pmpaddr : out std_logic_vector(XLEN-1 downto 0);


  --interrupts (3=M-mode, 0=U-mode)
    ext_int : in std_logic_vector(3 downto 0);  --external interrupt (per privilege mode; determined by PIC)
    ext_tint : in std_logic;  --machine timer interrupt
    ext_sint : in std_logic;  --machine software interrupt (for ipi)
    ext_nmi : in std_logic;  --non-maskable interrupt

  --CSR interface
    ex_csr_reg : in std_logic_vector(11 downto 0);
    ex_csr_we : in std_logic;
    ex_csr_wval : in std_logic_vector(XLEN-1 downto 0);
    st_csr_rval : out std_logic_vector(XLEN-1 downto 0);

  --Debug interface
    du_stall : in std_logic;
    du_flush : in std_logic;
    du_we_csr : in std_logic;
    du_dato : in std_logic_vector(XLEN-1 downto 0);  --output from debug unit
    du_addr : in std_logic_vector(11 downto 0);
    du_ie : in std_logic_vector(31 downto 0) 
    du_exceptions : out std_logic_vector(31 downto 0)
  );
  constant XLEN : integer := 64;
  constant FLEN : integer := 64;
  constant ILEN : integer := 64;
  constant EXCEPTION_SIZE : integer := 16;
  constant PC_INIT : std_logic_vector(XLEN-1 downto 0) := X"200";
  constant IS_RV32E : integer := 0;
  constant HAS_RVN : integer := 1;
  constant HAS_RVC : integer := 1;
  constant HAS_FPU : integer := 1;
  constant HAS_MMU : integer := 1;
  constant HAS_RVM : integer := 1;
  constant HAS_RVA : integer := 1;
  constant HAS_RVB : integer := 1;
  constant HAS_RVT : integer := 1;
  constant HAS_RVP : integer := 1;
  constant HAS_EXT : integer := 1;
  constant HAS_USER : integer := 1;
  constant HAS_SUPER : integer := 1;
  constant HAS_HYPER : integer := 1;
  constant MNMIVEC_DEFAULT : integer := PC_INIT-X"004";
  constant MTVEC_DEFAULT : integer := PC_INIT-X"040";
  constant HTVEC_DEFAULT : integer := PC_INIT-X"080";
  constant STVEC_DEFAULT : integer := PC_INIT-X"0C0";
  constant UTVEC_DEFAULT : integer := PC_INIT-X"100";
  constant JEDEC_BANK : integer := 9;
  constant JEDEC_MANUFACTURER_ID : integer := X"8a";
  constant PMP_CNT : integer := 16;
  constant HARTID : integer := 0;
end riscv_state;

architecture RTL of riscv_state is
  --//////////////////////////////////////////////////////////////
  --
  -- Constants
  --
  constant EXT_XLEN : integer := XLEN-32
  when (XLEN > 32) else 32;

  --//////////////////////////////////////////////////////////////
  --
  -- Functions
  --
  function get_trap_cause (
    exception : std_logic_vector(EXCEPTION_SIZE-1 downto 0);
    constant n : integer;
  ) return std_logic_vector is
    variable get_trap_cause_return : std_logic_vector (3 downto 0);
  begin


    get_trap_cause_return <= 0;

    for n in 0 to EXCEPTION_SIZE - 1 loop
      if (exception(n)) then
        get_trap_cause_return <= n;
      end if;
    end loop;
    return get_trap_cause_return;
  end get_trap_cause;



  --//////////////////////////////////////////////////////////////
  --
  -- Variables
  --
  --Floating point registers
  signal csr_fcsr_rm : std_logic_vector(2 downto 0);
  signal csr_fcsr_flags : std_logic_vector(4 downto 0);

  signal csr_fcsr : std_logic_vector(7 downto 0);

  --User trap setup
  signal csr_utvec : std_logic_vector(XLEN-1 downto 0);

  --User trap handler
  signal csr_uscratch : std_logic_vector(XLEN-1 downto 0);  --scratch register
  signal csr_uepc : std_logic_vector(XLEN-1 downto 0);  --exception program counter
  signal csr_ucause : std_logic_vector(XLEN-1 downto 0);  --trap cause
  signal csr_utval : std_logic_vector(XLEN-1 downto 0);  --bad address

  --Supervisor

  --Supervisor trap setup
  signal csr_stvec : std_logic_vector(XLEN-1 downto 0);  --trap handler base address
  signal csr_scounteren : std_logic_vector(XLEN-1 downto 0);  --Enable performance counters for lower privilege level
  signal csr_sedeleg : std_logic_vector(XLEN-1 downto 0);  --trap delegation register

  --Supervisor trap handler
  signal csr_sscratch : std_logic_vector(XLEN-1 downto 0);  --scratch register
  signal csr_sepc : std_logic_vector(XLEN-1 downto 0);  --exception program counter
  signal csr_scause : std_logic_vector(XLEN-1 downto 0);  --trap cause
  signal csr_stval : std_logic_vector(XLEN-1 downto 0);  --bad address

  --Supervisor protection and Translation
  signal csr_satp : std_logic_vector(XLEN-1 downto 0);  --Address translation & protection

  --
--  //Hypervisor
--  //Hypervisor Trap Setup
--  logic  [XLEN-1:0] csr_htvec;    //trap handler base address
--  logic  [XLEN-1:0] csr_hedeleg;  //trap delegation register
--
--  //Hypervisor trap handler
--  logic  [XLEN-1:0] csr_hscratch; //scratch register
--  logic  [XLEN-1:0] csr_hepc;     //exception program counter
--  logic  [XLEN-1:0] csr_hcause;   //trap cause
--  logic  [XLEN-1:0] csr_htval;    //bad address
--
--  //Hypervisor protection and Translation
--  //TBD per spec v1.7, somewhat defined in 1.9, removed in 1.10
-- */

  -- Machine
  signal csr_mvendorid_bank : std_logic_vector(7 downto 0);  --Vendor-ID
  signal csr_mvendorid_offset : std_logic_vector(6 downto 0);  --Vendor-ID

  signal csr_mvendorid : std_logic_vector(14 downto 0);

  signal csr_marchid : std_logic_vector(XLEN-1 downto 0);  --Architecture ID
  signal csr_mimpid : std_logic_vector(XLEN-1 downto 0);  --Revision number
  signal csr_mhartid : std_logic_vector(XLEN-1 downto 0);  --Hardware Thread ID

  --Machine Trap Setup
  signal csr_mstatus_sd : std_logic;
  signal csr_mstatus_sxl : std_logic_vector(1 downto 0);  --S-Mode XLEN
  signal csr_mstatus_uxl : std_logic_vector(1 downto 0);  --U-Mode XLEN
  --logic  [4      :0] csr_mstatus_vm;   //virtualisation management
  signal csr_mstatus_tsr : std_logic;
  signal csr_mstatus_tw : std_logic;
  signal csr_mstatus_tvm : std_logic;
  signal csr_mstatus_mxr : std_logic;
  signal csr_mstatus_sum : std_logic;
  signal csr_mstatus_mprv : std_logic;  --memory privilege

  signal csr_mstatus_xs : std_logic_vector(1 downto 0);  --user extension status
  signal csr_mstatus_fs : std_logic_vector(1 downto 0);  --floating point status

  signal csr_mstatus_mpp : std_logic_vector(1 downto 0);
  signal csr_mstatus_hpp : std_logic_vector(1 downto 0);  --previous privilege levels
  signal csr_mstatus_spp : std_logic;  --supervisor previous privilege level
  signal csr_mstatus_mpie : std_logic;
  signal csr_mstatus_hpie : std_logic;
  signal csr_mstatus_spie : std_logic;
  signal csr_mstatus_upie : std_logic;  --previous interrupt enable bits
  signal csr_mstatus_mie : std_logic;
  signal csr_mstatus_hie : std_logic;
  signal csr_mstatus_sie : std_logic;
  signal csr_mstatus_uie : std_logic;  --interrupt enable bits (per privilege level) 

  signal csr_misa_base : std_logic_vector(1 downto 0);  --Machine ISA
  signal csr_misa_extensions : std_logic_vector(25 downto 0);

  signal csr_misa : std_logic_vector(28 downto 0);

  signal csr_mnmivec : std_logic_vector(XLEN-1 downto 0);  --ROALOGIC NMI handler base address
  signal csr_mtvec : std_logic_vector(XLEN-1 downto 0);  --trap handler base address
  signal csr_mcounteren : std_logic_vector(XLEN-1 downto 0);  --Enable performance counters for lower level
  signal csr_medeleg : std_logic_vector(XLEN-1 downto 0);  --Exception delegation
  signal csr_mideleg : std_logic_vector(XLEN-1 downto 0);  --Interrupt delegation

  signal csr_mie_meie : std_logic;
  signal csr_mie_heie : std_logic;
  signal csr_mie_seie : std_logic;
  signal csr_mie_ueie : std_logic;
  signal csr_mie_mtie : std_logic;
  signal csr_mie_htie : std_logic;
  signal csr_mie_stie : std_logic;
  signal csr_mie_utie : std_logic;
  signal csr_mie_msie : std_logic;
  signal csr_mie_hsie : std_logic;
  signal csr_mie_ssie : std_logic;
  signal csr_mie_usie : std_logic;

  signal csr_mie : std_logic_vector(11 downto 0);  --interrupt enable

  --Machine trap handler
  signal csr_mscratch : std_logic_vector(XLEN-1 downto 0);  --scratch register
  signal csr_mepc : std_logic_vector(XLEN-1 downto 0);  --exception program counter
  signal csr_mcause : std_logic_vector(XLEN-1 downto 0);  --trap cause
  signal csr_mtval : std_logic_vector(XLEN-1 downto 0);  --bad address

  signal csr_mip_meip : std_logic;
  signal csr_mip_heip : std_logic;
  signal csr_mip_seip : std_logic;
  signal csr_mip_ueip : std_logic;
  signal csr_mip_mtip : std_logic;
  signal csr_mip_htip : std_logic;
  signal csr_mip_stip : std_logic;
  signal csr_mip_utip : std_logic;
  signal csr_mip_msip : std_logic;
  signal csr_mip_hsip : std_logic;
  signal csr_mip_ssip : std_logic;
  signal csr_mip_usip : std_logic;

  signal csr_mip : std_logic_vector(11 downto 0);  --interrupt pending

  --Machine protection and Translation
  signal csr_pmpcfg : std_logic_vector(7 downto 0);
  signal csr_pmpaddr : std_logic_vector(XLEN-1 downto 0);

  --Machine counters/Timers
  signal csr_mcycle_h : std_logic_vector(31 downto 0);  --timer for `MCYCLE
  signal csr_mcycle_l : std_logic_vector(31 downto 0);  --timer for `MCYCLE

  signal csr_mcycle : std_logic_vector(63 downto 0);

  signal csr_minstret_h : std_logic_vector(31 downto 0);  --instruction retire count for `MINSTRET
  signal csr_minstret_l : std_logic_vector(31 downto 0);  --instruction retire count for `MINSTRET

  signal csr_minstret : std_logic_vector(63 downto 0);


  signal is_rv32 : std_logic;
  signal is_rv32e : std_logic;
  signal is_rv64 : std_logic;
  signal is_rv128 : std_logic;
  signal has_rvc : std_logic;
  signal has_fpu : std_logic;
  signal has_fpud : std_logic;
  signal has_fpuq : std_logic;
  signal has_decfpu : std_logic;
  signal has_mmu : std_logic;
  signal has_muldiv : std_logic;
  signal has_amo : std_logic;
  signal has_bm : std_logic;
  signal has_tmem : std_logic;
  signal has_simd : std_logic;
  signal has_n : std_logic;
  signal has_u : std_logic;
  signal has_s : std_logic;
  signal has_h : std_logic;
  signal has_ext : std_logic;

  signal mstatus : std_logic_vector(127 downto 0);  --mstatus is special (can be larger than 32bits)
  signal uxl_wval : std_logic_vector(1 downto 0);  --u/sxl are taken from bits 35:32
  signal sxl_wval : std_logic_vector(1 downto 0);  --and can only have limited values

  signal soft_seip : std_logic;  --software supervisor-external-interrupt
  signal soft_ueip : std_logic;  --software user-external-interrupt

  signal take_interrupt : std_logic;

  signal st_int : std_logic_vector(11 downto 0);
  signal interrupt_cause : std_logic_vector(3 downto 0);
  signal trap_cause : std_logic_vector(3 downto 0);

  --Mux for debug-unit
  signal csr_raddr : std_logic_vector(11 downto 0);  --CSR read address
  signal csr_wval : std_logic_vector(XLEN-1 downto 0);  --CSR write value

  signal idx : std_logic;  --a-z are used by 'misa'

begin
  --//////////////////////////////////////////////////////////////
  --
  -- Module Body
  --

  csr_fcsr <= (csr_fcsr_rm & csr_fcsr_flags);
  csr_mvendorid <= (csr_mvendorid_bank & csr_mvendorid_offset);
  csr_misa <= (csr_misa_base & csr_misa_extensions);

  is_rv32 <= (XLEN = 32);
  is_rv64 <= (XLEN = 64);
  is_rv128 <= (XLEN = 128);
  is_rv32e <= (IS_RV32E /= 0) and is_rv32;
  has_n <= (HAS_RVN /= 0) and has_u;
  has_u <= (HAS_USER /= 0);
  has_s <= (HAS_SUPER /= 0) and has_u;
  has_h <= '0';  --(HAS_HYPER  !=   0) & has_s;   //No Hypervisor

  has_rvc <= (HAS_RVC /= 0);
  has_fpu <= (HAS_FPU /= 0);
  has_fpuq <= (FLEN = 128) and has_fpu;
  has_fpud <= ((FLEN = 64) and has_fpu) or has_fpuq;
  has_decfpu <= '0';
  has_mmu <= (HAS_MMU /= 0) and has_s;
  has_muldiv <= (HAS_RVM /= 0);
  has_amo <= (HAS_RVA /= 0);
  has_bm <= (HAS_RVB /= 0);
  has_tmem <= (HAS_RVT /= 0);
  has_simd <= (HAS_RVP /= 0);
  has_ext <= (HAS_EXT /= 0);

  --Mux address/data for Debug-Unit access
  csr_raddr <= du_addr
  when du_stall else ex_csr_reg;
  csr_wval <= du_dato
  when du_stall else ex_csr_wval;

  --Priviliged Control Registers

  --mstatus has different values for RV32 and RV64/RV128
  --treat it here as though it is a 128bit register
  mstatus <= (csr_mstatus_sd & concatenate(128-37, '0') & csr_mstatus_sxl & csr_mstatus_uxl & concatenate(9, '0') & csr_mstatus_tsr & csr_mstatus_tw & csr_mstatus_tvm & csr_mstatus_mxr & csr_mstatus_sum & csr_mstatus_mprv & csr_mstatus_xs & csr_mstatus_fs & csr_mstatus_mpp & "00" & csr_mstatus_spp & csr_mstatus_mpie & '0' & csr_mstatus_spie & csr_mstatus_upie & csr_mstatus_mie & '0' & csr_mstatus_sie & csr_mstatus_uie);

  --Read
  processing_0 : process
  begin
    case ((csr_raddr)) is
    --User
    when USTATUS =>
      st_csr_rval <= (mstatus(127) & mstatus(XLEN-2 downto 0)) and X"11";
    when UIE =>
      st_csr_rval <= csr_mie and X"111"
      when has_n else X"0";
    when UTVEC =>
      st_csr_rval <= csr_utvec
      when has_n else X"0";
    when USCRATCH =>
      st_csr_rval <= csr_uscratch
      when has_n else X"0";
    when UEPC =>
      st_csr_rval <= csr_uepc
      when has_n else X"0";
    when UCAUSE =>
      st_csr_rval <= csr_ucause
      when has_n else X"0";
    when UTVAL =>
      st_csr_rval <= csr_utval
      when has_n else X"0";
    when UIP =>


      st_csr_rval <= csr_mip and csr_mideleg and X"111"
      when has_n else X"0";
    when FFLAGS =>
      st_csr_rval <= (concatenate(XLEN-(null)(csr_fcsr_flags), '0') & csr_fcsr_flags)
      when has_fpu else X"0";
    when FRM =>
      st_csr_rval <= (concatenate(XLEN-(null)(csr_fcsr_rm), '0') & csr_fcsr_rm)
      when has_fpu else X"0";
    when FCSR =>
      st_csr_rval <= (concatenate(XLEN-(null)(csr_fcsr), '0') & csr_fcsr)
      when has_fpu else X"0";
    when CYCLE =>
      st_csr_rval <= csr_mcycle(XLEN-1 downto 0);
    --`TIME      : st_csr_rval = csr_timer[XLEN-1:0];
    when INSTRET =>
      st_csr_rval <= csr_minstret(XLEN-1 downto 0);
    when CYCLEH =>
      st_csr_rval <= csr_mcycle_h
      when is_rv32 else X"0";
    --`TIMEH     : st_csr_rval = is_rv32 ? csr_timer_h    : 'h0;
    when INSTRETH =>


      st_csr_rval <= csr_minstret_h
      when is_rv32 else X"0";
    --Supervisor
    when SSTATUS =>
      st_csr_rval <= (mstatus(127) & mstatus(XLEN-2 downto 0)) and (1 sll XLEN-1 or "11" sll 32 or X"de133");
    when STVEC =>
      st_csr_rval <= csr_stvec
      when has_s else X"0";
    when SCOUNTEREN =>
      st_csr_rval <= csr_scounteren
      when has_s else X"0";
    when SIE =>
      st_csr_rval <= csr_mie and X"333"
      when has_s else X"0";
    when SEDELEG =>
      st_csr_rval <= csr_sedeleg
      when has_s else X"0";
    when SIDELEG =>
      st_csr_rval <= csr_mideleg and X"111"
      when has_s else X"0";
    when SSCRATCH =>
      st_csr_rval <= csr_sscratch
      when has_s else X"0";
    when SEPC =>
      st_csr_rval <= csr_sepc
      when has_s else X"0";
    when SCAUSE =>
      st_csr_rval <= csr_scause
      when has_s else X"0";
    when STVAL =>
      st_csr_rval <= csr_stval
      when has_s else X"0";
    when SIP =>
      st_csr_rval <= csr_mip and csr_mideleg and X"333"
      when has_s else X"0";
    when SATP =>
      st_csr_rval <= csr_satp
      when has_s and has_mmu else X"0";
    --
--      //Hypervisor
--      HSTATUS   : st_csr_rval = {mstatus[127],mstatus[XLEN-2:0] & (1 << XLEN-1 | 2'b11 << 32 | 'hde133);
--      HTVEC     : st_csr_rval = has_h ? csr_htvec                       : 'h0;
--      HIE       : st_csr_rval = has_h ? csr_mie & 12'h777               : 'h0;
--      HEDELEG   : st_csr_rval = has_h ? csr_hedeleg                     : 'h0;
--      HIDELEG   : st_csr_rval = has_h ? csr_mideleg & 12'h333           : 'h0;
--      HSCRATCH  : st_csr_rval = has_h ? csr_hscratch                    : 'h0;
--      HEPC      : st_csr_rval = has_h ? csr_hepc                        : 'h0;
--      HCAUSE    : st_csr_rval = has_h ? csr_hcause                      : 'h0;
--      HTVAL     : st_csr_rval = has_h ? csr_htval                       : 'h0;
--      HIP       : st_csr_rval = has_h ? csr_mip & csr_mideleg & 12'h777 : 'h0;
-- */
    --Machine
    when MISA =>
      st_csr_rval <= (csr_misa_base & concatenate(XLEN-(null)(csr_misa), '0') & csr_misa_extensions);
    when MVENDORID =>
      st_csr_rval <= (concatenate(XLEN-(null)(csr_mvendorid), '0') & csr_mvendorid);
    when MARCHID =>
      st_csr_rval <= csr_marchid;
    when MIMPID =>
      st_csr_rval <= csr_mimpid
      when is_rv32 else (concatenate(XLEN-(null)(csr_mimpid), '0') & csr_mimpid);
    when MHARTID =>
      st_csr_rval <= csr_mhartid;
    when MSTATUS =>
      st_csr_rval <= (mstatus(127) & mstatus(XLEN-2 downto 0));
    when MTVEC =>
      st_csr_rval <= csr_mtvec;
    when MCOUNTEREN =>
      st_csr_rval <= csr_mcounteren;
    when MNMIVEC =>
      st_csr_rval <= csr_mnmivec;
    when MEDELEG =>
      st_csr_rval <= csr_medeleg;
    when MIDELEG =>
      st_csr_rval <= csr_mideleg;
    when MIE =>
      st_csr_rval <= csr_mie and X"FFF";
    when MSCRATCH =>
      st_csr_rval <= csr_mscratch;
    when MEPC =>
      st_csr_rval <= csr_mepc;
    when MCAUSE =>
      st_csr_rval <= csr_mcause;
    when MTVAL =>
      st_csr_rval <= csr_mtval;
    when MIP =>
      st_csr_rval <= csr_mip;
    when PMPCFG0 =>
      st_csr_rval <= csr_pmpcfg(00);
    when PMPCFG1 =>
      st_csr_rval <= csr_pmpcfg(04)
      when is_rv32 else X"0";
    when PMPCFG2 =>
      st_csr_rval <= csr_pmpcfg(08)
      when not is_rv128 else X"0";
    when PMPCFG3 =>
      st_csr_rval <= csr_pmpcfg(12)
      when is_rv32 else X"0";
    when PMPADDR0 =>
      st_csr_rval <= csr_pmpaddr(00);
    when PMPADDR1 =>
      st_csr_rval <= csr_pmpaddr(01);
    when PMPADDR2 =>
      st_csr_rval <= csr_pmpaddr(02);
    when PMPADDR3 =>
      st_csr_rval <= csr_pmpaddr(03);
    when PMPADDR4 =>
      st_csr_rval <= csr_pmpaddr(04);
    when PMPADDR5 =>
      st_csr_rval <= csr_pmpaddr(05);
    when PMPADDR6 =>
      st_csr_rval <= csr_pmpaddr(06);
    when PMPADDR7 =>
      st_csr_rval <= csr_pmpaddr(07);
    when PMPADDR8 =>
      st_csr_rval <= csr_pmpaddr(08);
    when PMPADDR9 =>
      st_csr_rval <= csr_pmpaddr(09);
    when PMPADDR10 =>
      st_csr_rval <= csr_pmpaddr(10);
    when PMPADDR11 =>
      st_csr_rval <= csr_pmpaddr(11);
    when PMPADDR12 =>
      st_csr_rval <= csr_pmpaddr(12);
    when PMPADDR13 =>
      st_csr_rval <= csr_pmpaddr(13);
    when PMPADDR14 =>
      st_csr_rval <= csr_pmpaddr(14);
    when PMPADDR15 =>
      st_csr_rval <= csr_pmpaddr(15);
    when MCYCLE =>
      st_csr_rval <= csr_mcycle(XLEN-1 downto 0);
    when MINSTRET =>
      st_csr_rval <= csr_minstret(XLEN-1 downto 0);
    when MCYCLEH =>
      st_csr_rval <= csr_mcycle_h
      when is_rv32 else X"0";
    when MINSTRETH =>


      st_csr_rval <= csr_minstret_h
      when is_rv32 else X"0";
    when others =>
      st_csr_rval <= X"0";
    end case;
  end process;


  --//////////////////////////////////////////////////////////////
  -- Machine registers
  --
  csr_misa_base <= RV128I
  when is_rv128 else RV64I
  when is_rv64 else RV32I;
  --reserved
  --reserved
  --reserved
  --reserved for vector extensions
  --user mode supported
  --supervisor mode supported
  --reserved
  --reserved
  --reserved
  --reserved for JIT
  --reserved
  --additional extensions
  csr_misa_extensions <= ('0' & '0' & has_ext & '0' & '0' & has_u & has_tmem & has_s & '0' & has_fpuq & has_simd & '0' & has_n & has_muldiv & has_decfpu & '0' & '0' & not is_rv32e & '0' & '0' & has_fpu & is_rv32e & has_fpud & has_rvc & has_bm & has_amo);

  csr_mvendorid_bank <= JEDEC_BANK-1;
  csr_mvendorid_offset <= JEDEC_MANUFACTURER_ID(6 downto 0);
  csr_marchid <= (1 sll (XLEN-1)) or ARCHID;
  csr_mimpid(31 downto 24) <= REVPRV_MAJOR;
  csr_mimpid(23 downto 16) <= REVPRV_MINOR;
  csr_mimpid(15 downto 8) <= REVUSR_MAJOR;
  csr_mimpid(7 downto 0) <= REVUSR_MINOR;
  csr_mhartid <= HARTID;

  --mstatus
  csr_mstatus_sd <= and csr_mstatus_fs or and csr_mstatus_xs;

  st_tvm <= csr_mstatus_tvm;
  st_tw <= csr_mstatus_tw;
  st_tsr <= csr_mstatus_tsr;

  if (XLEN = 128) generate
    sxl_wval <= csr_wval(35 downto 34)
    when or csr_wval(35 downto 34) else csr_mstatus_sxl;
    uxl_wval <= csr_wval(33 downto 32)
    when or csr_wval(33 downto 32) else csr_mstatus_uxl;
  elsif (XLEN = 64) generate
    sxl_wval <= csr_wval(35 downto 34) = RV32I or csr_wval(35 downto 34)
    when csr_wval(35 downto 34) = RV64I else csr_mstatus_sxl;
    uxl_wval <= csr_wval(33 downto 32) = RV32I or csr_wval(33 downto 32)
    when csr_wval(33 downto 32) = RV64I else csr_mstatus_uxl;
  else generate
    sxl_wval <= "00";
    uxl_wval <= "00";
  end generate;


  processing_1 : process
  begin
    case ((st_prv)) is
    when PRV_S =>
      st_xlen <= csr_mstatus_sxl
      when has_s else csr_misa_base;
    when PRV_U =>
      st_xlen <= csr_mstatus_uxl
      when has_u else csr_misa_base;
    when others =>
      st_xlen <= csr_misa_base;
    end case;
  end process;


  processing_2 : process (clk, rstn)
  begin
    if (not rstn) then
      st_prv <= PRV_M;      --start in machine mode
      st_nxt_pc <= PC_INIT;
      st_flush <= '1';

      --csr_mstatus_vm   <= VM_MBARE;
      csr_mstatus_sxl <= csr_misa_base
      when has_s else "00";
      csr_mstatus_uxl <= csr_misa_base
      when has_u else "00";
      csr_mstatus_tsr <= '0';
      csr_mstatus_tw <= '0';
      csr_mstatus_tvm <= '0';
      csr_mstatus_mxr <= '0';
      csr_mstatus_sum <= '0';
      csr_mstatus_mprv <= '0';
      csr_mstatus_xs <= (has_ext & has_ext);
      csr_mstatus_fs <= "00";

      csr_mstatus_mpp <= X"3";
      csr_mstatus_hpp <= X"0";      --reserved
      csr_mstatus_spp <= has_s;
      csr_mstatus_mpie <= '0';
      csr_mstatus_hpie <= '0';      --reserved
      csr_mstatus_spie <= '0';
      csr_mstatus_upie <= '0';
      csr_mstatus_mie <= '0';
      csr_mstatus_hie <= '0';      --reserved
      csr_mstatus_sie <= '0';
      csr_mstatus_uie <= '0';
    elsif (rising_edge(clk)) then
      st_flush <= '0';

      --write from EX, Machine Mode
      if ((ex_csr_we and ex_csr_reg = MSTATUS and st_prv = PRV_M) or (du_we_csr and du_addr = MSTATUS)) then
        --            csr_mstatus_vm    <= csr_wval[28:24];
        csr_mstatus_sxl <= sxl_wval
        when has_s and XLEN > 32 else "00";
        csr_mstatus_uxl <= uxl_wval
        when has_u and XLEN > 32 else "00";
        csr_mstatus_tsr <= csr_wval(22)
        when has_s else '0';
        csr_mstatus_tw <= csr_wval(21)
        when has_s else '0';
        csr_mstatus_tvm <= csr_wval(20)
        when has_s else '0';
        csr_mstatus_mxr <= csr_wval(19)
        when has_s else '0';
        csr_mstatus_sum <= csr_wval(18)
        when has_s else '0';
        csr_mstatus_mprv <= csr_wval(17)
        when has_u else '0';
        csr_mstatus_xs <= csr_wval(16 downto 15)
        when has_ext else "00";        --TODO
        csr_mstatus_fs <= csr_wval(14 downto 13)
        when has_s and has_fpu else "00";        --TODO

        csr_mstatus_mpp <= csr_wval(12 downto 11);
        csr_mstatus_hpp <= X"0";        --reserved
        csr_mstatus_spp <= csr_wval(8)
        when has_s else '0';
        csr_mstatus_mpie <= csr_wval(7);
        csr_mstatus_hpie <= '0';        --reserved
        csr_mstatus_spie <= csr_wval(5)
        when has_s else '0';
        csr_mstatus_upie <= csr_wval(4)
        when has_n else '0';
        csr_mstatus_mie <= csr_wval(3);
        csr_mstatus_hie <= '0';        --reserved
        csr_mstatus_sie <= csr_wval(1)
        when has_s else '0';
        csr_mstatus_uie <= csr_wval(0)
        when has_n else '0';
      end if;


      --Supervisor Mode access
      if (has_s) then
        if ((ex_csr_we and ex_csr_reg = SSTATUS and st_prv >= PRV_S) or (du_we_csr and du_addr = SSTATUS)) then
          csr_mstatus_uxl <= uxl_wval;
          csr_mstatus_mxr <= csr_wval(19);
          csr_mstatus_sum <= csr_wval(18);
          csr_mstatus_xs <= csr_wval(16 downto 15)
          when has_ext else "00";          --TODO
          csr_mstatus_fs <= csr_wval(14 downto 13)
          when has_fpu else "00";          --TODO

          csr_mstatus_spp <= csr_wval(7);
          csr_mstatus_spie <= csr_wval(5);
          csr_mstatus_upie <= csr_wval(4)
          when has_n else '0';
          csr_mstatus_sie <= csr_wval(1);
          csr_mstatus_uie <= csr_wval(0);
        end if;
      end if;


      --MRET,HRET,SRET,URET
      if (not id_bubble and not bu_flush and not du_stall) then
        case ((id_instr)) is
        --pop privilege stack
        when MRET =>
        --set privilege level
          st_prv <= csr_mstatus_mpp;
          st_nxt_pc <= csr_mepc;
          st_flush <= '1';

          --set `MIE
          csr_mstatus_mie <= csr_mstatus_mpie;
          csr_mstatus_mpie <= '1';
          csr_mstatus_mpp <= PRV_U
          when has_u else PRV_M;
        --
--          HRET : begin
--            //set privilege level
--            st_prv    <= csr_mstatus_hpp;
--            st_nxt_pc <= csr_hepc;
--            st_flush  <= 1'b1;
--
--            //set HIE
--            csr_mstatus_hie  <= csr_mstatus_hpie;
--            csr_mstatus_hpie <= 1'b1;
--            csr_mstatus_hpp  <= has_u ? `PRV_U : `PRV_M;
--          end
-- */
        when SRET =>
        --set privilege level
          st_prv <= ('0' & csr_mstatus_spp);
          st_nxt_pc <= csr_sepc;
          st_flush <= '1';

          --set `SIE
          csr_mstatus_sie <= csr_mstatus_spie;
          csr_mstatus_spie <= '1';
          csr_mstatus_spp <= '0';          --Must have User-mode. SPP is only 1 bit
        when URET =>
        --set privilege level
          st_prv <= PRV_U;
          st_nxt_pc <= csr_uepc;
          st_flush <= '1';

          --set `UIE
          csr_mstatus_uie <= csr_mstatus_upie;
          csr_mstatus_upie <= '1';
        end case;
      end if;


      --push privilege stack
      if (ext_nmi) then
        --NMI always at Machine-mode
        st_prv <= PRV_M;
        st_nxt_pc <= csr_mnmivec;
        st_flush <= '1';

        --store current state
        csr_mstatus_mpie <= csr_mstatus_mie;
        csr_mstatus_mie <= '0';
        csr_mstatus_mpp <= st_prv;
      elsif (take_interrupt) then
        st_flush <= not du_stall and not du_flush;

        --Check if interrupts are delegated
        if (has_n and st_prv = PRV_U and (st_int and csr_mideleg and (X"111" = '1'))) then
          st_prv <= PRV_U;
          st_nxt_pc <= csr_utvec and not X"3"+(interrupt_cause sll 2
          when csr_utvec(0) else 0);

          csr_mstatus_upie <= csr_mstatus_uie;
          csr_mstatus_uie <= '0';
        elsif (has_s and st_prv >= PRV_S and (st_int and csr_mideleg and (X"333" = '1'))) then
          st_prv <= PRV_S;
          st_nxt_pc <= csr_stvec and not X"3"+(interrupt_cause sll 2
          when csr_stvec(0) else 0);

          csr_mstatus_spie <= csr_mstatus_sie;
          csr_mstatus_sie <= '0';
          csr_mstatus_spp <= st_prv(0);
        else        --
--        else if (has_h && st_prv >= `PRV_H && (st_int & csr_mideleg & 12'h777) ) begin
--          st_prv    <= `PRV_H;
--          st_nxt_pc <= csr_htvec;
--
--          csr_mstatus_hpie <= csr_mstatus_hie;
--          csr_mstatus_hie  <= 1'b0;
--          csr_mstatus_hpp  <= st_prv;
--        end
-- */
          st_prv <= PRV_M;
          st_nxt_pc <= csr_mtvec and not X"3"+(interrupt_cause sll 2
          when csr_mtvec(0) else 0);

          csr_mstatus_mpie <= csr_mstatus_mie;
          csr_mstatus_mie <= '0';
          csr_mstatus_mpp <= st_prv;
        end if;
      elsif (or (wb_exception and not du_ie(15 downto 0))) then
        st_flush <= '1';

        if (has_n and st_prv = PRV_U and or (wb_exception and csr_medeleg)) then
          st_prv <= PRV_U;
          st_nxt_pc <= csr_utvec;

          csr_mstatus_upie <= csr_mstatus_uie;
          csr_mstatus_uie <= '0';
        elsif (has_s and st_prv >= PRV_S and or (wb_exception and csr_medeleg)) then
          st_prv <= PRV_S;
          st_nxt_pc <= csr_stvec;

          csr_mstatus_spie <= csr_mstatus_sie;
          csr_mstatus_sie <= '0';
          csr_mstatus_spp <= st_prv(0);

        else        --
--        else if (has_h && st_prv >= `PRV_H && |(wb_exception & csr_medeleg)) begin
--          st_prv    <= `PRV_H;
--          st_nxt_pc <= csr_htvec;
--
--          csr_mstatus_hpie <= csr_mstatus_hie;
--          csr_mstatus_hie  <= 1'b0;
--          csr_mstatus_hpp  <= st_prv;
--        end
-- */
          st_prv <= PRV_M;
          st_nxt_pc <= csr_mtvec and not X"3";

          csr_mstatus_mpie <= csr_mstatus_mie;
          csr_mstatus_mie <= '0';
          csr_mstatus_mpp <= st_prv;
        end if;
      end if;
    end if;
  end process;


  --mcycle, minstret
  if (XLEN = 32) generate
    processing_3 : process (clk, rstn)
    begin
      if (not rstn) then
        csr_mcycle <= X"0";
        csr_minstret <= X"0";
      elsif (rising_edge(clk)) then
        --cycle always counts (thread active time)
        if ((ex_csr_we and ex_csr_reg = MCYCLE and st_prv = PRV_M) or (du_we_csr and du_addr = MCYCLE)) then
          csr_mcycle_l <= csr_wval;
        elsif ((ex_csr_we and ex_csr_reg = MCYCLEH and st_prv = PRV_M) or (du_we_csr and du_addr = MCYCLEH)) then
          csr_mcycle_h <= csr_wval;
        else

          csr_mcycle <= csr_mcycle+X"1";
        end if;
        --instruction retire counter
        if ((ex_csr_we and ex_csr_reg = MINSTRET and st_prv = PRV_M) or (du_we_csr and du_addr = MINSTRET)) then
          csr_minstret_l <= csr_wval;
        elsif ((ex_csr_we and ex_csr_reg = MINSTRETH and st_prv = PRV_M) or (du_we_csr and du_addr = MINSTRETH)) then
          csr_minstret_h <= csr_wval;
        elsif (not wb_bubble) then
          csr_minstret <= csr_minstret+X"1";
        end if;
      end if;
    end process;
  else generate  --(XLEN > 32) begin
    processing_4 : process (clk, rstn)
    begin
      if (not rstn) then
        csr_mcycle <= X"0";
        csr_minstret <= X"0";
      elsif (rising_edge(clk)) then
        --cycle always counts (thread active time)
        if ((ex_csr_we and ex_csr_reg = MCYCLE and st_prv = PRV_M) or (du_we_csr and du_addr = MCYCLE)) then
          csr_mcycle <= csr_wval(63 downto 0);
        else

          csr_mcycle <= csr_mcycle+X"1";
        end if;
        --instruction retire counter
        if ((ex_csr_we and ex_csr_reg = MINSTRET and st_prv = PRV_M) or (du_we_csr and du_addr = MINSTRET)) then
          csr_minstret <= csr_wval(63 downto 0);
        elsif (not wb_bubble) then
          csr_minstret <= csr_minstret+X"1";
        end if;
      end if;
    end process;
  end generate;


  --mnmivec - RoaLogic Extension
  processing_5 : process (clk, rstn)
  begin
    if (not rstn) then
      csr_mnmivec <= MNMIVEC_DEFAULT;
    elsif (rising_edge(clk)) then
      if ((ex_csr_we and ex_csr_reg = MNMIVEC and st_prv = PRV_M) or (du_we_csr and du_addr = MNMIVEC)) then
        csr_mnmivec <= (csr_wval(XLEN-1 downto 2) & "00");
      end if;
    end if;
  end process;


  --mtvec
  processing_6 : process (clk, rstn)
  begin
    if (not rstn) then
      csr_mtvec <= MTVEC_DEFAULT;
    elsif (rising_edge(clk)) then
      if ((ex_csr_we and ex_csr_reg = MTVEC and st_prv = PRV_M) or (du_we_csr and du_addr = MTVEC)) then
        csr_mtvec <= csr_wval and not X"2";
      end if;
    end if;
  end process;


  --mcounteren
  processing_7 : process (clk, rstn)
  begin
    if (not rstn) then
      csr_mcounteren <= X"0";
    elsif (rising_edge(clk)) then
      if ((ex_csr_we and ex_csr_reg = MCOUNTEREN and st_prv = PRV_M) or (du_we_csr and du_addr = MCOUNTEREN)) then
        csr_mcounteren <= csr_wval and X"7";
      end if;
    end if;
  end process;


  st_mcounteren <= csr_mcounteren;

  --medeleg, mideleg
  if (not HAS_HYPER and not HAS_SUPER and not HAS_USER) generate
    csr_medeleg <= 0;
    csr_mideleg <= 0;
  else generate  --medeleg
    processing_8 : process (clk, rstn)
    begin
      if (not rstn) then
        csr_medeleg <= X"0";
      elsif (rising_edge(clk)) then
        if ((ex_csr_we and ex_csr_reg = MEDELEG and st_prv = PRV_M) or (du_we_csr and du_addr = MEDELEG)) then
          csr_medeleg <= csr_wval and concatenate(EXCEPTION_SIZE, '1');
        end if;
      end if;
    end process;


    --mideleg
    processing_9 : process (clk, rstn)
    begin
      if (not rstn) then
        csr_mideleg <= X"0";
      elsif (rising_edge(clk)) then
        if ((ex_csr_we and ex_csr_reg = MIDELEG and st_prv = PRV_M) or (du_we_csr and du_addr = MIDELEG)) then
          csr_mideleg(SSI) <= has_s and csr_wval(SSI);
          csr_mideleg(USI) <= has_n and csr_wval(USI);
        --
--        else if (has_h) begin
--          if ( (ex_csr_we && ex_csr_reg == HIDELEG && st_prv >= `PRV_H) ||
--               (du_we_csr && du_addr    == HIDELEG)                ) begin
--            csr_mideleg[`SSI] <= has_s & csr_wval[`SSI];
--            csr_mideleg[`USI] <= has_n & csr_wval[`USI];
--          end
--        end
-- */
        elsif (has_s) then
          if ((ex_csr_we and ex_csr_reg = SIDELEG and st_prv >= PRV_S) or (du_we_csr and du_addr = SIDELEG)) then
            csr_mideleg(USI) <= has_n and csr_wval(USI);
          end if;
        end if;
      end if;
    end process;
  end generate;


  --mip
  processing_10 : process (clk, rstn)
  begin
    if (not rstn) then
      csr_mip <= X"0";
      soft_seip <= '0';
      soft_ueip <= '0';
    elsif (rising_edge(clk)) then
      --external interrupts
      csr_mip_meip <= ext_int(PRV_M);
      csr_mip_heip <= has_h and ext_int(PRV_H);
      csr_mip_seip <= has_s and (ext_int(PRV_S) or soft_seip);
      csr_mip_ueip <= has_n and (ext_int(PRV_U) or soft_ueip);

      --may only be written by M-mode
      if ((ex_csr_we and ex_csr_reg = MIP and st_prv = PRV_M) or (du_we_csr and du_addr = MIP)) then
        soft_seip <= csr_wval(SEI) and has_s;
        soft_ueip <= csr_wval(UEI) and has_n;
      end if;


      --timer interrupts
      csr_mip_mtip <= ext_tint;

      --may only be written by M-mode
      if ((ex_csr_we and ex_csr_reg = MIP and st_prv = PRV_M) or (du_we_csr and du_addr = MIP)) then
        csr_mip_htip <= csr_wval(HTI) and has_h;
        csr_mip_stip <= csr_wval(STI) and has_s;
        csr_mip_utip <= csr_wval(UTI) and has_n;
      end if;



      --software interrupts
      csr_mip_msip <= ext_sint;
      --Machine Mode write
      if ((ex_csr_we and ex_csr_reg = MIP and st_prv = PRV_M) or (du_we_csr and du_addr = MIP)) then
        csr_mip_hsip <= csr_wval(HSI) and has_h;
        csr_mip_ssip <= csr_wval(SSI) and has_s;
        csr_mip_usip <= csr_wval(USI) and has_n;
      --
--        else if (has_h) begin
--          //Hypervisor Mode write
--          if ( (ex_csr_we && ex_csr_reg == HIP && st_prv >= `PRV_H) ||
--               (du_we_csr && du_addr    == HIP)                   ) begin
--              csr_mip_hsip <= csr_wval[`HSI] & csr_mideleg[`HSI];
--              csr_mip_ssip <= csr_wval[`SSI] & csr_mideleg[`SSI] & has_s;
--              csr_mip_usip <= csr_wval[`USI] & csr_mideleg[`USI] & has_n;
--            end
--        end
-- */
      elsif (has_s) then
        --Supervisor Mode write
        if ((ex_csr_we and ex_csr_reg = SIP and st_prv >= PRV_S) or (du_we_csr and du_addr = SIP)) then
          csr_mip_ssip <= csr_wval(SSI) and csr_mideleg(SSI);
          csr_mip_usip <= csr_wval(USI) and csr_mideleg(USI) and has_n;
        end if;
      elsif (has_n) then
        --User Mode write
        if ((ex_csr_we and ex_csr_reg = UIP) or (du_we_csr and du_addr = UIP)) then
          csr_mip_usip <= csr_wval(USI) and csr_mideleg(USI);
        end if;
      end if;
    end if;
  end process;


  --mie
  processing_11 : process (clk, rstn)
  begin
    if (not rstn) then
      csr_mie <= X"0";
    elsif (rising_edge(clk)) then
      if ((ex_csr_we and ex_csr_reg = MIE and st_prv = PRV_M) or (du_we_csr and du_addr = MIE)) then
        csr_mie_meie <= csr_wval(MEI);
        csr_mie_heie <= csr_wval(HEI) and has_h;
        csr_mie_seie <= csr_wval(SEI) and has_s;
        csr_mie_ueie <= csr_wval(UEI) and has_n;
        csr_mie_mtie <= csr_wval(MTI);
        csr_mie_htie <= csr_wval(HTI) and has_h;
        csr_mie_stie <= csr_wval(STI) and has_s;
        csr_mie_utie <= csr_wval(UTI) and has_n;
        csr_mie_msie <= csr_wval(MSI);
        csr_mie_hsie <= csr_wval(HSI) and has_h;
        csr_mie_ssie <= csr_wval(SSI) and has_s;
        csr_mie_usie <= csr_wval(USI) and has_n;
      --
--    else if (has_h) begin
--      if ( (ex_csr_we && ex_csr_reg == HIE && st_prv >= `PRV_H) ||
--           (du_we_csr && du_addr    == HIE)                   ) begin
--        csr_mie_heie <= csr_wval[`HEI];
--        csr_mie_seie <= csr_wval[`SEI] & has_s;
--        csr_mie_ueie <= csr_wval[`UEI] & has_n;
--        csr_mie_htie <= csr_wval[`HTI];
--        csr_mie_stie <= csr_wval[`STI] & has_s;
--        csr_mie_utie <= csr_wval[`UTI] & has_n;
--        csr_mie_hsie <= csr_wval[`HSI];
--        csr_mie_ssie <= csr_wval[`SSI] & has_s;
--        csr_mie_usie <= csr_wval[`USI] & has_n;
--      end
--    end
-- */
      elsif (has_s) then
        if ((ex_csr_we and ex_csr_reg = SIE and st_prv >= PRV_S) or (du_we_csr and du_addr = SIE)) then
          csr_mie_seie <= csr_wval(SEI);
          csr_mie_ueie <= csr_wval(UEI) and has_n;
          csr_mie_stie <= csr_wval(STI);
          csr_mie_utie <= csr_wval(UTI) and has_n;
          csr_mie_ssie <= csr_wval(SSI);
          csr_mie_usie <= csr_wval(USI) and has_n;
        end if;
      elsif (has_n) then
        if ((ex_csr_we and ex_csr_reg = UIE) or (du_we_csr and du_addr = UIE)) then
          csr_mie_ueie <= csr_wval(UEI);
          csr_mie_utie <= csr_wval(UTI);
          csr_mie_usie <= csr_wval(USI);
        end if;
      end if;
    end if;
  end process;


  --mscratch
  processing_12 : process (clk, rstn)
  begin
    if (not rstn) then
      csr_mscratch <= X"0";
    elsif (rising_edge(clk)) then
      if ((ex_csr_we and ex_csr_reg = MSCRATCH and st_prv = PRV_M) or (du_we_csr and du_addr = MSCRATCH)) then
        csr_mscratch <= csr_wval;
      end if;
    end if;
  end process;


  trap_cause <= (null)(wb_exception and not du_ie(15 downto 0));

  --decode interrupts
  --priority external, software, timer
  st_int(CAUSE_MEINT) <= (((st_prv < PRV_M) or (st_prv = PRV_M and csr_mstatus_mie)) and (csr_mip_meip and csr_mie_meie));
  st_int(CAUSE_HEINT) <= (((st_prv < PRV_H) or (st_prv = PRV_H and csr_mstatus_hie)) and (csr_mip_heip and csr_mie_heie));
  st_int(CAUSE_SEINT) <= (((st_prv < PRV_S) or (st_prv = PRV_S and csr_mstatus_sie)) and (csr_mip_seip and csr_mie_seie));
  st_int(CAUSE_UEINT) <= ((st_prv = PRV_U and csr_mstatus_uie) and (csr_mip_ueip and csr_mie_ueie));

  st_int(CAUSE_MSINT) <= (((st_prv < PRV_M) or (st_prv = PRV_M and csr_mstatus_mie)) and (csr_mip_msip and csr_mie_msie)) and not st_int(CAUSE_MEINT);
  st_int(CAUSE_HSINT) <= (((st_prv < PRV_H) or (st_prv = PRV_H and csr_mstatus_hie)) and (csr_mip_hsip and csr_mie_hsie)) and not st_int(CAUSE_HEINT);
  st_int(CAUSE_SSINT) <= (((st_prv < PRV_S) or (st_prv = PRV_S and csr_mstatus_sie)) and (csr_mip_ssip and csr_mie_ssie)) and not st_int(CAUSE_SEINT);
  st_int(CAUSE_USINT) <= ((st_prv = PRV_U and csr_mstatus_uie) and (csr_mip_usip and csr_mie_usie)) and not st_int(CAUSE_UEINT);

  st_int(CAUSE_MTINT) <= (((st_prv < PRV_M) or (st_prv = PRV_M and csr_mstatus_mie)) and (csr_mip_mtip and csr_mie_mtie)) and not (st_int(CAUSE_MEINT) or st_int(CAUSE_MSINT));
  st_int(CAUSE_HTINT) <= (((st_prv < PRV_H) or (st_prv = PRV_H and csr_mstatus_hie)) and (csr_mip_htip and csr_mie_htie)) and not (st_int(CAUSE_HEINT) or st_int(CAUSE_HSINT));
  st_int(CAUSE_STINT) <= (((st_prv < PRV_S) or (st_prv = PRV_S and csr_mstatus_sie)) and (csr_mip_stip and csr_mie_stie)) and not (st_int(CAUSE_SEINT) or st_int(CAUSE_SSINT));
  st_int(CAUSE_UTINT) <= ((st_prv = PRV_U and csr_mstatus_uie) and (csr_mip_utip and csr_mie_utie)) and not (st_int(CAUSE_UEINT) or st_int(CAUSE_USINT));

  --interrupt cause priority
  processing_13 : process
  begin
    case ((st_int and not du_ie(31 downto 16))) is
    when X"??1" =>
      interrupt_cause <= 0;
    when X"??2" =>
      interrupt_cause <= 1;
    when X"??4" =>
      interrupt_cause <= 2;
    when X"??8" =>
      interrupt_cause <= 3;
    when X"?10" =>
      interrupt_cause <= 4;
    when X"?20" =>
      interrupt_cause <= 5;
    when X"?40" =>
      interrupt_cause <= 6;
    when X"?80" =>
      interrupt_cause <= 7;
    when X"100" =>
      interrupt_cause <= 8;
    when X"200" =>
      interrupt_cause <= 9;
    when X"400" =>
      interrupt_cause <= 10;
    when X"800" =>
      interrupt_cause <= 11;
    when others =>
      interrupt_cause <= 0;
    end case;
  end process;


  take_interrupt <= or (st_int and not du_ie(31 downto 16));

  --for Debug Unit
  du_exceptions <= (concatenate(16-(null)(st_int), '0') & st_int & concatenate(16-(null)(wb_exception), '0') & wb_exception) and du_ie;

  --Update mepc and mcause
  processing_14 : process (clk, rstn)
  begin
    if (not rstn) then
      st_interrupt <= '0';

      csr_mepc <= X"0";
      --csr_hepc     <= 'h0;
      csr_sepc <= X"0";
      csr_uepc <= X"0";

      csr_mcause <= X"0";
      --csr_hcause   <= 'h0;
      csr_scause <= X"0";
      csr_ucause <= X"0";

      csr_mtval <= X"0";
      --csr_htval    <= 'h0;
      csr_stval <= X"0";
      csr_utval <= X"0";
    elsif (rising_edge(clk)) then
      --Write access to regs (lowest priority)
      if ((ex_csr_we and ex_csr_reg = MEPC and st_prv = PRV_M) or (du_we_csr and du_addr = MEPC)) then
        csr_mepc <= (csr_wval(XLEN-1 downto 2) & csr_wval(1) and has_rvc & '0');
      end if;
      --
--      if ( (ex_csr_we && ex_csr_reg == HEPC && st_prv >= `PRV_H) ||
--           (du_we_csr && du_addr    == HEPC)                  )
--        csr_hepc <= {csr_wval[XLEN-1:2], csr_wval[1] & has_rvc, 1'b0};
-- */
      if ((ex_csr_we and ex_csr_reg = SEPC and st_prv >= PRV_S) or (du_we_csr and du_addr = SEPC)) then
        csr_sepc <= (csr_wval(XLEN-1 downto 2) & csr_wval(1) and has_rvc & '0');

      end if;
      if ((ex_csr_we and ex_csr_reg = UEPC and st_prv >= PRV_U) or (du_we_csr and du_addr = UEPC)) then
        csr_uepc <= (csr_wval(XLEN-1 downto 2) & csr_wval(1) and has_rvc & '0');


      end if;
      if ((ex_csr_we and ex_csr_reg = MCAUSE and st_prv = PRV_M) or (du_we_csr and du_addr = MCAUSE)) then
        csr_mcause <= csr_wval;
      end if;
      --
--      if ( (ex_csr_we && ex_csr_reg == HCAUSE && st_prv >= `PRV_H) ||
--           (du_we_csr && du_addr    == HCAUSE)                  )
--        csr_hcause <= csr_wval;
-- */
      if ((ex_csr_we and ex_csr_reg = SCAUSE and st_prv >= PRV_S) or (du_we_csr and du_addr = SCAUSE)) then
        csr_scause <= csr_wval;

      end if;
      if ((ex_csr_we and ex_csr_reg = UCAUSE and st_prv >= PRV_U) or (du_we_csr and du_addr = UCAUSE)) then
        csr_ucause <= csr_wval;


      end if;
      if ((ex_csr_we and ex_csr_reg = MTVAL and st_prv = PRV_M) or (du_we_csr and du_addr = MTVAL)) then
        csr_mtval <= csr_wval;
      end if;
      --
--      if ( (ex_csr_we && ex_csr_reg == HTVAL && st_prv >= `PRV_H) ||
--           (du_we_csr && du_addr    == HTVAL)                  )
--        csr_htval <= csr_wval;
-- */
      if ((ex_csr_we and ex_csr_reg = STVAL and st_prv >= PRV_S) or (du_we_csr and du_addr = STVAL)) then
        csr_stval <= csr_wval;

      end if;
      if ((ex_csr_we and ex_csr_reg = UTVAL and st_prv >= PRV_U) or (du_we_csr and du_addr = UTVAL)) then
        csr_utval <= csr_wval;

      end if;
      --Handle exceptions
      st_interrupt <= '0';

      --priority external interrupts, software interrupts, timer interrupts, traps
      if (ext_nmi) then    --TODO: doesn't this cause a deadlock? Need to hold of NMI once handled
        --NMI always at Machine Level
        st_interrupt <= '1';
        csr_mepc <= bu_nxt_pc
        when bu_flush else id_pc;
        csr_mcause <= (1 sll (XLEN-1)) or X"0";        --Implementation dependent. '0' indicates 'unknown cause'
      elsif (take_interrupt) then
        st_interrupt <= '1';

        --Check if interrupts are delegated
        if (has_n and st_prv = PRV_U and (st_int and csr_mideleg and (X"111" = '1'))) then
          csr_ucause <= (1 sll (XLEN-1)) or interrupt_cause;
          csr_uepc <= id_pc;
        elsif (has_s and st_prv >= PRV_S and (st_int and csr_mideleg and (X"333" = '1'))) then
          csr_scause <= (1 sll (XLEN-1)) or interrupt_cause;
          csr_sepc <= id_pc;
        else        --
--        else if (has_h && st_prv >= `PRV_H && (st_int & csr_mideleg & 12'h777) ) begin
--          csr_hcause <= (1 << (XLEN-1)) | interrupt_cause;
--          csr_hepc   <= id_pc;
--        end
-- */
          csr_mcause <= (1 sll (XLEN-1)) or interrupt_cause;
          csr_mepc <= id_pc;
        end if;
      elsif (or (wb_exception and not du_ie(15 downto 0))) then
        --Trap
        if (has_n and st_prv = PRV_U and or (wb_exception and csr_medeleg)) then
          csr_uepc <= wb_pc;
          csr_ucause <= trap_cause;
          csr_utval <= wb_badaddr;
        elsif (has_s and st_prv >= PRV_S and or (wb_exception and csr_medeleg)) then
          csr_sepc <= wb_pc;
          csr_scause <= trap_cause;

          if (wb_exception(CAUSE_ILLEGAL_INSTRUCTION)) then
            csr_stval <= wb_instr;
          elsif (wb_exception(CAUSE_MISALIGNED_INSTRUCTION) or wb_exception(CAUSE_INSTRUCTION_ACCESS_FAULT) or wb_exception(CAUSE_INSTRUCTION_PAGE_FAULT) or wb_exception(CAUSE_MISALIGNED_LOAD) or wb_exception(CAUSE_LOAD_ACCESS_FAULT) or wb_exception(CAUSE_LOAD_PAGE_FAULT) or wb_exception(CAUSE_MISALIGNED_STORE) or wb_exception(CAUSE_STORE_ACCESS_FAULT) or wb_exception(CAUSE_STORE_PAGE_FAULT)) then
            csr_stval <= wb_badaddr;
          end if;
        else        --
--        else if (has_h && st_prv >= `PRV_H && |(wb_exception & csr_medeleg)) begin
--          csr_hepc   <= wb_pc;
--          csr_hcause <= trap_cause;
--
--          if (wb_exception[`CAUSE_ILLEGAL_INSTRUCTION]) begin
--            csr_htval <= wb_instr;
--          else if (wb_exception[`CAUSE_MISALIGNED_INSTRUCTION] || wb_exception[`CAUSE_INSTRUCTION_ACCESS_FAULT] || wb_exception[`CAUSE_INSTRUCTION_PAGE_FAULT] ||
--                   wb_exception[`CAUSE_MISALIGNED_LOAD       ] || wb_exception[`CAUSE_LOAD_ACCESS_FAULT       ] || wb_exception[`CAUSE_LOAD_PAGE_FAULT       ] ||
--                   wb_exception[`CAUSE_MISALIGNED_STORE      ] || wb_exception[`CAUSE_STORE_ACCESS_FAULT      ] || wb_exception[`CAUSE_STORE_PAGE_FAULT      ] )
--            csr_htval <= wb_badaddr;
--          end
--        end
-- */
          csr_mepc <= wb_pc;
          csr_mcause <= trap_cause;

          if (wb_exception(CAUSE_ILLEGAL_INSTRUCTION)) then
            csr_mtval <= wb_instr;
          elsif (wb_exception(CAUSE_MISALIGNED_INSTRUCTION) or wb_exception(CAUSE_INSTRUCTION_ACCESS_FAULT) or wb_exception(CAUSE_INSTRUCTION_PAGE_FAULT) or wb_exception(CAUSE_MISALIGNED_LOAD) or wb_exception(CAUSE_LOAD_ACCESS_FAULT) or wb_exception(CAUSE_LOAD_PAGE_FAULT) or wb_exception(CAUSE_MISALIGNED_STORE) or wb_exception(CAUSE_STORE_ACCESS_FAULT) or wb_exception(CAUSE_STORE_PAGE_FAULT)) then
            csr_mtval <= wb_badaddr;
          end if;
        end if;
      end if;
    end if;
  end process;


  --Physical Memory Protection & Translation registers
  if (XLEN > 64) generate--RV128
    for idx in 0 to 16 - 1 generate
      if (idx < PMP_CNT) generate
        processing_15 : process (clk, rstn)
        begin
          if (not rstn) then
            csr_pmpcfg(idx) <= X"0";
          elsif (rising_edge(clk)) then
            if ((ex_csr_we and ex_csr_reg = PMPCFG0 and st_prv = PRV_M) or (du_we_csr and du_addr = PMPCFG0)) then
              if (not csr_pmpcfg(idx)(7)) then
                csr_pmpcfg(idx) <= csr_wval(idx*8+8) and PMPCFG_MASK;
              end if;
            end if;
          end if;
        end process;
      else generate
        csr_pmpcfg(idx) <= X"0";
      end generate;
    end generate;
  --next idx

  --pmpaddr not defined for RV128 yet
  elsif (XLEN > 32) generate--RV64 
    for idx in 0 to 8 - 1 generate
      processing_16 : process (clk, rstn)
      begin
        if (not rstn) then
          csr_pmpcfg(idx) <= X"0";
        elsif (rising_edge(clk)) then
          if ((ex_csr_we and ex_csr_reg = PMPCFG0 and st_prv = PRV_M) or (du_we_csr and du_addr = PMPCFG0)) then
            if (idx < PMP_CNT and not csr_pmpcfg(idx)(7)) then
              csr_pmpcfg(idx) <= csr_wval(0+idx*8+8) and PMPCFG_MASK;
            end if;
          end if;
        end if;
      end process;
    end generate;
    --next idx

    for idx in 8 to 16 - 1 generate
      processing_17 : process (clk, rstn)
      begin
        if (not rstn) then
          csr_pmpcfg(idx) <= X"0";
        elsif (rising_edge(clk)) then
          if ((ex_csr_we and ex_csr_reg = PMPCFG2 and st_prv = PRV_M) or (du_we_csr and du_addr = PMPCFG2)) then
            if (idx < PMP_CNT and not csr_pmpcfg(idx)(7)) then
              csr_pmpcfg(idx) <= csr_wval((idx-8)*8+8) and PMPCFG_MASK;
            end if;
          end if;
        end if;
      end process;
    end generate;
    --next idx


    for idx in 0 to 16 - 1 generate
      if (idx < PMP_CNT) generate
        if (idx = 15) generate
          processing_18 : process (clk, rstn)
          begin
            if (not rstn) then
              csr_pmpaddr(idx) <= X"0";
            elsif (rising_edge(clk)) then
              if ((ex_csr_we and ex_csr_reg = (PMPADDR0+idx) and st_prv = PRV_M and not csr_pmpcfg(idx)(7)) or (du_we_csr and du_addr = (PMPADDR0+idx))) then
                csr_pmpaddr(idx) <= (X"0" & csr_wval(53 downto 0));
              end if;
            end if;
          end process;
        else generate
          processing_19 : process (clk, rstn)
          begin
            if (not rstn) then
              csr_pmpaddr(idx) <= X"0";
            elsif (rising_edge(clk)) then
              if ((ex_csr_we and ex_csr_reg = (PMPADDR0+idx) and st_prv = PRV_M and not csr_pmpcfg(idx)(7) and not (csr_pmpcfg(idx+1)(4 downto 3) = TOR and csr_pmpcfg(idx+1)(7))) or (du_we_csr and du_addr = (PMPADDR0+idx))) then
                csr_pmpaddr(idx) <= (X"0" & csr_wval(53 downto 0));
              end if;
            end if;
          end process;
        end generate;
      else generate
        csr_pmpaddr(idx) <= X"0";
      end generate;
    end generate;
  else generate  --next idx
  --RV32
    for idx in 0 to 4 - 1 generate
      processing_20 : process (clk, rstn)
      begin
        if (not rstn) then
          csr_pmpcfg(idx) <= X"0";
        elsif (rising_edge(clk)) then
          if ((ex_csr_we and ex_csr_reg = PMPCFG0 and st_prv = PRV_M) or (du_we_csr and du_addr = PMPCFG0)) then
            if (idx < PMP_CNT and not csr_pmpcfg(idx)(7)) then
              csr_pmpcfg(idx) <= csr_wval(idx*8+8) and PMPCFG_MASK;
            end if;
          end if;
        end if;
      end process;
    end generate;
    --next idx

    for idx in 4 to 8 - 1 generate
      processing_21 : process (clk, rstn)
      begin
        if (not rstn) then
          csr_pmpcfg(idx) <= X"0";
        elsif (rising_edge(clk)) then
          if ((ex_csr_we and ex_csr_reg = PMPCFG1 and st_prv = PRV_M) or (du_we_csr and du_addr = PMPCFG1)) then
            if (idx < PMP_CNT and not csr_pmpcfg(idx)(7)) then
              csr_pmpcfg(idx) <= csr_wval((idx-4)*8+8) and PMPCFG_MASK;
            end if;
          end if;
        end if;
      end process;
    end generate;
    --next idx

    for idx in 8 to 12 - 1 generate
      processing_22 : process (clk, rstn)
      begin
        if (not rstn) then
          csr_pmpcfg(idx) <= X"0";
        elsif (rising_edge(clk)) then
          if ((ex_csr_we and ex_csr_reg = PMPCFG2 and st_prv = PRV_M) or (du_we_csr and du_addr = PMPCFG2)) then
            if (idx < PMP_CNT and not csr_pmpcfg(idx)(7)) then
              csr_pmpcfg(idx) <= csr_wval((idx-8)*8+8) and PMPCFG_MASK;
            end if;
          end if;
        end if;
      end process;
    end generate;
    --next idx

    for idx in 12 to 16 - 1 generate
      processing_23 : process (clk, rstn)
      begin
        if (not rstn) then
          csr_pmpcfg(idx) <= X"0";
        elsif (rising_edge(clk)) then
          if ((ex_csr_we and ex_csr_reg = PMPCFG3 and st_prv = PRV_M) or (du_we_csr and du_addr = PMPCFG3)) then
            if (idx < PMP_CNT and not csr_pmpcfg(idx)(7)) then
              csr_pmpcfg(idx) <= csr_wval((idx-12)*8+8) and PMPCFG_MASK;
            end if;
          end if;
        end if;
      end process;
    end generate;
    --next idx

    for idx in 0 to 16 - 1 generate
      if (idx < PMP_CNT) generate
        if (idx = 15) generate
          processing_24 : process (clk, rstn)
          begin
            if (not rstn) then
              csr_pmpaddr(idx) <= X"0";
            elsif (rising_edge(clk)) then
              if ((ex_csr_we and ex_csr_reg = (PMPADDR0+idx) and st_prv = PRV_M and not csr_pmpcfg(idx)(7)) or (du_we_csr and du_addr = (PMPADDR0+idx))) then
                csr_pmpaddr(idx) <= csr_wval;
              end if;
            end if;
          end process;
        else generate
          processing_25 : process (clk, rstn)
          begin
            if (not rstn) then
              csr_pmpaddr(idx) <= X"0";
            elsif (rising_edge(clk)) then
              if ((ex_csr_we and ex_csr_reg = (PMPADDR0+idx) and st_prv = PRV_M and not csr_pmpcfg(idx)(7) and not (csr_pmpcfg(idx+1)(4 downto 3) = TOR and csr_pmpcfg(idx+1)(7))) or (du_we_csr and du_addr = (PMPADDR0+idx))) then
                csr_pmpaddr(idx) <= csr_wval;
              end if;
            end if;
          end process;
        end generate;
      else generate
        csr_pmpaddr(idx) <= X"0";
      end generate;
    end generate;
  end generate;
  --next idx


  st_pmpcfg <= csr_pmpcfg;
  st_pmpaddr <= csr_pmpaddr;

  --//////////////////////////////////////////////////////////////
  --
  -- Supervisor Registers
  --
  if (HAS_SUPER) generate
    --stvec
    processing_26 : process (clk, rstn)
    begin
      if (not rstn) then
        csr_stvec <= STVEC_DEFAULT;
      elsif (rising_edge(clk)) then
        if ((ex_csr_we and ex_csr_reg = STVEC and st_prv >= PRV_S) or (du_we_csr and du_addr = STVEC)) then
          csr_stvec <= csr_wval and not X"2";
        end if;
      end if;
    end process;


    --scounteren
    processing_27 : process (clk, rstn)
    begin
      if (not rstn) then
        csr_scounteren <= X"0";
      elsif (rising_edge(clk)) then
        if ((ex_csr_we and ex_csr_reg = SCOUNTEREN and st_prv = PRV_M) or (du_we_csr and du_addr = SCOUNTEREN)) then
          csr_scounteren <= csr_wval and X"7";
        end if;
      end if;
    end process;


    --sedeleg
    processing_28 : process (clk, rstn)
    begin
      if (not rstn) then
        csr_sedeleg <= X"0";
      elsif (rising_edge(clk)) then
        if ((ex_csr_we and ex_csr_reg = SEDELEG and st_prv >= PRV_S) or (du_we_csr and du_addr = SEDELEG)) then
          csr_sedeleg <= csr_wval and ((1 sll CAUSE_UMODE_ECALL) or (1 sll CAUSE_SMODE_ECALL));
        end if;
      end if;
    end process;


    --sscratch
    processing_29 : process (clk, rstn)
    begin
      if (not rstn) then
        csr_sscratch <= X"0";
      elsif (rising_edge(clk)) then
        if ((ex_csr_we and ex_csr_reg = SSCRATCH and st_prv >= PRV_S) or (du_we_csr and du_addr = SSCRATCH)) then
          csr_sscratch <= csr_wval;
        end if;
      end if;
    end process;


    --satp
    processing_30 : process (clk, rstn)
    begin
      if (not rstn) then
        csr_satp <= X"0";
      elsif (rising_edge(clk)) then
        if ((ex_csr_we and ex_csr_reg = SATP and st_prv >= PRV_S) or (du_we_csr and du_addr = SATP)) then
          csr_satp <= ex_csr_wval;
        end if;
      end if;
    end process;
  else generate  --NO SUPERVISOR MODE
    csr_stvec <= X"0";
    csr_scounteren <= X"0";
    csr_sedeleg <= X"0";
    csr_sscratch <= X"0";
    csr_satp <= X"0";
  end generate;


  st_scounteren <= csr_scounteren;

  --//////////////////////////////////////////////////////////////
  --User Registers
  --
  if (HAS_USER) generate
    --utvec
    processing_31 : process (clk, rstn)
    begin
      if (not rstn) then
        csr_utvec <= UTVEC_DEFAULT;
      elsif (rising_edge(clk)) then
        if ((ex_csr_we and ex_csr_reg = UTVEC) or (du_we_csr and du_addr = UTVEC)) then
          csr_utvec <= (csr_wval(XLEN-1 downto 2) & "00");
        end if;
      end if;
    end process;


    --uscratch
    processing_32 : process (clk, rstn)
    begin
      if (not rstn) then
        csr_uscratch <= X"0";
      elsif (rising_edge(clk)) then
        if ((ex_csr_we and ex_csr_reg = USCRATCH) or (du_we_csr and du_addr = USCRATCH)) then
          csr_uscratch <= csr_wval;
        end if;
      end if;
    end process;


    --Floating point registers
    if (HAS_FPU) generate
      --TODO
      null;
    end generate;
  else generate  --NO USER MODE
    csr_utvec <= X"0";
    csr_uscratch <= X"0";

    csr_fcsr_rm <= X"0";
    csr_fcsr_flags <= X"0";
  end generate;
end RTL;
