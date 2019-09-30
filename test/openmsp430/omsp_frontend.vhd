-- Converted from omsp_frontend.v
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
-- *File Name: omsp_frontend.v
--
-- *Module Description:
--                       openMSP430 Instruction fetch and decode unit
--
-- *Author(s):
--              - Olivier Girard,    olgirard@gmail.com
--

use work."openMSP430_defines.v".all;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity omsp_frontend is
  port (
  -- OUTPUTs
  --========
    cpu_halt_st : out std_logic;  -- Halt/Run status from CPU
    decode_noirq : out std_logic;  -- Frontend decode instruction
    e_state : out std_logic_vector(3 downto 0);  -- Execution state
    exec_done : out std_logic;  -- Execution completed
    inst_ad : out std_logic_vector(7 downto 0);  -- Decoded Inst: destination addressing mode
    inst_as : out std_logic_vector(7 downto 0);  -- Decoded Inst: source addressing mode
    inst_alu : out std_logic_vector(11 downto 0);  -- ALU control signals
    inst_bw : out std_logic;  -- Decoded Inst: byte width
    inst_dest : out std_logic_vector(15 downto 0);  -- Decoded Inst: destination (one hot)
    inst_dext : out std_logic_vector(15 downto 0);  -- Decoded Inst: destination extended instruction word
    inst_irq_rst : out std_logic;  -- Decoded Inst: Reset interrupt
    inst_jmp : out std_logic_vector(7 downto 0);  -- Decoded Inst: Conditional jump
    inst_mov : out std_logic;  -- Decoded Inst: mov instruction
    inst_sext : out std_logic_vector(15 downto 0);  -- Decoded Inst: source extended instruction word
    inst_so : out std_logic_vector(7 downto 0);  -- Decoded Inst: Single-operand arithmetic
    inst_src : out std_logic_vector(15 downto 0);  -- Decoded Inst: source (one hot)
    inst_type : out std_logic_vector(2 downto 0);  -- Decoded Instruction type
    irq_acc : out std_logic_vector(IRQ_NR-3 downto 0);  -- Interrupt request accepted (one-hot signal)
    mab : out std_logic_vector(15 downto 0);  -- Frontend Memory address bus
    mb_en : out std_logic;  -- Frontend Memory bus enable
    mclk_dma_enable : out std_logic;  -- DMA Sub-System Clock enable
    mclk_dma_wkup : out std_logic;  -- DMA Sub-System Clock wake-up (asynchronous)
    mclk_enable : out std_logic;  -- Main System Clock enable
    mclk_wkup : out std_logic;  -- Main System Clock wake-up (asynchronous)
    nmi_acc : out std_logic;  -- Non-Maskable interrupt request accepted
    pc : out std_logic_vector(15 downto 0);  -- Program counter
    pc_nxt : out std_logic_vector(15 downto 0);  -- Next PC value (for CALL & IRQ)

  -- INPUTs
  --=======
    cpu_en_s : in std_logic;  -- Enable CPU code execution (synchronous)
    cpu_halt_cmd : in std_logic;  -- Halt CPU command
    cpuoff : in std_logic;  -- Turns off the CPU
    dbg_reg_sel : in std_logic_vector(3 downto 0);  -- Debug selected register for rd/wr access
    dma_en : in std_logic;  -- Direct Memory Access enable (high active)
    dma_wkup : in std_logic;  -- DMA Sub-System Wake-up (asynchronous and non-glitchy)
    fe_pmem_wait : in std_logic;  -- Frontend wait for Instruction fetch
    gie : in std_logic;  -- General interrupt enable
    irq : in std_logic_vector(IRQ_NR-3 downto 0);  -- Maskable interrupts
    mclk : in std_logic;  -- Main system clock
    mdb_in : in std_logic_vector(15 downto 0);  -- Frontend Memory data bus input
    nmi_pnd : in std_logic;  -- Non-maskable interrupt pending
    nmi_wkup : in std_logic;  -- NMI Wakeup
    pc_sw : in std_logic_vector(15 downto 0);  -- Program counter software value
    pc_sw_wr : in std_logic;  -- Program counter software write
    puc_rst : in std_logic;  -- Main system reset
    scan_enable : in std_logic;  -- Scan enable (active during scan shifting)
    wdt_irq : in std_logic;  -- Watchdog-timer interrupt
    wdt_wkup : in std_logic   -- Watchdog Wakeup
    wkup : in std_logic  -- System Wake-up (asynchronous)
  );
end omsp_frontend;

architecture RTL of omsp_frontend is
  component omsp_clock_gate
  port (
    gclk : std_logic_vector(? downto 0);
    clk : std_logic_vector(? downto 0);
    enable : std_logic_vector(? downto 0);
    scan_enable : std_logic_vector(? downto 0)
  );
  end component;

  component omsp_and_gate
  port (
    y : std_logic_vector(? downto 0);
    a : std_logic_vector(? downto 0);
    b : std_logic_vector(? downto 0)
  );
  end component;

  --=============================================================================
  -- 1)  UTILITY FUNCTIONS
  --=============================================================================

  -- 64 bits one-hot decoder
  function one_hot64 (
    binary : std_logic_vector(5 downto 0)
  ) return std_logic_vector is
    variable one_hot64_return : std_logic_vector (63 downto 0);
  begin
    one_hot64_return <= X"0000_0000_0000_0000";
    one_hot64_return(binary) <= '1';
    return one_hot64_return;
  end one_hot64;



  -- 16 bits one-hot decoder
  function one_hot16 (
    binary : std_logic_vector(3 downto 0)
  ) return std_logic_vector is
    variable one_hot16_return : std_logic_vector (15 downto 0);
  begin
    one_hot16_return <= X"0000";
    one_hot16_return(binary) <= '1';
    return one_hot16_return;
  end one_hot16;



  -- 8 bits one-hot decoder
  function one_hot8 (
    binary : std_logic_vector(2 downto 0)
  ) return std_logic_vector is
    variable one_hot8_return : std_logic_vector (7 downto 0);
  begin
    one_hot8_return <= X"00";
    one_hot8_return(binary) <= '1';
    return one_hot8_return;
  end one_hot8;



  -- Get IRQ number
  function get_irq_num (
    irq_all : std_logic_vector(62 downto 0);
    constant ii : integer;
  ) return std_logic_vector is
    variable get_irq_num_return : std_logic_vector (5 downto 0);
  begin
    get_irq_num_return <= X"3f";
    for ii in 62 downto 0 loop
      if (and get_irq_num_return and irq_all(ii)) then
        get_irq_num_return <= ii(5 downto 0);
      end if;
    end loop;
    return get_irq_num_return;
  end get_irq_num;



  --=============================================================================
  -- 2)  PARAMETER DEFINITIONS
  --=============================================================================

  --
  -- 2.1) Instruction State machine definitons
  ---------------------------------------------

  constant I_IRQ_FETCH : integer := I_IRQ_FETCH;
  constant I_IRQ_DONE : integer := I_IRQ_DONE;
  constant I_DEC : integer := I_DEC;  -- New instruction ready for decode
  constant I_EXT1 : integer := I_EXT1;  -- 1st Extension word
  constant I_EXT2 : integer := I_EXT2;  -- 2nd Extension word
  constant I_IDLE : integer := I_IDLE;  -- CPU is in IDLE mode

  --
  -- 2.2) Execution State machine definitons
  ---------------------------------------------

  constant E_IRQ_0 : integer := E_IRQ_0;
  constant E_IRQ_1 : integer := E_IRQ_1;
  constant E_IRQ_2 : integer := E_IRQ_2;
  constant E_IRQ_3 : integer := E_IRQ_3;
  constant E_IRQ_4 : integer := E_IRQ_4;
  constant E_SRC_AD : integer := E_SRC_AD;
  constant E_SRC_RD : integer := E_SRC_RD;
  constant E_SRC_WR : integer := E_SRC_WR;
  constant E_DST_AD : integer := E_DST_AD;
  constant E_DST_RD : integer := E_DST_RD;
  constant E_DST_WR : integer := E_DST_WR;
  constant E_EXEC : integer := E_EXEC;
  constant E_JUMP : integer := E_JUMP;
  constant E_IDLE : integer := E_IDLE;

  --=============================================================================
  -- 3)  FRONTEND STATE MACHINE
  --=============================================================================

  -- The wire "conv" is used as state bits to calculate the next response
  signal i_state : std_logic_vector(2 downto 0);
  signal i_state_nxt : std_logic_vector(2 downto 0);

  signal inst_sz : std_logic_vector(1 downto 0);
  signal inst_sz_nxt : std_logic_vector(1 downto 0);
  signal irq_detect : std_logic;
  signal inst_type_nxt : std_logic_vector(2 downto 0);
  signal is_const : std_logic;
  signal sconst_nxt : std_logic_vector(15 downto 0);
  signal e_state_nxt : std_logic_vector(3 downto 0);

  -- CPU on/off through an external interface (debug or mstr) or cpu_en port
  signal cpu_halt_req : std_logic;

  -- Utility signals
  signal decode_noirq : std_logic;
  signal decode : std_logic;
  signal fetch : std_logic;

  -- Halt/Run CPU status
  signal cpu_halt_st : std_logic;

  --=============================================================================
  -- 4)  INTERRUPT HANDLING & SYSTEM WAKEUP
  --=============================================================================

  --
  -- 4.1) INTERRUPT HANDLING
  --------------------------

  -- Detect reset interrupt
  signal inst_irq_rst : std_logic;

  signal mclk_irq_num : std_logic;

  signal UNUSED_scan_enable : std_logic;

  -- Combine all IRQs
  signal irq_all : std_logic_vector(62 downto 0);

  -- Select highest priority IRQ
  signal irq_num : std_logic_vector(5 downto 0);

  -- Generate selected IRQ vector address
  signal irq_addr : std_logic_vector(15 downto 0);

  -- Interrupt request accepted
  signal irq_acc_all : std_logic_vector(63 downto 0);
  signal irq_acc : std_logic_vector(IRQ_NR-3 downto 0);
  signal nmi_acc : std_logic;

  --
  -- 4.2) SYSTEM WAKEUP
  -------------------------------------------

  -- Generate the main system clock enable signal
  signal mclk_enable : std_logic;

  -- Wakeup condition from maskable interrupts
  signal mirq_wkup : std_logic;

  signal mclk_dma_enable : std_logic;

  signal UNUSED_dma_en : std_logic;

  -- In the CPUOFF feature is disabled, the wake-up and enable signals are always 1
  signal UNUSED_wkup : std_logic;
  signal UNUSED_wdt_wkup : std_logic;
  signal UNUSED_nmi_wkup : std_logic;
  signal UNUSED_dma_wkup : std_logic;

  --=============================================================================
  -- 5)  FETCH INSTRUCTION
  --=============================================================================

  --
  -- 5.1) PROGRAM COUNTER & MEMORY INTERFACE
  -------------------------------------------

  -- Program counter
  signal pc : std_logic_vector(15 downto 0);

  -- Compute next PC value
  signal pc_incr : std_logic_vector(15 downto 0);
  signal pc_nxt : std_logic_vector(15 downto 0);

  signal pc_en : std_logic;
  signal mclk_pc : std_logic;

  -- Check if Program-Memory has been busy in order to retry Program-Memory access
  signal pmem_busy : std_logic;

  -- Memory interface
  signal mab : std_logic_vector(15 downto 0);
  signal mb_en : std_logic;

  --
  -- 5.2) INSTRUCTION REGISTER
  ----------------------------

  -- Instruction register
  signal ir : std_logic_vector(15 downto 0);

  -- Detect if source extension word is required
  signal is_sext : std_logic;

  -- For the Symbolic addressing mode, add -2 to the extension word in order
  -- to make up for the PC address
  signal ext_incr : std_logic_vector(15 downto 0);

  signal ext_nxt : std_logic_vector(15 downto 0);

  -- Store source extension word
  signal inst_sext : std_logic_vector(15 downto 0);

  signal inst_sext_en : std_logic;
  signal mclk_inst_sext : std_logic;

  -- Source extension word is ready
  signal inst_sext_rdy : std_logic;


  -- Store destination extension word
  signal inst_dext : std_logic_vector(15 downto 0);

  signal inst_dext_en : std_logic;
  signal mclk_inst_dext : std_logic;

  -- Destination extension word is ready
  signal inst_dext_rdy : std_logic;

  --=============================================================================
  -- 6)  DECODE INSTRUCTION
  --=============================================================================

  signal mclk_decode : std_logic;

  --
  -- 6.1) OPCODE: INSTRUCTION TYPE
  ------------------------------------------
  -- Instructions type is encoded in a one hot fashion as following:
  --
  -- 3'b001: Single-operand arithmetic
  -- 3'b010: Conditional jump
  -- 3'b100: Two-operand arithmetic

  signal inst_type : std_logic_vector(2 downto 0);

  --
  -- 6.2) OPCODE: SINGLE-OPERAND ARITHMETIC
  ------------------------------------------
  -- Instructions are encoded in a one hot fashion as following:
  --
  -- 8'b00000001: RRC
  -- 8'b00000010: SWPB
  -- 8'b00000100: RRA
  -- 8'b00001000: SXT
  -- 8'b00010000: PUSH
  -- 8'b00100000: CALL
  -- 8'b01000000: RETI
  -- 8'b10000000: IRQ

  signal inst_so : std_logic_vector(7 downto 0);
  signal inst_so_nxt : std_logic_vector(7 downto 0);

  --
  -- 6.3) OPCODE: CONDITIONAL JUMP
  ----------------------------------
  -- Instructions are encoded in a one hot fashion as following:
  --
  -- 8'b00000001: JNE/JNZ
  -- 8'b00000010: JEQ/JZ
  -- 8'b00000100: JNC/JLO
  -- 8'b00001000: JC/JHS
  -- 8'b00010000: JN
  -- 8'b00100000: JGE
  -- 8'b01000000: JL
  -- 8'b10000000: JMP

  signal inst_jmp_bin : std_logic_vector(2 downto 0);

  signal inst_jmp : std_logic_vector(7 downto 0);

  --
  -- 6.4) OPCODE: TWO-OPERAND ARITHMETIC
  ---------------------------------------
  -- Instructions are encoded in a one hot fashion as following:
  --
  -- 12'b000000000001: MOV
  -- 12'b000000000010: ADD
  -- 12'b000000000100: ADDC
  -- 12'b000000001000: SUBC
  -- 12'b000000010000: SUB
  -- 12'b000000100000: CMP
  -- 12'b000001000000: DADD
  -- 12'b000010000000: BITX
  -- 12'b000100000000: BIC
  -- 12'b001000000000: BIS
  -- 12'b010000000000: XOR
  -- 12'b100000000000: AND

  signal inst_to_1hot : std_logic_vector(15 downto 0);
  signal inst_to_nxt : std_logic_vector(11 downto 0);

  signal inst_mov : std_logic;

  --
  -- 6.5) SOURCE AND DESTINATION REGISTERS
  ----------------------------------------

  -- Destination register
  signal inst_dest_bin : std_logic_vector(3 downto 0);

  signal inst_dest : std_logic_vector(15 downto 0);

  -- Source register
  signal inst_src_bin : std_logic_vector(3 downto 0);

  signal inst_src : std_logic_vector(15 downto 0);

  --
  -- 6.6) SOURCE ADDRESSING MODES
  -------------------------------
  -- Source addressing modes are encoded in a one hot fashion as following:
  --
  -- 13'b0000000000001: Register direct.
  -- 13'b0000000000010: Register indexed.
  -- 13'b0000000000100: Register indirect.
  -- 13'b0000000001000: Register indirect autoincrement.
  -- 13'b0000000010000: Symbolic (operand is in memory at address PC+x).
  -- 13'b0000000100000: Immediate (operand is next word in the instruction stream).
  -- 13'b0000001000000: Absolute (operand is in memory at address x).
  -- 13'b0000010000000: Constant 4.
  -- 13'b0000100000000: Constant 8.
  -- 13'b0001000000000: Constant 0.
  -- 13'b0010000000000: Constant 1.
  -- 13'b0100000000000: Constant 2.
  -- 13'b1000000000000: Constant -1.

  signal inst_as_nxt : std_logic_vector(12 downto 0);

  signal src_reg : std_logic_vector(3 downto 0);

  signal inst_as : std_logic_vector(7 downto 0);

  --
  -- 6.7) DESTINATION ADDRESSING MODES
  -------------------------------------
  -- Destination addressing modes are encoded in a one hot fashion as following:
  --
  -- 8'b00000001: Register direct.
  -- 8'b00000010: Register indexed.
  -- 8'b00010000: Symbolic (operand is in memory at address PC+x).
  -- 8'b01000000: Absolute (operand is in memory at address x).

  signal inst_ad_nxt : std_logic_vector(7 downto 0);

  signal dest_reg : std_logic_vector(3 downto 0);

  signal inst_ad : std_logic_vector(7 downto 0);

  --
  -- 6.8) REMAINING INSTRUCTION DECODING
  ---------------------------------------

  -- Operation size
  signal inst_bw : std_logic;

  --=============================================================================
  -- 7)  EXECUTION-UNIT STATE MACHINE
  --=============================================================================

  -- State machine registers
  signal e_state : std_logic_vector(3 downto 0);

  -- State machine control signals
  ----------------------------------

  signal src_acalc_pre : std_logic;
  signal src_rd_pre : std_logic;
  signal dst_acalc_pre : std_logic;
  signal dst_acalc : std_logic;
  signal dst_rd_pre : std_logic;
  signal dst_rd : std_logic;

  signal inst_branch : std_logic;

  signal exec_jmp : std_logic;

  signal exec_dst_wr : std_logic;
  signal exec_src_wr : std_logic;

  signal exec_dext_rdy : std_logic;

  -- Execution first state
  signal e_first_state : std_logic_vector(3 downto 0);

  -- Frontend State machine control signals
  -----------------------------------------
  signal exec_done : std_logic;

  --=============================================================================
  -- 8)  EXECUTION-UNIT STATE CONTROL
  --=============================================================================

  --
  -- 8.1) ALU CONTROL SIGNALS
  ---------------------------
  --
  -- 12'b000000000001: Enable ALU source inverter
  -- 12'b000000000010: Enable Incrementer
  -- 12'b000000000100: Enable Incrementer on carry bit
  -- 12'b000000001000: Select Adder
  -- 12'b000000010000: Select AND
  -- 12'b000000100000: Select OR
  -- 12'b000001000000: Select XOR
  -- 12'b000010000000: Select DADD
  -- 12'b000100000000: Update N, Z & C (C=~Z)
  -- 12'b001000000000: Update all status bits
  -- 12'b010000000000: Update status bit for XOR instruction
  -- 12'b100000000000: Don't write to destination

  signal inst_alu : std_logic_vector(11 downto 0);

  signal alu_src_inv : std_logic;

  signal alu_inc : std_logic;

  signal alu_inc_c : std_logic;

  signal alu_add : std_logic;

  signal alu_and : std_logic;

  signal alu_or : std_logic;

  signal alu_xor : std_logic;

  signal alu_dadd : std_logic;

  signal alu_stat_7 : std_logic;

  signal alu_stat_f : std_logic;

  signal alu_shift : std_logic;

  signal exec_no_wr : std_logic;

  signal inst_alu_nxt : std_logic_vector(11 downto 0);

begin
  --=============================================================================
  -- 3)  FRONTEND STATE MACHINE
  --=============================================================================

  -- CPU on/off through an external interface (debug or mstr) or cpu_en port
  cpu_halt_req <= cpu_halt_cmd or not cpu_en_s;

  -- States Transitions
  processing_0 : process (i_state, inst_sz, inst_sz_nxt, pc_sw_wr, exec_done, irq_detect, cpuoff, cpu_halt_req, e_state)
  begin
    case ((i_state)) is
    when I_IDLE =>
      i_state_nxt <= I_IRQ_FETCH
      when (irq_detect and not cpu_halt_req) else I_DEC
      when (not cpuoff and not cpu_halt_req) else I_IDLE;
    when I_IRQ_FETCH =>
      i_state_nxt <= I_IRQ_DONE;
    when I_IRQ_DONE =>
      i_state_nxt <= I_DEC;
    when I_DEC =>
    -- Wait in decode state
    -- until execution is completed
      i_state_nxt <= I_IRQ_FETCH
      when irq_detect else I_IDLE
      when (cpuoff or cpu_halt_req) and exec_done else I_IDLE
      when cpu_halt_req and (e_state = E_IDLE) else I_DEC
      when pc_sw_wr else I_DEC
      when not exec_done and not (e_state = E_IDLE) else I_EXT1
      when (inst_sz_nxt /= "00") else I_DEC;
    when I_EXT1 =>
      i_state_nxt <= I_DEC
      when pc_sw_wr else I_EXT2
      when (inst_sz /= "01") else I_DEC;
    when I_EXT2 =>
      i_state_nxt <= I_DEC;
    -- pragma coverage off
    when others =>
      i_state_nxt <= I_IRQ_FETCH;
    end case;
  end process;
  -- pragma coverage on


  -- State machine
  processing_1 : process (mclk, puc_rst)
  begin
    if (puc_rst) then
      i_state <= I_IRQ_FETCH;
    elsif (rising_edge(mclk)) then
      i_state <= i_state_nxt;
    end if;
  end process;


  -- Utility signals
  decode_noirq <= ((i_state = I_DEC) and (exec_done or (e_state = E_IDLE)));
  decode <= decode_noirq or irq_detect;
  fetch <= not ((i_state = I_DEC) and not (exec_done or (e_state = E_IDLE))) and not (e_state_nxt = E_IDLE);

  -- Halt/Run CPU status
  processing_2 : process (mclk, puc_rst)
  begin
    if (puc_rst) then
      cpu_halt_st <= '0';
    elsif (rising_edge(mclk)) then
      cpu_halt_st <= cpu_halt_req and (i_state_nxt = I_IDLE);
    end if;
  end process;


  --=============================================================================
  -- 4)  INTERRUPT HANDLING & SYSTEM WAKEUP
  --=============================================================================

  --
  -- 4.1) INTERRUPT HANDLING
  --------------------------

  -- Detect reset interrupt
  processing_3 : process (mclk, puc_rst)
  begin
    if (puc_rst) then
      inst_irq_rst <= '1';
    elsif (rising_edge(mclk)) then
      if (exec_done) then
        inst_irq_rst <= '0';
      end if;
    end if;
  end process;


  --  Detect other interrupts
  irq_detect <= (nmi_pnd or ((or irq or wdt_irq) and gie)) and not cpu_halt_req and not cpu_halt_st and (exec_done or (i_state = I_IDLE));

  CLOCK_GATING_GENERATING_0 : if (CLOCK_GATING = '1') generate
    clock_gate_irq_num : omsp_clock_gate
    port map (
      gclk => mclk_irq_num,
      clk => mclk,
      enable => irq_detect,
      scan_enable => scan_enable
    );
  elsif (CLOCK_GATING = '0') generate
    UNUSED_scan_enable <= scan_enable;
    mclk_irq_num <= mclk;
  end generate;


  -- Combine all IRQs
  IRQ_16_GENERATING_1 : if (IRQ_16 = '1') generate
    irq_all <= (nmi_pnd & irq & X"0000_0000_0000") or ('0' & X"0" & wdt_irq & concatenate(58, '0'));
  elsif (IRQ_16 = '0') generate
    IRQ_32_GENERATING_2 : if (IRQ_32 = '1') generate
      irq_all <= (nmi_pnd & irq & X"0000_0000") or ('0' & X"0" & wdt_irq & concatenate(58, '0'));
    elsif (IRQ_32 = '0') generate
      IRQ_64_GENERATING_3 : if (IRQ_64 = '1') generate
        irq_all <= (nmi_pnd & irq) or ('0' & X"0" & wdt_irq & concatenate(58, '0'));
      end generate;
    end generate;
  end generate;


  -- Select highest priority IRQ
  CLOCK_GATING_GENERATING_4 : if (CLOCK_GATING = '1') generate
    processing_4 : process (mclk_irq_num, puc_rst)
    begin
      if (puc_rst) then
        irq_num <= X"3f";
      elsif (rising_edge(mclk_irq_num)) then
        irq_num <= (null)(irq_all);
      end if;
    end process;
  elsif (CLOCK_GATING = '0') generate
    processing_5 : process (mclk_irq_num, puc_rst)
    begin
      if (puc_rst) then
        irq_num <= X"3f";
      elsif (rising_edge(mclk_irq_num)) then
        if (irq_detect) then
          irq_num <= (null)(irq_all);
        end if;
      end if;
    end process;
  end generate;


  -- Generate selected IRQ vector address
  irq_addr <= (X"1ff" & irq_num & '0');

  -- Interrupt request accepted
  irq_acc_all <= (null)(irq_num) and concatenate(64, (i_state = I_IRQ_FETCH));
  irq_acc <= irq_acc_all(61 downto 64-IRQ_NR);
  nmi_acc <= irq_acc_all(62);

  --
  -- 4.2) SYSTEM WAKEUP
  ---------------------
  CPUOFF_EN_GENERATING_5 : if (CPUOFF_EN = '1') generate

    -- Generate the main system clock enable signal
    -- Keep the clock running if:
    --      - the RESET interrupt is currently executing
    --        and if the CPU is enabled
    -- otherwise if:
    --      - the CPUOFF flag, cpu_en command, instruction
    --        and execution state machines are all two
    mclk_enable <= cpu_en_s
    when inst_irq_rst else not ((cpuoff or not cpu_en_s) and (i_state = I_IDLE) and (e_state = E_IDLE));    --        not idle.

    -- Wakeup condition from maskable interrupts
    and_mirq_wkup : omsp_and_gate
    port map (
      y => mirq_wkup,
      a => wkup or wdt_wkup,
      b => gie
    );


    -- Combined asynchronous wakeup detection from nmi & irq (masked if the cpu is disabled)
    and_mclk_wkup : omsp_and_gate
    port map (
      y => mclk_wkup,
      a => nmi_wkup or mirq_wkup,
      b => cpu_en_s
    );


    -- Wakeup condition from DMA interface
    DMA_IF_EN_GENERATING_6 : if (DMA_IF_EN = '1') generate
      mclk_dma_enable <= dma_en and cpu_en_s;
      and_mclk_dma_wkup : omsp_and_gate
      port map (
        y => mclk_dma_wkup,
        a => dma_wkup,
        b => cpu_en_s
      );
    elsif (DMA_IF_EN = '0') generate
      mclk_dma_wkup <= '0';
      mclk_dma_enable <= '0';
      UNUSED_dma_en <= dma_en;
      UNUSED_dma_wkup <= dma_wkup;
    end generate;
  elsif (CPUOFF_EN = '0') generate


    -- In the CPUOFF feature is disabled, the wake-up and enable signals are always 1
    mclk_dma_wkup <= '1';
    mclk_dma_enable <= '1';
    mclk_wkup <= '1';
    mclk_enable <= '1';
    UNUSED_dma_en <= dma_en;
    UNUSED_wkup <= wkup;
    UNUSED_wdt_wkup <= wdt_wkup;
    UNUSED_nmi_wkup <= nmi_wkup;
    UNUSED_dma_wkup <= dma_wkup;
  end generate;


  --=============================================================================
  -- 5)  FETCH INSTRUCTION
  --=============================================================================

  --
  -- 5.1) PROGRAM COUNTER & MEMORY INTERFACE
  -------------------------------------------

  -- Program counter

  -- Compute next PC value
  pc_incr <= pc+(X"0000" & fetch & '0');
  pc_nxt <= pc_sw
  when pc_sw_wr else irq_addr
  when (i_state = I_IRQ_FETCH) else mdb_in
  when (i_state = I_IRQ_DONE) else pc_incr;

  CLOCK_GATING_GENERATING_7 : if (CLOCK_GATING = '1') generate
    pc_en <= fetch or pc_sw_wr or (i_state = I_IRQ_FETCH) or (i_state = I_IRQ_DONE);

    clock_gate_pc : omsp_clock_gate
    port map (
      gclk => mclk_pc,
      clk => mclk,
      enable => pc_en,
      scan_enable => scan_enable
    );
  elsif (CLOCK_GATING = '0') generate
    mclk_pc <= mclk;
  end generate;


  processing_6 : process (mclk_pc, puc_rst)
  begin
    if (puc_rst) then
      pc <= X"0000";
    elsif (rising_edge(mclk_pc)) then
      pc <= pc_nxt;
    end if;
  end process;


  -- Check if Program-Memory has been busy in order to retry Program-Memory access
  processing_7 : process (mclk, puc_rst)
  begin
    if (puc_rst) then
      pmem_busy <= '0';
    elsif (rising_edge(mclk)) then
      pmem_busy <= fe_pmem_wait;
    end if;
  end process;


  -- Memory interface
  mab <= pc_nxt;
  mb_en <= fetch or pc_sw_wr or (i_state = I_IRQ_FETCH) or pmem_busy or (cpu_halt_st and not cpu_halt_req);

  --
  -- 5.2) INSTRUCTION REGISTER
  ----------------------------

  -- Instruction register
  ir <= mdb_in;

  -- Detect if source extension word is required
  is_sext <= (inst_as(IDX) or inst_as(SYMB) or inst_as(ABS) or inst_as(IMM));

  -- For the Symbolic addressing mode, add -2 to the extension word in order
  -- to make up for the PC address
  ext_incr <= X"fffe"
  when ((i_state = I_EXT1) and inst_as(SYMB)) or ((i_state = I_EXT2) and inst_ad(SYMB)) or ((i_state = I_EXT1) and not inst_as(SYMB) and not (i_state_nxt = I_EXT2) and inst_ad(SYMB)) else X"0000";

  ext_nxt <= ir+ext_incr;

  -- Store source extension word
  CLOCK_GATING_GENERATING_8 : if (CLOCK_GATING = '1') generate
    inst_sext_en <= (decode and is_const) or (decode and inst_type_nxt(INST_JMP)) or ((i_state = I_EXT1) and is_sext);

    clock_gate_inst_sext : omsp_clock_gate
    port map (
      gclk => mclk_inst_sext,
      clk => mclk,
      enable => inst_sext_en,
      scan_enable => scan_enable
    );
  elsif (CLOCK_GATING = '0') generate
    mclk_inst_sext <= mclk;
  end generate;


  CLOCK_GATING_GENERATING_9 : if (CLOCK_GATING = '1') generate
    processing_8 : process (mclk_inst_sext, puc_rst)
    begin
      if (puc_rst) then
        inst_sext <= X"0000";
      elsif (rising_edge(mclk_inst_sext)) then
        if (decode and is_const) then
          inst_sext <= sconst_nxt;
        elsif (decode and inst_type_nxt(INST_JMP)) then
          inst_sext <= (concatenate(5, ir(9)) & ir(9 downto 0) & '0');
        else
          inst_sext <= ext_nxt;
        end if;
      end if;
    end process;
  elsif (CLOCK_GATING = '0') generate
    processing_9 : process (mclk_inst_sext, puc_rst)
    begin
      if (puc_rst) then
        inst_sext <= X"0000";
      elsif (rising_edge(mclk_inst_sext)) then
        if (decode and is_const) then
          inst_sext <= sconst_nxt;
        elsif (decode and inst_type_nxt(INST_JMP)) then
          inst_sext <= (concatenate(5, ir(9)) & ir(9 downto 0) & '0');
        elsif ((i_state = I_EXT1) and is_sext) then
          inst_sext <= ext_nxt;
        end if;
      end if;
    end process;
  end generate;


  -- Source extension word is ready
  inst_sext_rdy <= (i_state = I_EXT1) and is_sext;


  -- Store destination extension word
  CLOCK_GATING_GENERATING_10 : if (CLOCK_GATING = '1') generate
    inst_dext_en <= ((i_state = I_EXT1) and not is_sext) or (i_state = I_EXT2);

    clock_gate_inst_dext : omsp_clock_gate
    port map (
      gclk => mclk_inst_dext,
      clk => mclk,
      enable => inst_dext_en,
      scan_enable => scan_enable
    );
  elsif (CLOCK_GATING = '0') generate
    mclk_inst_dext <= mclk;
  end generate;


  CLOCK_GATING_GENERATING_11 : if (CLOCK_GATING = '1') generate
    processing_10 : process (mclk_inst_dext, puc_rst)
    begin
      if (puc_rst) then
        inst_dext <= X"0000";
      elsif (rising_edge(mclk_inst_dext)) then
        if ((i_state = I_EXT1) and not is_sext) then
          inst_dext <= ext_nxt;
        else
          inst_dext <= ext_nxt;
        end if;
      end if;
    end process;
  elsif (CLOCK_GATING = '0') generate
    processing_11 : process (mclk_inst_dext, puc_rst)
    begin
      if (puc_rst) then
        inst_dext <= X"0000";
      elsif (rising_edge(mclk_inst_dext)) then
        if ((i_state = I_EXT1) and not is_sext) then
          inst_dext <= ext_nxt;
        elsif (i_state = I_EXT2) then
          inst_dext <= ext_nxt;
        end if;
      end if;
    end process;
  end generate;


  -- Destination extension word is ready
  inst_dext_rdy <= (((i_state = I_EXT1) and not is_sext) or (i_state = I_EXT2));

  --=============================================================================
  -- 6)  DECODE INSTRUCTION
  --=============================================================================

  CLOCK_GATING_GENERATING_12 : if (CLOCK_GATING = '1') generate
    clock_gate_decode : omsp_clock_gate
    port map (
      gclk => mclk_decode,
      clk => mclk,
      enable => decode,
      scan_enable => scan_enable
    );
  elsif (CLOCK_GATING = '0') generate
    mclk_decode <= mclk;
  end generate;


  --
  -- 6.1) OPCODE: INSTRUCTION TYPE
  ------------------------------------------
  -- Instructions type is encoded in a one hot fashion as following:
  --
  -- 3'b001: Single-operand arithmetic
  -- 3'b010: Conditional jump
  -- 3'b100: Two-operand arithmetic

  inst_type_nxt <= ((ir(15 downto 14) /= "00") & (ir(15 downto 13) = "001") & (ir(15 downto 13) = "000")) and (not irq_detect & not irq_detect & not irq_detect);

  CLOCK_GATING_GENERATING_13 : if (CLOCK_GATING = '1') generate
    processing_12 : process (mclk_decode, puc_rst)
    begin
      if (puc_rst) then
        inst_type <= "000";
      elsif (rising_edge(mclk_decode)) then
        inst_type <= inst_type_nxt;
      end if;
    end process;
  elsif (CLOCK_GATING = '0') generate
    processing_13 : process (mclk_decode, puc_rst)
    begin
      if (puc_rst) then
        inst_type <= "000";
      elsif (rising_edge(mclk_decode)) then
        if (decode) then
          inst_type <= inst_type_nxt;
        end if;
      end if;
    end process;
  end generate;


  --
  -- 6.2) OPCODE: SINGLE-OPERAND ARITHMETIC
  ------------------------------------------
  -- Instructions are encoded in a one hot fashion as following:
  --
  -- 8'b00000001: RRC
  -- 8'b00000010: SWPB
  -- 8'b00000100: RRA
  -- 8'b00001000: SXT
  -- 8'b00010000: PUSH
  -- 8'b00100000: CALL
  -- 8'b01000000: RETI
  -- 8'b10000000: IRQ

  inst_so_nxt <= X"80"
  when irq_detect else ((null)(ir(9 downto 7)) and concatenate(8, inst_type_nxt(INST_SO)));

  CLOCK_GATING_GENERATING_14 : if (CLOCK_GATING = '1') generate
    processing_14 : process (mclk_decode, puc_rst)
    begin
      if (puc_rst) then
        inst_so <= X"00";
      elsif (rising_edge(mclk_decode)) then
        inst_so <= inst_so_nxt;
      end if;
    end process;
  elsif (CLOCK_GATING = '0') generate
    processing_15 : process (mclk_decode, puc_rst)
    begin
      if (puc_rst) then
        inst_so <= X"00";
      elsif (rising_edge(mclk_decode)) then
        if (decode) then
          inst_so <= inst_so_nxt;
        end if;
      end if;
    end process;
  end generate;


  --
  -- 6.3) OPCODE: CONDITIONAL JUMP
  ----------------------------------
  -- Instructions are encoded in a one hot fashion as following:
  --
  -- 8'b00000001: JNE/JNZ
  -- 8'b00000010: JEQ/JZ
  -- 8'b00000100: JNC/JLO
  -- 8'b00001000: JC/JHS
  -- 8'b00010000: JN
  -- 8'b00100000: JGE
  -- 8'b01000000: JL
  -- 8'b10000000: JMP

  CLOCK_GATING_GENERATING_15 : if (CLOCK_GATING = '1') generate
    processing_16 : process (mclk_decode, puc_rst)
    begin
      if (puc_rst) then
        inst_jmp_bin <= X"0";
      elsif (rising_edge(mclk_decode)) then
        inst_jmp_bin <= ir(12 downto 10);
      end if;
    end process;
  elsif (CLOCK_GATING = '0') generate
    processing_17 : process (mclk_decode, puc_rst)
    begin
      if (puc_rst) then
        inst_jmp_bin <= X"0";
      elsif (rising_edge(mclk_decode)) then
        if (decode) then
          inst_jmp_bin <= ir(12 downto 10);
        end if;
      end if;
    end process;
  end generate;


  inst_jmp <= (null)(inst_jmp_bin) and concatenate(8, inst_type(INST_JMP));

  --
  -- 6.4) OPCODE: TWO-OPERAND ARITHMETIC
  ---------------------------------------
  -- Instructions are encoded in a one hot fashion as following:
  --
  -- 12'b000000000001: MOV
  -- 12'b000000000010: ADD
  -- 12'b000000000100: ADDC
  -- 12'b000000001000: SUBC
  -- 12'b000000010000: SUB
  -- 12'b000000100000: CMP
  -- 12'b000001000000: DADD
  -- 12'b000010000000: BITX
  -- 12'b000100000000: BIC
  -- 12'b001000000000: BIS
  -- 12'b010000000000: XOR
  -- 12'b100000000000: AND

  inst_to_1hot <= (null)(ir(15 downto 12)) and concatenate(16, inst_type_nxt(INST_TO));
  inst_to_nxt <= inst_to_1hot(15 downto 4);

  CLOCK_GATING_GENERATING_16 : if (CLOCK_GATING = '1') generate
    processing_18 : process (mclk_decode, puc_rst)
    begin
      if (puc_rst) then
        inst_mov <= '0';
      elsif (rising_edge(mclk_decode)) then
        inst_mov <= inst_to_nxt(MOV);
      end if;
    end process;
  elsif (CLOCK_GATING = '0') generate
    processing_19 : process (mclk_decode, puc_rst)
    begin
      if (puc_rst) then
        inst_mov <= '0';
      elsif (rising_edge(mclk_decode)) then
        if (decode) then
          inst_mov <= inst_to_nxt(MOV);
        end if;
      end if;
    end process;
  end generate;


  --
  -- 6.5) SOURCE AND DESTINATION REGISTERS
  -----------------------------------------

  -- Destination register
  CLOCK_GATING_GENERATING_17 : if (CLOCK_GATING = '1') generate
    processing_20 : process (mclk_decode, puc_rst)
    begin
      if (puc_rst) then
        inst_dest_bin <= X"0";
      elsif (rising_edge(mclk_decode)) then
        inst_dest_bin <= ir(3 downto 0);
      end if;
    end process;
  elsif (CLOCK_GATING = '0') generate
    processing_21 : process (mclk_decode, puc_rst)
    begin
      if (puc_rst) then
        inst_dest_bin <= X"0";
      elsif (rising_edge(mclk_decode)) then
        if (decode) then
          inst_dest_bin <= ir(3 downto 0);
        end if;
      end if;
    end process;
  end generate;


  inst_dest <= (null)(dbg_reg_sel)
  when cpu_halt_st else X"0001"
  when inst_type(INST_JMP) else X"0002"
  when inst_so(IRQ) or inst_so(PUSH) or inst_so(CALL) else (null)(inst_dest_bin);

  -- Source register
  CLOCK_GATING_GENERATING_18 : if (CLOCK_GATING = '1') generate
    processing_22 : process (mclk_decode, puc_rst)
    begin
      if (puc_rst) then
        inst_src_bin <= X"0";
      elsif (rising_edge(mclk_decode)) then
        inst_src_bin <= ir(11 downto 8);
      end if;
    end process;
  elsif (CLOCK_GATING = '0') generate
    processing_23 : process (mclk_decode, puc_rst)
    begin
      if (puc_rst) then
        inst_src_bin <= X"0";
      elsif (rising_edge(mclk_decode)) then
        if (decode) then
          inst_src_bin <= ir(11 downto 8);
        end if;
      end if;
    end process;
  end generate;


  inst_src <= (null)(inst_src_bin)
  when inst_type(INST_TO) else X"0002"
  when inst_so(RETI) else X"0001"
  when inst_so(IRQ) else (null)(inst_dest_bin)
  when inst_type(INST_SO) else X"0000";


  --
  -- 6.6) SOURCE ADDRESSING MODES
  ----------------------------------
  -- Source addressing modes are encoded in a one hot fashion as following:
  --
  -- 13'b0000000000001: Register direct.
  -- 13'b0000000000010: Register indexed.
  -- 13'b0000000000100: Register indirect.
  -- 13'b0000000001000: Register indirect autoincrement.
  -- 13'b0000000010000: Symbolic (operand is in memory at address PC+x).
  -- 13'b0000000100000: Immediate (operand is next word in the instruction stream).
  -- 13'b0000001000000: Absolute (operand is in memory at address x).
  -- 13'b0000010000000: Constant 4.
  -- 13'b0000100000000: Constant 8.
  -- 13'b0001000000000: Constant 0.
  -- 13'b0010000000000: Constant 1.
  -- 13'b0100000000000: Constant 2.
  -- 13'b1000000000000: Constant -1.

  src_reg <= ir(3 downto 0)
  when inst_type_nxt(INST_SO) else ir(11 downto 8);

  processing_24 : process (src_reg, ir, inst_type_nxt)
  begin
    if (inst_type_nxt(INST_JMP)) then
      inst_as_nxt <= "0000000000001";
    elsif (src_reg = X"3") then  -- Addressing mode using R3
      case ((ir(5 downto 4))) is
      when "11" =>
        inst_as_nxt <= "1000000000000";
      when "10" =>
        inst_as_nxt <= "0100000000000";
      when "01" =>
        inst_as_nxt <= "0010000000000";
      when others =>
        inst_as_nxt <= "0001000000000";
      end case;
    elsif (src_reg = X"2") then  -- Addressing mode using R2
      case ((ir(5 downto 4))) is
      when "11" =>
        inst_as_nxt <= "0000100000000";
      when "10" =>
        inst_as_nxt <= "0000010000000";
      when "01" =>
        inst_as_nxt <= "0000001000000";
      when others =>
        inst_as_nxt <= "0000000000001";
      end case;
    elsif (src_reg = X"0") then  -- Addressing mode using R0
      case ((ir(5 downto 4))) is
      when "11" =>
        inst_as_nxt <= "0000000100000";
      when "10" =>
        inst_as_nxt <= "0000000000100";
      when "01" =>
        inst_as_nxt <= "0000000010000";
      when others =>
        inst_as_nxt <= "0000000000001";
      end case;
    else    -- General Addressing mode
      case ((ir(5 downto 4))) is
      when "11" =>
        inst_as_nxt <= "0000000001000";
      when "10" =>
        inst_as_nxt <= "0000000000100";
      when "01" =>
        inst_as_nxt <= "0000000000010";
      when others =>
        inst_as_nxt <= "0000000000001";
      end case;
    end if;
  end process;


  is_const <= or inst_as_nxt(12 downto 7);

  CLOCK_GATING_GENERATING_19 : if (CLOCK_GATING = '1') generate
    processing_25 : process (mclk_decode, puc_rst)
    begin
      if (puc_rst) then
        inst_as <= X"00";
      elsif (rising_edge(mclk_decode)) then
        inst_as <= (is_const & inst_as_nxt(6 downto 0));
      end if;
    end process;
  elsif (CLOCK_GATING = '0') generate
    processing_26 : process (mclk_decode, puc_rst)
    begin
      if (puc_rst) then
        inst_as <= X"00";
      elsif (rising_edge(mclk_decode)) then
        if (decode) then
          inst_as <= (is_const & inst_as_nxt(6 downto 0));
        end if;
      end if;
    end process;
  end generate;


  -- 13'b0000010000000: Constant 4.
  -- 13'b0000100000000: Constant 8.
  -- 13'b0001000000000: Constant 0.
  -- 13'b0010000000000: Constant 1.
  -- 13'b0100000000000: Constant 2.
  -- 13'b1000000000000: Constant -1.
  processing_27 : process (inst_as_nxt)
  begin
    if (inst_as_nxt(7)) then
      sconst_nxt <= X"0004";
    elsif (inst_as_nxt(8)) then
      sconst_nxt <= X"0008";
    elsif (inst_as_nxt(9)) then
      sconst_nxt <= X"0000";
    elsif (inst_as_nxt(10)) then
      sconst_nxt <= X"0001";
    elsif (inst_as_nxt(11)) then
      sconst_nxt <= X"0002";
    elsif (inst_as_nxt(12)) then
      sconst_nxt <= X"ffff";
    else
      sconst_nxt <= X"0000";
    end if;
  end process;


  --
  -- 6.7) DESTINATION ADDRESSING MODES
  -------------------------------------
  -- Destination addressing modes are encoded in a one hot fashion as following:
  --
  -- 8'b00000001: Register direct.
  -- 8'b00000010: Register indexed.
  -- 8'b00010000: Symbolic (operand is in memory at address PC+x).
  -- 8'b01000000: Absolute (operand is in memory at address x).

  dest_reg <= ir(3 downto 0);

  processing_28 : process (dest_reg, ir, inst_type_nxt)
  begin
    if (not inst_type_nxt(INST_TO)) then
      inst_ad_nxt <= "00000000";
    elsif (dest_reg = X"2") then  -- Addressing mode using R2
      case ((ir(7))) is
      when '1' =>
        inst_ad_nxt <= "01000000";
      when others =>
        inst_ad_nxt <= "00000001";
      end case;
    elsif (dest_reg = X"0") then  -- Addressing mode using R0
      case ((ir(7))) is
      when '1' =>
        inst_ad_nxt <= "00010000";
      when others =>
        inst_ad_nxt <= "00000001";
      end case;
    else    -- General Addressing mode
      case ((ir(7))) is
      when '1' =>
        inst_ad_nxt <= "00000010";
      when others =>
        inst_ad_nxt <= "00000001";
      end case;
    end if;
  end process;


  CLOCK_GATING_GENERATING_20 : if (CLOCK_GATING = '1') generate
    processing_29 : process (mclk_decode, puc_rst)
    begin
      if (puc_rst) then
        inst_ad <= X"00";
      elsif (rising_edge(mclk_decode)) then
        inst_ad <= inst_ad_nxt;
      end if;
    end process;
  elsif (CLOCK_GATING = '0') generate
    processing_30 : process (mclk_decode, puc_rst)
    begin
      if (puc_rst) then
        inst_ad <= X"00";
      elsif (rising_edge(mclk_decode)) then
        if (decode) then
          inst_ad <= inst_ad_nxt;
        end if;
      end if;
    end process;
  end generate;


  --
  -- 6.8) REMAINING INSTRUCTION DECODING
  --------------------------------------

  -- Operation size
  processing_31 : process (mclk, puc_rst)
  begin
    if (puc_rst) then
      inst_bw <= '0';
    elsif (rising_edge(mclk)) then
      if (decode) then
        inst_bw <= ir(6) and not inst_type_nxt(INST_JMP) and not irq_detect and not cpu_halt_req;
      end if;
    end if;
  end process;


  -- Extended instruction size
  inst_sz_nxt <= ('0' & (inst_as_nxt(IDX) or inst_as_nxt(SYMB) or inst_as_nxt(ABS) or inst_as_nxt(IMM)))+('0' & ((inst_ad_nxt(IDX) or inst_ad_nxt(SYMB) or inst_ad_nxt(ABS)) and not inst_type_nxt(INST_SO)));

  CLOCK_GATING_GENERATING_21 : if (CLOCK_GATING = '1') generate
    processing_32 : process (mclk_decode, puc_rst)
    begin
      if (puc_rst) then
        inst_sz <= "00";
      elsif (rising_edge(mclk_decode)) then
        inst_sz <= inst_sz_nxt;
      end if;
    end process;
  elsif (CLOCK_GATING = '0') generate
    processing_33 : process (mclk_decode, puc_rst)
    begin
      if (puc_rst) then
        inst_sz <= "00";
      elsif (rising_edge(mclk_decode)) then
        if (decode) then
          inst_sz <= inst_sz_nxt;
        end if;
      end if;
    end process;
  end generate;


  --=============================================================================
  -- 7)  EXECUTION-UNIT STATE MACHINE
  --=============================================================================

  -- State machine registers

  -- State machine control signals
  ----------------------------------

  src_acalc_pre <= inst_as_nxt(IDX) or inst_as_nxt(SYMB) or inst_as_nxt(ABS);
  src_rd_pre <= inst_as_nxt(INDIR) or inst_as_nxt(INDIR_I) or inst_as_nxt(IMM) or inst_so_nxt(RETI);
  dst_acalc_pre <= inst_ad_nxt(IDX) or inst_ad_nxt(SYMB) or inst_ad_nxt(ABS);
  dst_acalc <= inst_ad(IDX) or inst_ad(SYMB) or inst_ad(ABS);
  dst_rd_pre <= inst_ad_nxt(IDX) or inst_so_nxt(PUSH) or inst_so_nxt(CALL) or inst_so_nxt(RETI);
  dst_rd <= inst_ad(IDX) or inst_so(PUSH) or inst_so(CALL) or inst_so(RETI);

  inst_branch <= (inst_ad_nxt(DIR) and (ir(3 downto 0) = X"0")) or inst_type_nxt(INST_JMP) or inst_so_nxt(RETI);

  processing_34 : process (mclk, puc_rst)
  begin
    if (puc_rst) then
      exec_jmp <= '0';
    elsif (rising_edge(mclk)) then
      if (inst_branch and decode) then
        exec_jmp <= '1';
      elsif (e_state = E_JUMP) then
        exec_jmp <= '0';
      end if;
    end if;
  end process;


  processing_35 : process (mclk, puc_rst)
  begin
    if (puc_rst) then
      exec_dst_wr <= '0';
    elsif (rising_edge(mclk)) then
      if (e_state = E_DST_RD) then
        exec_dst_wr <= '1';
      elsif (e_state = E_DST_WR) then
        exec_dst_wr <= '0';
      end if;
    end if;
  end process;


  processing_36 : process (mclk, puc_rst)
  begin
    if (puc_rst) then
      exec_src_wr <= '0';
    elsif (rising_edge(mclk)) then
      if (inst_type(INST_SO) and (e_state = E_SRC_RD)) then
        exec_src_wr <= '1';
      elsif ((e_state = E_SRC_WR) or (e_state = E_DST_WR)) then
        exec_src_wr <= '0';
      end if;
    end if;
  end process;


  processing_37 : process (mclk, puc_rst)
  begin
    if (puc_rst) then
      exec_dext_rdy <= '0';
    elsif (rising_edge(mclk)) then
      if (e_state = E_DST_RD) then
        exec_dext_rdy <= '0';
      elsif (inst_dext_rdy) then
        exec_dext_rdy <= '1';
      end if;
    end if;
  end process;


  -- Execution first state
  e_first_state <= E_IRQ_0
  when not cpu_halt_st and inst_so_nxt(IRQ) else E_IDLE
  when cpu_halt_req or (i_state = I_IDLE) else E_IDLE
  when cpuoff else E_SRC_AD
  when src_acalc_pre else E_SRC_RD
  when src_rd_pre else E_DST_AD
  when dst_acalc_pre else E_DST_RD
  when dst_rd_pre else E_EXEC;

  -- State machine
  ----------------

  -- States Transitions
  processing_38 : process (e_state, dst_acalc, dst_rd, inst_sext_rdy, inst_dext_rdy, exec_dext_rdy, exec_jmp, exec_dst_wr, e_first_state, exec_src_wr)
  begin
    case ((e_state)) is
    when E_IDLE =>
      e_state_nxt <= e_first_state;
    when E_IRQ_0 =>
      e_state_nxt <= E_IRQ_1;
    when E_IRQ_1 =>
      e_state_nxt <= E_IRQ_2;
    when E_IRQ_2 =>
      e_state_nxt <= E_IRQ_3;
    when E_IRQ_3 =>
      e_state_nxt <= E_IRQ_4;
    when E_IRQ_4 =>


      e_state_nxt <= E_EXEC;
    when E_SRC_AD =>


      e_state_nxt <= E_SRC_RD
      when inst_sext_rdy else E_SRC_AD;
    when E_SRC_RD =>


      e_state_nxt <= E_DST_AD
      when dst_acalc else E_DST_RD
      when dst_rd else E_EXEC;
    when E_DST_AD =>


      e_state_nxt <= E_DST_RD
      when (inst_dext_rdy or exec_dext_rdy) else E_DST_AD;
    when E_DST_RD =>


      e_state_nxt <= E_EXEC;
    when E_EXEC =>


      e_state_nxt <= E_DST_WR
      when exec_dst_wr else E_JUMP
      when exec_jmp else E_SRC_WR
      when exec_src_wr else e_first_state;
    when E_JUMP =>
      e_state_nxt <= e_first_state;
    when E_DST_WR =>
      e_state_nxt <= E_JUMP
      when exec_jmp else e_first_state;
    when E_SRC_WR =>
      e_state_nxt <= e_first_state;
    -- pragma coverage off
    when others =>
      e_state_nxt <= E_IRQ_0;
    end case;
  end process;
  -- pragma coverage on


  -- State machine
  processing_39 : process (mclk, puc_rst)
  begin
    if (puc_rst) then
      e_state <= E_IRQ_1;
    elsif (rising_edge(mclk)) then
      e_state <= e_state_nxt;
    end if;
  end process;


  -- Frontend State machine control signals
  ------------------------------------------

  exec_done <= (e_state = E_JUMP)
  when exec_jmp else (e_state = E_DST_WR)
  when exec_dst_wr else (e_state = E_SRC_WR)
  when exec_src_wr else (e_state = E_EXEC);

  --=============================================================================
  -- 8)  EXECUTION-UNIT STATE CONTROL
  --=============================================================================

  --
  -- 8.1) ALU CONTROL SIGNALS
  ---------------------------
  --
  -- 12'b000000000001: Enable ALU source inverter
  -- 12'b000000000010: Enable Incrementer
  -- 12'b000000000100: Enable Incrementer on carry bit
  -- 12'b000000001000: Select Adder
  -- 12'b000000010000: Select AND
  -- 12'b000000100000: Select OR
  -- 12'b000001000000: Select XOR
  -- 12'b000010000000: Select DADD
  -- 12'b000100000000: Update N, Z & C (C=~Z)
  -- 12'b001000000000: Update all status bits
  -- 12'b010000000000: Update status bit for XOR instruction
  -- 12'b100000000000: Don't write to destination

  alu_src_inv <= inst_to_nxt(SUB) or inst_to_nxt(SUBC) or inst_to_nxt(CMP) or inst_to_nxt(BIC);

  alu_inc <= inst_to_nxt(SUB) or inst_to_nxt(CMP);

  alu_inc_c <= inst_to_nxt(ADDC) or inst_to_nxt(DADD) or inst_to_nxt(SUBC);

  alu_add <= inst_to_nxt(ADD) or inst_to_nxt(ADDC) or inst_to_nxt(SUB) or inst_to_nxt(SUBC) or inst_to_nxt(CMP) or inst_type_nxt(INST_JMP) or inst_so_nxt(RETI);


  alu_and <= inst_to_nxt(ANDX) or inst_to_nxt(BIC) or inst_to_nxt(BITX);

  alu_or <= inst_to_nxt(BIS);

  alu_xor <= inst_to_nxt(XORX);

  alu_dadd <= inst_to_nxt(DADD);

  alu_stat_7 <= inst_to_nxt(BITX) or inst_to_nxt(ANDX) or inst_so_nxt(SXT);

  alu_stat_f <= inst_to_nxt(ADD) or inst_to_nxt(ADDC) or inst_to_nxt(SUB) or inst_to_nxt(SUBC) or inst_to_nxt(CMP) or inst_to_nxt(DADD) or inst_to_nxt(BITX) or inst_to_nxt(XORX) or inst_to_nxt(ANDX) or inst_so_nxt(RRC) or inst_so_nxt(RRA) or inst_so_nxt(SXT);

  alu_shift <= inst_so_nxt(RRC) or inst_so_nxt(RRA);

  exec_no_wr <= inst_to_nxt(CMP) or inst_to_nxt(BITX);

  inst_alu_nxt <= (exec_no_wr & alu_shift & alu_stat_f & alu_stat_7 & alu_dadd & alu_xor & alu_or & alu_and & alu_add & alu_inc_c & alu_inc & alu_src_inv);
  CLOCK_GATING_GENERATING_22 : if (CLOCK_GATING = '1') generate
    processing_40 : process (mclk_decode, puc_rst)
    begin
      if (puc_rst) then
        inst_alu <= X"000";
      elsif (rising_edge(mclk_decode)) then
        inst_alu <= inst_alu_nxt;
      end if;
    end process;
  elsif (CLOCK_GATING = '0') generate
    processing_41 : process (mclk_decode, puc_rst)
    begin
      if (puc_rst) then
        inst_alu <= X"000";
      elsif (rising_edge(mclk_decode)) then
        if (decode) then
          inst_alu <= inst_alu_nxt;
        end if;
      end if;
    end process;
  end generate;
end RTL;
