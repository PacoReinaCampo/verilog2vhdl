-- Converted from core/cache/riscv_noicache_core.sv
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
--              Core - No-Instruction Cache Core Logic                        //
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

entity riscv_noicache_core is
  port (
    rstn : in std_logic;
    clk : in std_logic;

  --CPU side
    if_stall_nxt_pc : out std_logic;
    if_stall : in std_logic;
    if_flush : in std_logic;
    if_nxt_pc : in std_logic_vector(XLEN-1 downto 0);
    if_parcel_pc : out std_logic_vector(XLEN-1 downto 0);
    if_parcel : out std_logic_vector(PARCEL_SIZE-1 downto 0);
    if_parcel_valid : out std_logic;
    if_parcel_misaligned : out std_logic;
    bu_cacheflush : in std_logic;
    dcflush_rdy : in std_logic;
    st_prv : in std_logic_vector(1 downto 0);

  --To BIU
    biu_stb : out std_logic;
    biu_stb_ack : in std_logic;
    biu_adri : out std_logic_vector(PLEN-1 downto 0);
    biu_adro : in std_logic_vector(PLEN-1 downto 0);
    biu_size : out std_logic_vector(2 downto 0);  --transfer size
    biu_type : out std_logic_vector(2 downto 0);  --burst type -AHB style
    biu_lock : out std_logic;
    biu_we : out std_logic;
    biu_di : out std_logic_vector(XLEN-1 downto 0);
    biu_do : in std_logic_vector(XLEN-1 downto 0);
    biu_ack : in std_logic;  --data acknowledge, 1 per data
    biu_err : in std_logic;  --data error

    biu_is_cacheable : out std_logic;
    biu_is_instruction : out std_logic 
    biu_prv : out std_logic_vector(1 downto 0)
  );
  constant XLEN : integer := 64;
  constant PLEN : integer := 64;
  constant PARCEL_SIZE : integer := 64;
end riscv_noicache_core;

architecture RTL of riscv_noicache_core is


  --////////////////////////////////////////////////////////////////
  --
  -- Variables
  --
  signal is_cacheable : std_logic;

  signal biu_stb_cnt : std_logic_vector(1 downto 0);

  signal biu_fifo_valid : std_logic_vector(2 downto 0);
  signal biu_fifo_dat : array (3) of std_logic_vector(XLEN-1 downto 0);
  signal biu_fifo_adr : array (3) of std_logic_vector(PLEN-1 downto 0);

  signal if_flush_dly : std_logic;

begin
  --////////////////////////////////////////////////////////////////
  --
  -- Module Body
  --

  --Is this a cacheable region?
  --MSB=1 non-cacheable (IO region)
  --MSB=0 cacheabel (instruction/data region)
  is_cacheable <= not if_nxt_pc(PLEN-1);

  --For now don't support 16bit accesses
  if_parcel_misaligned <= or if_nxt_pc(1 downto 0);  --send out together with instruction

  --delay IF-flush
  processing_0 : process (clk, rstn)
  begin
    if (not rstn) then
      if_flush_dly <= '0';
    elsif (rising_edge(clk)) then
      if_flush_dly <= if_flush;
    end if;
  end process;


  -- To CPU
  if_stall_nxt_pc <= not dcflush_rdy or not biu_stb_ack or biu_fifo_valid(1);
  if_parcel_valid <= dcflush_rdy and not (if_flush or if_flush_dly) and not if_stall and biu_fifo_valid(0);
  if_parcel_pc <= (concatenate(XLEN-PLEN, '0') & biu_fifo_adr(0));
  if_parcel <= biu_fifo_dat(0)(if_parcel_pc((null)(XLEN/32)+1 downto 1)*16+PARCEL_SIZE);

  --External Interface
  biu_stb <= dcflush_rdy and not if_flush and not if_stall and not biu_fifo_valid(1);  --TODO when is ~biu_fifo[1] required?
  biu_adri <= if_nxt_pc(PLEN-1 downto 0);
  biu_size <= DWORD
  when XLEN = 64 else WORD;
  biu_lock <= '0';
  biu_we <= '0';  --no writes
  biu_di <= X"0";
  biu_type <= SINGLE;  --single access

  --Instruction cache..
  biu_is_instruction <= '1';
  biu_is_cacheable <= is_cacheable;
  biu_prv <= st_prv;

  --FIFO
  processing_1 : process (clk, rstn)
  begin
    if (not rstn) then
      biu_stb_cnt <= X"0";
    elsif (rising_edge(clk)) then
      if (if_flush) then
        biu_stb_cnt <= X"0";
      elsif (biu_stb_ack) then
        biu_stb_cnt <= ('1' & biu_stb_cnt(1));
      end if;
    end if;
  end process;


  --valid bits
  processing_2 : process (clk, rstn)
  begin
    if (not rstn) then
      biu_fifo_valid(0) <= '0';
      biu_fifo_valid(1) <= '0';
      biu_fifo_valid(2) <= '0';
    elsif (rising_edge(clk)) then
      if (not biu_stb_cnt(0)) then
        biu_fifo_valid(0) <= '0';
        biu_fifo_valid(1) <= '0';
        biu_fifo_valid(2) <= '0';
      else
        case (((biu_ack & if_parcel_valid))) is
        when "00" =>
        --no action
          null;
        when "10" =>
        --FIFO write
          case (((biu_fifo_valid(1) & biu_fifo_valid(0)))) is
          when "11" =>
          --entry 0,1 full. Fill entry2
            biu_fifo_valid(2) <= '1';
          when "01" =>
          --entry 0 full. Fill entry1, clear entry2
            biu_fifo_valid(1) <= '1';
            biu_fifo_valid(2) <= '0';
          when others =>
          --Fill entry0, clear entry1,2
            biu_fifo_valid(0) <= '1';
            biu_fifo_valid(1) <= '0';
            biu_fifo_valid(2) <= '0';
          end case;
        when "01" =>
        --FIFO read
          biu_fifo_valid(0) <= biu_fifo_valid(1);
          biu_fifo_valid(1) <= biu_fifo_valid(2);
          biu_fifo_valid(2) <= '0';
        when "11" =>
        --FIFO read/write, no change
          null;
        end case;
      end if;
    end if;
  end process;


  --Address & Data
  processing_3 : process (clk)
  begin
    if (rising_edge(clk)) then
      case (((biu_ack & if_parcel_valid))) is
      when "00" =>
        null;
      when "10" =>
        case (((biu_fifo_valid(1) & biu_fifo_valid(0)))) is
        when "11" =>
        --fill entry2
          biu_fifo_dat(2) <= biu_do;
          biu_fifo_adr(2) <= biu_adro;
        when "01" =>
        --fill entry1
          biu_fifo_dat(1) <= biu_do;
          biu_fifo_adr(1) <= biu_adro;
        when others =>
        --fill entry0
          biu_fifo_dat(0) <= biu_do;
          biu_fifo_adr(0) <= biu_adro;
        end case;
      when "01" =>
        biu_fifo_dat(0) <= biu_fifo_dat(1);
        biu_fifo_adr(0) <= biu_fifo_adr(1);
        biu_fifo_dat(1) <= biu_fifo_dat(2);
        biu_fifo_adr(1) <= biu_fifo_adr(2);
        biu_fifo_dat(2) <= X"x";
        biu_fifo_adr(2) <= X"x";
      when "11" =>
        case (((biu_fifo_valid(2) & biu_fifo_valid(1) & biu_fifo_valid(0)))) is
        when "1??" =>
        --fill entry2
          biu_fifo_dat(2) <= biu_do;
          biu_fifo_adr(2) <= biu_adro;

          --push other entries
          biu_fifo_dat(0) <= biu_fifo_dat(1);
          biu_fifo_adr(0) <= biu_fifo_adr(1);
          biu_fifo_dat(1) <= biu_fifo_dat(2);
          biu_fifo_adr(1) <= biu_fifo_adr(2);
        when "01?" =>
        --fill entry1
          biu_fifo_dat(1) <= biu_do;
          biu_fifo_adr(1) <= biu_adro;

          --push entry0
          biu_fifo_dat(0) <= biu_fifo_dat(1);
          biu_fifo_adr(0) <= biu_fifo_adr(1);

          --don't care
          biu_fifo_dat(2) <= X"x";
          biu_fifo_adr(2) <= X"x";
        when others =>
        --fill entry0
          biu_fifo_dat(0) <= biu_do;
          biu_fifo_adr(0) <= biu_adro;

          --don't care
          biu_fifo_dat(1) <= X"x";
          biu_fifo_adr(1) <= X"x";
          biu_fifo_dat(2) <= X"x";
          biu_fifo_adr(2) <= X"x";
        end case;
      end case;
    end if;
  end process;
end RTL;
