-- Converted from core/riscv_du.sv
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
--              Core - Debug Unit                                             //
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

entity riscv_du is
  port (






    rstn : in std_logic;
    clk : in std_logic;

  --Debug Port interface
    dbg_stall : in std_logic;
    dbg_strb : in std_logic;
    dbg_we : in std_logic;
    dbg_addr : in std_logic_vector(PLEN-1 downto 0);
    dbg_dati : in std_logic_vector(XLEN-1 downto 0);
    dbg_dato : out std_logic_vector(XLEN-1 downto 0);
    dbg_ack : out std_logic;
    dbg_bp : out std_logic;


  --CPU signals
    du_stall : out std_logic;
    du_stall_dly : out std_logic;
    du_flush : out std_logic;
    du_we_rf : out std_logic;
    du_we_frf : out std_logic;
    du_we_csr : out std_logic;
    du_we_pc : out std_logic;
    du_addr : out std_logic_vector(DU_ADDR_SIZE-1 downto 0);
    du_dato : out std_logic_vector(XLEN-1 downto 0);
    du_ie : out std_logic_vector(31 downto 0);
    du_dati_rf : in std_logic_vector(XLEN-1 downto 0);
    du_dati_frf : in std_logic_vector(XLEN-1 downto 0);
    st_csr_rval : in std_logic_vector(XLEN-1 downto 0);
    if_pc : in std_logic_vector(XLEN-1 downto 0);
    id_pc : in std_logic_vector(XLEN-1 downto 0);
    ex_pc : in std_logic_vector(XLEN-1 downto 0);
    bu_nxt_pc : in std_logic_vector(XLEN-1 downto 0);
    bu_flush : in std_logic;
    st_flush : in std_logic;

    if_instr : in std_logic_vector(ILEN-1 downto 0);
    mem_instr : in std_logic_vector(ILEN-1 downto 0);
    if_bubble : in std_logic;
    mem_bubble : in std_logic;
    mem_exception : in std_logic_vector(EXCEPTION_SIZE-1 downto 0);
    mem_memadr : in std_logic_vector(XLEN-1 downto 0);
    dmem_ack : in std_logic;
    ex_stall : in std_logic 
  --                                mem_req,
  --                                mem_we,
  --input      [XLEN          -1:0] mem_adr,

  --From state
    du_exceptions : in std_logic_vector(31 downto 0)
  );
  constant XLEN : integer := 64;
  constant PLEN : integer := 64;
  constant ILEN : integer := 64;
  constant EXCEPTION_SIZE : integer := 16;
  constant DU_ADDR_SIZE : integer := 12;
  constant MAX_BREAKPOINTS : integer := 8;
  constant BREAKPOINTS : integer := 3;
end riscv_du;

architecture RTL of riscv_du is


  --////////////////////////////////////////////////////////////////
  --
  -- Variables
  --
  signal dbg_strb_dly : std_logic;
  signal du_bank_addr : std_logic_vector(PLEN-1 downto DU_ADDR_SIZE);
  signal du_sel_internal : std_logic;
  signal du_sel_gprs : std_logic;
  signal du_sel_csrs : std_logic;
  signal du_access : std_logic;
  signal du_we : std_logic;
  signal du_ack : std_logic_vector(2 downto 0);

  signal du_we_internal : std_logic;
  signal du_internal_regs : std_logic_vector(XLEN-1 downto 0);

  signal dbg_branch_break_ena : std_logic;
  signal dbg_instr_break_ena : std_logic;
  signal dbg_ie : std_logic_vector(31 downto 0);
  signal dbg_cause : std_logic_vector(XLEN-1 downto 0);

  signal dbg_bp_hit : std_logic_vector(MAX_BREAKPOINTS-1 downto 0);
  signal dbg_branch_break_hit : std_logic;
  signal dbg_instr_break_hit : std_logic;
  signal dbg_cc : std_logic_vector(2 downto 0);
  signal dbg_enabled : std_logic_vector(MAX_BREAKPOINTS-1 downto 0);
  signal dbg_implemented : std_logic_vector(MAX_BREAKPOINTS-1 downto 0);
  signal dbg_data : std_logic_vector(XLEN-1 downto 0);

  signal bp_instr_hit : std_logic;
  signal bp_branch_hit : std_logic;
  signal bp_hit : std_logic_vector(MAX_BREAKPOINTS-1 downto 0);

  signal mem_read : std_logic;
  signal mem_write : std_logic;

  signal n : std_logic;

begin
  --////////////////////////////////////////////////////////////////
  --
  -- Module Body
  --

  --Debugger Interface

  -- Decode incoming address
  du_bank_addr <= dbg_addr(PLEN-1 downto DU_ADDR_SIZE);
  du_sel_internal <= du_bank_addr = DBG_INTERNAL;
  du_sel_gprs <= du_bank_addr = DBG_GPRS;
  du_sel_csrs <= du_bank_addr = DBG_CSRS;

  --generate 1 cycle pulse strobe
  processing_0 : process (clk)
  begin
    if (rising_edge(clk)) then
      dbg_strb_dly <= dbg_strb;
    end if;
  end process;


  --generate (write) access signals
  du_access <= (dbg_strb and dbg_stall) or (dbg_strb and du_sel_internal);
  du_we <= du_access and not dbg_strb_dly and dbg_we;

  -- generate ACK
  processing_1 : process (clk, rstn)
  begin
    if (not rstn) then
      du_ack <= X"0";
    elsif (rising_edge(clk)) then
      if (not ex_stall) then
        du_ack <= (du_access and not dbg_ack & du_access and not dbg_ack & du_access and not dbg_ack) and ('1' & du_ack(2 downto 1));
      end if;
    end if;
  end process;


  dbg_ack <= du_ack(0);

  --actual BreakPoint signal
  processing_2 : process (clk, rstn)
  begin
    if (not rstn) then
      dbg_bp <= '0';
    elsif (rising_edge(clk)) then
      dbg_bp <= not ex_stall and not du_stall and not du_flush and not bu_flush and not st_flush and (or du_exceptions or or (dbg_bp_hit & dbg_branch_break_hit & dbg_instr_break_hit));
    end if;
  end process;


  --CPU Interface

  -- assign CPU signals
  du_stall <= dbg_stall;

  processing_3 : process (clk, rstn)
  begin
    if (not rstn) then
      du_stall_dly <= '0';
    elsif (rising_edge(clk)) then
      du_stall_dly <= du_stall;
    end if;
  end process;


  du_flush <= du_stall_dly and not dbg_stall and or du_exceptions;

  processing_4 : process (clk)
  begin
    if (rising_edge(clk)) then
      du_addr <= dbg_addr(DU_ADDR_SIZE-1 downto 0);
      du_dato <= dbg_dati;

      du_we_rf <= du_we and du_sel_gprs and (dbg_addr(DU_ADDR_SIZE-1 downto 0) = DBG_GPR);
      du_we_frf <= du_we and du_sel_gprs and (dbg_addr(DU_ADDR_SIZE-1 downto 0) = DBG_FPR);
      du_we_internal <= du_we and du_sel_internal;
      du_we_csr <= du_we and du_sel_csrs;
      du_we_pc <= du_we and du_sel_gprs and (dbg_addr(DU_ADDR_SIZE-1 downto 0) = DBG_NPC);
    end if;
  end process;


  -- Return signals
  processing_5 : process
  begin
    case ((du_addr)) is
    when DBG_CTRL =>
      du_internal_regs <= (concatenate(XLEN-2, '0') & dbg_branch_break_ena & dbg_instr_break_ena);
    when DBG_HIT =>
      du_internal_regs <= (concatenate(XLEN-16, '0') & dbg_bp_hit & X"0" & dbg_branch_break_hit & dbg_instr_break_hit);
    when DBG_IE =>
      du_internal_regs <= (concatenate(XLEN-32, '0') & dbg_ie);
    when DBG_CAUSE =>


      du_internal_regs <= (concatenate(XLEN-32, '0') & dbg_cause);
    when DBG_BPCTRL0 =>
      du_internal_regs <= (concatenate(XLEN-7, '0') & dbg_cc(0) & X"0" & dbg_enabled(0) & dbg_implemented(0));
    when DBG_BPDATA0 =>


      du_internal_regs <= dbg_data(0);
    when DBG_BPCTRL1 =>
      du_internal_regs <= (concatenate(XLEN-7, '0') & dbg_cc(1) & X"0" & dbg_enabled(1) & dbg_implemented(1));
    when DBG_BPDATA1 =>


      du_internal_regs <= dbg_data(1);
    when DBG_BPCTRL2 =>
      du_internal_regs <= (concatenate(XLEN-7, '0') & dbg_cc(2) & X"0" & dbg_enabled(2) & dbg_implemented(2));
    when DBG_BPDATA2 =>


      du_internal_regs <= dbg_data(2);
    when DBG_BPCTRL3 =>
      du_internal_regs <= (concatenate(XLEN-7, '0') & dbg_cc(3) & X"0" & dbg_enabled(3) & dbg_implemented(3));
    when DBG_BPDATA3 =>


      du_internal_regs <= dbg_data(3);
    when DBG_BPCTRL4 =>
      du_internal_regs <= (concatenate(XLEN-7, '0') & dbg_cc(4) & X"0" & dbg_enabled(4) & dbg_implemented(4));
    when DBG_BPDATA4 =>


      du_internal_regs <= dbg_data(4);
    when DBG_BPCTRL5 =>
      du_internal_regs <= (concatenate(XLEN-7, '0') & dbg_cc(5) & X"0" & dbg_enabled(5) & dbg_implemented(5));
    when DBG_BPDATA5 =>


      du_internal_regs <= dbg_data(5);
    when DBG_BPCTRL6 =>
      du_internal_regs <= (concatenate(XLEN-7, '0') & dbg_cc(6) & X"0" & dbg_enabled(6) & dbg_implemented(6));
    when DBG_BPDATA6 =>


      du_internal_regs <= dbg_data(6);
    when DBG_BPCTRL7 =>
      du_internal_regs <= (concatenate(XLEN-7, '0') & dbg_cc(7) & X"0" & dbg_enabled(7) & dbg_implemented(7));
    when DBG_BPDATA7 =>


      du_internal_regs <= dbg_data(7);
    when others =>
      du_internal_regs <= X"0";
    end case;
  end process;


  processing_6 : process (clk)
  begin
    if (rising_edge(clk)) then
      case ((dbg_addr)) is
      when (DBG_INTERNAL & X"???") =>
        dbg_dato <= du_internal_regs;
      when (DBG_GPRS & DBG_GPR) =>
        dbg_dato <= du_dati_rf;
      when (DBG_GPRS & DBG_FPR) =>
        dbg_dato <= du_dati_frf;
      when (DBG_GPRS & DBG_NPC) =>
        dbg_dato <= bu_nxt_pc
        when bu_flush else id_pc;
      when (DBG_GPRS & DBG_PPC) =>
        dbg_dato <= ex_pc;
      when (DBG_CSRS & X"???") =>
        dbg_dato <= st_csr_rval;
      when others =>
        dbg_dato <= X"0";
      end case;
    end if;
  end process;


  --Registers

  --DBG CTRL
  processing_7 : process (clk, rstn)
  begin
    if (not rstn) then
      dbg_instr_break_ena <= '0';
      dbg_branch_break_ena <= '0';
    elsif (rising_edge(clk)) then
      if (du_we_internal and du_addr = DBG_CTRL) then
        dbg_instr_break_ena <= du_dato(0);
        dbg_branch_break_ena <= du_dato(1);
      end if;
    end if;
  end process;


  --DBG HIT
  processing_8 : process (clk, rstn)
  begin
    if (not rstn) then
      dbg_instr_break_hit <= '0';
      dbg_branch_break_hit <= '0';
    elsif (rising_edge(clk)) then
      if (du_we_internal and du_addr = DBG_HIT) then
        dbg_instr_break_hit <= du_dato(0);
        dbg_branch_break_hit <= du_dato(1);
      elsif (bp_instr_hit) then
        dbg_instr_break_hit <= '1';
      if (bp_branch_hit) then
        dbg_branch_break_hit <= '1';
      end if;
      end if;
    end if;
  end process;


  for n in 0 to MAX_BREAKPOINTS - 1 generate
    if (n < BREAKPOINTS) generate
      processing_9 : process (clk, rstn)
      begin
        if (not rstn) then
          dbg_bp_hit(n) <= '0';
        elsif (rising_edge(clk)) then
          if (du_we_internal and du_addr = DBG_HIT) then
            dbg_bp_hit(n) <= du_dato(n+4);
          elsif (bp_hit(n)) then
            dbg_bp_hit(n) <= '1';
          end if;
        end if;
      end process;
    end generate;
  end generate;
  --else //n >= BREAKPOINTS
  --assign dbg_bp_hit[n] = 1'b0;


  --DBG IE
  processing_10 : process (clk, rstn)
  begin
    if (not rstn) then
      dbg_ie <= X"0";
    elsif (rising_edge(clk)) then
      if (du_we_internal and du_addr = DBG_IE) then
        dbg_ie <= du_dato(31 downto 0);
      end if;
    end if;
  end process;


  --send to Thread-State
  du_ie <= dbg_ie;

  --DBG CAUSE
  processing_11 : process (clk, rstn)
  begin
    if (not rstn) then
      dbg_cause <= X"0";
    elsif (rising_edge(clk)) then
      if (du_we_internal and du_addr = DBG_CAUSE) then
        dbg_cause <= du_dato;
      elsif (or du_exceptions(15 downto 0)) then    --traps
        case ((du_exceptions(15 downto 0))) is
        when X"???1" =>
          dbg_cause <= 0;
        when X"???2" =>
          dbg_cause <= 1;
        when X"???4" =>
          dbg_cause <= 2;
        when X"???8" =>
          dbg_cause <= 3;
        when X"??10" =>
          dbg_cause <= 4;
        when X"??20" =>
          dbg_cause <= 5;
        when X"??40" =>
          dbg_cause <= 6;
        when X"??80" =>
          dbg_cause <= 7;
        when X"?100" =>
          dbg_cause <= 8;
        when X"?200" =>
          dbg_cause <= 9;
        when X"?400" =>
          dbg_cause <= 10;
        when X"?800" =>
          dbg_cause <= 11;
        when X"1000" =>
          dbg_cause <= 12;
        when X"2000" =>
          dbg_cause <= 13;
        when X"4000" =>
          dbg_cause <= 14;
        when X"8000" =>
          dbg_cause <= 15;
        when others =>
          dbg_cause <= 0;
        end case;
      elsif (or du_exceptions(31 downto 16)) then    --Interrupts
        case ((du_exceptions(31 downto 16))) is
        when X"???1" =>
          dbg_cause <= (X"1" sll (XLEN-1)) or 0;
        when X"???2" =>
          dbg_cause <= (X"1" sll (XLEN-1)) or 1;
        when X"???4" =>
          dbg_cause <= (X"1" sll (XLEN-1)) or 2;
        when X"???8" =>
          dbg_cause <= (X"1" sll (XLEN-1)) or 3;
        when X"??10" =>
          dbg_cause <= (X"1" sll (XLEN-1)) or 4;
        when X"??20" =>
          dbg_cause <= (X"1" sll (XLEN-1)) or 5;
        when X"??40" =>
          dbg_cause <= (X"1" sll (XLEN-1)) or 6;
        when X"??80" =>
          dbg_cause <= (X"1" sll (XLEN-1)) or 7;
        when X"?100" =>
          dbg_cause <= (X"1" sll (XLEN-1)) or 8;
        when X"?200" =>
          dbg_cause <= (X"1" sll (XLEN-1)) or 9;
        when X"?400" =>
          dbg_cause <= (X"1" sll (XLEN-1)) or 10;
        when X"?800" =>
          dbg_cause <= (X"1" sll (XLEN-1)) or 11;
        when X"1000" =>
          dbg_cause <= (X"1" sll (XLEN-1)) or 12;
        when X"2000" =>
          dbg_cause <= (X"1" sll (XLEN-1)) or 13;
        when X"4000" =>
          dbg_cause <= (X"1" sll (XLEN-1)) or 14;
        when X"8000" =>
          dbg_cause <= (X"1" sll (XLEN-1)) or 15;
        when others =>
          dbg_cause <= (X"1" sll (XLEN-1)) or 0;
        end case;
      end if;
    end if;
  end process;


  --DBG BPCTRL / DBG BPDATA
  for n in 0 to MAX_BREAKPOINTS - 1 generate
    if (n < BREAKPOINTS) generate
      dbg_implemented(n) <= '1';

      processing_12 : process (clk, rstn)
      begin
        if (not rstn) then
          dbg_enabled(n) <= '0';
          dbg_cc(n) <= X"0";
        elsif (rising_edge(clk)) then
          if (du_we_internal and du_addr = (DBG_BPCTRL0+2*n)) then
            dbg_enabled(n) <= du_dato(1);
            dbg_cc(n) <= du_dato(6 downto 4);
          end if;
        end if;
      end process;
      processing_13 : process (clk, rstn)
      begin
        if (not rstn) then
          dbg_data(n) <= X"0";
        elsif (rising_edge(clk)) then
          if (du_we_internal and du_addr = (DBG_BPDATA0+2*n)) then
            dbg_data(n) <= du_dato;
          end if;
        end if;
      end process;
    else generate
      null;
    end generate;
  end generate;
  --assign dbg_cc          [n] = 'h0;
  --assign dbg_enabled     [n] = 'h0;
  --assign dbg_implemented [n] = 'h0;
  --assign dbg_data        [n] = 'h0;


  --
--   * BreakPoints
--   *
--   * Combinatorial generation of break-point hit logic
--   * For actual registers see 'Registers' section
--   */

  bp_instr_hit <= dbg_instr_break_ena and not if_bubble;
  bp_branch_hit <= dbg_branch_break_ena and not if_bubble and (if_instr(6 downto 2) = OPC_BRANCH);

  --Memory access
  mem_read <= nor mem_exception and not mem_bubble and (mem_instr(6 downto 2) = OPC_LOAD);
  mem_write <= nor mem_exception and not mem_bubble and (mem_instr(6 downto 2) = OPC_STORE);

  for n in 0 to MAX_BREAKPOINTS - 1 generate
    if (n < BREAKPOINTS) generate
      processing_14 : process
      begin
        if (not dbg_enabled(n) or not dbg_implemented(n)) then
          bp_hit(n) <= '0';
        else
          case ((dbg_cc(n))) is
          when BP_CTRL_CC_FETCH =>
            bp_hit(n) <= (if_pc = dbg_data(n)) and not bu_flush and not st_flush;
          when BP_CTRL_CC_LD_ADR =>
            bp_hit(n) <= (mem_memadr = dbg_data(n)) and dmem_ack and mem_read;
          when BP_CTRL_CC_ST_ADR =>
            bp_hit(n) <= (mem_memadr = dbg_data(n)) and dmem_ack and mem_write;
          when BP_CTRL_CC_LDST_ADR =>
            bp_hit(n) <= (mem_memadr = dbg_data(n)) and dmem_ack and (mem_read or mem_write);
          --`BP_CTRL_CC_LD_ADR   : bp_hit[n] = (mem_adr    == dbg_data[n]) & mem_req & ~mem_we;
          --`BP_CTRL_CC_ST_ADR   : bp_hit[n] = (mem_adr    == dbg_data[n]) & mem_req &  mem_we;
          --`BP_CTRL_CC_LDST_ADR : bp_hit[n] = (mem_adr    == dbg_data[n]) & mem_req;
          when others =>
            bp_hit(n) <= '0';
          end case;
        end if;
      end process;
    else generate    --n >= BREAKPOINTS
      null;
    end generate;
  end generate;
end RTL;
