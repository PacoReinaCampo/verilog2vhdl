-- Converted from openMSP430.v
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
-- *File Name: openMSP430.v
--
-- *Module Description:
--                       openMSP430 Top level file
--
-- *Author(s):
--              - Olivier Girard,    olgirard@gmail.com
--

use work."openMSP430_defines.v".all;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity openMSP430 is
  port (
  -- Current oMSP instance number     (for multicore systems)
  -- Total number of oMSP instances-1 (for multicore systems)
  -- OUTPUTs
  --========
    aclk : out std_logic;  -- ASIC ONLY: ACLK
    aclk_en : out std_logic;  -- FPGA ONLY: ACLK enable
    dbg_freeze : out std_logic;  -- Freeze peripherals
    dbg_i2c_sda_out : out std_logic;  -- Debug interface: I2C SDA OUT
    dbg_uart_txd : out std_logic;  -- Debug interface: UART TXD
    dco_enable : out std_logic;  -- ASIC ONLY: Fast oscillator enable
    dco_wkup : out std_logic;  -- ASIC ONLY: Fast oscillator wake-up (asynchronous)
    dmem_addr : out std_logic_vector(DMEM_MSB downto 0);  -- Data Memory address
    dmem_cen : out std_logic;  -- Data Memory chip enable (low active)
    dmem_din : out std_logic_vector(15 downto 0);  -- Data Memory data input
    dmem_wen : out std_logic_vector(1 downto 0);  -- Data Memory write byte enable (low active)
    irq_acc : out std_logic_vector(IRQ_NR-3 downto 0);  -- Interrupt request accepted (one-hot signal)
    lfxt_enable : out std_logic;  -- ASIC ONLY: Low frequency oscillator enable
    lfxt_wkup : out std_logic;  -- ASIC ONLY: Low frequency oscillator wake-up (asynchronous)
    mclk : out std_logic;  -- Main system clock
    dma_dout : out std_logic_vector(15 downto 0);  -- Direct Memory Access data output
    dma_ready : out std_logic;  -- Direct Memory Access is complete
    dma_resp : out std_logic;  -- Direct Memory Access response (0:Okay / 1:Error)
    per_addr : out std_logic_vector(13 downto 0);  -- Peripheral address
    per_din : out std_logic_vector(15 downto 0);  -- Peripheral data input
    per_en : out std_logic;  -- Peripheral enable (high active)
    per_we : out std_logic_vector(1 downto 0);  -- Peripheral write byte enable (high active)
    pmem_addr : out std_logic_vector(PMEM_MSB downto 0);  -- Program Memory address
    pmem_cen : out std_logic;  -- Program Memory chip enable (low active)
    pmem_din : out std_logic_vector(15 downto 0);  -- Program Memory data input (optional)
    pmem_wen : out std_logic_vector(1 downto 0);  -- Program Memory write enable (low active) (optional)
    puc_rst : out std_logic;  -- Main system reset
    smclk : out std_logic;  -- ASIC ONLY: SMCLK
    smclk_en : out std_logic;  -- FPGA ONLY: SMCLK enable

  -- INPUTs
  --=======
    cpu_en : in std_logic;  -- Enable CPU code execution (asynchronous and non-glitchy)
    dbg_en : in std_logic;  -- Debug interface enable (asynchronous and non-glitchy)
    dbg_i2c_addr : in std_logic_vector(6 downto 0);  -- Debug interface: I2C Address
    dbg_i2c_broadcast : in std_logic_vector(6 downto 0);  -- Debug interface: I2C Broadcast Address (for multicore systems)
    dbg_i2c_scl : in std_logic;  -- Debug interface: I2C SCL
    dbg_i2c_sda_in : in std_logic;  -- Debug interface: I2C SDA IN
    dbg_uart_rxd : in std_logic;  -- Debug interface: UART RXD (asynchronous)
    dco_clk : in std_logic;  -- Fast oscillator (fast clock)
    dmem_dout : in std_logic_vector(15 downto 0);  -- Data Memory data output
    irq : in std_logic_vector(IRQ_NR-3 downto 0);  -- Maskable interrupts (14, 30 or 62)
    lfxt_clk : in std_logic;  -- Low frequency oscillator (typ 32kHz)
    dma_addr : in std_logic_vector(15 downto 1);  -- Direct Memory Access address
    dma_din : in std_logic_vector(15 downto 0);  -- Direct Memory Access data input
    dma_en : in std_logic;  -- Direct Memory Access enable (high active)
    dma_priority : in std_logic;  -- Direct Memory Access priority (0:low / 1:high)
    dma_we : in std_logic_vector(1 downto 0);  -- Direct Memory Access write byte enable (high active)
    dma_wkup : in std_logic;  -- ASIC ONLY: DMA Wake-up (asynchronous and non-glitchy)
    nmi : in std_logic;  -- Non-maskable interrupt (asynchronous and non-glitchy)
    per_dout : in std_logic_vector(15 downto 0);  -- Peripheral data output
    pmem_dout : in std_logic_vector(15 downto 0);  -- Program Memory data output
    reset_n : in std_logic;  -- Reset Pin (active low, asynchronous and non-glitchy)
    scan_enable : in std_logic;  -- ASIC ONLY: Scan enable (active during scan shifting)
    scan_mode : in std_logic   -- ASIC ONLY: Scan mode
    wkup : in std_logic  -- ASIC ONLY: System Wake-up (asynchronous and non-glitchy)
  );
  constant INST_NR : std_logic_vector(7 downto 0) := X"00";
  constant TOTAL_NR : std_logic_vector(7 downto 0) := X"00";
end openMSP430;

architecture RTL of openMSP430 is
  component omsp_clock_module
  port (
    aclk : std_logic_vector(? downto 0);
    aclk_en : std_logic_vector(? downto 0);
    cpu_en_s : std_logic_vector(? downto 0);
    cpu_mclk : std_logic_vector(? downto 0);
    dma_mclk : std_logic_vector(? downto 0);
    dbg_clk : std_logic_vector(? downto 0);
    dbg_en_s : std_logic_vector(? downto 0);
    dbg_rst : std_logic_vector(? downto 0);
    dco_enable : std_logic_vector(? downto 0);
    dco_wkup : std_logic_vector(? downto 0);
    lfxt_enable : std_logic_vector(? downto 0);
    lfxt_wkup : std_logic_vector(? downto 0);
    per_dout : std_logic_vector(? downto 0);
    por : std_logic_vector(? downto 0);
    puc_pnd_set : std_logic_vector(? downto 0);
    puc_rst : std_logic_vector(? downto 0);
    smclk : std_logic_vector(? downto 0);
    smclk_en : std_logic_vector(? downto 0);
    cpu_en : std_logic_vector(? downto 0);
    cpuoff : std_logic_vector(? downto 0);
    dbg_cpu_reset : std_logic_vector(? downto 0);
    dbg_en : std_logic_vector(? downto 0);
    dco_clk : std_logic_vector(? downto 0);
    lfxt_clk : std_logic_vector(? downto 0);
    mclk_dma_enable : std_logic_vector(? downto 0);
    mclk_dma_wkup : std_logic_vector(? downto 0);
    mclk_enable : std_logic_vector(? downto 0);
    mclk_wkup : std_logic_vector(? downto 0);
    oscoff : std_logic_vector(? downto 0);
    per_addr : std_logic_vector(? downto 0);
    per_din : std_logic_vector(? downto 0);
    per_en : std_logic_vector(? downto 0);
    per_we : std_logic_vector(? downto 0);
    reset_n : std_logic_vector(? downto 0);
    scan_enable : std_logic_vector(? downto 0);
    scan_mode : std_logic_vector(? downto 0);
    scg0 : std_logic_vector(? downto 0);
    scg1 : std_logic_vector(? downto 0);
    wdt_reset : std_logic_vector(? downto 0)
  );
  end component;

  component omsp_frontend
  port (
    cpu_halt_st : std_logic_vector(? downto 0);
    decode_noirq : std_logic_vector(? downto 0);
    e_state : std_logic_vector(? downto 0);
    exec_done : std_logic_vector(? downto 0);
    inst_ad : std_logic_vector(? downto 0);
    inst_as : std_logic_vector(? downto 0);
    inst_alu : std_logic_vector(? downto 0);
    inst_bw : std_logic_vector(? downto 0);
    inst_dest : std_logic_vector(? downto 0);
    inst_dext : std_logic_vector(? downto 0);
    inst_irq_rst : std_logic_vector(? downto 0);
    inst_jmp : std_logic_vector(? downto 0);
    inst_mov : std_logic_vector(? downto 0);
    inst_sext : std_logic_vector(? downto 0);
    inst_so : std_logic_vector(? downto 0);
    inst_src : std_logic_vector(? downto 0);
    inst_type : std_logic_vector(? downto 0);
    irq_acc : std_logic_vector(? downto 0);
    mab : std_logic_vector(? downto 0);
    mb_en : std_logic_vector(? downto 0);
    mclk_dma_enable : std_logic_vector(? downto 0);
    mclk_dma_wkup : std_logic_vector(? downto 0);
    mclk_enable : std_logic_vector(? downto 0);
    mclk_wkup : std_logic_vector(? downto 0);
    nmi_acc : std_logic_vector(? downto 0);
    pc : std_logic_vector(? downto 0);
    pc_nxt : std_logic_vector(? downto 0);
    cpu_en_s : std_logic_vector(? downto 0);
    cpu_halt_cmd : std_logic_vector(? downto 0);
    cpuoff : std_logic_vector(? downto 0);
    dbg_reg_sel : std_logic_vector(? downto 0);
    dma_en : std_logic_vector(? downto 0);
    dma_wkup : std_logic_vector(? downto 0);
    fe_pmem_wait : std_logic_vector(? downto 0);
    gie : std_logic_vector(? downto 0);
    irq : std_logic_vector(? downto 0);
    mclk : std_logic_vector(? downto 0);
    mdb_in : std_logic_vector(? downto 0);
    nmi_pnd : std_logic_vector(? downto 0);
    nmi_wkup : std_logic_vector(? downto 0);
    pc_sw : std_logic_vector(? downto 0);
    pc_sw_wr : std_logic_vector(? downto 0);
    puc_rst : std_logic_vector(? downto 0);
    scan_enable : std_logic_vector(? downto 0);
    wdt_irq : std_logic_vector(? downto 0);
    wdt_wkup : std_logic_vector(? downto 0);
    wkup : std_logic_vector(? downto 0)
  );
  end component;

  component omsp_execution_unit
  port (
    cpuoff : std_logic_vector(? downto 0);
    dbg_reg_din : std_logic_vector(? downto 0);
    mab : std_logic_vector(? downto 0);
    mb_en : std_logic_vector(? downto 0);
    mb_wr : std_logic_vector(? downto 0);
    mdb_out : std_logic_vector(? downto 0);
    oscoff : std_logic_vector(? downto 0);
    pc_sw : std_logic_vector(? downto 0);
    pc_sw_wr : std_logic_vector(? downto 0);
    scg0 : std_logic_vector(? downto 0);
    scg1 : std_logic_vector(? downto 0);
    dbg_halt_st : std_logic_vector(? downto 0);
    dbg_mem_dout : std_logic_vector(? downto 0);
    dbg_reg_wr : std_logic_vector(? downto 0);
    e_state : std_logic_vector(? downto 0);
    exec_done : std_logic_vector(? downto 0);
    gie : std_logic_vector(? downto 0);
    inst_ad : std_logic_vector(? downto 0);
    inst_as : std_logic_vector(? downto 0);
    inst_alu : std_logic_vector(? downto 0);
    inst_bw : std_logic_vector(? downto 0);
    inst_dest : std_logic_vector(? downto 0);
    inst_dext : std_logic_vector(? downto 0);
    inst_irq_rst : std_logic_vector(? downto 0);
    inst_jmp : std_logic_vector(? downto 0);
    inst_mov : std_logic_vector(? downto 0);
    inst_sext : std_logic_vector(? downto 0);
    inst_so : std_logic_vector(? downto 0);
    inst_src : std_logic_vector(? downto 0);
    inst_type : std_logic_vector(? downto 0);
    mclk : std_logic_vector(? downto 0);
    mdb_in : std_logic_vector(? downto 0);
    pc : std_logic_vector(? downto 0);
    pc_nxt : std_logic_vector(? downto 0);
    puc_rst : std_logic_vector(? downto 0);
    scan_enable : std_logic_vector(? downto 0)
  );
  end component;

  component omsp_mem_backbone
  port (
    cpu_halt_cmd : std_logic_vector(? downto 0);
    dbg_mem_din : std_logic_vector(? downto 0);
    dmem_addr : std_logic_vector(? downto 0);
    dmem_cen : std_logic_vector(? downto 0);
    dmem_din : std_logic_vector(? downto 0);
    dmem_wen : std_logic_vector(? downto 0);
    eu_mdb_in : std_logic_vector(? downto 0);
    fe_mdb_in : std_logic_vector(? downto 0);
    fe_pmem_wait : std_logic_vector(? downto 0);
    dma_dout : std_logic_vector(? downto 0);
    dma_ready : std_logic_vector(? downto 0);
    dma_resp : std_logic_vector(? downto 0);
    per_addr : std_logic_vector(? downto 0);
    per_din : std_logic_vector(? downto 0);
    per_we : std_logic_vector(? downto 0);
    per_en : std_logic_vector(? downto 0);
    pmem_addr : std_logic_vector(? downto 0);
    pmem_cen : std_logic_vector(? downto 0);
    pmem_din : std_logic_vector(? downto 0);
    pmem_wen : std_logic_vector(? downto 0);
    cpu_halt_st : std_logic_vector(? downto 0);
    dbg_halt_cmd : std_logic_vector(? downto 0);
    dbg_mem_addr : std_logic_vector(? downto 0);
    dbg_mem_dout : std_logic_vector(? downto 0);
    dbg_mem_en : std_logic_vector(? downto 0);
    dbg_mem_wr : std_logic_vector(? downto 0);
    dmem_dout : std_logic_vector(? downto 0);
    eu_mab : std_logic_vector(? downto 0);
    eu_mb_en : std_logic_vector(? downto 0);
    eu_mb_wr : std_logic_vector(? downto 0);
    eu_mdb_out : std_logic_vector(? downto 0);
    fe_mab : std_logic_vector(? downto 0);
    fe_mb_en : std_logic_vector(? downto 0);
    mclk : std_logic_vector(? downto 0);
    dma_addr : std_logic_vector(? downto 0);
    dma_din : std_logic_vector(? downto 0);
    dma_en : std_logic_vector(? downto 0);
    dma_priority : std_logic_vector(? downto 0);
    dma_we : std_logic_vector(? downto 0);
    per_dout : std_logic_vector(? downto 0);
    pmem_dout : std_logic_vector(? downto 0);
    puc_rst : std_logic_vector(? downto 0);
    scan_enable : std_logic_vector(? downto 0)
  );
  end component;

  component omsp_sfr
  port (
    cpu_id : std_logic_vector(? downto 0);
    nmi_pnd : std_logic_vector(? downto 0);
    nmi_wkup : std_logic_vector(? downto 0);
    per_dout : std_logic_vector(? downto 0);
    wdtie : std_logic_vector(? downto 0);
    wdtifg_sw_clr : std_logic_vector(? downto 0);
    wdtifg_sw_set : std_logic_vector(? downto 0);
    cpu_nr_inst : std_logic_vector(? downto 0);
    cpu_nr_total : std_logic_vector(? downto 0);
    mclk : std_logic_vector(? downto 0);
    nmi : std_logic_vector(? downto 0);
    nmi_acc : std_logic_vector(? downto 0);
    per_addr : std_logic_vector(? downto 0);
    per_din : std_logic_vector(? downto 0);
    per_en : std_logic_vector(? downto 0);
    per_we : std_logic_vector(? downto 0);
    puc_rst : std_logic_vector(? downto 0);
    scan_mode : std_logic_vector(? downto 0);
    wdtifg : std_logic_vector(? downto 0);
    wdtnmies : std_logic_vector(? downto 0)
  );
  end component;

  component omsp_watchdog
  port (
    per_dout : std_logic_vector(? downto 0);
    wdt_irq : std_logic_vector(? downto 0);
    wdt_reset : std_logic_vector(? downto 0);
    wdt_wkup : std_logic_vector(? downto 0);
    wdtifg : std_logic_vector(? downto 0);
    wdtnmies : std_logic_vector(? downto 0);
    aclk : std_logic_vector(? downto 0);
    aclk_en : std_logic_vector(? downto 0);
    dbg_freeze : std_logic_vector(? downto 0);
    mclk : std_logic_vector(? downto 0);
    per_addr : std_logic_vector(? downto 0);
    per_din : std_logic_vector(? downto 0);
    per_en : std_logic_vector(? downto 0);
    per_we : std_logic_vector(? downto 0);
    por : std_logic_vector(? downto 0);
    puc_rst : std_logic_vector(? downto 0);
    scan_enable : std_logic_vector(? downto 0);
    scan_mode : std_logic_vector(? downto 0);
    smclk : std_logic_vector(? downto 0);
    smclk_en : std_logic_vector(? downto 0);
    wdtie : std_logic_vector(? downto 0);
    wdtifg_irq_clr : std_logic_vector(? downto 0);
    wdtifg_sw_clr : std_logic_vector(? downto 0);
    wdtifg_sw_set : std_logic_vector(? downto 0)
  );
  end component;

  component omsp_multiplier
  port (
    per_dout : std_logic_vector(? downto 0);
    mclk : std_logic_vector(? downto 0);
    per_addr : std_logic_vector(? downto 0);
    per_din : std_logic_vector(? downto 0);
    per_en : std_logic_vector(? downto 0);
    per_we : std_logic_vector(? downto 0);
    puc_rst : std_logic_vector(? downto 0);
    scan_enable : std_logic_vector(? downto 0)
  );
  end component;

  component omsp_dbg
  port (
    dbg_cpu_reset : std_logic_vector(? downto 0);
    dbg_freeze : std_logic_vector(? downto 0);
    dbg_halt_cmd : std_logic_vector(? downto 0);
    dbg_i2c_sda_out : std_logic_vector(? downto 0);
    dbg_mem_addr : std_logic_vector(? downto 0);
    dbg_mem_dout : std_logic_vector(? downto 0);
    dbg_mem_en : std_logic_vector(? downto 0);
    dbg_mem_wr : std_logic_vector(? downto 0);
    dbg_reg_wr : std_logic_vector(? downto 0);
    dbg_uart_txd : std_logic_vector(? downto 0);
    cpu_en_s : std_logic_vector(? downto 0);
    cpu_id : std_logic_vector(? downto 0);
    cpu_nr_inst : std_logic_vector(? downto 0);
    cpu_nr_total : std_logic_vector(? downto 0);
    dbg_clk : std_logic_vector(? downto 0);
    dbg_en_s : std_logic_vector(? downto 0);
    dbg_halt_st : std_logic_vector(? downto 0);
    dbg_i2c_addr : std_logic_vector(? downto 0);
    dbg_i2c_broadcast : std_logic_vector(? downto 0);
    dbg_i2c_scl : std_logic_vector(? downto 0);
    dbg_i2c_sda_in : std_logic_vector(? downto 0);
    dbg_mem_din : std_logic_vector(? downto 0);
    dbg_reg_din : std_logic_vector(? downto 0);
    dbg_rst : std_logic_vector(? downto 0);
    dbg_uart_rxd : std_logic_vector(? downto 0);
    decode_noirq : std_logic_vector(? downto 0);
    eu_mab : std_logic_vector(? downto 0);
    eu_mb_en : std_logic_vector(? downto 0);
    eu_mb_wr : std_logic_vector(? downto 0);
    fe_mdb_in : std_logic_vector(? downto 0);
    pc : std_logic_vector(? downto 0);
    puc_pnd_set : std_logic_vector(? downto 0)
  );
  end component;

  --=============================================================================
  -- 1)  INTERNAL WIRES/REGISTERS/PARAMETERS DECLARATION
  --=============================================================================

  signal inst_ad : std_logic_vector(7 downto 0);
  signal inst_as : std_logic_vector(7 downto 0);
  signal inst_alu : std_logic_vector(11 downto 0);
  signal inst_bw : std_logic;
  signal inst_irq_rst : std_logic;
  signal inst_mov : std_logic;
  signal inst_dest : std_logic_vector(15 downto 0);
  signal inst_dext : std_logic_vector(15 downto 0);
  signal inst_sext : std_logic_vector(15 downto 0);
  signal inst_so : std_logic_vector(7 downto 0);
  signal inst_src : std_logic_vector(15 downto 0);
  signal inst_type : std_logic_vector(2 downto 0);
  signal inst_jmp : std_logic_vector(7 downto 0);
  signal e_state : std_logic_vector(3 downto 0);
  signal exec_done : std_logic;
  signal decode_noirq : std_logic;
  signal cpu_en_s : std_logic;
  signal cpuoff : std_logic;
  signal oscoff : std_logic;
  signal scg0 : std_logic;
  signal scg1 : std_logic;
  signal por : std_logic;
  signal gie : std_logic;
  signal cpu_mclk : std_logic;
  signal dma_mclk : std_logic;
  signal mclk_dma_enable : std_logic;
  signal mclk_dma_wkup : std_logic;
  signal mclk_enable : std_logic;
  signal mclk_wkup : std_logic;
  signal cpu_id : std_logic_vector(31 downto 0);
  signal cpu_nr_inst : std_logic_vector(7 downto 0);
  signal cpu_nr_total : std_logic_vector(7 downto 0);

  signal eu_mab : std_logic_vector(15 downto 0);
  signal eu_mdb_in : std_logic_vector(15 downto 0);
  signal eu_mdb_out : std_logic_vector(15 downto 0);
  signal eu_mb_wr : std_logic_vector(1 downto 0);
  signal eu_mb_en : std_logic;
  signal fe_mab : std_logic_vector(15 downto 0);
  signal fe_mdb_in : std_logic_vector(15 downto 0);
  signal fe_mb_en : std_logic;
  signal fe_pmem_wait : std_logic;

  signal pc_sw_wr : std_logic;
  signal pc_sw : std_logic_vector(15 downto 0);
  signal pc : std_logic_vector(15 downto 0);
  signal pc_nxt : std_logic_vector(15 downto 0);

  signal nmi_acc : std_logic;
  signal nmi_pnd : std_logic;
  signal nmi_wkup : std_logic;

  signal wdtie : std_logic;
  signal wdtnmies : std_logic;
  signal wdtifg : std_logic;
  signal wdt_irq : std_logic;
  signal wdt_wkup : std_logic;
  signal wdt_reset : std_logic;
  signal wdtifg_sw_clr : std_logic;
  signal wdtifg_sw_set : std_logic;

  signal dbg_clk : std_logic;
  signal dbg_rst : std_logic;
  signal dbg_en_s : std_logic;
  signal dbg_halt_cmd : std_logic;
  signal dbg_mem_en : std_logic;
  signal dbg_reg_wr : std_logic;
  signal dbg_cpu_reset : std_logic;
  signal dbg_mem_addr : std_logic_vector(15 downto 0);
  signal dbg_mem_dout : std_logic_vector(15 downto 0);
  signal dbg_mem_din : std_logic_vector(15 downto 0);
  signal dbg_reg_din : std_logic_vector(15 downto 0);
  signal dbg_mem_wr : std_logic_vector(1 downto 0);

  signal cpu_halt_st : std_logic;
  signal cpu_halt_cmd : std_logic;
  signal puc_pnd_set : std_logic;

  signal per_dout_or : std_logic_vector(15 downto 0);
  signal per_dout_sfr : std_logic_vector(15 downto 0);
  signal per_dout_wdog : std_logic_vector(15 downto 0);
  signal per_dout_mpy : std_logic_vector(15 downto 0);
  signal per_dout_clk : std_logic_vector(15 downto 0);

  --=============================================================================
  -- 5)  MEMORY BACKBONE
  --=============================================================================

  signal UNUSED_fe_mab_0 : std_logic;

  --=============================================================================
  -- 7)  WATCHDOG TIMER
  --=============================================================================

  signal UNUSED_por : std_logic;
  signal UNUSED_wdtie : std_logic;
  signal UNUSED_wdtifg_sw_clr : std_logic;
  signal UNUSED_wdtifg_sw_set : std_logic;

  --=============================================================================
  -- 10)  DEBUG INTERFACE
  --=============================================================================

  signal UNUSED_decode_noirq : std_logic;
  signal UNUSED_cpu_id : std_logic_vector(31 downto 0);
  signal UNUSED_eu_mab_0 : std_logic;
  signal UNUSED_dbg_clk : std_logic;
  signal UNUSED_dbg_rst : std_logic;
  signal UNUSED_dbg_en_s : std_logic;
  signal UNUSED_dbg_mem_din : std_logic_vector(15 downto 0);
  signal UNUSED_dbg_reg_din : std_logic_vector(15 downto 0);
  signal UNUSED_puc_pnd_set : std_logic;
  signal UNUSED_dbg_i2c_addr : std_logic_vector(6 downto 0);
  signal UNUSED_dbg_i2c_broadcast : std_logic_vector(6 downto 0);
  signal UNUSED_dbg_i2c_scl : std_logic;
  signal UNUSED_dbg_i2c_sda_in : std_logic;
  signal UNUSED_dbg_uart_rxd : std_logic;

begin
  --=============================================================================
  -- 2)  GLOBAL CLOCK & RESET MANAGEMENT
  --=============================================================================

  clock_module_0 : omsp_clock_module
  port map (
    -- OUTPUTs
    aclk => aclk,  -- ACLK
    aclk_en => aclk_en,  -- ACLK enablex
    cpu_en_s => cpu_en_s,  -- Enable CPU code execution (synchronous)
    cpu_mclk => cpu_mclk,  -- Main system CPU only clock
    dma_mclk => dma_mclk,  -- Main system DMA and/or CPU clock
    dbg_clk => dbg_clk,  -- Debug unit clock
    dbg_en_s => dbg_en_s,  -- Debug interface enable (synchronous)
    dbg_rst => dbg_rst,  -- Debug unit reset
    dco_enable => dco_enable,  -- Fast oscillator enable
    dco_wkup => dco_wkup,  -- Fast oscillator wake-up (asynchronous)
    lfxt_enable => lfxt_enable,  -- Low frequency oscillator enable
    lfxt_wkup => lfxt_wkup,  -- Low frequency oscillator wake-up (asynchronous)
    per_dout => per_dout_clk,  -- Peripheral data output
    por => por,  -- Power-on reset
    puc_pnd_set => puc_pnd_set,  -- PUC pending set for the serial debug interface
    puc_rst => puc_rst,  -- Main system reset
    smclk => smclk,  -- SMCLK
    smclk_en => smclk_en,  -- SMCLK enable

    -- INPUTs
    cpu_en => cpu_en,  -- Enable CPU code execution (asynchronous)
    cpuoff => cpuoff,  -- Turns off the CPU
    dbg_cpu_reset => dbg_cpu_reset,  -- Reset CPU from debug interface
    dbg_en => dbg_en,  -- Debug interface enable (asynchronous)
    dco_clk => dco_clk,  -- Fast oscillator (fast clock)
    lfxt_clk => lfxt_clk,  -- Low frequency oscillator (typ 32kHz)
    mclk_dma_enable => mclk_dma_enable,  -- DMA Sub-System Clock enable
    mclk_dma_wkup => mclk_dma_wkup,  -- DMA Sub-System Clock wake-up (asynchronous)
    mclk_enable => mclk_enable,  -- Main System Clock enable
    mclk_wkup => mclk_wkup,  -- Main System Clock wake-up (asynchronous)
    oscoff => oscoff,  -- Turns off LFXT1 clock input
    per_addr => per_addr,  -- Peripheral address
    per_din => per_din,  -- Peripheral data input
    per_en => per_en,  -- Peripheral enable (high active)
    per_we => per_we,  -- Peripheral write enable (high active)
    reset_n => reset_n,  -- Reset Pin (low active, asynchronous)
    scan_enable => scan_enable,  -- Scan enable (active during scan shifting)
    scan_mode => scan_mode,  -- Scan mode
    scg0 => scg0,  -- System clock generator 1. Turns off the DCO
    scg1 => scg1,  -- System clock generator 1. Turns off the SMCLK
    wdt_reset => wdt_reset  -- Watchdog-timer reset
  );


  mclk <= dma_mclk;

  --=============================================================================
  -- 3)  FRONTEND (<=> FETCH & DECODE)
  --=============================================================================

  frontend_0 : omsp_frontend
  port map (
    -- OUTPUTs
    cpu_halt_st => cpu_halt_st,  -- Halt/Run status from CPU
    decode_noirq => decode_noirq,  -- Frontend decode instruction
    e_state => e_state,  -- Execution state
    exec_done => exec_done,  -- Execution completed
    inst_ad => inst_ad,  -- Decoded Inst: destination addressing mode
    inst_as => inst_as,  -- Decoded Inst: source addressing mode
    inst_alu => inst_alu,  -- ALU control signals
    inst_bw => inst_bw,  -- Decoded Inst: byte width
    inst_dest => inst_dest,  -- Decoded Inst: destination (one hot)
    inst_dext => inst_dext,  -- Decoded Inst: destination extended instruction word
    inst_irq_rst => inst_irq_rst,  -- Decoded Inst: Reset interrupt
    inst_jmp => inst_jmp,  -- Decoded Inst: Conditional jump
    inst_mov => inst_mov,  -- Decoded Inst: mov instruction
    inst_sext => inst_sext,  -- Decoded Inst: source extended instruction word
    inst_so => inst_so,  -- Decoded Inst: Single-operand arithmetic
    inst_src => inst_src,  -- Decoded Inst: source (one hot)
    inst_type => inst_type,  -- Decoded Instruction type
    irq_acc => irq_acc,  -- Interrupt request accepted
    mab => fe_mab,  -- Frontend Memory address bus
    mb_en => fe_mb_en,  -- Frontend Memory bus enable
    mclk_dma_enable => mclk_dma_enable,  -- DMA Sub-System Clock enable
    mclk_dma_wkup => mclk_dma_wkup,  -- DMA Sub-System Clock wake-up (asynchronous)
    mclk_enable => mclk_enable,  -- Main System Clock enable
    mclk_wkup => mclk_wkup,  -- Main System Clock wake-up (asynchronous)
    nmi_acc => nmi_acc,  -- Non-Maskable interrupt request accepted
    pc => pc,  -- Program counter
    pc_nxt => pc_nxt,  -- Next PC value (for CALL & IRQ)

    -- INPUTs
    cpu_en_s => cpu_en_s,  -- Enable CPU code execution (synchronous)
    cpu_halt_cmd => cpu_halt_cmd,  -- Halt CPU command
    cpuoff => cpuoff,  -- Turns off the CPU
    dbg_reg_sel => dbg_mem_addr(3 downto 0),  -- Debug selected register for rd/wr access
    dma_en => dma_en,  -- Direct Memory Access enable (high active)
    dma_wkup => dma_wkup,  -- DMA Sub-System Wake-up (asynchronous and non-glitchy)
    fe_pmem_wait => fe_pmem_wait,  -- Frontend wait for Instruction fetch
    gie => gie,  -- General interrupt enable
    irq => irq,  -- Maskable interrupts
    mclk => cpu_mclk,  -- Main system clock
    mdb_in => fe_mdb_in,  -- Frontend Memory data bus input
    nmi_pnd => nmi_pnd,  -- Non-maskable interrupt pending
    nmi_wkup => nmi_wkup,  -- NMI Wakeup
    pc_sw => pc_sw,  -- Program counter software value
    pc_sw_wr => pc_sw_wr,  -- Program counter software write
    puc_rst => puc_rst,  -- Main system reset
    scan_enable => scan_enable,  -- Scan enable (active during scan shifting)
    wdt_irq => wdt_irq,  -- Watchdog-timer interrupt
    wdt_wkup => wdt_wkup,  -- Watchdog Wakeup
    wkup => wkup  -- System Wake-up (asynchronous)
  );


  --=============================================================================
  -- 4)  EXECUTION UNIT
  --=============================================================================

  execution_unit_0 : omsp_execution_unit
  port map (
    -- OUTPUTs
    cpuoff => cpuoff,  -- Turns off the CPU
    dbg_reg_din => dbg_reg_din,  -- Debug unit CPU register data input
    mab => eu_mab,  -- Memory address bus
    mb_en => eu_mb_en,  -- Memory bus enable
    mb_wr => eu_mb_wr,  -- Memory bus write transfer
    mdb_out => eu_mdb_out,  -- Memory data bus output
    oscoff => oscoff,  -- Turns off LFXT1 clock input
    pc_sw => pc_sw,  -- Program counter software value
    pc_sw_wr => pc_sw_wr,  -- Program counter software write
    scg0 => scg0,  -- System clock generator 1. Turns off the DCO
    scg1 => scg1,  -- System clock generator 1. Turns off the SMCLK

    -- INPUTs
    dbg_halt_st => cpu_halt_st,  -- Halt/Run status from CPU
    dbg_mem_dout => dbg_mem_dout,  -- Debug unit data output
    dbg_reg_wr => dbg_reg_wr,  -- Debug unit CPU register write
    e_state => e_state,  -- Execution state
    exec_done => exec_done,  -- Execution completed
    gie => gie,  -- General interrupt enable
    inst_ad => inst_ad,  -- Decoded Inst: destination addressing mode
    inst_as => inst_as,  -- Decoded Inst: source addressing mode
    inst_alu => inst_alu,  -- ALU control signals
    inst_bw => inst_bw,  -- Decoded Inst: byte width
    inst_dest => inst_dest,  -- Decoded Inst: destination (one hot)
    inst_dext => inst_dext,  -- Decoded Inst: destination extended instruction word
    inst_irq_rst => inst_irq_rst,  -- Decoded Inst: reset interrupt
    inst_jmp => inst_jmp,  -- Decoded Inst: Conditional jump
    inst_mov => inst_mov,  -- Decoded Inst: mov instruction
    inst_sext => inst_sext,  -- Decoded Inst: source extended instruction word
    inst_so => inst_so,  -- Decoded Inst: Single-operand arithmetic
    inst_src => inst_src,  -- Decoded Inst: source (one hot)
    inst_type => inst_type,  -- Decoded Instruction type
    mclk => cpu_mclk,  -- Main system clock
    mdb_in => eu_mdb_in,  -- Memory data bus input
    pc => pc,  -- Program counter
    pc_nxt => pc_nxt,  -- Next PC value (for CALL & IRQ)
    puc_rst => puc_rst,  -- Main system reset
    scan_enable => scan_enable  -- Scan enable (active during scan shifting)
  );


  --=============================================================================
  -- 5)  MEMORY BACKBONE
  --=============================================================================

  mem_backbone_0 : omsp_mem_backbone
  port map (
    -- OUTPUTs
    cpu_halt_cmd => cpu_halt_cmd,  -- Halt CPU command
    dbg_mem_din => dbg_mem_din,  -- Debug unit Memory data input
    dmem_addr => dmem_addr,  -- Data Memory address
    dmem_cen => dmem_cen,  -- Data Memory chip enable (low active)
    dmem_din => dmem_din,  -- Data Memory data input
    dmem_wen => dmem_wen,  -- Data Memory write enable (low active)
    eu_mdb_in => eu_mdb_in,  -- Execution Unit Memory data bus input
    fe_mdb_in => fe_mdb_in,  -- Frontend Memory data bus input
    fe_pmem_wait => fe_pmem_wait,  -- Frontend wait for Instruction fetch
    dma_dout => dma_dout,  -- Direct Memory Access data output
    dma_ready => dma_ready,  -- Direct Memory Access is complete
    dma_resp => dma_resp,  -- Direct Memory Access response (0:Okay / 1:Error)
    per_addr => per_addr,  -- Peripheral address
    per_din => per_din,  -- Peripheral data input
    per_we => per_we,  -- Peripheral write enable (high active)
    per_en => per_en,  -- Peripheral enable (high active)
    pmem_addr => pmem_addr,  -- Program Memory address
    pmem_cen => pmem_cen,  -- Program Memory chip enable (low active)
    pmem_din => pmem_din,  -- Program Memory data input (optional)
    pmem_wen => pmem_wen,  -- Program Memory write enable (low active) (optional)

    -- INPUTs
    cpu_halt_st => cpu_halt_st,  -- Halt/Run status from CPU
    dbg_halt_cmd => dbg_halt_cmd,  -- Debug interface Halt CPU command
    dbg_mem_addr => dbg_mem_addr(15 downto 1),  -- Debug address for rd/wr access
    dbg_mem_dout => dbg_mem_dout,  -- Debug unit data output
    dbg_mem_en => dbg_mem_en,  -- Debug unit memory enable
    dbg_mem_wr => dbg_mem_wr,  -- Debug unit memory write
    dmem_dout => dmem_dout,  -- Data Memory data output
    eu_mab => eu_mab(15 downto 1),  -- Execution Unit Memory address bus
    eu_mb_en => eu_mb_en,  -- Execution Unit Memory bus enable
    eu_mb_wr => eu_mb_wr,  -- Execution Unit Memory bus write transfer
    eu_mdb_out => eu_mdb_out,  -- Execution Unit Memory data bus output
    fe_mab => fe_mab(15 downto 1),  -- Frontend Memory address bus
    fe_mb_en => fe_mb_en,  -- Frontend Memory bus enable
    mclk => dma_mclk,  -- Main system clock
    dma_addr => dma_addr,  -- Direct Memory Access address
    dma_din => dma_din,  -- Direct Memory Access data input
    dma_en => dma_en,  -- Direct Memory Access enable (high active)
    dma_priority => dma_priority,  -- Direct Memory Access priority (0:low / 1:high)
    dma_we => dma_we,  -- Direct Memory Access write byte enable (high active)
    per_dout => per_dout_or,  -- Peripheral data output
    pmem_dout => pmem_dout,  -- Program Memory data output
    puc_rst => puc_rst,  -- Main system reset
    scan_enable => scan_enable  -- Scan enable (active during scan shifting)
  );


  UNUSED_fe_mab_0 <= fe_mab(0);

  --=============================================================================
  -- 6)  SPECIAL FUNCTION REGISTERS
  --=============================================================================
  sfr_0 : omsp_sfr
  port map (
    -- OUTPUTs
    cpu_id => cpu_id,  -- CPU ID
    nmi_pnd => nmi_pnd,  -- NMI Pending
    nmi_wkup => nmi_wkup,  -- NMI Wakeup
    per_dout => per_dout_sfr,  -- Peripheral data output
    wdtie => wdtie,  -- Watchdog-timer interrupt enable
    wdtifg_sw_clr => wdtifg_sw_clr,  -- Watchdog-timer interrupt flag software clear
    wdtifg_sw_set => wdtifg_sw_set,  -- Watchdog-timer interrupt flag software set

    -- INPUTs
    cpu_nr_inst => cpu_nr_inst,  -- Current oMSP instance number
    cpu_nr_total => cpu_nr_total,  -- Total number of oMSP instances-1
    mclk => dma_mclk,  -- Main system clock
    nmi => nmi,  -- Non-maskable interrupt (asynchronous)
    nmi_acc => nmi_acc,  -- Non-Maskable interrupt request accepted
    per_addr => per_addr,  -- Peripheral address
    per_din => per_din,  -- Peripheral data input
    per_en => per_en,  -- Peripheral enable (high active)
    per_we => per_we,  -- Peripheral write enable (high active)
    puc_rst => puc_rst,  -- Main system reset
    scan_mode => scan_mode,  -- Scan mode
    wdtifg => wdtifg,  -- Watchdog-timer interrupt flag
    wdtnmies => wdtnmies  -- Watchdog-timer NMI edge selection
  );


  --=============================================================================
  -- 7)  WATCHDOG TIMER
  --=============================================================================
  WATCHDOG_GENERATING_0 : if (WATCHDOG = '1') generate
    watchdog_0 : omsp_watchdog
    port map (
      -- OUTPUTs
      per_dout => per_dout_wdog,    -- Peripheral data output
      wdt_irq => wdt_irq,    -- Watchdog-timer interrupt
      wdt_reset => wdt_reset,    -- Watchdog-timer reset
      wdt_wkup => wdt_wkup,    -- Watchdog Wakeup
      wdtifg => wdtifg,    -- Watchdog-timer interrupt flag
      wdtnmies => wdtnmies,    -- Watchdog-timer NMI edge selection

      -- INPUTs
      aclk => aclk,    -- ACLK
      aclk_en => aclk_en,    -- ACLK enable
      dbg_freeze => dbg_freeze,    -- Freeze Watchdog counter
      mclk => dma_mclk,    -- Main system clock
      per_addr => per_addr,    -- Peripheral address
      per_din => per_din,    -- Peripheral data input
      per_en => per_en,    -- Peripheral enable (high active)
      per_we => per_we,    -- Peripheral write enable (high active)
      por => por,    -- Power-on reset
      puc_rst => puc_rst,    -- Main system reset
      scan_enable => scan_enable,    -- Scan enable (active during scan shifting)
      scan_mode => scan_mode,    -- Scan mode
      smclk => smclk,    -- SMCLK
      smclk_en => smclk_en,    -- SMCLK enable
      wdtie => wdtie,    -- Watchdog-timer interrupt enable
      wdtifg_irq_clr => irq_acc(IRQ_NR-6),    -- Clear Watchdog-timer interrupt flag
      wdtifg_sw_clr => wdtifg_sw_clr,    -- Watchdog-timer interrupt flag software clear
      wdtifg_sw_set => wdtifg_sw_set    -- Watchdog-timer interrupt flag software set
    );
  elsif (WATCHDOG = '0') generate
    per_dout_wdog <= X"0000";
    wdt_irq <= '0';
    wdt_reset <= '0';
    wdt_wkup <= '0';
    wdtifg <= '0';
    wdtnmies <= '0';
    UNUSED_por <= por;
    UNUSED_wdtie <= wdtie;
    UNUSED_wdtifg_sw_clr <= wdtifg_sw_clr;
    UNUSED_wdtifg_sw_set <= wdtifg_sw_set;
  end generate;


  --=============================================================================
  -- 8)  HARDWARE MULTIPLIER
  --=============================================================================
  MULTIPLIER_GENERATING_1 : if (MULTIPLIER = '1') generate
    multiplier_0 : omsp_multiplier
    port map (


      -- OUTPUTs
      per_dout => per_dout_mpy,    -- Peripheral data output

      -- INPUTs
      mclk => dma_mclk,    -- Main system clock
      per_addr => per_addr,    -- Peripheral address
      per_din => per_din,    -- Peripheral data input
      per_en => per_en,    -- Peripheral enable (high active)
      per_we => per_we,    -- Peripheral write enable (high active)
      puc_rst => puc_rst,    -- Main system reset
      scan_enable => scan_enable    -- Scan enable (active during scan shifting)
    );
  elsif (MULTIPLIER = '0') generate
    per_dout_mpy <= X"0000";
  end generate;


  --=============================================================================
  -- 9)  PERIPHERALS' OUTPUT BUS
  --=============================================================================

  per_dout_or <= per_dout or per_dout_clk or per_dout_sfr or per_dout_wdog or per_dout_mpy;

  --=============================================================================
  -- 10)  DEBUG INTERFACE
  --=============================================================================

  cpu_nr_inst <= INST_NR;
  cpu_nr_total <= TOTAL_NR;

  DBG_EN_GENERATING_2 : if (DBG_EN = '1') generate
    dbg_0 : omsp_dbg
    port map (
      -- OUTPUTs
      dbg_cpu_reset => dbg_cpu_reset,    -- Reset CPU from debug interface
      dbg_freeze => dbg_freeze,    -- Freeze peripherals
      dbg_halt_cmd => dbg_halt_cmd,    -- Halt CPU command
      dbg_i2c_sda_out => dbg_i2c_sda_out,    -- Debug interface: I2C SDA OUT
      dbg_mem_addr => dbg_mem_addr,    -- Debug address for rd/wr access
      dbg_mem_dout => dbg_mem_dout,    -- Debug unit data output
      dbg_mem_en => dbg_mem_en,    -- Debug unit memory enable
      dbg_mem_wr => dbg_mem_wr,    -- Debug unit memory write
      dbg_reg_wr => dbg_reg_wr,    -- Debug unit CPU register write
      dbg_uart_txd => dbg_uart_txd,    -- Debug interface: UART TXD

      -- INPUTs
      cpu_en_s => cpu_en_s,    -- Enable CPU code execution (synchronous)
      cpu_id => cpu_id,    -- CPU ID
      cpu_nr_inst => cpu_nr_inst,    -- Current oMSP instance number
      cpu_nr_total => cpu_nr_total,    -- Total number of oMSP instances-1
      dbg_clk => dbg_clk,    -- Debug unit clock
      dbg_en_s => dbg_en_s,    -- Debug interface enable (synchronous)
      dbg_halt_st => cpu_halt_st,    -- Halt/Run status from CPU
      dbg_i2c_addr => dbg_i2c_addr,    -- Debug interface: I2C Address
      dbg_i2c_broadcast => dbg_i2c_broadcast,    -- Debug interface: I2C Broadcast Address (for multicore systems)
      dbg_i2c_scl => dbg_i2c_scl,    -- Debug interface: I2C SCL
      dbg_i2c_sda_in => dbg_i2c_sda_in,    -- Debug interface: I2C SDA IN
      dbg_mem_din => dbg_mem_din,    -- Debug unit Memory data input
      dbg_reg_din => dbg_reg_din,    -- Debug unit CPU register data input
      dbg_rst => dbg_rst,    -- Debug unit reset
      dbg_uart_rxd => dbg_uart_rxd,    -- Debug interface: UART RXD (asynchronous)
      decode_noirq => decode_noirq,    -- Frontend decode instruction
      eu_mab => eu_mab,    -- Execution-Unit Memory address bus
      eu_mb_en => eu_mb_en,    -- Execution-Unit Memory bus enable
      eu_mb_wr => eu_mb_wr,    -- Execution-Unit Memory bus write transfer
      fe_mdb_in => fe_mdb_in,    -- Frontend Memory data bus input
      pc => pc,    -- Program counter
      puc_pnd_set => puc_pnd_set    -- PUC pending set for the serial debug interface
    );
  elsif (DBG_EN = '0') generate
    dbg_cpu_reset <= '0';
    dbg_freeze <= not cpu_en_s;
    dbg_halt_cmd <= '0';
    dbg_i2c_sda_out <= '1';
    dbg_mem_addr <= X"0000";
    dbg_mem_dout <= X"0000";
    dbg_mem_en <= '0';
    dbg_mem_wr <= "00";
    dbg_reg_wr <= '0';
    dbg_uart_txd <= '1';
    dbg_uart_txd <= '1';
    UNUSED_decode_noirq <= decode_noirq;
    UNUSED_cpu_id <= cpu_id;
    UNUSED_eu_mab_0 <= eu_mab(0);
    UNUSED_dbg_clk <= dbg_clk;
    UNUSED_dbg_rst <= dbg_rst;
    UNUSED_dbg_en_s <= dbg_en_s;
    UNUSED_dbg_mem_din <= dbg_mem_din;
    UNUSED_dbg_reg_din <= dbg_reg_din;
    UNUSED_puc_pnd_set <= puc_pnd_set;
    UNUSED_dbg_i2c_addr <= dbg_i2c_addr;
    UNUSED_dbg_i2c_broadcast <= dbg_i2c_broadcast;
    UNUSED_dbg_i2c_scl <= dbg_i2c_scl;
    UNUSED_dbg_i2c_sda_in <= dbg_i2c_sda_in;
    UNUSED_dbg_uart_rxd <= dbg_uart_rxd;
  end generate;
end RTL;
