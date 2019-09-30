-- Converted from omsp_dbg_i2c.v
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
-- *File Name: omsp_dbg_i2c.v
--
-- *Module Description:
--                       Debug I2C Slave communication interface
--
-- *Author(s):
--              - Olivier Girard,    olgirard@gmail.com
--

use work."openMSP430_defines.v".all;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity omsp_dbg_i2c is
  port (
  -- OUTPUTs
  --========
    dbg_addr : out std_logic_vector(5 downto 0);  -- Debug register address
    dbg_din : out std_logic_vector(15 downto 0);  -- Debug register data input
    dbg_i2c_sda_out : out std_logic;  -- Debug interface: I2C SDA OUT
    dbg_rd : out std_logic;  -- Debug register data read
    dbg_wr : out std_logic;  -- Debug register data write

  -- INPUTs
  --=======
    dbg_clk : in std_logic;  -- Debug unit clock
    dbg_dout : in std_logic_vector(15 downto 0);  -- Debug register data output
    dbg_i2c_addr : in std_logic_vector(6 downto 0);  -- Debug interface: I2C ADDRESS
    dbg_i2c_broadcast : in std_logic_vector(6 downto 0);  -- Debug interface: I2C Broadcast Address (for multicore systems)
    dbg_i2c_scl : in std_logic;  -- Debug interface: I2C SCL
    dbg_i2c_sda_in : in std_logic;  -- Debug interface: I2C SDA IN
    dbg_rst : in std_logic;  -- Debug unit reset
    mem_burst : in std_logic;  -- Burst on going
    mem_burst_end : in std_logic;  -- End TX/RX burst
    mem_burst_rd : in std_logic;  -- Start TX burst
    mem_burst_wr : in std_logic   -- Start RX burst
    mem_bw : in std_logic  -- Burst byte width
  );
end omsp_dbg_i2c;

architecture RTL of omsp_dbg_i2c is
  component omsp_sync_cell
  port (
    data_out : std_logic_vector(? downto 0);
    data_in : std_logic_vector(? downto 0);
    clk : std_logic_vector(? downto 0);
    rst : std_logic_vector(? downto 0)
  );
  end component;

  --=============================================================================
  -- 1) I2C RECEIVE LINE SYNCHRONIZTION & FILTERING
  --=============================================================================

  -- Synchronize SCL/SDA inputs
  -----------------------------

  signal scl_sync_n : std_logic;

  signal scl_sync : std_logic;

  signal sda_in_sync_n : std_logic;

  signal sda_in_sync : std_logic;

  -- SCL/SDA input buffers
  ------------------------

  signal scl_buf : std_logic_vector(1 downto 0);

  signal sda_in_buf : std_logic_vector(1 downto 0);

  -- SCL/SDA Majority decision
  ----------------------------

  signal scl : std_logic;

  signal sda_in : std_logic;

  -- SCL/SDA Edge detection
  -------------------------

  -- SDA Edge detection
  signal sda_in_dly : std_logic;

  signal sda_in_fe : std_logic;
  signal sda_in_re : std_logic;
  signal sda_in_edge : std_logic;

  -- SCL Edge detection
  signal scl_dly : std_logic;

  signal scl_fe : std_logic;
  signal scl_re : std_logic;
  signal scl_edge : std_logic;

  -- Delayed SCL Rising-Edge for SDA data sampling
  signal scl_re_dly : std_logic_vector(1 downto 0);

  signal scl_sample : std_logic;

  --=============================================================================
  -- 2) I2C START & STOP CONDITION DETECTION
  --=============================================================================

  -------------------
  -- Start condition
  -------------------

  signal start_detect : std_logic;

  -------------------
  -- Stop condition
  -------------------

  signal stop_detect : std_logic;

  -------------------
  -- I2C Slave Active
  -------------------
  -- The I2C logic will be activated whenever a start condition
  -- is detected and will be disactivated if the slave address
  -- doesn't match or if a stop condition is detected.

  signal i2c_addr_not_valid : std_logic;

  signal i2c_active_seq : std_logic;

  signal i2c_active : std_logic;
  signal i2c_init : std_logic;

  --=============================================================================
  -- 3) I2C STATE MACHINE
  --=============================================================================

  -- State register/wires
  signal i2c_state : std_logic_vector(2 downto 0);
  signal i2c_state_nxt : std_logic_vector(2 downto 0);

  -- Utility signals
  signal shift_buf : std_logic_vector(8 downto 0);
  signal shift_rx_done : std_logic;
  signal shift_tx_done : std_logic;
  signal dbg_rd : std_logic;

  -- State machine definition
  constant RX_ADDR : std_logic_vector(2 downto 0) := X"0";
  constant RX_ADDR_ACK : std_logic_vector(2 downto 0) := X"1";
  constant RX_DATA : std_logic_vector(2 downto 0) := X"2";
  constant RX_DATA_ACK : std_logic_vector(2 downto 0) := X"3";
  constant TX_DATA : std_logic_vector(2 downto 0) := X"4";
  constant TX_DATA_ACK : std_logic_vector(2 downto 0) := X"5";

  --=============================================================================
  -- 4) I2C SHIFT REGISTER (FOR RECEIVING & TRANSMITING)
  --=============================================================================

  signal shift_rx_en : std_logic;
  signal shift_tx_en : std_logic;
  signal shift_tx_en_pre : std_logic;

  signal shift_buf_rx_init : std_logic;
  signal shift_buf_rx_en : std_logic;
  signal shift_buf_tx_init : std_logic;
  signal shift_buf_tx_en : std_logic;

  signal shift_tx_val : std_logic_vector(7 downto 0);

  signal shift_buf_nxt : std_logic_vector(8 downto 0);

  -- Detect when the received I2C device address is not valid
  signal UNUSED_dbg_i2c_broadcast : std_logic_vector(6 downto 0);

  -- Utility signals
  signal shift_rx_data_done : std_logic;
  signal shift_tx_data_done : std_logic;

  --=============================================================================
  -- 5) I2C TRANSMIT BUFFER
  --=============================================================================

  signal dbg_i2c_sda_out : std_logic;

  --=============================================================================
  -- 6) DEBUG INTERFACE STATE MACHINE
  --=============================================================================

  -- State register/wires
  signal dbg_state : std_logic_vector(2 downto 0);
  signal dbg_state_nxt : std_logic_vector(2 downto 0);

  -- Utility signals
  signal dbg_bw : std_logic;

  -- State machine definition
  constant RX_CMD : std_logic_vector(2 downto 0) := X"0";
  constant RX_BYTE_LO : std_logic_vector(2 downto 0) := X"1";
  constant RX_BYTE_HI : std_logic_vector(2 downto 0) := X"2";
  constant TX_BYTE_LO : std_logic_vector(2 downto 0) := X"3";
  constant TX_BYTE_HI : std_logic_vector(2 downto 0) := X"4";

  -- Utility signals
  signal cmd_valid : std_logic;
  signal rx_lo_valid : std_logic;
  signal rx_hi_valid : std_logic;

  --=============================================================================
  -- 7) REGISTER READ/WRITE ACCESS
  --=============================================================================

  constant MEM_DATA : std_logic_vector(5 downto 0) := X"06";

  -- Debug register address & bit width
  signal dbg_addr : std_logic_vector(5 downto 0);

  -- Debug register data input
  signal dbg_din_lo : std_logic_vector(7 downto 0);
  signal dbg_din_hi : std_logic_vector(7 downto 0);

  -- Debug register data write command
  signal dbg_wr : std_logic;

begin
  --=============================================================================
  -- 1) I2C RECEIVE LINE SYNCHRONIZTION & FILTERING
  --=============================================================================

  -- Synchronize SCL/SDA inputs
  -----------------------------
  sync_cell_i2c_scl : omsp_sync_cell
  port map (
    data_out => scl_sync_n,
    data_in => not dbg_i2c_scl,
    clk => dbg_clk,
    rst => dbg_rst
  );
  scl_sync <= not scl_sync_n;

  sync_cell_i2c_sda : omsp_sync_cell
  port map (
    data_out => sda_in_sync_n,
    data_in => not dbg_i2c_sda_in,
    clk => dbg_clk,
    rst => dbg_rst
  );
  sda_in_sync <= not sda_in_sync_n;

  -- SCL/SDA input buffers
  ------------------------
  processing_0 : process (dbg_clk, dbg_rst)
  begin
    if (dbg_rst) then
      scl_buf <= X"3";
    elsif (rising_edge(dbg_clk)) then
      scl_buf <= (scl_buf(0) & scl_sync);
    end if;
  end process;


  processing_1 : process (dbg_clk, dbg_rst)
  begin
    if (dbg_rst) then
      sda_in_buf <= X"3";
    elsif (rising_edge(dbg_clk)) then
      sda_in_buf <= (sda_in_buf(0) & sda_in_sync);
    end if;
  end process;


  -- SCL/SDA Majority decision
  ----------------------------

  scl <= (scl_sync and scl_buf(0)) or (scl_sync and scl_buf(1)) or (scl_buf(0) and scl_buf(1));

  sda_in <= (sda_in_sync and sda_in_buf(0)) or (sda_in_sync and sda_in_buf(1)) or (sda_in_buf(0) and sda_in_buf(1));

  -- SCL/SDA Edge detection
  -------------------------

  -- SDA Edge detection
  processing_2 : process (dbg_clk, dbg_rst)
  begin
    if (dbg_rst) then
      sda_in_dly <= '1';
    elsif (rising_edge(dbg_clk)) then
      sda_in_dly <= sda_in;
    end if;
  end process;


  sda_in_fe <= sda_in_dly and not sda_in;
  sda_in_re <= not sda_in_dly and sda_in;
  sda_in_edge <= sda_in_dly xor sda_in;

  -- SCL Edge detection
  processing_3 : process (dbg_clk, dbg_rst)
  begin
    if (dbg_rst) then
      scl_dly <= '1';
    elsif (rising_edge(dbg_clk)) then
      scl_dly <= scl;
    end if;
  end process;


  scl_fe <= scl_dly and not scl;
  scl_re <= not scl_dly and scl;
  scl_edge <= scl_dly xor scl;

  -- Delayed SCL Rising-Edge for SDA data sampling
  processing_4 : process (dbg_clk, dbg_rst)
  begin
    if (dbg_rst) then
      scl_re_dly <= "00";
    elsif (rising_edge(dbg_clk)) then
      scl_re_dly <= (scl_re_dly(0) & scl_re);
    end if;
  end process;


  scl_sample <= scl_re_dly(1);

  --=============================================================================
  -- 2) I2C START & STOP CONDITION DETECTION
  --=============================================================================

  -------------------
  -- Start condition
  -------------------

  start_detect <= sda_in_fe and scl;

  -------------------
  -- Stop condition
  -------------------

  stop_detect <= sda_in_re and scl;

  -------------------
  -- I2C Slave Active
  -------------------
  -- The I2C logic will be activated whenever a start condition
  -- is detected and will be disactivated if the slave address
  -- doesn't match or if a stop condition is detected.

  processing_5 : process (dbg_clk, dbg_rst)
  begin
    if (dbg_rst) then
      i2c_active_seq <= '0';
    elsif (rising_edge(dbg_clk)) then
      if (start_detect) then
        i2c_active_seq <= '1';
      elsif (stop_detect or i2c_addr_not_valid) then
        i2c_active_seq <= '0';
      end if;
    end if;
  end process;


  i2c_active <= i2c_active_seq and not stop_detect;
  i2c_init <= not i2c_active or start_detect;

  --=============================================================================
  -- 3) I2C STATE MACHINE
  --=============================================================================

  -- State transition
  processing_6 : process (i2c_state, i2c_init, shift_rx_done, i2c_addr_not_valid, shift_tx_done, scl_fe, shift_buf, sda_in)
  begin
    case ((i2c_state)) is
    when RX_ADDR =>


      i2c_state_nxt <= RX_ADDR
      when i2c_init else RX_ADDR
      when not shift_rx_done else RX_ADDR
      when i2c_addr_not_valid else RX_ADDR_ACK;
    when RX_ADDR_ACK =>


      i2c_state_nxt <= RX_ADDR
      when i2c_init else RX_ADDR_ACK
      when not scl_fe else TX_DATA
      when shift_buf(0) else RX_DATA;
    when RX_DATA =>


      i2c_state_nxt <= RX_ADDR
      when i2c_init else RX_DATA
      when not shift_rx_done else RX_DATA_ACK;
    when RX_DATA_ACK =>


      i2c_state_nxt <= RX_ADDR
      when i2c_init else RX_DATA_ACK
      when not scl_fe else RX_DATA;
    when TX_DATA =>


      i2c_state_nxt <= RX_ADDR
      when i2c_init else TX_DATA
      when not shift_tx_done else TX_DATA_ACK;
    when TX_DATA_ACK =>
      i2c_state_nxt <= RX_ADDR
      when i2c_init else TX_DATA_ACK
      when not scl_fe else TX_DATA
      when not sda_in else RX_ADDR;
    -- pragma coverage off
    when others =>
      i2c_state_nxt <= RX_ADDR;
    end case;
  end process;
  -- pragma coverage on


  -- State machine
  processing_7 : process (dbg_clk, dbg_rst)
  begin
    if (dbg_rst) then
      i2c_state <= RX_ADDR;
    elsif (rising_edge(dbg_clk)) then
      i2c_state <= i2c_state_nxt;
    end if;
  end process;


  --=============================================================================
  -- 4) I2C SHIFT REGISTER (FOR RECEIVING & TRANSMITING)
  --=============================================================================

  shift_rx_en <= ((i2c_state = RX_ADDR) or (i2c_state = RX_DATA) or (i2c_state = RX_DATA_ACK));
  shift_tx_en <= (i2c_state = TX_DATA) or (i2c_state = TX_DATA_ACK);
  shift_tx_en_pre <= (i2c_state_nxt = TX_DATA) or (i2c_state_nxt = TX_DATA_ACK);

  shift_rx_done <= shift_rx_en and scl_fe and shift_buf(8);
  shift_tx_done <= shift_tx_en and scl_fe and (shift_buf = X"100");

  shift_buf_rx_init <= i2c_init or ((i2c_state = RX_ADDR_ACK) and scl_fe and not shift_buf(0)) or ((i2c_state = RX_DATA_ACK) and scl_fe);
  shift_buf_rx_en <= shift_rx_en and scl_sample;

  shift_buf_tx_init <= ((i2c_state = RX_ADDR_ACK) and scl_re and shift_buf(0)) or ((i2c_state = TX_DATA_ACK) and scl_re);
  shift_buf_tx_en <= shift_tx_en_pre and scl_fe and (shift_buf /= X"100");

  -- RX Init
  -- TX Init
  -- RX Shift
  -- TX Shift
  shift_buf_nxt <= X"001"
  when shift_buf_rx_init else (shift_tx_val & '1')
  when shift_buf_tx_init else (shift_buf(7 downto 0) & sda_in)
  when shift_buf_rx_en else (shift_buf(7 downto 0) & '0')
  when shift_buf_tx_en else shift_buf(8 downto 0);  -- Hold

  processing_8 : process (dbg_clk, dbg_rst)
  begin
    if (dbg_rst) then
      shift_buf <= X"001";
    elsif (rising_edge(dbg_clk)) then
      shift_buf <= shift_buf_nxt;
    end if;
  end process;


  -- Detect when the received I2C device address is not valid
  DBG_I2C_BROADCAST_GENERATING_0 : if (DBG_I2C_BROADCAST = '1') generate
    i2c_addr_not_valid <= (i2c_state = RX_ADDR) and shift_rx_done and ((shift_buf(7 downto 1) /= dbg_i2c_broadcast(6 downto 0)) and (shift_buf(7 downto 1) /= dbg_i2c_addr(6 downto 0)));
  elsif (DBG_I2C_BROADCAST = '0') generate
    i2c_addr_not_valid <= (i2c_state = RX_ADDR) and shift_rx_done and ((shift_buf(7 downto 1) /= dbg_i2c_addr(6 downto 0)));
  end generate;


  DBG_I2C_BROADCAST_GENERATING_1 : if (DBG_I2C_BROADCAST = '1') generate
  elsif (DBG_I2C_BROADCAST = '0') generate
    UNUSED_dbg_i2c_broadcast <= dbg_i2c_broadcast;
  end generate;
  -- Utility signals
  shift_rx_data_done <= shift_rx_done and (i2c_state = RX_DATA);
  shift_tx_data_done <= shift_tx_done;

  --=============================================================================
  -- 5) I2C TRANSMIT BUFFER
  --=============================================================================

  processing_9 : process (dbg_clk, dbg_rst)
  begin
    if (dbg_rst) then
      dbg_i2c_sda_out <= '1';
    elsif (rising_edge(dbg_clk)) then
      if (scl_fe) then
        dbg_i2c_sda_out <= not ((i2c_state_nxt = RX_ADDR_ACK) or (i2c_state_nxt = RX_DATA_ACK) or (shift_buf_tx_en and not shift_buf(8)));
      end if;
    end if;
  end process;


  --=============================================================================
  -- 6) DEBUG INTERFACE STATE MACHINE
  --=============================================================================

  -- State transition
  processing_10 : process (dbg_state, shift_rx_data_done, shift_tx_data_done, shift_buf, dbg_bw, mem_burst_wr, mem_burst_rd, mem_burst, mem_burst_end, mem_bw)
  begin
    case ((dbg_state)) is
    when RX_CMD =>


      dbg_state_nxt <= RX_BYTE_LO
      when mem_burst_wr else TX_BYTE_LO
      when mem_burst_rd else RX_CMD
      when not shift_rx_data_done else RX_BYTE_LO
      when shift_buf(7) else TX_BYTE_LO;
    when RX_BYTE_LO =>


      dbg_state_nxt <= RX_CMD
      when (mem_burst and mem_burst_end) else RX_BYTE_LO
      when not shift_rx_data_done else RX_BYTE_LO
      when mem_bw else RX_BYTE_HI
      when (mem_burst and not mem_burst_end) else RX_CMD
      when dbg_bw else RX_BYTE_HI;
    when RX_BYTE_HI =>


      dbg_state_nxt <= RX_BYTE_HI
      when not shift_rx_data_done else RX_BYTE_LO
      when (mem_burst and not mem_burst_end) else RX_CMD;
    when TX_BYTE_LO =>


      dbg_state_nxt <= TX_BYTE_LO
      when not shift_tx_data_done else TX_BYTE_LO
      when (mem_burst and mem_bw) else TX_BYTE_HI
      when (mem_burst and not mem_bw) else TX_BYTE_HI
      when not dbg_bw else RX_CMD;
    when TX_BYTE_HI =>


      dbg_state_nxt <= TX_BYTE_HI
      when not shift_tx_data_done else TX_BYTE_LO
      when mem_burst else RX_CMD;
    -- pragma coverage off
    when others =>
      dbg_state_nxt <= RX_CMD;
    end case;
  end process;
  -- pragma coverage on


  -- State machine
  processing_11 : process (dbg_clk, dbg_rst)
  begin
    if (dbg_rst) then
      dbg_state <= RX_CMD;
    elsif (rising_edge(dbg_clk)) then
      dbg_state <= dbg_state_nxt;
    end if;
  end process;


  -- Utility signals
  cmd_valid <= (dbg_state = RX_CMD) and shift_rx_data_done;
  rx_lo_valid <= (dbg_state = RX_BYTE_LO) and shift_rx_data_done;
  rx_hi_valid <= (dbg_state = RX_BYTE_HI) and shift_rx_data_done;

  --=============================================================================
  -- 7) REGISTER READ/WRITE ACCESS
  --=============================================================================

  -- Debug register address & bit width
  processing_12 : process (dbg_clk, dbg_rst)
  begin
    if (dbg_rst) then
      dbg_bw <= '0';
      dbg_addr <= X"00";
    elsif (rising_edge(dbg_clk)) then
      if (cmd_valid) then
        dbg_bw <= shift_buf(6);
        dbg_addr <= shift_buf(5 downto 0);
      elsif (mem_burst) then
        dbg_bw <= mem_bw;
        dbg_addr <= MEM_DATA;
      end if;
    end if;
  end process;


  -- Debug register data input
  processing_13 : process (dbg_clk, dbg_rst)
  begin
    if (dbg_rst) then
      dbg_din_lo <= X"00";
    elsif (rising_edge(dbg_clk)) then
      if (rx_lo_valid) then
        dbg_din_lo <= shift_buf(7 downto 0);
      end if;
    end if;
  end process;


  processing_14 : process (dbg_clk, dbg_rst)
  begin
    if (dbg_rst) then
      dbg_din_hi <= X"00";
    elsif (rising_edge(dbg_clk)) then
      if (rx_lo_valid) then
        dbg_din_hi <= X"00";
      elsif (rx_hi_valid) then
        dbg_din_hi <= shift_buf(7 downto 0);
      end if;
    end if;
  end process;


  dbg_din <= (dbg_din_hi & dbg_din_lo);

  -- Debug register data write command
  processing_15 : process (dbg_clk, dbg_rst)
  begin
    if (dbg_rst) then
      dbg_wr <= '0';
    elsif (rising_edge(dbg_clk)) then
      dbg_wr <= rx_lo_valid
      when (mem_burst and mem_bw) else rx_hi_valid
      when (mem_burst and not mem_bw) else rx_lo_valid
      when dbg_bw else rx_hi_valid;
    end if;
  end process;


  -- Debug register data read command
  processing_16 : process (dbg_clk, dbg_rst)
  begin
    if (dbg_rst) then
      dbg_rd <= '0';
    elsif (rising_edge(dbg_clk)) then
      dbg_rd <= (shift_tx_data_done and (dbg_state = TX_BYTE_LO))
      when (mem_burst and mem_bw) else (shift_tx_data_done and (dbg_state = TX_BYTE_HI))
      when (mem_burst and not mem_bw) else not shift_buf(7)
      when cmd_valid else '0';
    end if;
  end process;


  -- Debug register data read value
  shift_tx_val <= dbg_dout(15 downto 8)
  when (dbg_state = TX_BYTE_HI) else dbg_dout(7 downto 0);
end RTL;
