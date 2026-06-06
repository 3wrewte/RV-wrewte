# RV-wrewte Makefile
# Targets:
#   make asm         - compile src/a.s -> init_data.mem
#   make sim         - run simulation (quiet, only PASS/FAIL)
#   make sim V=1     - run simulation (verbose)
#   make test        - asm + sim
#   make clean       - remove build/ and tmp/

.PHONY: asm sim test clean

asm:
	@scripts/asm.sh

sim:
	@scripts/sim.sh $(if $(V),-v,)

test: asm
	@scripts/sim.sh $(if $(V),-v,)

clean:
	rm -rf build tmp
