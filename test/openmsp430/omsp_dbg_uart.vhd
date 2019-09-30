-- Converted from omsp_dbg_uart.v
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
-- *File Name: omsp_dbg_uart.v
--
-- *Module Description:
--                       Debug UART communication interface (8N1, Half-duplex)
--
-- *Author(s):
--              - Olivier Girard,    olgirard@gmail.com
--

use work."openMSP430_defines.v".all;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity omsp_dbg_uart is
  port (
  -- OUTPUTs
  --=========
    dbg_addr : out std_logic_vector(5 downto 0);  -- Debug register address
    dbg_din : out std_logic_vector(15 downto 0);  -- Debug register data input
    dbg_rd : out std_logic;  -- Debug register data read
    dbg_uart_txd : out std_logic;  -- Debug interface: UART TXD
    dbg_wr : out std_logic;  -- Debug register data write

  -- INPUTs
  --=========
    dbg_clk : in std_logic;  -- Debug unit clock
    dbg_dout : in std_logic_vector(15 downto 0);  -- Debug register data output
    dbg_rd_rdy : in std_logic;  -- Debug register data is ready for read
    dbg_rst : in std_logic;  -- Debug unit reset
    dbg_uart_rxd : in std_logic;  -- Debug interface: UART RXD
    mem_burst : in std_logic;  -- Burst on going
    mem_burst_end : in std_logic;  -- End TX/RX burst
    mem_burst_rd : in std_logic;  -- Start TX burst
    mem_burst_wr : in std_logic   -- Start RX burst
    mem_bw : in std_logic  -- Burst byte width
  );
end omsp_dbg_uart;

architecture RTL of omsp_dbg_uart is
  component omsp_sync_cell
  port (
    data_out : std_logic_vector(? downto 0);
    data_in : std_logic_vector(? downto 0);
    clk : std_logic_vector(? downto 0);
    rst : std_logic_vector(? downto 0)
  );
  end component;

  --=============================================================================
  -- 1)  UART RECEIVE LINE SYNCHRONIZTION & FILTERING
  --=============================================================================

  -- Synchronize RXD input
  ------------------------
  signal uart_rxd_n : std_logic;
  signal uart_rxd : std_logic;

  -- RXD input buffer
  -------------------
  signal rxd_buf : std_logic_vector(1 downto 0);

  -- Majority decision
  --------------------
  signal rxd_maj : std_logic;
  signal rxd_maj_nxt : std_logic;

  signal rxd_s : std_logic;
  signal rxd_fe : std_logic;
  signal rxd_re : std_logic;
  signal rxd_edge : std_logic;

  --=============================================================================
  -- 2)  UART STATE MACHINE
  --=============================================================================

  -- Receive state
  ----------------
  signal uart_state : std_logic_vector(2 downto 0);
  signal uart_state_nxt : std_logic_vector(2 downto 0);

  signal sync_done : std_logic;
  signal xfer_done : std_logic;
  signal xfer_buf : std_logic_vector(19 downto 0);
  signal xfer_buf_nxt : std_logic_vector(19 downto 0);

  -- State machine definition
  constant RX_SYNC : std_logic_vector(2 downto 0) := X"0";
  constant RX_CMD : std_logic_vector(2 downto 0) := X"1";
  constant RX_DATA1 : std_logic_vector(2 downto 0) := X"2";
  constant RX_DATA2 : std_logic_vector(2 downto 0) := X"3";
  constant TX_DATA1 : std_logic_vector(2 downto 0) := X"4";
  constant TX_DATA2 : std_logic_vector(2 downto 0) := X"5";

  -- Utility signals
  signal cmd_valid : std_logic;
  signal rx_active : std_logic;
  signal tx_active : std_logic;

  --=============================================================================
  -- 3)  UART SYNCHRONIZATION
  --=============================================================================
  -- After DBG_RST, the host needs to fist send a synchronization character (0x80)
  -- If this feature doesn't work properly, it is possible to disable it by
  -- commenting the DBG_UART_AUTO_SYNC define in the openMSP430.inc file.

  signal sync_busy : std_logic;

  signal sync_cnt : std_logic_vector(DBG_UART_XFER_CNT_W+2 downto 0);

  signal bit_cnt_max : std_logic_vector(DBG_UART_XFER_CNT_W-1 downto 0);

  --=============================================================================
  -- 4)  UART RECEIVE / TRANSMIT
  --=============================================================================

  -- Transfer counter
  -------------------
  signal xfer_bit : std_logic_vector(3 downto 0);
  signal xfer_cnt : std_logic_vector(DBG_UART_XFER_CNT_W-1 downto 0);

  signal txd_start : std_logic;
  signal rxd_start : std_logic;
  signal xfer_bit_inc : std_logic;

  -- Generate TXD output
  ----------------------
  signal dbg_uart_txd : std_logic;

  --=============================================================================
  -- 5) INTERFACE TO DEBUG REGISTERS
  --=============================================================================

  signal dbg_addr : std_logic_vector(5 downto 0);
  signal dbg_bw : std_logic;

  signal dbg_din_bw : std_logic;

  signal dbg_din : std_logic_vector(15 downto 0);
  signal dbg_wr : std_logic;
  signal dbg_rd : std_logic;

  --=============================================================================
  -- 1)  UART RECEIVE LINE SYNCHRONIZTION & FILTERING
  --=============================================================================

  -- Synchronize RXD input
  ------------------------
begin
  SYNC_DBG_UART_RXD_GENERATING_0 : if (SYNC_DBG_UART_RXD = '1') generate
    sync_cell_uart_rxd : omsp_sync_cell
    port map (
      data_out => uart_rxd_n,
      data_in => not dbg_uart_rxd,
      clk => dbg_clk,
      rst => dbg_rst
    );
    uart_rxd <= not uart_rxd_n;
  elsif (SYNC_DBG_UART_RXD = '0') generate
    uart_rxd <= dbg_uart_rxd;
  end generate;


  -- RXD input buffer
  -------------------
  processing_0 : process (dbg_clk, dbg_rst)
  begin
    if (dbg_rst) then
      rxd_buf <= X"3";
    elsif (rising_edge(dbg_clk)) then
      rxd_buf <= (rxd_buf(0) & uart_rxd);
    end if;
  end process;


  -- Majority decision
  --------------------

  rxd_maj_nxt <= (uart_rxd and rxd_buf(0)) or (uart_rxd and rxd_buf(1)) or (rxd_buf(0) and rxd_buf(1));

  processing_1 : process (dbg_clk, dbg_rst)
  begin
    if (dbg_rst) then
      rxd_maj <= '1';
    elsif (rising_edge(dbg_clk)) then
      rxd_maj <= rxd_maj_nxt;
    end if;
  end process;


  rxd_s <= rxd_maj;
  rxd_fe <= rxd_maj and not rxd_maj_nxt;
  rxd_re <= not rxd_maj and rxd_maj_nxt;
  rxd_edge <= rxd_maj xor rxd_maj_nxt;

  --=============================================================================
  -- 2)  UART STATE MACHINE
  --=============================================================================

  -- State transition
  processing_2 : process (uart_state, xfer_buf_nxt, mem_burst, mem_burst_wr, mem_burst_rd, mem_burst_end, mem_bw)
  begin
    case ((uart_state)) is
    when RX_SYNC =>
      uart_state_nxt <= RX_CMD;
    when RX_CMD =>
      uart_state_nxt <= RX_DATA2
      when mem_bw else RX_DATA1
      when mem_burst_wr else TX_DATA2
      when mem_bw else TX_DATA1
      when mem_burst_rd else RX_DATA2
      when xfer_buf_nxt(DBG_UART_BW) else RX_DATA1
      when xfer_buf_nxt(DBG_UART_WR) else TX_DATA2
      when xfer_buf_nxt(DBG_UART_BW) else TX_DATA1;
    when RX_DATA1 =>
      uart_state_nxt <= RX_DATA2;
    when RX_DATA2 =>
      uart_state_nxt <= RX_DATA2
      when mem_bw else RX_DATA1
      when (mem_burst and not mem_burst_end) else RX_CMD;
    when TX_DATA1 =>
      uart_state_nxt <= TX_DATA2;
    when TX_DATA2 =>
      uart_state_nxt <= TX_DATA2
      when mem_bw else TX_DATA1
      when (mem_burst and not mem_burst_end) else RX_CMD;
    -- pragma coverage off
    when others =>
      uart_state_nxt <= RX_CMD;
    end case;
  end process;
  -- pragma coverage on


  -- State machine
  processing_3 : process (dbg_clk, dbg_rst)
  begin
    if (dbg_rst) then
      uart_state <= RX_SYNC;
    elsif (rising_edge(dbg_clk)) then
      if (xfer_done or sync_done or mem_burst_wr or mem_burst_rd) then
        uart_state <= uart_state_nxt;
      end if;
    end if;
  end process;


  -- Utility signals
  cmd_valid <= (uart_state = RX_CMD) and xfer_done;
  rx_active <= (uart_state = RX_DATA1) or (uart_state = RX_DATA2) or (uart_state = RX_CMD);
  tx_active <= (uart_state = TX_DATA1) or (uart_state = TX_DATA2);

  --=============================================================================
  -- 3)  UART SYNCHRONIZATION
  --=============================================================================
  -- After DBG_RST, the host needs to fist send a synchronization character (0x80)
  -- If this feature doesn't work properly, it is possible to disable it by
  -- commenting the DBG_UART_AUTO_SYNC define in the openMSP430.inc file.

  processing_4 : process (dbg_clk, dbg_rst)
  begin
    if (dbg_rst) then
      sync_busy <= '0';
    elsif (rising_edge(dbg_clk)) then
      if ((uart_state = RX_SYNC) and rxd_fe) then
        sync_busy <= '1';
      elsif ((uart_state = RX_SYNC) and rxd_re) then
        sync_busy <= '0';
      end if;
    end if;
  end process;


  sync_done <= (uart_state = RX_SYNC) and rxd_re and sync_busy;

  DBG_UART_AUTO_SYNC_GENERATING_1 : if (DBG_UART_AUTO_SYNC = '1') generate
    processing_5 : process (dbg_clk, dbg_rst)
    begin
      if (dbg_rst) then
        sync_cnt <= (concatenate(DBG_UART_XFER_CNT_W, '1') & "000");
      elsif (rising_edge(dbg_clk)) then
        if (sync_busy or (not sync_busy and sync_cnt(2))) then
          sync_cnt <= sync_cnt+(concatenate(DBG_UART_XFER_CNT_W+2, '0') & '1');
        end if;
      end if;
    end process;


    bit_cnt_max <= sync_cnt(DBG_UART_XFER_CNT_W+2 downto 3);
  elsif (DBG_UART_AUTO_SYNC = '0') generate
    bit_cnt_max <= DBG_UART_CNT;
  end generate;


  --=============================================================================
  -- 4)  UART RECEIVE / TRANSMIT
  --=============================================================================

  -- Transfer counter
  -------------------
  txd_start <= dbg_rd_rdy or (xfer_done and (uart_state = TX_DATA1));
  rxd_start <= (xfer_bit = X"0") and rxd_fe and ((uart_state /= RX_SYNC));
  xfer_bit_inc <= (xfer_bit /= X"0") and (xfer_cnt = concatenate(DBG_UART_XFER_CNT_W, '0'));
  xfer_done <= (xfer_bit = X"a")
  when rx_active else (xfer_bit = X"b");

  processing_6 : process (dbg_clk, dbg_rst)
  begin
    if (dbg_rst) then
      xfer_bit <= X"0";
    elsif (rising_edge(dbg_clk)) then
      if (txd_start or rxd_start) then
        xfer_bit <= X"1";
      elsif (xfer_done) then
        xfer_bit <= X"0";
      elsif (xfer_bit_inc) then
        xfer_bit <= xfer_bit+X"1";
      end if;
    end if;
  end process;


  processing_7 : process (dbg_clk, dbg_rst)
  begin
    if (dbg_rst) then
      xfer_cnt <= concatenate(DBG_UART_XFER_CNT_W, '0');
    elsif (rising_edge(dbg_clk)) then
      if (rx_active and rxd_edge) then
        xfer_cnt <= ('0' & bit_cnt_max(DBG_UART_XFER_CNT_W-1 downto 1));
      elsif (txd_start or xfer_bit_inc) then
        xfer_cnt <= bit_cnt_max;
      elsif (or xfer_cnt) then
        xfer_cnt <= xfer_cnt+concatenate(DBG_UART_XFER_CNT_W, '1');
      end if;
    end if;
  end process;


  -- Receive/Transmit buffer
  --------------------------
  xfer_buf_nxt <= (rxd_s & xfer_buf(19 downto 1));

  processing_8 : process (dbg_clk, dbg_rst)
  begin
    if (dbg_rst) then
      xfer_buf <= X"00000";
    elsif (rising_edge(dbg_clk)) then
      if (dbg_rd_rdy) then
        xfer_buf <= ('1' & dbg_dout(15 downto 8) & "01" & dbg_dout(7 downto 0) & '0');
      elsif (xfer_bit_inc) then
        xfer_buf <= xfer_buf_nxt;
      end if;
    end if;
  end process;


  -- Generate TXD output
  ----------------------
  processing_9 : process (dbg_clk, dbg_rst)
  begin
    if (dbg_rst) then
      dbg_uart_txd <= '1';
    elsif (rising_edge(dbg_clk)) then
      if (xfer_bit_inc and tx_active) then
        dbg_uart_txd <= xfer_buf(0);
      end if;
    end if;
  end process;


  --=============================================================================
  -- 5) INTERFACE TO DEBUG REGISTERS
  --=============================================================================

  processing_10 : process (dbg_clk, dbg_rst)
  begin
    if (dbg_rst) then
      dbg_addr <= X"00";
    elsif (rising_edge(dbg_clk)) then
      if (cmd_valid) then
        dbg_addr <= xfer_buf_nxt(DBG_UART_ADDR);
      end if;
    end if;
  end process;


  processing_11 : process (dbg_clk, dbg_rst)
  begin
    if (dbg_rst) then
      dbg_bw <= '0';
    elsif (rising_edge(dbg_clk)) then
      if (cmd_valid) then
        dbg_bw <= xfer_buf_nxt(DBG_UART_BW);
      end if;
    end if;
  end process;


  dbg_din_bw <= mem_bw
  when mem_burst else dbg_bw;

  dbg_din <= (X"00" & xfer_buf_nxt(18 downto 11))
  when dbg_din_bw else (xfer_buf_nxt(18 downto 11) & xfer_buf_nxt(9 downto 2));
  dbg_wr <= (xfer_done and (uart_state = RX_DATA2));
  dbg_rd <= (xfer_done and (uart_state = TX_DATA2))
  when mem_burst else (cmd_valid and not xfer_buf_nxt(DBG_UART_WR)) or mem_burst_rd;
end RTL;
