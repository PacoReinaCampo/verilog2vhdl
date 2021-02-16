sudo rm -f /usr/local/bin/verilog2vhdl
cd src
make
sudo cp verilog2vhdl /usr/local/bin/
make clean
