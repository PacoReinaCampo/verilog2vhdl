////////////////////////////////////////////////////////////////////////////////
//                                            __ _      _     _               //
//                                           / _(_)    | |   | |              //
//                __ _ _   _  ___  ___ _ __ | |_ _  ___| | __| |              //
//               / _` | | | |/ _ \/ _ \ '_ \|  _| |/ _ \ |/ _` |              //
//              | (_| | |_| |  __/  __/ | | | | | |  __/ | (_| |              //
//               \__, |\__,_|\___|\___|_| |_|_| |_|\___|_|\__,_|              //
//                  | |                                                       //
//                  |_|                                                       //
//                                                                            //
//                                                                            //
//              MSP430 CPU                                                    //
//              Processing Unit                                               //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

/* Copyright (c) 2015-2016 by the author(s)
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of the authors nor the names of its contributors
 *       may be used to endorse or promote products derived from this software
 *       without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
 * OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE
 *
 * =============================================================================
 * Author(s):
 *   Olivier Girard <olgirard@gmail.com>
 *   Paco Reina Campo <pacoreinacampo@queenfield.tech>
 */

`ifdef OMSP_NO_INCLUDE
`else
`include "msp430_defines.sv"
`endif

module msp430_wakeup_cell (
  // OUTPUTs
  output reg     wkup_out,       // Wakup signal (asynchronous)

  // INPUTs
  input          scan_clk,       // Scan clock
  input          scan_mode,      // Scan mode
  input          scan_rst,       // Scan reset
  input          wkup_clear,     // Glitch free wakeup event clear
  input          wkup_event      // Glitch free asynchronous wakeup event
);

  //=============================================================================
  // 1)  AND GATE
  //=============================================================================

  // Scan stuff for the ASIC mode
  `ifdef ASIC
  wire wkup_rst;
  msp430_scan_mux scan_mux_rst (
    .scan_mode    (scan_mode),
    .data_in_scan (scan_rst),
    .data_in_func (wkup_clear),
    .data_out     (wkup_rst)
  );

  wire wkup_clk;
  msp430_scan_mux scan_mux_clk (
    .scan_mode    (scan_mode),
    .data_in_scan (scan_clk),
    .data_in_func (wkup_event),
    .data_out     (wkup_clk)
  );

  `else
  wire wkup_rst  =  wkup_clear;
  wire wkup_clk  =  wkup_event;
  `endif

  // Wakeup capture
  always @(posedge wkup_clk or posedge wkup_rst) begin
    if (wkup_rst) wkup_out <= 1'b0;
    else          wkup_out <= 1'b1;
  end
endmodule // msp430_wakeup_cell

`ifdef OMSP_NO_INCLUDE
`else
`include "msp430_undefines.sv"
`endif
