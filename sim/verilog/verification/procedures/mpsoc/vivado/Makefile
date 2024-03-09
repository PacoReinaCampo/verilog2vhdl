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
##              Universal Verification Methodology                               ##
##              Simulation Test Makefile                                         ##
##                                                                               ##
###################################################################################

###################################################################################
##                                                                               ##
## Copyright (c) 2018-2019 by the author(s)                                      ##
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
##   Francisco Javier Reina Campo <pacoreinacampo@queenfield.tech>               ##
##                                                                               ##
###################################################################################

all: build simulate

build_mpsoc2d:
	xvlog -prj mpsoc2d.prj \
	-i ../../../../../../soc/rtl/verilog/soc/bootrom

build_mpsoc3d:
	xvlog -prj mpsoc3d.prj \
	-i ../../../../../../soc/rtl/verilog/soc/bootrom

build_mpsoc4d:
	xvlog -prj mpsoc4d.prj \
	-i ../../../../../../soc/rtl/verilog/soc/bootrom

simulate_mpsoc2d: build_mpsoc2d
	xelab mpsoc2d_riscv_testbench
	xsim -R mpsoc2d_riscv_testbench

simulate_mpsoc3d: build_mpsoc3d
	xelab mpsoc3d_riscv_testbench
	xsim -R mpsoc3d_riscv_testbench

simulate_mpsoc4d: build_mpsoc4d
	xelab mpsoc4d_riscv_testbench
	xsim -R mpsoc4d_riscv_testbench

clean:
	rm -rf *.vcd .Xil *.dir *.jou *.log *.pb
