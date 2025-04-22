###################################################################################
##                                            __ _      _     _                  ##
##                                           / _(_)    | |   | |                 ##
##                __ _ _   _  ___  ___ _ __ | |_ _  ___| | __| |                 ##
##               / _` | | | |/ _ \/ _ \ '_ \|  _| |/ _ \ |/ _` |                 ##
##              | (_| | |_| |  __/  __/ | | | | | |  __/ | (_| |                 ##
##               \__, |\__,_|\___|\___|_| |_|_| |_|\___|_|\__,_|                 ##
##                  | |                                                          ##
##                  |_|                                                          ##
##                                                                               ##
##                                                                               ##
##              Architecture                                                     ##
##              QueenField                                                       ##
##                                                                               ##
###################################################################################

###################################################################################
##                                                                               ##
## Copyright (c) 2019-2020 by the author(s)                                      ##
##                                                                               ##
## Permission is hereby granted, free of charge, to any person obtaining a copy  ##
## of this software and associated documentation files (the "Software"), to deal ##
## in the Software without restriction, including without limitation the rights  ##
## to use, copy, modify, merge, publish, distribute, sublicense, and/or sell     ##
## copies of the Software, and to permit persons to whom the Software is         ##
## furnished to do so, subject to the following conditions:                      ##
##                                                                               ##
## The above copyright notice and this permission notice shall be included in    ##
## all copies or substantial portions of the Software.                           ##
##                                                                               ##
## THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR    ##
## IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,      ##
## FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE   ##
## AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER        ##
## LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, ##
## OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN     ##
## THE SOFTWARE.                                                                 ##
##                                                                               ##
## ============================================================================= ##
## Author(s):                                                                    ##
##   Paco Reina Campo <pacoreinacampo@queenfield.tech>                           ##
##                                                                               ##
###################################################################################

+incdir+../../../../../../soc/rtl/verilog/soc/bootrom
+incdir+../../../../../../soc/bench/cpp/verilator/inc
+incdir+../../../../../../soc/bench/cpp/glip

../../../../../../soc/peripheral/dma/rtl/verilog/code/pkg/core/peripheral_dma_pkg.sv

../../../../../../soc/pu/rtl/verilog/pkg/peripheral_ahb4_pkg.sv
../../../../../../soc/pu/rtl/verilog/pkg/peripheral_biu_pkg.sv
../../../../../../soc/pu/rtl/verilog/pkg/pu_riscv_pkg.sv

../../../../../../soc/rtl/verilog/pkg/arbiter/soc_arbiter_rr.sv
../../../../../../soc/rtl/verilog/pkg/functions/soc_optimsoc_functions.sv
../../../../../../soc/rtl/verilog/pkg/configuration/soc_optimsoc_configuration.sv
../../../../../../soc/rtl/verilog/pkg/constants/soc_optimsoc_constants.sv

../../../../../../soc/peripheral/dbg/rtl/soc/verilog/code/peripheral/interfaces/common/peripheral_dbg_soc_dii_channel_flat.sv
../../../../../../soc/peripheral/dbg/rtl/soc/verilog/code/peripheral/interfaces/common/peripheral_dbg_soc_dii_channel.sv
../../../../../../soc/peripheral/dbg/rtl/soc/verilog/code/peripheral/interfaces/riscv/peripheral_dbg_soc_mriscv_trace_exec.sv

../../../../../../soc/bench/verilog/glip/soc_glip_channel.sv

../../../../../../soc/peripheral/dbg/rtl/soc/verilog/code/peripheral/blocks/buffer/peripheral_dbg_soc_dii_buffer.sv
../../../../../../soc/peripheral/dbg/rtl/soc/verilog/code/peripheral/blocks/buffer/peripheral_dbg_soc_osd_fifo.sv
../../../../../../soc/peripheral/dbg/rtl/soc/verilog/code/peripheral/blocks/eventpacket/peripheral_dbg_soc_osd_event_packetization_fixedwidth.sv
../../../../../../soc/peripheral/dbg/rtl/soc/verilog/code/peripheral/blocks/eventpacket/peripheral_dbg_soc_osd_event_packetization.sv
../../../../../../soc/peripheral/dbg/rtl/soc/verilog/code/peripheral/blocks/regaccess/peripheral_dbg_soc_osd_regaccess_demux.sv
../../../../../../soc/peripheral/dbg/rtl/soc/verilog/code/peripheral/blocks/regaccess/peripheral_dbg_soc_osd_regaccess_layer.sv
../../../../../../soc/peripheral/dbg/rtl/soc/verilog/code/peripheral/blocks/regaccess/peripheral_dbg_soc_osd_regaccess.sv
../../../../../../soc/peripheral/dbg/rtl/soc/verilog/code/peripheral/blocks/timestamp/peripheral_dbg_soc_osd_timestamp.sv
../../../../../../soc/peripheral/dbg/rtl/soc/verilog/code/peripheral/blocks/tracesample/peripheral_dbg_soc_osd_tracesample.sv
../../../../../../soc/peripheral/dbg/rtl/soc/verilog/code/peripheral/interconnect/peripheral_dbg_soc_debug_ring_expand.sv
../../../../../../soc/peripheral/dbg/rtl/soc/verilog/code/peripheral/interconnect/peripheral_dbg_soc_debug_ring.sv
../../../../../../soc/peripheral/dbg/rtl/soc/verilog/code/peripheral/interconnect/peripheral_dbg_soc_ring_router_demux.sv
../../../../../../soc/peripheral/dbg/rtl/soc/verilog/code/peripheral/interconnect/peripheral_dbg_soc_ring_router_gateway_demux.sv
../../../../../../soc/peripheral/dbg/rtl/soc/verilog/code/peripheral/interconnect/peripheral_dbg_soc_ring_router_gateway_mux.sv
../../../../../../soc/peripheral/dbg/rtl/soc/verilog/code/peripheral/interconnect/peripheral_dbg_soc_ring_router_gateway.sv
../../../../../../soc/peripheral/dbg/rtl/soc/verilog/code/peripheral/interconnect/peripheral_dbg_soc_ring_router_mux_rr.sv
../../../../../../soc/peripheral/dbg/rtl/soc/verilog/code/peripheral/interconnect/peripheral_dbg_soc_ring_router_mux.sv
../../../../../../soc/peripheral/dbg/rtl/soc/verilog/code/peripheral/interconnect/peripheral_dbg_soc_ring_router.sv
../../../../../../soc/peripheral/dbg/rtl/soc/verilog/code/peripheral/modules/ctm/common/peripheral_dbg_soc_osd_ctm.sv
../../../../../../soc/peripheral/dbg/rtl/soc/verilog/code/peripheral/modules/ctm/riscv/peripheral_dbg_soc_osd_ctm_mriscv.sv
../../../../../../soc/peripheral/dbg/rtl/soc/verilog/code/peripheral/modules/dem_uart/peripheral_dbg_soc_osd_dem_uart_16550.sv
../../../../../../soc/peripheral/dbg/rtl/soc/verilog/code/peripheral/modules/dem_uart/peripheral_dbg_soc_osd_dem_uart.sv
../../../../../../soc/peripheral/dbg/rtl/soc/verilog/code/peripheral/modules/dem_uart/peripheral_dbg_soc_osd_dem_uart_ahb4.sv
../../../../../../soc/peripheral/dbg/rtl/soc/verilog/code/peripheral/modules/him/peripheral_dbg_soc_osd_him.sv
../../../../../../soc/peripheral/dbg/rtl/soc/verilog/code/peripheral/modules/mam/common/peripheral_dbg_soc_osd_mam.sv
../../../../../../soc/peripheral/dbg/rtl/soc/verilog/code/peripheral/modules/mam/ahb4/peripheral_dbg_soc_mam_adapter_ahb4.sv
../../../../../../soc/peripheral/dbg/rtl/soc/verilog/code/peripheral/modules/mam/ahb4/peripheral_dbg_soc_osd_mam_if_ahb4.sv
../../../../../../soc/peripheral/dbg/rtl/soc/verilog/code/peripheral/modules/mam/ahb4/peripheral_dbg_soc_osd_mam_ahb4.sv
../../../../../../soc/peripheral/dbg/rtl/soc/verilog/code/peripheral/modules/scm/peripheral_dbg_soc_osd_scm.sv
../../../../../../soc/peripheral/dbg/rtl/soc/verilog/code/peripheral/modules/stm/common/peripheral_dbg_soc_osd_stm.sv
../../../../../../soc/peripheral/dbg/rtl/soc/verilog/code/peripheral/modules/stm/riscv/mriscv/peripheral_dbg_soc_osd_stm_mriscv.sv
../../../../../../soc/peripheral/dbg/rtl/soc/verilog/code/peripheral/top/peripheral_dbg_soc_interface.sv

../../../../../../soc/peripheral/dma/rtl/verilog/code/core/peripheral_dma_initiator_nocreq.sv
../../../../../../soc/peripheral/dma/rtl/verilog/code/core/peripheral_dma_packet_buffer.sv
../../../../../../soc/peripheral/dma/rtl/verilog/code/core/peripheral_dma_request_table.sv
../../../../../../soc/peripheral/dma/rtl/verilog/code/peripheral/ahb4/peripheral_dma_initiator_nocres_ahb4.sv
../../../../../../soc/peripheral/dma/rtl/verilog/code/peripheral/ahb4/peripheral_dma_initiator_req_ahb4.sv
../../../../../../soc/peripheral/dma/rtl/verilog/code/peripheral/ahb4/peripheral_dma_initiator_ahb4.sv
../../../../../../soc/peripheral/dma/rtl/verilog/code/peripheral/ahb4/peripheral_dma_interface_ahb4.sv
../../../../../../soc/peripheral/dma/rtl/verilog/code/peripheral/ahb4/peripheral_dma_target_ahb4.sv
../../../../../../soc/peripheral/dma/rtl/verilog/code/peripheral/ahb4/peripheral_dma_top_ahb4.sv

../../../../../../soc/peripheral/mpi/rtl/verilog/code/core/peripheral_mpi_buffer.sv
../../../../../../soc/peripheral/mpi/rtl/verilog/code/core/peripheral_mpi_buffer_endpoint.sv
../../../../../../soc/peripheral/mpi/rtl/verilog/code/peripheral/ahb4/peripheral_mpi_ahb4.sv

../../../../../../soc/peripheral/noc/rtl/verilog/code/peripheral/main/peripheral_arbiter_rr.sv
../../../../../../soc/peripheral/noc/rtl/verilog/code/peripheral/main/peripheral_noc_buffer.sv
../../../../../../soc/peripheral/noc/rtl/verilog/code/peripheral/main/peripheral_noc_demux.sv
../../../../../../soc/peripheral/noc/rtl/verilog/code/peripheral/main/peripheral_noc_mux.sv
../../../../../../soc/peripheral/noc/rtl/verilog/code/peripheral/main/peripheral_noc_vchannel_mux.sv
../../../../../../soc/peripheral/noc/rtl/verilog/code/peripheral/router/peripheral_noc_router_input.sv
../../../../../../soc/peripheral/noc/rtl/verilog/code/peripheral/router/peripheral_noc_router_lookup_slice.sv
../../../../../../soc/peripheral/noc/rtl/verilog/code/peripheral/router/peripheral_noc_router_lookup.sv
../../../../../../soc/peripheral/noc/rtl/verilog/code/peripheral/router/peripheral_noc_router_output.sv
../../../../../../soc/peripheral/noc/rtl/verilog/code/peripheral/router/peripheral_noc_router.sv
../../../../../../soc/peripheral/noc/rtl/verilog/code/peripheral/topology/peripheral_noc_mesh3d.sv

../../../../../../soc/pu/rtl/verilog/core/cache/pu_riscv_dcache_core.sv
../../../../../../soc/pu/rtl/verilog/core/cache/pu_riscv_dext.sv
../../../../../../soc/pu/rtl/verilog/core/cache/pu_riscv_icache_core.sv
../../../../../../soc/pu/rtl/verilog/core/cache/pu_riscv_noicache_core.sv
../../../../../../soc/pu/rtl/verilog/core/decode/pu_riscv_id.sv
../../../../../../soc/pu/rtl/verilog/core/execute/pu_riscv_alu.sv
../../../../../../soc/pu/rtl/verilog/core/execute/pu_riscv_bu.sv
../../../../../../soc/pu/rtl/verilog/core/execute/pu_riscv_divider.sv
../../../../../../soc/pu/rtl/verilog/core/execute/pu_riscv_execution.sv
../../../../../../soc/pu/rtl/verilog/core/execute/pu_riscv_lsu.sv
../../../../../../soc/pu/rtl/verilog/core/execute/pu_riscv_multiplier.sv
../../../../../../soc/pu/rtl/verilog/core/fetch/pu_riscv_if.sv
../../../../../../soc/pu/rtl/verilog/core/main/pu_riscv_bp.sv
../../../../../../soc/pu/rtl/verilog/core/main/pu_riscv_core.sv
../../../../../../soc/pu/rtl/verilog/core/main/pu_riscv_du.sv
../../../../../../soc/pu/rtl/verilog/core/main/pu_riscv_memory.sv
../../../../../../soc/pu/rtl/verilog/core/main/pu_riscv_rf.sv
../../../../../../soc/pu/rtl/verilog/core/main/pu_riscv_state.sv
../../../../../../soc/pu/rtl/verilog/core/main/pu_riscv_wb.sv
../../../../../../soc/pu/rtl/verilog/core/memory/pu_riscv_dmem_ctrl.sv
../../../../../../soc/pu/rtl/verilog/core/memory/pu_riscv_imem_ctrl.sv
../../../../../../soc/pu/rtl/verilog/core/memory/pu_riscv_membuf.sv
../../../../../../soc/pu/rtl/verilog/core/memory/pu_riscv_memmisaligned.sv
../../../../../../soc/pu/rtl/verilog/core/memory/pu_riscv_mmu.sv
../../../../../../soc/pu/rtl/verilog/core/memory/pu_riscv_mux.sv
../../../../../../soc/pu/rtl/verilog/core/memory/pu_riscv_pmachk.sv
../../../../../../soc/pu/rtl/verilog/core/memory/pu_riscv_pmpchk.sv
../../../../../../soc/pu/rtl/verilog/memory/pu_riscv_ram_1r1w_generic.sv
../../../../../../soc/pu/rtl/verilog/memory/pu_riscv_ram_1r1w.sv
../../../../../../soc/pu/rtl/verilog/memory/pu_riscv_ram_1rw_generic.sv
../../../../../../soc/pu/rtl/verilog/memory/pu_riscv_ram_1rw.sv
../../../../../../soc/pu/rtl/verilog/memory/pu_riscv_ram_queue.sv
../../../../../../soc/pu/rtl/verilog/pu/ahb4/pu_riscv_ahb4.sv
../../../../../../soc/pu/rtl/verilog/pu/ahb4/pu_riscv_biu2ahb4.sv
../../../../../../soc/pu/rtl/verilog/pu/ahb4/pu_riscv_module_ahb4.sv

../../../../../../soc/rtl/verilog/soc/adapter/soc_network_adapter_configuration.sv
../../../../../../soc/rtl/verilog/soc/adapter/soc_network_adapter_ct.sv
../../../../../../soc/rtl/verilog/soc/bootrom/soc_bootrom.sv
../../../../../../soc/rtl/verilog/soc/interconnection/bus/soc_b3_ahb4.sv
../../../../../../soc/rtl/verilog/soc/interconnection/decode/soc_decode_ahb4.sv
../../../../../../soc/rtl/verilog/soc/interconnection/mux/soc_mux_ahb4.sv
../../../../../../soc/rtl/verilog/soc/main/soc_riscv_tile.sv
../../../../../../soc/rtl/verilog/soc/spram/soc_sram_sp_impl_plain.sv
../../../../../../soc/rtl/verilog/soc/spram/soc_sram_sp.sv
../../../../../../soc/rtl/verilog/soc/spram/soc_sram_sp_ahb4.sv
../../../../../../soc/rtl/verilog/soc/spram/soc_ahb42sram.sv

../../../../../../rtl/verilog/mpsoc/mpsoc3d_riscv.sv

../../../../../../bench/verilog/main/mpsoc3d_riscv_testbench.sv
