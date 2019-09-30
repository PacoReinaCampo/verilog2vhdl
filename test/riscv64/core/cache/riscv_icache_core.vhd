-- Converted from core/cache/riscv_icache_core.sv
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
--              Core - Instruction Cache (Write Back)                         //
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

entity riscv_icache_core is
  port (




    rst_ni : in std_logic;
    clk_i : in std_logic;
    clr_i : in std_logic;  --clear any pending request

  --CPU side
    mem_vreq_i : in std_logic;
    mem_preq_i : in std_logic;
    mem_vadr_i : in std_logic_vector(XLEN-1 downto 0);
    mem_padr_i : in std_logic_vector(PLEN-1 downto 0);
    mem_size_i : in std_logic_vector(2 downto 0);
    mem_lock_i : in std_logic;
    mem_prot_i : in std_logic_vector(2 downto 0);
    mem_q_o : out std_logic_vector(XLEN-1 downto 0);
    mem_ack_o : out std_logic;
    mem_err_o : out std_logic;
    flush_i : in std_logic;
    flushrdy_i : in std_logic;

  --To BIU
    biu_stb_o : out std_logic;  --access request
    biu_stb_ack_i : in std_logic;  --access acknowledge
    biu_d_ack_i : in std_logic;  --BIU needs new data (biu_d_o)
    biu_adri_o : out std_logic_vector(PLEN-1 downto 0);  --access start address
    biu_adro_i : in std_logic_vector(PLEN-1 downto 0);
    biu_size_o : out std_logic_vector(2 downto 0);  --transfer size
    biu_type_o : out std_logic_vector(2 downto 0);  --burst type
    biu_lock_o : out std_logic;  --locked transfer
    biu_prot_o : out std_logic_vector(2 downto 0);  --protection bits
    biu_we_o : out std_logic;  --write enable
    biu_d_o : out std_logic_vector(XLEN-1 downto 0);  --write data
    biu_q_i : in std_logic_vector(XLEN-1 downto 0);  --read data
    biu_ack_i : in std_logic   --transfer acknowledge
    biu_err_i : in std_logic  --transfer error
  );
  constant XLEN : integer := 64;
  constant PLEN : integer := 64;
  constant ICACHE_SIZE : integer := 64;
  constant ICACHE_BLOCK_SIZE : integer := 64;
  constant ICACHE_WAYS : integer := 2;
  constant ICACHE_REPLACE_ALG : integer := 0;
  constant TECHNOLOGY : integer := "GENERIC";
end riscv_icache_core;

architecture RTL of riscv_icache_core is
  component riscv_ram_1rw
  generic (
    ? : std_logic_vector(? downto 0) := ?;
    ? : std_logic_vector(? downto 0) := ?;
    ? : std_logic_vector(? downto 0) := ?
  );
  port (
    rst_ni : std_logic_vector(? downto 0);
    clk_i : std_logic_vector(? downto 0);
    addr_i : std_logic_vector(? downto 0);
    we_i : std_logic_vector(? downto 0);
    be_i : std_logic_vector(? downto 0);
    din_i : std_logic_vector(? downto 0);
    dout_o : std_logic_vector(? downto 0)
  );
  end component;



  --////////////////////////////////////////////////////////////////
  --
  -- Constants
  --

  ------------------------------------------------------------------
  -- Cache
  ------------------------------------------------------------------
  constant PAGE_SIZE : integer := 4*1024;  --4KB pages
  constant MAX_IDX_BITS : integer := (null)(PAGE_SIZE)-(null)(ICACHE_BLOCK_SIZE);  --Maximum IDX_BITS

  constant SETS : integer := (ICACHE_SIZE*1024)/ICACHE_BLOCK_SIZE/ICACHE_WAYS;  --Number of sets TODO:SETS=1 doesn't work
  constant BLK_OFF_BITS : integer := (null)(ICACHE_BLOCK_SIZE);  --Number of BlockOffset bits
  constant IDX_BITS : integer := (null)(SETS);  --Number of Index-bits
  constant TAG_BITS : integer := XLEN-IDX_BITS-BLK_OFF_BITS;  --Number of TAG-bits
  constant BLK_BITS : integer := 8*ICACHE_BLOCK_SIZE;  --Total number of bits in a Block
  constant BURST_SIZE : integer := BLK_BITS/XLEN;  --Number of transfers to load 1 Block
  constant BURST_BITS : integer := (null)(BURST_SIZE);
  constant BURST_OFF : integer := XLEN/8;
  constant BURST_LSB : integer := (null)(BURST_OFF);

  --BLOCK decoding
  constant DAT_OFF_BITS : integer := (null)(BLK_BITS/XLEN);  --Offset in block
  constant PARCEL_OFF_BITS : integer := (null)(XLEN/PARCEL_SIZE);

  --////////////////////////////////////////////////////////////////
  --
  -- Functions
  --
  function size2be (
    size : std_logic_vector(2 downto 0);
    adr : std_logic_vector(XLEN-1 downto 0);

    signal adr_lsbs : std_logic_vector((null)(XLEN/8)-1 downto 0);

  ) return std_logic_vector is
    variable size2be_return : std_logic_vector (XLEN/8-1 downto 0);
  begin
    adr_lsbs <= adr((null)(XLEN/8)-1 downto 0);

    case ((size)) is
    when BYTE =>
      size2be_return <= X"1" sll adr_lsbs;
    when HWORD =>
      size2be_return <= X"3" sll adr_lsbs;
    when WORD =>
      size2be_return <= X"f" sll adr_lsbs;
    when DWORD =>
      size2be_return <= X"ff" sll adr_lsbs;
    when others =>
      null;
    end case;
    return size2be_return;
  end size2be;



  --////////////////////////////////////////////////////////////////
  --
  -- Constants
  --

  constant ARMED : integer := 0;
  constant FLUSH : integer := 1;
  constant WAIT4BIUCMD0 : integer := 2;
  constant RECOVER : integer := 4;

  constant IDLE : std_logic_vector(1 downto 0) := "00";
  constant WAIT4BIU : std_logic_vector(1 downto 0) := "01";
  constant BURST : std_logic_vector(1 downto 0) := "10";

  constant NOP : integer := 0;
  constant WRITE_WAY : integer := 1;
  constant READ_WAY : integer := 2;

  --////////////////////////////////////////////////////////////////
  --
  -- Variables
  --
  signal way : std_logic;
  constant n : integer;


  --Memory Interface State Machine Section
  signal mem_vreq_dly : std_logic;
  signal mem_preq_dly : std_logic;
  signal mem_vadr_dly : std_logic_vector(XLEN-1 downto 0);
  signal mem_padr_dly : std_logic_vector(PLEN-1 downto 0);
  signal mem_be : std_logic_vector(XLEN/8-1 downto 0);
  signal mem_be_dly : std_logic_vector(XLEN/8-1 downto 0);

  signal core_tag : std_logic_vector(TAG_BITS-1 downto 0);
  signal core_tag_hold : std_logic_vector(TAG_BITS-1 downto 0);

  signal hold_flush : std_logic;  --stretch flush_i until FSM is ready to serve

  signal memfsm_state : std_logic_vector(2 downto 0);

  --Cache Section
  signal tag_idx : std_logic_vector(IDX_BITS-1 downto 0);
  signal tag_idx_dly : std_logic_vector(IDX_BITS-1 downto 0);  --delayed version for writing valid/dirty
  signal tag_idx_hold : std_logic_vector(IDX_BITS-1 downto 0);  --stretched version for writing TAG during fill
  signal vadr_idx : std_logic_vector(IDX_BITS-1 downto 0);  --index bits extracted from vadr_i
  signal vadr_dly_idx : std_logic_vector(IDX_BITS-1 downto 0);  --index bits extracted from vadr_dly
  signal padr_idx : std_logic_vector(IDX_BITS-1 downto 0);
  signal padr_dly_idx : std_logic_vector(IDX_BITS-1 downto 0);

  signal tag_we : std_logic_vector(ICACHE_WAYS-1 downto 0);

  signal tag_in_valid : std_logic_vector(ICACHE_WAYS-1 downto 0);
  signal tag_in_tag : std_logic_vector(TAG_BITS-1 downto 0);

  signal tag_out_valid : std_logic_vector(ICACHE_WAYS-1 downto 0);
  signal tag_out_tag : std_logic_vector(TAG_BITS-1 downto 0);

  signal tag_byp_idx : std_logic_vector(IDX_BITS-1 downto 0);
  signal tag_byp_tag : std_logic_vector(TAG_BITS-1 downto 0);
  signal tag_valid : std_logic_vector(SETS-1 downto 0);

  signal dat_idx : std_logic_vector(IDX_BITS-1 downto 0);
  signal dat_idx_dly : std_logic_vector(IDX_BITS-1 downto 0);
  signal dat_we : std_logic_vector(ICACHE_WAYS-1 downto 0);
  signal dat_be : std_logic_vector(BLK_BITS/8-1 downto 0);
  signal dat_in : std_logic_vector(BLK_BITS-1 downto 0);
  signal dat_out : std_logic_vector(BLK_BITS-1 downto 0);

  signal way_q_mux : std_logic_vector(BLK_BITS-1 downto 0);
  signal way_hit : std_logic_vector(ICACHE_WAYS-1 downto 0);

  signal dat_offset : std_logic_vector(DAT_OFF_BITS-1 downto 0);
  signal parcel_offset : std_logic_vector(PARCEL_OFF_BITS downto 0);

  signal cache_hit : std_logic;
  signal cache_q : std_logic_vector(XLEN-1 downto 0);

  signal way_random : std_logic_vector(19 downto 0);
  signal fill_way_select : std_logic_vector(ICACHE_WAYS-1 downto 0);
  signal fill_way_select_hold : std_logic_vector(ICACHE_WAYS-1 downto 0);

  signal biu_adro_eq_cache_adr_dly : std_logic;
  signal flushing : std_logic;
  signal filling : std_logic;
  signal flush_idx : std_logic_vector(IDX_BITS-1 downto 0);

  --Bus Interface State Machine Section
  signal biufsm_state : std_logic_vector(1 downto 0);

  signal biucmd : std_logic_vector(1 downto 0);

  signal biufsm_ack : std_logic;
  signal biufsm_err : std_logic;
  signal biufsm_ack_write_way : std_logic;  --BIU FSM should generate biufsm_ack on WRITE_WAY
  signal biu_buffer : std_logic_vector(BLK_BITS-1 downto 0);
  signal biu_buffer_valid : std_logic_vector(BURST_SIZE-1 downto 0);
  signal in_biubuffer : std_logic;

  signal biu_adri_hold : std_logic_vector(PLEN-1 downto 0);
  signal biu_d_hold : std_logic_vector(XLEN-1 downto 0);

  signal burst_cnt : std_logic_vector(BURST_BITS-1 downto 0);

begin
  --////////////////////////////////////////////////////////////////
  --
  -- Module Body
  --

  ------------------------------------------------------------------
  -- Memory Interface State Machine
  ------------------------------------------------------------------

  --generate cache_* signals
  mem_be <= (null)(mem_size_i, mem_vadr_i);

  --generate delayed mem_* signals
  processing_0 : process (clk_i, rst_ni)
  begin
    if (not rst_ni) then
      mem_vreq_dly <= '0';
    elsif (rising_edge(clk_i)) then
      if (clr_i) then
        mem_vreq_dly <= '0';
      else
        mem_vreq_dly <= mem_vreq_i or (mem_vreq_dly and not mem_ack_o);
      end if;
    end if;
  end process;


  processing_1 : process (clk_i, rst_ni)
  begin
    if (not rst_ni) then
      mem_preq_dly <= '0';
    elsif (rising_edge(clk_i)) then
      if (clr_i) then
        mem_preq_dly <= '0';
      else
        mem_preq_dly <= (mem_preq_i or mem_preq_dly) and not mem_ack_o;
      end if;
    end if;
  end process;


  --register memory signals
  processing_2 : process (clk_i)
  begin
    if (rising_edge(clk_i)) then
      if (mem_vreq_i) then
        mem_vadr_dly <= mem_vadr_i;
        mem_be_dly <= mem_be;
      end if;
    end if;
  end process;


  processing_3 : process (clk_i)
  begin
    if (rising_edge(clk_i)) then
      if (mem_preq_i) then
        mem_padr_dly <= mem_padr_i;
      end if;
    end if;
  end process;


  --extract index bits from virtual address(es)
  vadr_idx <= mem_vadr_i(BLK_OFF_BITS+IDX_BITS);
  vadr_dly_idx <= mem_vadr_dly(BLK_OFF_BITS+IDX_BITS);
  padr_idx <= mem_padr_i(BLK_OFF_BITS+IDX_BITS);
  padr_dly_idx <= mem_padr_dly(BLK_OFF_BITS+IDX_BITS);

  --extract core_tag from physical address
  core_tag <= mem_padr_i(XLEN-1-TAG_BITS);

  --hold core_tag during filling. Prevents new mem_req (during fill) to mess up the 'tag' value
  processing_4 : process (clk_i)
  begin
    if (rising_edge(clk_i)) then
      if (not filling) then
        core_tag_hold <= core_tag;
      end if;
    end if;
  end process;


  --hold flush until ready to service it
  processing_5 : process (clk_i, rst_ni)
  begin
    if (not rst_ni) then
      hold_flush <= '0';
    elsif (rising_edge(clk_i)) then
      hold_flush <= not flushing and (flush_i or hold_flush);
    end if;
  end process;


  --State Machine
  processing_6 : process (clk_i, rst_ni)
  begin
    if (not rst_ni) then
      memfsm_state <= ARMED;
      flushing <= '0';
      filling <= '0';
      biucmd <= NOP;
    elsif (rising_edge(clk_i)) then
      case ((memfsm_state)) is
      when ARMED =>
        if (flush_i or hold_flush) then
          memfsm_state <= FLUSH;
          flushing <= '1';
        elsif (mem_vreq_dly and not cache_hit and (mem_preq_i or mem_preq_dly)) then      --it takes 1 cycle to read TAG
          --Load way
          memfsm_state <= WAIT4BIUCMD0;
          biucmd <= READ_WAY;
          filling <= '1';
        else
          biucmd <= NOP;
        end if;
      when FLUSH =>
        if (flushrdy_i) then
          memfsm_state <= RECOVER;          --allow to read new tag_idx
          flushing <= '0';
        end if;
      when WAIT4BIUCMD0 =>
        if (biufsm_err) then
          memfsm_state <= RECOVER
          when vadr_idx /= tag_idx_hold else ARMED;
          biucmd <= NOP;
          filling <= '0';
        elsif (biufsm_ack) then
          memfsm_state <= RECOVER
          when vadr_idx /= tag_idx_hold else ARMED;
          biucmd <= NOP;
          filling <= '0';
        end if;
      when RECOVER =>
      --Allow DATA memory read after writing/filling
        memfsm_state <= ARMED;
        biucmd <= NOP;
        filling <= '0';
      end case;
    end if;
  end process;


  --address check, used in a few places
  biu_adro_eq_cache_adr_dly <= (biu_adro_i(PLEN-1 downto BURST_LSB) = mem_padr_i(PLEN-1 downto BURST_LSB));

  --signal downstream that data is ready
  processing_7 : process
  begin
    case ((memfsm_state)) is
    when ARMED =>
      mem_ack_o <= mem_vreq_dly and (mem_preq_i or mem_preq_dly) and cache_hit;
    when WAIT4BIUCMD0 =>
      mem_ack_o <= mem_vreq_dly and (mem_preq_i or mem_preq_dly) and biu_ack_i and biu_adro_eq_cache_adr_dly;
    when others =>
      mem_ack_o <= '0';
    end case;
  end process;


  --signal downstream the BIU reported an error
  mem_err_o <= biu_err_i;

  --Assign mem_q
  --biu_q_i and cache_q are XLEN size. If PARCEL_SIZE is smaller, adjust
  parcel_offset <= mem_vadr_dly(1+PARCEL_OFF_BITS downto 1);  --[1 +: PARCEL_OFF_BITS] errors out

  processing_8 : process
  begin
    case ((memfsm_state)) is
    when WAIT4BIUCMD0 =>
      mem_q_o <= biu_q_i srl (parcel_offset*16);
    when others =>
      mem_q_o <= cache_q srl (parcel_offset*16);
    end case;
  end process;


  ------------------------------------------------------------------
  -- End Memory Interface State Machine
  ------------------------------------------------------------------

  ------------------------------------------------------------------
  -- TAG and Data memory
  ------------------------------------------------------------------

  --TAG
  for way in 0 to ICACHE_WAYS - 1 generate
    --TAG is stored in RAM
    tag_ram : riscv_ram_1rw
    generic map (
      ABITS, 
      DBITS, 
      TECHNOLOGY
    )
    port map (
      rst_ni => rst_ni,
      clk_i => clk_i,
      addr_i => tag_idx,
      we_i => tag_we(way),
      be_i => concatenate((TAG_BITS+7)/8, '1'),
      din_i => tag_in_tag(way),
      dout_o => tag_out_tag(way)
    );


    --tag-register for bypass (RAW hazard)
    processing_9 : process (clk_i)
    begin
      if (rising_edge(clk_i)) then
        if (tag_we(way)) then
          tag_byp_tag(way) <= tag_in_tag(way);
          tag_byp_idx(way) <= tag_idx;
        end if;
      end if;
    end process;


    --Valid is stored in DFF
    processing_10 : process (clk_i, rst_ni)
    begin
      if (not rst_ni) then
        tag_valid(way) <= X"0";
      elsif (rising_edge(clk_i)) then
        if (flush_i) then
          tag_valid(way) <= X"0";
        elsif (tag_we(way)) then
          tag_valid(way) <= tag_in_valid(way);
        end if;
      end if;
    end process;


    tag_out_valid(way) <= tag_valid(way)(tag_idx_dly);

    --compare way-tag to TAG;
    way_hit(way) <= tag_out_valid(way) and (core_tag = (tag_byp_tag(way)
    when tag_idx_dly = tag_byp_idx(way) else tag_out_tag(way)));
  end generate;


  -- Generate 'hit'
  cache_hit <= or way_hit;  -- & mem_vreq_dly;

  --DATA
  for way in 0 to ICACHE_WAYS - 1 generate
    data_ram : riscv_ram_1rw
    generic map (
      ABITS, 
      DBITS, 
      TECHNOLOGY
    )
    port map (
      rst_ni => rst_ni,
      clk_i => clk_i,
      addr_i => dat_idx,
      we_i => dat_we(way),
      be_i => dat_be,
      din_i => dat_in,
      dout_o => dat_out(way)
    );


    --assign way_q; Build MUX (AND/OR) structure
    if (way = 0) generate
      way_q_mux(way) <= dat_out(way) and concatenate(BLK_BITS, way_hit(way));
    else generate
      way_q_mux(way) <= (dat_out(way) and concatenate(BLK_BITS, way_hit(way))) or way_q_mux(way-1);
    end generate;
  end generate;


  --get requested data (XLEN-size) from way_q_mux(BLK_BITS-size)
  in_biubuffer <= (biu_adri_hold(PLEN-1 downto BLK_OFF_BITS) = mem_padr_dly(PLEN-1 downto BLK_OFF_BITS)) and (biu_buffer_valid srl dat_offset)
  when mem_preq_dly else (biu_adri_hold(PLEN-1 downto BLK_OFF_BITS) = mem_padr_i(PLEN-1 downto BLK_OFF_BITS)) and (biu_buffer_valid srl dat_offset);

  cache_q <= (biu_buffer
  when in_biubuffer else way_q_mux(ICACHE_WAYS-1)) srl (dat_offset*XLEN);

  ------------------------------------------------------------------
  -- END TAG and Data memory
  ------------------------------------------------------------------

  ------------------------------------------------------------------
  -- TAG and Data memory control signals
  ------------------------------------------------------------------

  --Random generator for RANDOM replacement algorithm
  processing_11 : process (clk_i, rst_ni)
  begin
    if (not rst_ni) then
      way_random <= X"0";
    elsif (rising_edge(clk_i)) then
      if (not filling) then
        way_random <= (way_random & way_random(19) xnor way_random(16));
      end if;
    end if;
  end process;


  --select which way to fill
  fill_way_select <= 1
  when (ICACHE_WAYS <= 1) else 1 sll way_random(ICACHE_WAYS-1 downto 0);

  --FILL / WRITE_WAYS use fill_way_select 1 cycle later
  processing_12 : process (clk_i)
  begin
    if (rising_edge(clk_i)) then
      case ((memfsm_state)) is
      when ARMED =>
        fill_way_select_hold <= fill_way_select;
      when others =>
        null;
      end case;
    end if;
  end process;


  --TAG Index
  processing_13 : process
  begin
    case ((memfsm_state)) is
    --TAG write
    when WAIT4BIUCMD0 =>
      tag_idx <= tag_idx_hold;
    --TAG read
    when FLUSH =>
      tag_idx <= flush_idx;
    when RECOVER =>
    --pending access
    --new access
      tag_idx <= vadr_dly_idx
      when mem_vreq_dly else vadr_idx;
    when others =>
    --current access
      tag_idx <= vadr_idx;
    end case;
  end process;


  --registered version, for tag_valid
  processing_14 : process (clk_i)
  begin
    if (rising_edge(clk_i)) then
      tag_idx_dly <= tag_idx;
    end if;
  end process;


  --hold tag-idx; prevent new mem_vreq_i from messing up tag during filling
  processing_15 : process (clk_i)
  begin
    if (rising_edge(clk_i)) then
      case ((memfsm_state)) is
      when ARMED =>
        if (mem_vreq_dly and not cache_hit) then
          tag_idx_hold <= vadr_dly_idx;
        end if;
      when RECOVER =>
      --pending access
      --current access
        tag_idx_hold <= vadr_dly_idx
        when mem_vreq_dly else vadr_idx;
      when others =>
        null;
      end case;
    end if;
  end process;


  --TAG Write Enable
  --Update tag during flushing    (clear valid bits)
  for way in 0 to ICACHE_WAYS - 1 generate
    processing_16 : process
    begin
      case ((memfsm_state)) is
      when others =>
        tag_we(way) <= filling and fill_way_select_hold(way) and biufsm_ack;
      end case;
    end process;
  end generate;


  --TAG Write Data
  for way in 0 to ICACHE_WAYS - 1 generate
    --clear valid tag during flushing and cache-coherency checks
    tag_in_valid(way) <= not flushing;

    tag_in_tag(way) <= core_tag_hold;
  end generate;


  --Shift amount for data
  dat_offset <= mem_vadr_dly(BLK_OFF_BITS-1-DAT_OFF_BITS);

  --DAT Byte Enable
  dat_be <= concatenate(BLK_BITS/8, '1');

  --DAT Index
  processing_17 : process
  begin
    case ((memfsm_state)) is
    when ARMED =>
    --read access
      dat_idx <= vadr_idx;
    when RECOVER =>
    --read pending cycle
    --read new access
      dat_idx <= vadr_dly_idx
      when mem_vreq_dly else vadr_idx;
    when others =>
      dat_idx <= tag_idx_hold;
    end case;
  end process;


  --delayed dat_idx
  processing_18 : process (clk_i)
  begin
    if (rising_edge(clk_i)) then
      dat_idx_dly <= dat_idx;
    end if;
  end process;


  --DAT Write Enable
  for way in 0 to ICACHE_WAYS - 1 generate
    processing_19 : process
    begin
      case ((memfsm_state)) is
      when WAIT4BIUCMD0 =>
      --write BIU data
        dat_we(way) <= fill_way_select_hold(way) and biufsm_ack;
      when others =>
        dat_we(way) <= '0';
      end case;
    end process;
  end generate;


  --DAT Write Data
  processing_20 : process
  begin
    dat_in <= biu_buffer;    --dat_in = biu_buffer
    dat_in(biu_adro_i(BLK_OFF_BITS-1-DAT_OFF_BITS)*XLEN+XLEN) <= biu_q_i;    --except for last transaction
  end process;


  ------------------------------------------------------------------
  -- TAG and Data memory control signals
  ------------------------------------------------------------------

  ------------------------------------------------------------------
  -- Bus Interface State Machine
  ------------------------------------------------------------------
  biu_lock_o <= '0';
  biu_prot_o <= (mem_prot_i or PROT_CACHEABLE);

  processing_21 : process (clk_i, rst_ni)
  begin
    if (not rst_ni) then
      biufsm_state <= IDLE;
    elsif (rising_edge(clk_i)) then
      case ((biufsm_state)) is
      when IDLE =>
        case ((biucmd)) is
        when NOP =>
        --do nothing

          null;
        when READ_WAY =>
        --read a way from main memory
          if (biu_stb_ack_i) then
            biufsm_state <= BURST;
          else          --BIU is not ready to start a new transfer
            biufsm_state <= WAIT4BIU;
          end if;


        when WRITE_WAY =>
        --write way back to main memory
          if (biu_stb_ack_i) then
            biufsm_state <= BURST;
          else          --BIU is not ready to start a new transfer
            biufsm_state <= WAIT4BIU;
          end if;
        end case;


      when WAIT4BIU =>
        if (biu_stb_ack_i) then
          --BIU acknowledged burst transfer
          biufsm_state <= BURST;
        end if;


      when BURST =>
        if (biu_err_i or (nor burst_cnt and biu_ack_i)) then
          --write complete
          biufsm_state <= IDLE;          --TODO: detect if another BURST request is pending, skip IDLE
        end if;
      end case;
    end if;
  end process;


  --write data
  processing_22 : process (clk_i)
  begin
    if (rising_edge(clk_i)) then
      case ((biufsm_state)) is
      when IDLE =>
        biu_buffer <= X"0";
        biu_buffer_valid <= X"0";


      when BURST =>
      --latch incoming data when transfer-acknowledged
        if (biu_ack_i) then
          biu_buffer(biu_adro_i(BLK_OFF_BITS-1-DAT_OFF_BITS)*XLEN+XLEN) <= biu_q_i;
          biu_buffer_valid(biu_adro_i(BLK_OFF_BITS-1-DAT_OFF_BITS)) <= '1';
        end if;
      when others =>
        null;
      end case;
    end if;
  end process;


  --acknowledge burst to memfsm
  processing_23 : process
  begin
    case ((biufsm_state)) is
    when BURST =>
      biufsm_ack <= (nor burst_cnt and biu_ack_i) or biu_err_i;
    when others =>
      biufsm_ack <= '0';
    end case;
  end process;


  processing_24 : process (clk_i)
  begin
    if (rising_edge(clk_i)) then
      case ((biufsm_state)) is
      when IDLE =>
        case ((biucmd)) is
        when READ_WAY =>
          burst_cnt <= concatenate(BURST_BITS, '1');
        when WRITE_WAY =>
          burst_cnt <= concatenate(BURST_BITS, '1');
        end case;
      when BURST =>
        if (biu_ack_i) then
          burst_cnt <= burst_cnt-1;
        end if;
      end case;
    end if;
  end process;


  biufsm_err <= biu_err_i;

  --output BIU signals asynchronously for speed reasons. BIU will synchronize ...
  biu_d_o <= X"0";
  biu_we_o <= '0';

  processing_25 : process
  begin
    case ((biufsm_state)) is
    when IDLE =>
      case ((biucmd)) is
      when NOP =>
        biu_stb_o <= '0';
        biu_adri_o <= X"x";


      when READ_WAY =>
        biu_stb_o <= '1';
        biu_adri_o <= (mem_padr_dly(PLEN-1 downto BURST_LSB) & concatenate(BURST_LSB, '0'));
      end case;
    when WAIT4BIU =>
    --stretch biu_*_o signals until BIU acknowledges strobe
      biu_stb_o <= '1';
      biu_adri_o <= biu_adri_hold;
    when BURST =>
      biu_stb_o <= '0';
      biu_adri_o <= X"x";      --don't care
    when others =>
      biu_stb_o <= '0';
      biu_adri_o <= X"x";      --don't care
    end case;
  end process;


  --store biu_we/adri/d used when stretching biu_stb
  processing_26 : process (clk_i)
  begin
    if (rising_edge(clk_i)) then
      if (biufsm_state = IDLE) then
        biu_adri_hold <= biu_adri_o;
        biu_d_hold <= biu_d_o;
      end if;
    end if;
  end process;


  --transfer size
  biu_size_o <= DWORD
  when XLEN = 64 else WORD;

  --burst length
  biu_type_o <= WRAP16
  when BURST_SIZE = 16 else WRAP8
  when BURST_SIZE = 8 else WRAP4;
end RTL;
