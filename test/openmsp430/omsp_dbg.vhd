-- Converted from omsp_dbg.v
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
-- *File Name: omsp_dbg.v
--
-- *Module Description:
--                       Debug interface
--
-- *Author(s):
--              - Olivier Girard,    olgirard@gmail.com
--

use work."openMSP430_defines.v".all;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity omsp_dbg is
  port (
  -- OUTPUTs
  --========
    dbg_cpu_reset : out std_logic;  -- Reset CPU from debug interface
    dbg_freeze : out std_logic;  -- Freeze peripherals
    dbg_halt_cmd : out std_logic;  -- Halt CPU command
    dbg_i2c_sda_out : out std_logic;  -- Debug interface: I2C SDA OUT
    dbg_mem_addr : out std_logic_vector(15 downto 0);  -- Debug address for rd/wr access
    dbg_mem_dout : out std_logic_vector(15 downto 0);  -- Debug unit data output
    dbg_mem_en : out std_logic;  -- Debug unit memory enable
    dbg_mem_wr : out std_logic_vector(1 downto 0);  -- Debug unit memory write
    dbg_reg_wr : out std_logic;  -- Debug unit CPU register write
    dbg_uart_txd : out std_logic;  -- Debug interface: UART TXD

  -- INPUTs
  --=======
    cpu_en_s : in std_logic;  -- Enable CPU code execution (synchronous)
    cpu_id : in std_logic_vector(31 downto 0);  -- CPU ID
    cpu_nr_inst : in std_logic_vector(7 downto 0);  -- Current oMSP instance number
    cpu_nr_total : in std_logic_vector(7 downto 0);  -- Total number of oMSP instances-1
    dbg_clk : in std_logic;  -- Debug unit clock
    dbg_en_s : in std_logic;  -- Debug interface enable (synchronous)
    dbg_halt_st : in std_logic;  -- Halt/Run status from CPU
    dbg_i2c_addr : in std_logic_vector(6 downto 0);  -- Debug interface: I2C Address
    dbg_i2c_broadcast : in std_logic_vector(6 downto 0);  -- Debug interface: I2C Broadcast Address (for multicore systems)
    dbg_i2c_scl : in std_logic;  -- Debug interface: I2C SCL
    dbg_i2c_sda_in : in std_logic;  -- Debug interface: I2C SDA IN
    dbg_mem_din : in std_logic_vector(15 downto 0);  -- Debug unit Memory data input
    dbg_reg_din : in std_logic_vector(15 downto 0);  -- Debug unit CPU register data input
    dbg_rst : in std_logic;  -- Debug unit reset
    dbg_uart_rxd : in std_logic;  -- Debug interface: UART RXD (asynchronous)
    decode_noirq : in std_logic;  -- Frontend decode instruction
    eu_mab : in std_logic_vector(15 downto 0);  -- Execution-Unit Memory address bus
    eu_mb_en : in std_logic;  -- Execution-Unit Memory bus enable
    eu_mb_wr : in std_logic_vector(1 downto 0);  -- Execution-Unit Memory bus write transfer
    fe_mdb_in : in std_logic_vector(15 downto 0);  -- Frontend Memory data bus input
    pc : in std_logic_vector(15 downto 0)   -- Program counter
    puc_pnd_set : in std_logic  -- PUC pending set for the serial debug interface
  );
end omsp_dbg;

architecture RTL of omsp_dbg is
  component omsp_dbg_hwbrk
  port (
    brk_halt : std_logic_vector(? downto 0);
    brk_pnd : std_logic_vector(? downto 0);
    brk_dout : std_logic_vector(? downto 0);
    brk_reg_rd : std_logic_vector(? downto 0);
    brk_reg_wr : std_logic_vector(? downto 0);
    dbg_clk : std_logic_vector(? downto 0);
    dbg_din : std_logic_vector(? downto 0);
    dbg_rst : std_logic_vector(? downto 0);
    decode_noirq : std_logic_vector(? downto 0);
    eu_mab : std_logic_vector(? downto 0);
    eu_mb_en : std_logic_vector(? downto 0);
    eu_mb_wr : std_logic_vector(? downto 0);
    pc : std_logic_vector(? downto 0)
  );
  end component;

  component omsp_dbg_uart
  port (
    dbg_addr : std_logic_vector(? downto 0);
    dbg_din : std_logic_vector(? downto 0);
    dbg_rd : std_logic_vector(? downto 0);
    dbg_uart_txd : std_logic_vector(? downto 0);
    dbg_wr : std_logic_vector(? downto 0);
    dbg_clk : std_logic_vector(? downto 0);
    dbg_dout : std_logic_vector(? downto 0);
    dbg_rd_rdy : std_logic_vector(? downto 0);
    dbg_rst : std_logic_vector(? downto 0);
    dbg_uart_rxd : std_logic_vector(? downto 0);
    mem_burst : std_logic_vector(? downto 0);
    mem_burst_end : std_logic_vector(? downto 0);
    mem_burst_rd : std_logic_vector(? downto 0);
    mem_burst_wr : std_logic_vector(? downto 0);
    mem_bw : std_logic_vector(? downto 0)
  );
  end component;

  component omsp_dbg_i2c
  port (
    dbg_addr : std_logic_vector(? downto 0);
    dbg_din : std_logic_vector(? downto 0);
    dbg_i2c_sda_out : std_logic_vector(? downto 0);
    dbg_rd : std_logic_vector(? downto 0);
    dbg_wr : std_logic_vector(? downto 0);
    dbg_clk : std_logic_vector(? downto 0);
    dbg_dout : std_logic_vector(? downto 0);
    dbg_i2c_addr : std_logic_vector(? downto 0);
    dbg_i2c_broadcast : std_logic_vector(? downto 0);
    dbg_i2c_scl : std_logic_vector(? downto 0);
    dbg_i2c_sda_in : std_logic_vector(? downto 0);
    dbg_rst : std_logic_vector(? downto 0);
    mem_burst : std_logic_vector(? downto 0);
    mem_burst_end : std_logic_vector(? downto 0);
    mem_burst_rd : std_logic_vector(? downto 0);
    mem_burst_wr : std_logic_vector(? downto 0);
    mem_bw : std_logic_vector(? downto 0)
  );
  end component;

  --=============================================================================
  -- 1)  WIRE & PARAMETER DECLARATION
  --=============================================================================

  -- Diverse wires and registers
  signal dbg_addr : std_logic_vector(5 downto 0);
  signal dbg_din : std_logic_vector(15 downto 0);
  signal dbg_wr : std_logic;
  signal mem_burst : std_logic;
  signal dbg_reg_rd : std_logic;
  signal dbg_mem_rd : std_logic;
  signal dbg_mem_rd_dly : std_logic;
  signal dbg_swbrk : std_logic;
  signal dbg_rd : std_logic;
  signal dbg_rd_rdy : std_logic;
  signal mem_burst_rd : std_logic;
  signal mem_burst_wr : std_logic;
  signal brk0_halt : std_logic;
  signal brk0_pnd : std_logic;
  signal brk0_dout : std_logic_vector(15 downto 0);
  signal brk1_halt : std_logic;
  signal brk1_pnd : std_logic;
  signal brk1_dout : std_logic_vector(15 downto 0);
  signal brk2_halt : std_logic;
  signal brk2_pnd : std_logic;
  signal brk2_dout : std_logic_vector(15 downto 0);
  signal brk3_halt : std_logic;
  signal brk3_pnd : std_logic;
  signal brk3_dout : std_logic_vector(15 downto 0);

  -- Number of registers
  constant NR_REG : integer := 25;

  -- Register addresses
  constant CPU_ID_LO : std_logic_vector(5 downto 0) := X"00";
  constant CPU_ID_HI : std_logic_vector(5 downto 0) := X"01";
  constant CPU_CTL : std_logic_vector(5 downto 0) := X"02";
  constant CPU_STAT : std_logic_vector(5 downto 0) := X"03";
  constant MEM_CTL : std_logic_vector(5 downto 0) := X"04";
  constant MEM_ADDR : std_logic_vector(5 downto 0) := X"05";
  constant MEM_DATA : std_logic_vector(5 downto 0) := X"06";
  constant MEM_CNT : std_logic_vector(5 downto 0) := X"07";
  constant BRK0_CTL : std_logic_vector(5 downto 0) := X"08";
  constant BRK0_STAT : std_logic_vector(5 downto 0) := X"09";
  constant BRK0_ADDR0 : std_logic_vector(5 downto 0) := X"0A";
  constant BRK0_ADDR1 : std_logic_vector(5 downto 0) := X"0B";
  constant BRK1_CTL : std_logic_vector(5 downto 0) := X"0C";
  constant BRK1_STAT : std_logic_vector(5 downto 0) := X"0D";
  constant BRK1_ADDR0 : std_logic_vector(5 downto 0) := X"0E";
  constant BRK1_ADDR1 : std_logic_vector(5 downto 0) := X"0F";
  constant BRK2_CTL : std_logic_vector(5 downto 0) := X"10";
  constant BRK2_STAT : std_logic_vector(5 downto 0) := X"11";
  constant BRK2_ADDR0 : std_logic_vector(5 downto 0) := X"12";
  constant BRK2_ADDR1 : std_logic_vector(5 downto 0) := X"13";
  constant BRK3_CTL : std_logic_vector(5 downto 0) := X"14";
  constant BRK3_STAT : std_logic_vector(5 downto 0) := X"15";
  constant BRK3_ADDR0 : std_logic_vector(5 downto 0) := X"16";
  constant BRK3_ADDR1 : std_logic_vector(5 downto 0) := X"17";
  constant CPU_NR : std_logic_vector(5 downto 0) := X"18";

  -- Register one-hot decoder
  constant BASE_D : integer := (concatenate(NR_REG-1, '0') & '1');
  constant CPU_ID_LO_D : integer := (BASE_D sll CPU_ID_LO);
  constant CPU_ID_HI_D : integer := (BASE_D sll CPU_ID_HI);
  constant CPU_CTL_D : integer := (BASE_D sll CPU_CTL);
  constant CPU_STAT_D : integer := (BASE_D sll CPU_STAT);
  constant MEM_CTL_D : integer := (BASE_D sll MEM_CTL);
  constant MEM_ADDR_D : integer := (BASE_D sll MEM_ADDR);
  constant MEM_DATA_D : integer := (BASE_D sll MEM_DATA);
  constant MEM_CNT_D : integer := (BASE_D sll MEM_CNT);
  constant BRK0_CTL_D : integer := (BASE_D sll BRK0_CTL);
  constant BRK0_STAT_D : integer := (BASE_D sll BRK0_STAT);
  constant BRK0_ADDR0_D : integer := (BASE_D sll BRK0_ADDR0);
  constant BRK0_ADDR1_D : integer := (BASE_D sll BRK0_ADDR1);
  constant BRK1_CTL_D : integer := (BASE_D sll BRK1_CTL);
  constant BRK1_STAT_D : integer := (BASE_D sll BRK1_STAT);
  constant BRK1_ADDR0_D : integer := (BASE_D sll BRK1_ADDR0);
  constant BRK1_ADDR1_D : integer := (BASE_D sll BRK1_ADDR1);
  constant BRK2_CTL_D : integer := (BASE_D sll BRK2_CTL);
  constant BRK2_STAT_D : integer := (BASE_D sll BRK2_STAT);
  constant BRK2_ADDR0_D : integer := (BASE_D sll BRK2_ADDR0);
  constant BRK2_ADDR1_D : integer := (BASE_D sll BRK2_ADDR1);
  constant BRK3_CTL_D : integer := (BASE_D sll BRK3_CTL);
  constant BRK3_STAT_D : integer := (BASE_D sll BRK3_STAT);
  constant BRK3_ADDR0_D : integer := (BASE_D sll BRK3_ADDR0);
  constant BRK3_ADDR1_D : integer := (BASE_D sll BRK3_ADDR1);
  constant CPU_NR_D : integer := (BASE_D sll CPU_NR);

  --============================================================================
  -- 2)  REGISTER DECODER
  --============================================================================

  -- Select Data register during a burst
  signal dbg_addr_in : std_logic_vector(5 downto 0);

  -- Register address decode
  signal reg_dec : std_logic_vector(NR_REG-1 downto 0);

  -- Read/Write probes
  signal reg_write : std_logic;
  signal reg_read : std_logic;

  -- Read/Write vectors
  signal reg_wr : std_logic_vector(NR_REG-1 downto 0);
  signal reg_rd : std_logic_vector(NR_REG-1 downto 0);

  --=============================================================================
  -- 3)  REGISTER: CORE INTERFACE
  --=============================================================================

  -- CPU_ID Register
  -------------------
  --              -------------------------------------------------------------------
  -- CPU_ID_LO:  | 15  14  13  12  11  10  9  |  8  7  6  5  4  |  3   |   2  1  0   |
  --             |----------------------------+-----------------+------+-------------|
  --             |        PER_SPACE           |   USER_VERSION  | ASIC | CPU_VERSION |
  --              --------------------------------------------------------------------
  -- CPU_ID_HI:  |   15  14  13  12  11  10   |   9  8  7  6  5  4  3  2  1   |   0  |
  --             |----------------------------+-------------------------------+------|
  --             |         PMEM_SIZE          |            DMEM_SIZE          |  MPY |
  --              -------------------------------------------------------------------

  -- This register is assigned in the SFR module


  -- CPU_NR Register
  -------------------
  --    -------------------------------------------------------------------
  --   | 15  14  13  12  11  10   9   8  |  7   6   5   4   3   2   1   0  |
  --   |---------------------------------+---------------------------------|
  --   |            CPU_TOTAL_NR         |           CPU_INST_NR           |
  --    -------------------------------------------------------------------

  signal cpu_nr : std_logic_vector(15 downto 0);


  -- CPU_CTL Register
  -------------------------------------------------------------------------------
  --       7         6          5          4           3        2     1    0
  --   Reserved   CPU_RST  RST_BRK_EN  FRZ_BRK_EN  SW_BRK_EN  ISTEP  RUN  HALT
  -------------------------------------------------------------------------------
  signal cpu_ctl : std_logic_vector(6 downto 3);

  signal cpu_ctl_wr : std_logic;

  signal cpu_ctl_full : std_logic_vector(7 downto 0);

  signal halt_cpu : std_logic;
  signal run_cpu : std_logic;
  signal istep : std_logic;


  -- CPU_STAT Register
  --------------------------------------------------------------------------------------
  --      7           6          5           4           3         2      1       0
  -- HWBRK3_PND  HWBRK2_PND  HWBRK1_PND  HWBRK0_PND  SWBRK_PND  PUC_PND  Res.  HALT_RUN
  --------------------------------------------------------------------------------------
  signal cpu_stat : std_logic_vector(3 downto 2);

  signal cpu_stat_wr : std_logic;
  signal cpu_stat_set : std_logic_vector(3 downto 2);
  signal cpu_stat_clr : std_logic_vector(3 downto 2);

  signal cpu_stat_full : std_logic_vector(7 downto 0);

  --=============================================================================
  -- 4)  REGISTER: MEMORY INTERFACE
  --=============================================================================

  -- MEM_CTL Register
  -------------------------------------------------------------------------------
  --       7     6     5     4          3        2         1       0
  --            Reserved               B/W    MEM/REG    RD/WR   START
  --
  -- START  :  -  0 : Do nothing.
  --           -  1 : Initiate memory transfer.
  --
  -- RD/WR  :  -  0 : Read access.
  --           -  1 : Write access.
  --
  -- MEM/REG:  -  0 : Memory access.
  --           -  1 : CPU Register access.
  --
  -- B/W    :  -  0 : 16 bit access.
  --           -  1 :  8 bit access (not valid for CPU Registers).
  --
  -------------------------------------------------------------------------------
  signal mem_ctl : std_logic_vector(3 downto 1);

  signal mem_ctl_wr : std_logic;

  signal mem_ctl_full : std_logic_vector(7 downto 0);

  signal mem_start : std_logic;

  signal mem_bw : std_logic;

  -- MEM_DATA Register
  --------------------
  signal mem_data : std_logic_vector(15 downto 0);
  signal mem_addr : std_logic_vector(15 downto 0);
  signal mem_access : std_logic;

  signal mem_data_wr : std_logic;

  signal dbg_mem_din_bw : std_logic_vector(15 downto 0);


  -- MEM_ADDR Register
  --------------------
  signal mem_cnt : std_logic_vector(15 downto 0);

  signal mem_addr_wr : std_logic;
  signal dbg_mem_acc : std_logic;
  signal dbg_reg_acc : std_logic;

  signal mem_addr_inc : std_logic_vector(15 downto 0);

  -- MEM_CNT Register
  -------------------

  signal mem_cnt_wr : std_logic;

  signal mem_cnt_dec : std_logic_vector(15 downto 0);

  --=============================================================================
  -- 5)  BREAKPOINTS / WATCHPOINTS
  --=============================================================================

  -- Hardware Breakpoint/Watchpoint Register read select
  signal brk0_reg_rd : std_logic_vector(3 downto 0);

  -- Hardware Breakpoint/Watchpoint Register write select
  signal brk0_reg_wr : std_logic_vector(3 downto 0);

  signal UNUSED_eu_mab : std_logic_vector(15 downto 0);
  signal UNUSED_eu_mb_en : std_logic;
  signal UNUSED_eu_mb_wr : std_logic_vector(1 downto 0);
  signal UNUSED_pc : std_logic_vector(15 downto 0);

  -- Hardware Breakpoint/Watchpoint Register read select
  signal brk1_reg_rd : std_logic_vector(3 downto 0);

  -- Hardware Breakpoint/Watchpoint Register write select
  signal brk1_reg_wr : std_logic_vector(3 downto 0);

  -- Hardware Breakpoint/Watchpoint Register read select
  signal brk2_reg_rd : std_logic_vector(3 downto 0);

  -- Hardware Breakpoint/Watchpoint Register write select
  signal brk2_reg_wr : std_logic_vector(3 downto 0);

  -- Hardware Breakpoint/Watchpoint Register read select
  signal brk3_reg_rd : std_logic_vector(3 downto 0);

  -- Hardware Breakpoint/Watchpoint Register write select
  signal brk3_reg_wr : std_logic_vector(3 downto 0);

  --============================================================================
  -- 6) DATA OUTPUT GENERATION
  --============================================================================

  signal cpu_id_lo_rd : std_logic_vector(15 downto 0);
  signal cpu_id_hi_rd : std_logic_vector(15 downto 0);
  signal cpu_ctl_rd : std_logic_vector(15 downto 0);
  signal cpu_stat_rd : std_logic_vector(15 downto 0);
  signal mem_ctl_rd : std_logic_vector(15 downto 0);
  signal mem_data_rd : std_logic_vector(15 downto 0);
  signal mem_addr_rd : std_logic_vector(15 downto 0);
  signal mem_cnt_rd : std_logic_vector(15 downto 0);
  signal cpu_nr_rd : std_logic_vector(15 downto 0);

  signal dbg_dout : std_logic_vector(15 downto 0);

  --============================================================================
  -- 7) CPU CONTROL
  --============================================================================

  -- Reset CPU
  ------------
  signal dbg_cpu_reset : std_logic;

  -- Break after reset
  --------------------
  signal halt_rst : std_logic;

  -- Freeze peripherals
  ---------------------
  signal dbg_freeze : std_logic;

  -- Single step
  --------------
  signal inc_step : std_logic_vector(1 downto 0);

  -- Run / Halt
  -------------
  signal halt_flag : std_logic;

  signal mem_halt_cpu : std_logic;
  signal mem_run_cpu : std_logic;

  signal halt_flag_clr : std_logic;
  signal halt_flag_set : std_logic;
  signal dbg_halt_cmd : std_logic;

  --============================================================================
  -- 8) MEMORY CONTROL
  --============================================================================

  -- Control Memory bursts
  ------------------------
  signal mem_burst_start : std_logic;
  signal mem_burst_end : std_logic;

  -- Trigger CPU Register or memory access during a burst
  signal mem_startb : std_logic;

  -- Combine single and burst memory start of sequence
  signal mem_seq_start : std_logic;

  -- Memory access state machine
  --------------------------------
  signal mem_state : std_logic_vector(1 downto 0);
  signal mem_state_nxt : std_logic_vector(1 downto 0);

  -- State machine definition
  constant M_IDLE : std_logic_vector(1 downto 0) := X"0";
  constant M_SET_BRK : std_logic_vector(1 downto 0) := X"1";
  constant M_ACCESS_BRK : std_logic_vector(1 downto 0) := X"2";
  constant M_ACCESS : std_logic_vector(1 downto 0) := X"3";

  -- Interface to CPU Registers and Memory bacbkone
  -------------------------------------------------
  signal dbg_mem_wr_msk : std_logic_vector(1 downto 0);

  --=============================================================================
  -- 9)  UART COMMUNICATION
  --=============================================================================

  signal UNUSED_dbg_uart_rxd : std_logic;

  --=============================================================================
  -- 10)  I2C COMMUNICATION
  --=============================================================================

  signal UNUSED_dbg_i2c_addr : std_logic_vector(6 downto 0);
  signal UNUSED_dbg_i2c_broadcast : std_logic_vector(6 downto 0);
  signal UNUSED_dbg_i2c_scl : std_logic;
  signal UNUSED_dbg_i2c_sda_in : std_logic;
  signal UNUSED_dbg_rd_rdy : std_logic;

begin
  --============================================================================
  -- 2)  REGISTER DECODER
  --============================================================================

  -- Select Data register during a burst
  dbg_addr_in <= MEM_DATA
  when mem_burst else dbg_addr;

  -- Register address decode
  processing_0 : process (dbg_addr_in)
  begin
    case ((dbg_addr_in)) is
    when CPU_ID_LO =>
      reg_dec <= CPU_ID_LO_D;
    when CPU_ID_HI =>
      reg_dec <= CPU_ID_HI_D;
    when CPU_CTL =>
      reg_dec <= CPU_CTL_D;
    when CPU_STAT =>
      reg_dec <= CPU_STAT_D;
    when MEM_CTL =>
      reg_dec <= MEM_CTL_D;
    when MEM_ADDR =>
      reg_dec <= MEM_ADDR_D;
    when MEM_DATA =>
      reg_dec <= MEM_DATA_D;
    when MEM_CNT =>
      reg_dec <= MEM_CNT_D;
    when BRK0_CTL =>
      reg_dec <= BRK0_CTL_D;
    when BRK0_STAT =>
      reg_dec <= BRK0_STAT_D;
    when BRK0_ADDR0 =>
      reg_dec <= BRK0_ADDR0_D;
    when BRK0_ADDR1 =>
      reg_dec <= BRK0_ADDR1_D;
    when BRK1_CTL =>
      reg_dec <= BRK1_CTL_D;
    when BRK1_STAT =>
      reg_dec <= BRK1_STAT_D;
    when BRK1_ADDR0 =>
      reg_dec <= BRK1_ADDR0_D;
    when BRK1_ADDR1 =>
      reg_dec <= BRK1_ADDR1_D;
    when BRK2_CTL =>
      reg_dec <= BRK2_CTL_D;
    when BRK2_STAT =>
      reg_dec <= BRK2_STAT_D;
    when BRK2_ADDR0 =>
      reg_dec <= BRK2_ADDR0_D;
    when BRK2_ADDR1 =>
      reg_dec <= BRK2_ADDR1_D;
    when BRK3_CTL =>
      reg_dec <= BRK3_CTL_D;
    when BRK3_STAT =>
      reg_dec <= BRK3_STAT_D;
    when BRK3_ADDR0 =>
      reg_dec <= BRK3_ADDR0_D;
    when BRK3_ADDR1 =>
      reg_dec <= BRK3_ADDR1_D;
    when CPU_NR =>
      reg_dec <= CPU_NR_D;
    -- pragma coverage off
    when others =>
      reg_dec <= concatenate(NR_REG, '0');
    end case;
  end process;
  -- pragma coverage on


  -- Read/Write probes
  reg_write <= dbg_wr;
  reg_read <= '1';

  -- Read/Write vectors
  reg_wr <= reg_dec and concatenate(NR_REG, reg_write);
  reg_rd <= reg_dec and concatenate(NR_REG, reg_read);

  --=============================================================================
  -- 3)  REGISTER: CORE INTERFACE
  --=============================================================================

  -- CPU_ID Register
  -------------------
  --              -------------------------------------------------------------------
  -- CPU_ID_LO:  | 15  14  13  12  11  10  9  |  8  7  6  5  4  |  3   |   2  1  0   |
  --             |----------------------------+-----------------+------+-------------|
  --             |        PER_SPACE           |   USER_VERSION  | ASIC | CPU_VERSION |
  --              --------------------------------------------------------------------
  -- CPU_ID_HI:  |   15  14  13  12  11  10   |   9  8  7  6  5  4  3  2  1   |   0  |
  --             |----------------------------+-------------------------------+------|
  --             |         PMEM_SIZE          |            DMEM_SIZE          |  MPY |
  --              -------------------------------------------------------------------

  -- This register is assigned in the SFR module


  -- CPU_NR Register
  -------------------
  --    -------------------------------------------------------------------
  --   | 15  14  13  12  11  10   9   8  |  7   6   5   4   3   2   1   0  |
  --   |---------------------------------+---------------------------------|
  --   |            CPU_TOTAL_NR         |           CPU_INST_NR           |
  --    -------------------------------------------------------------------

  cpu_nr <= (cpu_nr_total & cpu_nr_inst);


  -- CPU_CTL Register
  -------------------------------------------------------------------------------
  --       7         6          5          4           3        2     1    0
  --   Reserved   CPU_RST  RST_BRK_EN  FRZ_BRK_EN  SW_BRK_EN  ISTEP  RUN  HALT
  -------------------------------------------------------------------------------

  cpu_ctl_wr <= reg_wr(CPU_CTL);

  DBG_RST_BRK_EN_GENERATING_0 : if (DBG_RST_BRK_EN = '1') generate
    processing_1 : process (dbg_clk, dbg_rst)
    begin
      if (dbg_rst) then
        cpu_ctl <= X"6";
      elsif (rising_edge(dbg_clk)) then
        if (cpu_ctl_wr) then
          cpu_ctl <= dbg_din(6 downto 3);
        end if;
      end if;
    end process;
  elsif (DBG_RST_BRK_EN = '0') generate
    processing_2 : process (dbg_clk, dbg_rst)
    begin
      if (dbg_rst) then
        cpu_ctl <= X"2";
      elsif (rising_edge(dbg_clk)) then
        if (cpu_ctl_wr) then
          cpu_ctl <= dbg_din(6 downto 3);
        end if;
      end if;
    end process;
  end generate;


  cpu_ctl_full <= ('0' & cpu_ctl & "000");

  halt_cpu <= cpu_ctl_wr and dbg_din(HALT) and not dbg_halt_st;
  run_cpu <= cpu_ctl_wr and dbg_din(RUN) and dbg_halt_st;
  istep <= cpu_ctl_wr and dbg_din(ISTEP) and dbg_halt_st;

  -- CPU_STAT Register
  --------------------------------------------------------------------------------------
  --      7           6          5           4           3         2      1       0
  -- HWBRK3_PND  HWBRK2_PND  HWBRK1_PND  HWBRK0_PND  SWBRK_PND  PUC_PND  Res.  HALT_RUN
  --------------------------------------------------------------------------------------

  cpu_stat_wr <= reg_wr(CPU_STAT);
  cpu_stat_set <= (dbg_swbrk & puc_pnd_set);
  cpu_stat_clr <= not dbg_din(3 downto 2);

  processing_3 : process (dbg_clk, dbg_rst)
  begin
    if (dbg_rst) then
      cpu_stat <= "00";
    elsif (rising_edge(dbg_clk)) then
      if (cpu_stat_wr) then
        cpu_stat <= ((cpu_stat and cpu_stat_clr) or cpu_stat_set);
      else
        cpu_stat <= (cpu_stat or cpu_stat_set);
      end if;
    end if;
  end process;


  cpu_stat_full <= (brk3_pnd & brk2_pnd & brk1_pnd & brk0_pnd & cpu_stat & '0' & dbg_halt_st);

  --=============================================================================
  -- 4)  REGISTER: MEMORY INTERFACE
  --=============================================================================

  -- MEM_CTL Register
  -------------------------------------------------------------------------------
  --       7     6     5     4          3        2         1       0
  --            Reserved               B/W    MEM/REG    RD/WR   START
  --
  -- START  :  -  0 : Do nothing.
  --           -  1 : Initiate memory transfer.
  --
  -- RD/WR  :  -  0 : Read access.
  --           -  1 : Write access.
  --
  -- MEM/REG:  -  0 : Memory access.
  --           -  1 : CPU Register access.
  --
  -- B/W    :  -  0 : 16 bit access.
  --           -  1 :  8 bit access (not valid for CPU Registers).
  --
  -------------------------------------------------------------------------------

  mem_ctl_wr <= reg_wr(MEM_CTL);

  processing_4 : process (dbg_clk, dbg_rst)
  begin
    if (dbg_rst) then
      mem_ctl <= X"0";
    elsif (rising_edge(dbg_clk)) then
      if (mem_ctl_wr) then
        mem_ctl <= dbg_din(3 downto 1);
      end if;
    end if;
  end process;


  mem_ctl_full <= ("0000" & mem_ctl & '0');

  processing_5 : process (dbg_clk, dbg_rst)
  begin
    if (dbg_rst) then
      mem_start <= '0';
    elsif (rising_edge(dbg_clk)) then
      mem_start <= mem_ctl_wr and dbg_din(0);
    end if;
  end process;


  mem_bw <= mem_ctl(3);

  -- MEM_DATA Register
  --------------------
  mem_data_wr <= reg_wr(MEM_DATA);

  dbg_mem_din_bw <= dbg_mem_din
  when not mem_bw else (X"00" & dbg_mem_din(15 downto 8))
  when mem_addr(0) else (X"00" & dbg_mem_din(7 downto 0));

  processing_6 : process (dbg_clk, dbg_rst)
  begin
    if (dbg_rst) then
      mem_data <= X"0000";
    elsif (rising_edge(dbg_clk)) then
      if (mem_data_wr) then
        mem_data <= dbg_din;
      elsif (dbg_reg_rd) then
        mem_data <= dbg_reg_din;
      elsif (dbg_mem_rd_dly) then
        mem_data <= dbg_mem_din_bw;
      end if;
    end if;
  end process;


  -- MEM_ADDR Register
  --------------------
  mem_addr_wr <= reg_wr(MEM_ADDR);
  dbg_mem_acc <= (or dbg_mem_wr or (dbg_rd_rdy and not mem_ctl(2)));
  dbg_reg_acc <= (dbg_reg_wr or (dbg_rd_rdy and mem_ctl(2)));

  mem_addr_inc <= X"0000"
  when (mem_cnt = X"0000") else X"0002"
  when (mem_burst and dbg_mem_acc and not mem_bw) else X"0001"
  when (mem_burst and (dbg_mem_acc or dbg_reg_acc)) else X"0000";

  processing_7 : process (dbg_clk, dbg_rst)
  begin
    if (dbg_rst) then
      mem_addr <= X"0000";
    elsif (rising_edge(dbg_clk)) then
      if (mem_addr_wr) then
        mem_addr <= dbg_din;
      else
        mem_addr <= mem_addr+mem_addr_inc;
      end if;
    end if;
  end process;


  -- MEM_CNT Register
  -------------------
  mem_cnt_wr <= reg_wr(MEM_CNT);

  mem_cnt_dec <= X"0000"
  when (mem_cnt = X"0000") else X"ffff"
  when (mem_burst and (dbg_mem_acc or dbg_reg_acc)) else X"0000";

  processing_8 : process (dbg_clk, dbg_rst)
  begin
    if (dbg_rst) then
      mem_cnt <= X"0000";
    elsif (rising_edge(dbg_clk)) then
      if (mem_cnt_wr) then
        mem_cnt <= dbg_din;
      else
        mem_cnt <= mem_cnt+mem_cnt_dec;
      end if;
    end if;
  end process;


  --=============================================================================
  -- 5)  BREAKPOINTS / WATCHPOINTS
  --=============================================================================

  DBG_HWBRK_0_GENERATING_1 : if (DBG_HWBRK_0 = '1') generate
    -- Hardware Breakpoint/Watchpoint Register read select
    brk0_reg_rd <= (reg_rd(BRK0_ADDR1) & reg_rd(BRK0_ADDR0) & reg_rd(BRK0_STAT) & reg_rd(BRK0_CTL));

    -- Hardware Breakpoint/Watchpoint Register write select
    brk0_reg_wr <= (reg_wr(BRK0_ADDR1) & reg_wr(BRK0_ADDR0) & reg_wr(BRK0_STAT) & reg_wr(BRK0_CTL));

    dbg_hwbr_0 : omsp_dbg_hwbrk
    port map (
      -- OUTPUTs
      brk_halt => brk0_halt,    -- Hardware breakpoint command
      brk_pnd => brk0_pnd,    -- Hardware break/watch-point pending
      brk_dout => brk0_dout,    -- Hardware break/watch-point register data input

      -- INPUTs
      brk_reg_rd => brk0_reg_rd,    -- Hardware break/watch-point register read select
      brk_reg_wr => brk0_reg_wr,    -- Hardware break/watch-point register write select
      dbg_clk => dbg_clk,    -- Debug unit clock
      dbg_din => dbg_din,    -- Debug register data input
      dbg_rst => dbg_rst,    -- Debug unit reset
      decode_noirq => decode_noirq,    -- Frontend decode instruction
      eu_mab => eu_mab,    -- Execution-Unit Memory address bus
      eu_mb_en => eu_mb_en,    -- Execution-Unit Memory bus enable
      eu_mb_wr => eu_mb_wr,    -- Execution-Unit Memory bus write transfer
      pc => pc    -- Program counter
    );
  elsif (DBG_HWBRK_0 = '0') generate


    brk0_halt <= '0';
    brk0_pnd <= '0';
    brk0_dout <= X"0000";

    UNUSED_eu_mab <= eu_mab;
    UNUSED_eu_mb_en <= eu_mb_en;
    UNUSED_eu_mb_wr <= eu_mb_wr;
    UNUSED_pc <= pc;
  end generate;


  DBG_HWBRK_1_GENERATING_2 : if (DBG_HWBRK_1 = '1') generate
    -- Hardware Breakpoint/Watchpoint Register read select
    brk1_reg_rd <= (reg_rd(BRK1_ADDR1) & reg_rd(BRK1_ADDR0) & reg_rd(BRK1_STAT) & reg_rd(BRK1_CTL));

    -- Hardware Breakpoint/Watchpoint Register write select
    brk1_reg_wr <= (reg_wr(BRK1_ADDR1) & reg_wr(BRK1_ADDR0) & reg_wr(BRK1_STAT) & reg_wr(BRK1_CTL));

    dbg_hwbr_1 : omsp_dbg_hwbrk
    port map (
      -- OUTPUTs
      brk_halt => brk1_halt,    -- Hardware breakpoint command
      brk_pnd => brk1_pnd,    -- Hardware break/watch-point pending
      brk_dout => brk1_dout,    -- Hardware break/watch-point register data input

      -- INPUTs
      brk_reg_rd => brk1_reg_rd,    -- Hardware break/watch-point register read select
      brk_reg_wr => brk1_reg_wr,    -- Hardware break/watch-point register write select
      dbg_clk => dbg_clk,    -- Debug unit clock
      dbg_din => dbg_din,    -- Debug register data input
      dbg_rst => dbg_rst,    -- Debug unit reset
      decode_noirq => decode_noirq,    -- Frontend decode instruction
      eu_mab => eu_mab,    -- Execution-Unit Memory address bus
      eu_mb_en => eu_mb_en,    -- Execution-Unit Memory bus enable
      eu_mb_wr => eu_mb_wr,    -- Execution-Unit Memory bus write transfer
      pc => pc    -- Program counter
    );
  elsif (DBG_HWBRK_1 = '0') generate


    brk1_halt <= '0';
    brk1_pnd <= '0';
    brk1_dout <= X"0000";
  end generate;


  DBG_HWBRK_2_GENERATING_3 : if (DBG_HWBRK_2 = '1') generate
    -- Hardware Breakpoint/Watchpoint Register read select
    brk2_reg_rd <= (reg_rd(BRK2_ADDR1) & reg_rd(BRK2_ADDR0) & reg_rd(BRK2_STAT) & reg_rd(BRK2_CTL));

    -- Hardware Breakpoint/Watchpoint Register write select
    brk2_reg_wr <= (reg_wr(BRK2_ADDR1) & reg_wr(BRK2_ADDR0) & reg_wr(BRK2_STAT) & reg_wr(BRK2_CTL));

    dbg_hwbr_2 : omsp_dbg_hwbrk
    port map (
      -- OUTPUTs
      brk_halt => brk2_halt,    -- Hardware breakpoint command
      brk_pnd => brk2_pnd,    -- Hardware break/watch-point pending
      brk_dout => brk2_dout,    -- Hardware break/watch-point register data input

      -- INPUTs
      brk_reg_rd => brk2_reg_rd,    -- Hardware break/watch-point register read select
      brk_reg_wr => brk2_reg_wr,    -- Hardware break/watch-point register write select
      dbg_clk => dbg_clk,    -- Debug unit clock
      dbg_din => dbg_din,    -- Debug register data input
      dbg_rst => dbg_rst,    -- Debug unit reset
      decode_noirq => decode_noirq,    -- Frontend decode instruction
      eu_mab => eu_mab,    -- Execution-Unit Memory address bus
      eu_mb_en => eu_mb_en,    -- Execution-Unit Memory bus enable
      eu_mb_wr => eu_mb_wr,    -- Execution-Unit Memory bus write transfer
      pc => pc    -- Program counter
    );
  elsif (DBG_HWBRK_2 = '0') generate


    brk2_halt <= '0';
    brk2_pnd <= '0';
    brk2_dout <= X"0000";
  end generate;


  DBG_HWBRK_3_GENERATING_4 : if (DBG_HWBRK_3 = '1') generate
    -- Hardware Breakpoint/Watchpoint Register read select
    brk3_reg_rd <= (reg_rd(BRK3_ADDR1) & reg_rd(BRK3_ADDR0) & reg_rd(BRK3_STAT) & reg_rd(BRK3_CTL));

    -- Hardware Breakpoint/Watchpoint Register write select
    brk3_reg_wr <= (reg_wr(BRK3_ADDR1) & reg_wr(BRK3_ADDR0) & reg_wr(BRK3_STAT) & reg_wr(BRK3_CTL));

    dbg_hwbr_3 : omsp_dbg_hwbrk
    port map (
      -- OUTPUTs
      brk_halt => brk3_halt,    -- Hardware breakpoint command
      brk_pnd => brk3_pnd,    -- Hardware break/watch-point pending
      brk_dout => brk3_dout,    -- Hardware break/watch-point register data input

      -- INPUTs
      brk_reg_rd => brk3_reg_rd,    -- Hardware break/watch-point register read select
      brk_reg_wr => brk3_reg_wr,    -- Hardware break/watch-point register write select
      dbg_clk => dbg_clk,    -- Debug unit clock
      dbg_din => dbg_din,    -- Debug register data input
      dbg_rst => dbg_rst,    -- Debug unit reset
      decode_noirq => decode_noirq,    -- Frontend decode instruction
      eu_mab => eu_mab,    -- Execution-Unit Memory address bus
      eu_mb_en => eu_mb_en,    -- Execution-Unit Memory bus enable
      eu_mb_wr => eu_mb_wr,    -- Execution-Unit Memory bus write transfer
      pc => pc    -- Program counter
    );
  elsif (DBG_HWBRK_3 = '0') generate


    brk3_halt <= '0';
    brk3_pnd <= '0';
    brk3_dout <= X"0000";
  end generate;


  --============================================================================
  -- 6) DATA OUTPUT GENERATION
  --============================================================================

  cpu_id_lo_rd <= cpu_id(15 downto 0) and concatenate(16, reg_rd(CPU_ID_LO));
  cpu_id_hi_rd <= cpu_id(31 downto 16) and concatenate(16, reg_rd(CPU_ID_HI));
  cpu_ctl_rd <= (X"00" & cpu_ctl_full) and concatenate(16, reg_rd(CPU_CTL));
  cpu_stat_rd <= (X"00" & cpu_stat_full) and concatenate(16, reg_rd(CPU_STAT));
  mem_ctl_rd <= (X"00" & mem_ctl_full) and concatenate(16, reg_rd(MEM_CTL));
  mem_data_rd <= mem_data and concatenate(16, reg_rd(MEM_DATA));
  mem_addr_rd <= mem_addr and concatenate(16, reg_rd(MEM_ADDR));
  mem_cnt_rd <= mem_cnt and concatenate(16, reg_rd(MEM_CNT));
  cpu_nr_rd <= cpu_nr and concatenate(16, reg_rd(CPU_NR));

  dbg_dout <= cpu_id_lo_rd or cpu_id_hi_rd or cpu_ctl_rd or cpu_stat_rd or mem_ctl_rd or mem_data_rd or mem_addr_rd or mem_cnt_rd or brk0_dout or brk1_dout or brk2_dout or brk3_dout or cpu_nr_rd;

  -- Tell UART/I2C interface that the data is ready to be read
  processing_9 : process (dbg_clk, dbg_rst)
  begin
    if (dbg_rst) then
      dbg_rd_rdy <= '0';
    elsif (rising_edge(dbg_clk)) then
      if (mem_burst or mem_burst_rd) then
        dbg_rd_rdy <= (dbg_reg_rd or dbg_mem_rd_dly);
      else
        dbg_rd_rdy <= dbg_rd;
      end if;
    end if;
  end process;


  --============================================================================
  -- 7) CPU CONTROL
  --============================================================================

  -- Reset CPU
  ------------
  dbg_cpu_reset <= cpu_ctl(CPU_RST);

  -- Break after reset
  --------------------
  halt_rst <= cpu_ctl(RST_BRK_EN) and dbg_en_s and puc_pnd_set;

  -- Freeze peripherals
  dbg_freeze <= dbg_halt_st and (cpu_ctl(FRZ_BRK_EN) or not cpu_en_s);

  -- Software break
  -----------------
  dbg_swbrk <= (fe_mdb_in = DBG_SWBRK_OP) and decode_noirq and cpu_ctl(SW_BRK_EN);

  -- Single step
  --------------
  processing_10 : process (dbg_clk, dbg_rst)
  begin
    if (dbg_rst) then
      inc_step <= "00";
    elsif (rising_edge(dbg_clk)) then
      if (istep) then
        inc_step <= "11";
      else
        inc_step <= (inc_step(0) & '0');
      end if;
    end if;
  end process;


  -- Run / Halt
  -------------
  halt_flag_clr <= run_cpu or mem_run_cpu;
  halt_flag_set <= halt_cpu or halt_rst or dbg_swbrk or mem_halt_cpu or brk0_halt or brk1_halt or brk2_halt or brk3_halt;

  processing_11 : process (dbg_clk, dbg_rst)
  begin
    if (dbg_rst) then
      halt_flag <= '0';
    elsif (rising_edge(dbg_clk)) then
      if (halt_flag_clr) then
        halt_flag <= '0';
      elsif (halt_flag_set) then
        halt_flag <= '1';
      end if;
    end if;
  end process;


  dbg_halt_cmd <= (halt_flag or halt_flag_set) and not inc_step(1);

  --============================================================================
  -- 8) MEMORY CONTROL
  --============================================================================

  -- Control Memory bursts
  ------------------------
  mem_burst_start <= (mem_start and or mem_cnt);
  mem_burst_end <= ((dbg_wr or dbg_rd_rdy) and nor mem_cnt);

  -- Detect when burst is on going
  processing_12 : process (dbg_clk, dbg_rst)
  begin
    if (dbg_rst) then
      mem_burst <= '0';
    elsif (rising_edge(dbg_clk)) then
      if (mem_burst_start) then
        mem_burst <= '1';
      elsif (mem_burst_end) then

        mem_burst <= '0';
      end if;
    end if;
  end process;
  -- Control signals for UART/I2C interface
  mem_burst_rd <= (mem_burst_start and not mem_ctl(1));
  mem_burst_wr <= (mem_burst_start and mem_ctl(1));

  -- Trigger CPU Register or memory access during a burst
  processing_13 : process (dbg_clk, dbg_rst)
  begin
    if (dbg_rst) then
      mem_startb <= '0';
    elsif (rising_edge(dbg_clk)) then
      mem_startb <= (mem_burst and (dbg_wr or dbg_rd)) or mem_burst_rd;
    end if;
  end process;


  -- Combine single and burst memory start of sequence
  mem_seq_start <= ((mem_start and nor mem_cnt) or mem_startb);

  -- Memory access state machine
  ------------------------------

  -- State transition
  processing_14 : process (mem_state, mem_seq_start, dbg_halt_st)
  begin
    case ((mem_state)) is
    when M_IDLE =>
      mem_state_nxt <= M_IDLE
      when not mem_seq_start else M_ACCESS
      when dbg_halt_st else M_SET_BRK;
    when M_SET_BRK =>
      mem_state_nxt <= M_ACCESS_BRK
      when dbg_halt_st else M_SET_BRK;
    when M_ACCESS_BRK =>
      mem_state_nxt <= M_IDLE;
    when M_ACCESS =>
      mem_state_nxt <= M_IDLE;
    -- pragma coverage off
    when others =>
      mem_state_nxt <= M_IDLE;
    end case;
  end process;
  -- pragma coverage on


  -- State machine
  processing_15 : process (dbg_clk, dbg_rst)
  begin
    if (dbg_rst) then
      mem_state <= M_IDLE;
    elsif (rising_edge(dbg_clk)) then
      mem_state <= mem_state_nxt;
    end if;
  end process;


  -- Utility signals
  mem_halt_cpu <= (mem_state = M_IDLE) and (mem_state_nxt = M_SET_BRK);
  mem_run_cpu <= (mem_state = M_ACCESS_BRK) and (mem_state_nxt = M_IDLE);
  mem_access <= (mem_state = M_ACCESS) or (mem_state = M_ACCESS_BRK);

  -- Interface to CPU Registers and Memory bacbkone
  -------------------------------------------------
  dbg_mem_addr <= mem_addr;
  dbg_mem_dout <= mem_data
  when not mem_bw else (mem_data(7 downto 0) & X"00")
  when mem_addr(0) else (X"00" & mem_data(7 downto 0));

  dbg_reg_wr <= mem_access and mem_ctl(1) and mem_ctl(2);
  dbg_reg_rd <= mem_access and not mem_ctl(1) and mem_ctl(2);

  dbg_mem_en <= mem_access and not mem_ctl(2);
  dbg_mem_rd <= dbg_mem_en and not mem_ctl(1);

  dbg_mem_wr_msk <= "11"
  when not mem_bw else "10"
  when mem_addr(0) else "01";
  dbg_mem_wr <= (dbg_mem_en and mem_ctl(1) & dbg_mem_en and mem_ctl(1)) and dbg_mem_wr_msk;


  -- It takes one additional cycle to read from Memory as from registers
  processing_16 : process (dbg_clk, dbg_rst)
  begin
    if (dbg_rst) then
      dbg_mem_rd_dly <= '0';
    elsif (rising_edge(dbg_clk)) then
      dbg_mem_rd_dly <= dbg_mem_rd;
    end if;
  end process;


  --=============================================================================
  -- 9)  UART COMMUNICATION
  --=============================================================================
  DBG_UART_GENERATING_5 : if (DBG_UART = '1') generate
    dbg_uart_0 : omsp_dbg_uart
    port map (
      -- OUTPUTs
      dbg_addr => dbg_addr,    -- Debug register address
      dbg_din => dbg_din,    -- Debug register data input
      dbg_rd => dbg_rd,    -- Debug register data read
      dbg_uart_txd => dbg_uart_txd,    -- Debug interface: UART TXD
      dbg_wr => dbg_wr,    -- Debug register data write

      -- INPUTs
      dbg_clk => dbg_clk,    -- Debug unit clock
      dbg_dout => dbg_dout,    -- Debug register data output
      dbg_rd_rdy => dbg_rd_rdy,    -- Debug register data is ready for read
      dbg_rst => dbg_rst,    -- Debug unit reset
      dbg_uart_rxd => dbg_uart_rxd,    -- Debug interface: UART RXD
      mem_burst => mem_burst,    -- Burst on going
      mem_burst_end => mem_burst_end,    -- End TX/RX burst
      mem_burst_rd => mem_burst_rd,    -- Start TX burst
      mem_burst_wr => mem_burst_wr,    -- Start RX burst
      mem_bw => mem_bw    -- Burst byte width
    );
  elsif (DBG_UART = '0') generate


    dbg_uart_txd <= '1';

    UNUSED_dbg_uart_rxd <= dbg_uart_rxd;

    DBG_I2C_GENERATING_6 : if (DBG_I2C = '1') generate
    elsif (DBG_I2C = '0') generate
      dbg_addr <= X"00";
      dbg_din <= X"0000";
      dbg_rd <= '0';
      dbg_wr <= '0';
    end generate;
  end generate;


  --=============================================================================
  -- 10)  I2C COMMUNICATION
  --=============================================================================
  DBG_I2C_GENERATING_7 : if (DBG_I2C = '1') generate
    dbg_i2c_0 : omsp_dbg_i2c
    port map (
      -- OUTPUTs
      dbg_addr => dbg_addr,    -- Debug register address
      dbg_din => dbg_din,    -- Debug register data input
      dbg_i2c_sda_out => dbg_i2c_sda_out,    -- Debug interface: I2C SDA OUT
      dbg_rd => dbg_rd,    -- Debug register data read
      dbg_wr => dbg_wr,    -- Debug register data write

      -- INPUTs
      dbg_clk => dbg_clk,    -- Debug unit clock
      dbg_dout => dbg_dout,    -- Debug register data output
      dbg_i2c_addr => dbg_i2c_addr,    -- Debug interface: I2C Address
      dbg_i2c_broadcast => dbg_i2c_broadcast,    -- Debug interface: I2C Broadcast Address (for multicore systems)
      dbg_i2c_scl => dbg_i2c_scl,    -- Debug interface: I2C SCL
      dbg_i2c_sda_in => dbg_i2c_sda_in,    -- Debug interface: I2C SDA IN
      dbg_rst => dbg_rst,    -- Debug unit reset
      mem_burst => mem_burst,    -- Burst on going
      mem_burst_end => mem_burst_end,    -- End TX/RX burst
      mem_burst_rd => mem_burst_rd,    -- Start TX burst
      mem_burst_wr => mem_burst_wr,    -- Start RX burst
      mem_bw => mem_bw    -- Burst byte width
    );
  elsif (DBG_I2C = '0') generate


    dbg_i2c_sda_out <= '1';

    UNUSED_dbg_i2c_addr <= dbg_i2c_addr;
    UNUSED_dbg_i2c_broadcast <= dbg_i2c_broadcast;
    UNUSED_dbg_i2c_scl <= dbg_i2c_scl;
    UNUSED_dbg_i2c_sda_in <= dbg_i2c_sda_in;
    UNUSED_dbg_rd_rdy <= dbg_rd_rdy;
  end generate;
end RTL;
