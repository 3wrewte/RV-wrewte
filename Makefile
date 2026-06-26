# RV-wrewte Makefile
# Targets:
#   make asm  TEST=<name>   - compile tests/<name>/test.s -> init_data.mem
#   make sim  TEST=<name>   - run simulation (quiet)
#   make sim  TEST=<name> V=1 - run simulation (verbose)
#   make test TEST=<name>   - asm + sim
#   make fpga TEST=<name>   - asm + synth + impl + bitstream
#   make program            - program FPGA via JTAG
#   make uart-test          - automated UART loopback test
#   make ddr-uart-test      - read DDR hardware test result from UART
#   make clean              - remove build/ tmp/ log/

TEST ?= read_write
VIVADO ?= /opt/Xilinx/2025.1/Vivado/bin/vivado

.PHONY: asm sim test fpga program uart-test ddr-uart-test clean

asm:
	@scripts/asm.sh $(TEST)

sim:
	@scripts/sim.sh $(TEST) $(if $(V),-v,)

test: asm
	@scripts/sim.sh $(TEST) $(if $(V),-v,)

fpga: asm
	@mkdir -p log
	@if [ -n "$(V)" ]; then \
		$(VIVADO) -mode batch -source scripts/build_fpga.tcl -tclargs -v; \
	else \
		$(VIVADO) -mode batch -source scripts/build_fpga.tcl -tclargs > log/fpga_build.log 2>&1 \
		&& echo "FPGA build OK (bitstream: build/fpga/rv32_fpga.runs/impl_1/top.bit)" \
		|| { echo "FPGA build FAILED (see log/fpga_build.log)"; exit 1; }; \
	fi

program:
	@$(VIVADO) -mode batch -source scripts/program.tcl

uart-test:
	@python3 scripts/uart_test.py $(if $(PORT),--port $(PORT),)

ddr-uart-test:
	@python3 scripts/ddr_uart_test.py $(if $(PORT),--port $(PORT),)

clean:
	rm -rf build tmp log
