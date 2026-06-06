# RV-wrewte Makefile
# Targets:
#   make asm  TEST=<name>   - compile tests/<name>/test.s -> init_data.mem
#   make sim  TEST=<name>   - run simulation (quiet)
#   make sim  TEST=<name> V=1 - run simulation (verbose)
#   make test TEST=<name>   - asm + sim
#   make clean              - remove build/ tmp/ log/

TEST ?= read_write

.PHONY: asm sim test clean

asm:
	@scripts/asm.sh $(TEST)

sim:
	@scripts/sim.sh $(TEST) $(if $(V),-v,)

test: asm
	@scripts/sim.sh $(TEST) $(if $(V),-v,)

clean:
	rm -rf build tmp log
