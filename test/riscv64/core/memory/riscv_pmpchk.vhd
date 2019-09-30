-- Converted from core/memory/riscv_pmpchk.sv
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
--              Core - Physical Memory Protection Checker                     //
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

entity riscv_pmpchk is
  port (
  --From State
    st_pmpcfg_i : in std_logic_vector(7 downto 0);
    st_pmpaddr_i : in std_logic_vector(XLEN-1 downto 0);

    st_prv_i : in std_logic_vector(1 downto 0);

  --Memory Access
    instruction_i : in std_logic;  --This is an instruction access
    req_i : in std_logic;  --Memory access requested
    adr_i : in std_logic_vector(PLEN-1 downto 0);  --Physical Memory address (i.e. after translation)
    size_i : in std_logic_vector(2 downto 0);  --Transfer size
    we_i : in std_logic   --Read/Write enable

  --Output
    exception_o : out std_logic
  );
  constant XLEN : integer := 64;
  constant PLEN : integer := 64;
  constant PMP_CNT : integer := 16;
end riscv_pmpchk;

architecture RTL of riscv_pmpchk is


  --////////////////////////////////////////////////////////////////
  --
  -- Functions
  --

  --convert transfer size in number of bytes in transfer
  function size2bytes (
  ) return std_logic_vector is
    variable size2bytes_return : std_logic_vector (      size : std_logic_vector(2 downto 0)

);
  begin
    case ((size)) is
    when BYTE =>
      size2bytes_return <= 1;
    when HWORD =>
      size2bytes_return <= 2;
    when WORD =>
      size2bytes_return <= 4;
    when DWORD =>
      size2bytes_return <= 8;
    when QWORD =>
      size2bytes_return <= 16;
    when others =>
      size2bytes_return <= 0-1;
    end case;
    return size2bytes_return;
  end size2bytes;

  --$error ("Illegal biu_size_t");


  --Lower and Upper bounds for NA4/NAPOT
  function napot_lb (
    na4 : std_logic;  --special case na4
    pmaddr : std_logic_vector(PLEN-1 downto 2);

    constant n, i : integer;
    signal true : std_logic;
    signal mask : std_logic_vector(PLEN-1 downto 2);

  ) return std_logic_vector is
    variable napot_lb_return : std_logic_vector (PLEN-1 downto 2);
  begin
    --find 'n' boundary = 2^(n+2) bytes
    n <= 0;
    if (not na4) then
      true <= '1';
      for i in 0 to (null)(pmaddr) - 1 loop
        if (true) then
          if (pmaddr(i+2)) then
            n <= n+1;
          else
            true <= '0';
          end if;
        end if;
      end loop;
      n <= n+1;
    end if;


    --create mask
    mask <= concatenate((null)(mask), '1') sll n;

    --lower bound address
    napot_lb_return <= pmaddr and mask;
    return napot_lb_return;
  end napot_lb;



  function napot_ub (
    na4 : std_logic;  --special case na4
    pmaddr : std_logic_vector(PLEN-1 downto 2);

    constant n, i : integer;
    signal true : std_logic;
    signal mask : std_logic_vector(PLEN-1 downto 2);
    signal incr : std_logic_vector(PLEN-1 downto 2);

  ) return std_logic_vector is
    variable napot_ub_return : std_logic_vector (PLEN-1 downto 2);
  begin
    --find 'n' boundary = 2^(n+2) bytes
    n <= 0;
    if (not na4) then
      true <= '1';
      for i in 0 to (null)(pmaddr) - 1 loop
        if (true) then
          if (pmaddr(i+2)) then
            n <= n+1;
          else
            true <= '0';
          end if;
        end if;
      end loop;
      n <= n+1;
    end if;


    --create mask and increment
    mask <= concatenate((null)(mask), '1') sll n;
    incr <= X"1" sll n;

    --upper bound address
    napot_ub_return <= (pmaddr+incr) and mask;
    return napot_ub_return;
  end napot_ub;



  --Is ANY byte of 'access' in pma range?
  function match_any (
    access_lb : std_logic_vector(PLEN-1 downto 2);
    access_ub : std_logic_vector(PLEN-1 downto 2);
    pma_lb : std_logic_vector(PLEN-1 downto 2);
    pma_ub : std_logic_vector(PLEN-1 downto 2)

  ) return std_logic
    variable match_any_return : std_logic;
  begin
    -- Check if ANY byte of the access lies within the PMA range
--     *   pma_lb <= range < pma_ub
--     * 
--     *   match_none = (access_lb >= pma_ub) OR (access_ub < pma_lb)  (1)
--     *   match_any  = !match_none                                    (2)
--     */



    --Are ALL bytes of 'access' in PMA range?
    function match_all (
      access_lb : std_logic_vector(PLEN-1 downto 2);
      access_ub : std_logic_vector(PLEN-1 downto 2);
      pma_lb : std_logic_vector(PLEN-1 downto 2);
      pma_ub : std_logic_vector(PLEN-1 downto 2)

    ) return std_logic
      variable match_all_return : std_logic;
    begin


      --get highest priority (==lowest number) PMP that matches
      function highest_priority_match (
      ) return std_logic_vector is
        variable highest_priority_match_return : std_logic_vector (          m : std_logic_vector(PMP_CNT-1 downto 0);

          constant n : integer;
);
      begin


        highest_priority_match_return <= 0;        --default value

        for n in PMP_CNT-1 downto 0 loop
          if (m(n)) then
            highest_priority_match_return <= n;
          end if;
        end loop;
        return highest_priority_match_return;
      end highest_priority_match;



      --////////////////////////////////////////////////////////////////
      --
      -- Variables
      --
      signal i : std_logic;

      signal access_ub : std_logic_vector(PLEN-1 downto 0);
      signal access_lb : std_logic_vector(PLEN-1 downto 0);
      signal pmp_ub : std_logic_vector(PLEN-1 downto 2);
      signal pmp_lb : std_logic_vector(PLEN-1 downto 2);
      signal pmp_match : std_logic_vector(PMP_CNT-1 downto 0);
      signal pmp_match_all : std_logic_vector(PMP_CNT-1 downto 0);
      signal matched_pmp : std_logic;
      signal matched_pmpcfg : std_logic_vector(7 downto 0);

    function highest_priority_match (
    ) return std_logic_vector is
      variable highest_priority_match_return : std_logic_vector (        m : std_logic_vector(PMP_CNT-1 downto 0);
        constant n : integer;
);
    begin
      highest_priority_match_return <= 0;
      for n in PMP_CNT-1 downto 0 loop
        if (m(n)) then
          highest_priority_match_return <= n;
        end if;
      end loop;
      return highest_priority_match_return;
    end highest_priority_match;

    signal i : std_logic;
    signal access_ub : std_logic_vector(PLEN-1 downto 0);
    signal access_lb : std_logic_vector(PLEN-1 downto 0);
    signal pmp_ub : std_logic_vector(PLEN-1 downto 2);
    signal pmp_lb : std_logic_vector(PLEN-1 downto 2);
    signal pmp_match : std_logic_vector(PMP_CNT-1 downto 0);
    signal pmp_match_all : std_logic_vector(PMP_CNT-1 downto 0);
    signal matched_pmp : std_logic;
    signal matched_pmpcfg : std_logic_vector(7 downto 0);
  function match_all (
    access_lb : std_logic_vector(PLEN-1 downto 2);
    access_ub : std_logic_vector(PLEN-1 downto 2);
    pma_lb : std_logic_vector(PLEN-1 downto 2);
    pma_ub : std_logic_vector(PLEN-1 downto 2)
  ) return std_logic
    variable match_all_return : std_logic;
  begin
    function highest_priority_match (
    ) return std_logic_vector is
      variable highest_priority_match_return : std_logic_vector (        m : std_logic_vector(PMP_CNT-1 downto 0);
        constant n : integer;
);
    begin
      highest_priority_match_return <= 0;
      for n in PMP_CNT-1 downto 0 loop
        if (m(n)) then
          highest_priority_match_return <= n;
        end if;
      end loop;
      return highest_priority_match_return;
    end highest_priority_match;

    signal i : std_logic;
    signal access_ub : std_logic_vector(PLEN-1 downto 0);
    signal access_lb : std_logic_vector(PLEN-1 downto 0);
    signal pmp_ub : std_logic_vector(PLEN-1 downto 2);
    signal pmp_lb : std_logic_vector(PLEN-1 downto 2);
    signal pmp_match : std_logic_vector(PMP_CNT-1 downto 0);
    signal pmp_match_all : std_logic_vector(PMP_CNT-1 downto 0);
    signal matched_pmp : std_logic;
    signal matched_pmpcfg : std_logic_vector(7 downto 0);
  function highest_priority_match (
  ) return std_logic_vector is
    variable highest_priority_match_return : std_logic_vector (      m : std_logic_vector(PMP_CNT-1 downto 0);
      constant n : integer;
);
  begin
    highest_priority_match_return <= 0;
    for n in PMP_CNT-1 downto 0 loop
      if (m(n)) then
        highest_priority_match_return <= n;
      end if;
    end loop;
    return highest_priority_match_return;
  end highest_priority_match;

  signal i : std_logic;
  signal access_ub : std_logic_vector(PLEN-1 downto 0);
  signal access_lb : std_logic_vector(PLEN-1 downto 0);
  signal pmp_ub : std_logic_vector(PLEN-1 downto 2);
  signal pmp_lb : std_logic_vector(PLEN-1 downto 2);
  signal pmp_match : std_logic_vector(PMP_CNT-1 downto 0);
  signal pmp_match_all : std_logic_vector(PMP_CNT-1 downto 0);
  signal matched_pmp : std_logic;
  signal matched_pmpcfg : std_logic_vector(7 downto 0);
begin
      --////////////////////////////////////////////////////////////////
      --
      -- Module Body
      --

      --
--   * Address Range Matching
--   * Access Exception
--   * Cacheable
--   */

      access_lb <= adr_i;
      access_ub <= adr_i+(null)(size_i)-1;

      for i in 0 to PMP_CNT - 1 generate
        --lower bounds
        processing_0 : process
        begin
          case ((st_pmpcfg_i(i)(4 downto 3))) is
          when TOR =>
            pmp_lb(i) <= 0
            when (i = 0) else pmp_ub(i)
            when st_pmpcfg_i(i)(4 downto 3) /= TOR else st_pmpaddr_i(i)(PLEN-3 downto 0);
          when NA4 =>
            pmp_lb(i) <= (null)('1', st_pmpaddr_i(i));
          when NAPOT =>
            pmp_lb(i) <= (null)('0', st_pmpaddr_i(i));
          when others =>
            pmp_lb(i) <= X"x";
          end case;
        end process;


        --upper bounds
        processing_1 : process
        begin
          case ((st_pmpcfg_i(i)(4 downto 3))) is
          when TOR =>
            pmp_ub(i) <= st_pmpaddr_i(i)(PLEN-3 downto 0);
          when NA4 =>
            pmp_ub(i) <= (null)('1', st_pmpaddr_i(i));
          when NAPOT =>
            pmp_ub(i) <= (null)('0', st_pmpaddr_i(i));
          when others =>
            pmp_ub(i) <= X"x";
          end case;
        end process;


        --match-any
        pmp_match(i) <= (null)(access_lb(PLEN-1 downto 2), access_ub(PLEN-1 downto 2), pmp_lb(i), pmp_ub(i)) and (st_pmpcfg_i(i)(4 downto 3) /= OFF);

        pmp_match_all(i) <= (null)(access_lb(PLEN-1 downto 2), access_ub(PLEN-1 downto 2), pmp_lb(i), pmp_ub(i));
      end generate;


      matched_pmp <= (null)(pmp_match);
      matched_pmpcfg <= st_pmpcfg_i(matched_pmp);

      -- Access FAIL when:
--   * 1. some bytes matched highest priority PMP, but not the entire transfer range OR
--   * 2. pmpcfg.l is set AND privilegel level is S or U AND pmpcfg.rwx tests fail OR
--   * 3. privilegel level is S or U AND no PMPs matched AND PMPs are implemented
--   */

      --Prv.Lvl != M-Mode, no PMP matched, but PMPs implemented -> FAIL
      --pmpcfg.l set or privilege level != M-mode
      -- read-access while not allowed          -> FAIL
      -- write-access while not allowed         -> FAIL
      -- instruction read, but not instruction  -> FAIL
      exception_o <= req_i and ((st_prv_i /= PRV_M) and (PMP_CNT > 0)
      when nor pmp_match else not pmp_match_all(matched_pmp) or (((st_prv_i /= PRV_M) or matched_pmpcfg(7)) and ((not matched_pmpcfg(0) and not we_i) or (not matched_pmpcfg(1) and we_i) or (not matched_pmpcfg(2) and instruction_i))));
      return match_all_return;
    end match_all;

    access_lb <= adr_i;
    access_ub <= adr_i+(null)(size_i)-1;
    for i in 0 to PMP_CNT - 1 generate
      processing_2 : process
      begin
        case ((st_pmpcfg_i(i)(4 downto 3))) is
        when TOR =>
          pmp_lb(i) <= 0
          when (i = 0) else pmp_ub(i)
          when st_pmpcfg_i(i)(4 downto 3) /= TOR else st_pmpaddr_i(i)(PLEN-3 downto 0);
        when NA4 =>
          pmp_lb(i) <= (null)('1', st_pmpaddr_i(i));
        when NAPOT =>
          pmp_lb(i) <= (null)('0', st_pmpaddr_i(i));
        when others =>
          pmp_lb(i) <= X"x";
        end case;
      end process;
      processing_3 : process
      begin
        case ((st_pmpcfg_i(i)(4 downto 3))) is
        when TOR =>
          pmp_ub(i) <= st_pmpaddr_i(i)(PLEN-3 downto 0);
        when NA4 =>
          pmp_ub(i) <= (null)('1', st_pmpaddr_i(i));
        when NAPOT =>
          pmp_ub(i) <= (null)('0', st_pmpaddr_i(i));
        when others =>
          pmp_ub(i) <= X"x";
        end case;
      end process;
      pmp_match(i) <= (null)(access_lb(PLEN-1 downto 2), access_ub(PLEN-1 downto 2), pmp_lb(i), pmp_ub(i)) and (st_pmpcfg_i(i)(4 downto 3) /= OFF);
      pmp_match_all(i) <= (null)(access_lb(PLEN-1 downto 2), access_ub(PLEN-1 downto 2), pmp_lb(i), pmp_ub(i));
    end generate;
    matched_pmp <= (null)(pmp_match);
    matched_pmpcfg <= st_pmpcfg_i(matched_pmp);
    exception_o <= req_i and ((st_prv_i /= PRV_M) and (PMP_CNT > 0)
    when nor pmp_match else not pmp_match_all(matched_pmp) or (((st_prv_i /= PRV_M) or matched_pmpcfg(7)) and ((not matched_pmpcfg(0) and not we_i) or (not matched_pmpcfg(1) and we_i) or (not matched_pmpcfg(2) and instruction_i))));
    return match_any_return;
  end match_any;

    access_lb <= adr_i;
    access_ub <= adr_i+(null)(size_i)-1;
    for i in 0 to PMP_CNT - 1 generate
      processing_4 : process
      begin
        case ((st_pmpcfg_i(i)(4 downto 3))) is
        when TOR =>
          pmp_lb(i) <= 0
          when (i = 0) else pmp_ub(i)
          when st_pmpcfg_i(i)(4 downto 3) /= TOR else st_pmpaddr_i(i)(PLEN-3 downto 0);
        when NA4 =>
          pmp_lb(i) <= (null)('1', st_pmpaddr_i(i));
        when NAPOT =>
          pmp_lb(i) <= (null)('0', st_pmpaddr_i(i));
        when others =>
          pmp_lb(i) <= X"x";
        end case;
      end process;
      processing_5 : process
      begin
        case ((st_pmpcfg_i(i)(4 downto 3))) is
        when TOR =>
          pmp_ub(i) <= st_pmpaddr_i(i)(PLEN-3 downto 0);
        when NA4 =>
          pmp_ub(i) <= (null)('1', st_pmpaddr_i(i));
        when NAPOT =>
          pmp_ub(i) <= (null)('0', st_pmpaddr_i(i));
        when others =>
          pmp_ub(i) <= X"x";
        end case;
      end process;
      pmp_match(i) <= (null)(access_lb(PLEN-1 downto 2), access_ub(PLEN-1 downto 2), pmp_lb(i), pmp_ub(i)) and (st_pmpcfg_i(i)(4 downto 3) /= OFF);
      pmp_match_all(i) <= (null)(access_lb(PLEN-1 downto 2), access_ub(PLEN-1 downto 2), pmp_lb(i), pmp_ub(i));
    end generate;
    matched_pmp <= (null)(pmp_match);
    matched_pmpcfg <= st_pmpcfg_i(matched_pmp);
    exception_o <= req_i and ((st_prv_i /= PRV_M) and (PMP_CNT > 0)
    when nor pmp_match else not pmp_match_all(matched_pmp) or (((st_prv_i /= PRV_M) or matched_pmpcfg(7)) and ((not matched_pmpcfg(0) and not we_i) or (not matched_pmpcfg(1) and we_i) or (not matched_pmpcfg(2) and instruction_i))));
    return match_all_return;
  end match_all;

  access_lb <= adr_i;
  access_ub <= adr_i+(null)(size_i)-1;
  for i in 0 to PMP_CNT - 1 generate
    processing_6 : process
    begin
      case ((st_pmpcfg_i(i)(4 downto 3))) is
      when TOR =>
        pmp_lb(i) <= 0
        when (i = 0) else pmp_ub(i)
        when st_pmpcfg_i(i)(4 downto 3) /= TOR else st_pmpaddr_i(i)(PLEN-3 downto 0);
      when NA4 =>
        pmp_lb(i) <= (null)('1', st_pmpaddr_i(i));
      when NAPOT =>
        pmp_lb(i) <= (null)('0', st_pmpaddr_i(i));
      when others =>
        pmp_lb(i) <= X"x";
      end case;
    end process;
    processing_7 : process
    begin
      case ((st_pmpcfg_i(i)(4 downto 3))) is
      when TOR =>
        pmp_ub(i) <= st_pmpaddr_i(i)(PLEN-3 downto 0);
      when NA4 =>
        pmp_ub(i) <= (null)('1', st_pmpaddr_i(i));
      when NAPOT =>
        pmp_ub(i) <= (null)('0', st_pmpaddr_i(i));
      when others =>
        pmp_ub(i) <= X"x";
      end case;
    end process;
    pmp_match(i) <= (null)(access_lb(PLEN-1 downto 2), access_ub(PLEN-1 downto 2), pmp_lb(i), pmp_ub(i)) and (st_pmpcfg_i(i)(4 downto 3) /= OFF);
    pmp_match_all(i) <= (null)(access_lb(PLEN-1 downto 2), access_ub(PLEN-1 downto 2), pmp_lb(i), pmp_ub(i));
  end generate;
  matched_pmp <= (null)(pmp_match);
  matched_pmpcfg <= st_pmpcfg_i(matched_pmp);
  exception_o <= req_i and ((st_prv_i /= PRV_M) and (PMP_CNT > 0)
  when nor pmp_match else not pmp_match_all(matched_pmp) or (((st_prv_i /= PRV_M) or matched_pmpcfg(7)) and ((not matched_pmpcfg(0) and not we_i) or (not matched_pmpcfg(1) and we_i) or (not matched_pmpcfg(2) and instruction_i))));
end RTL;
