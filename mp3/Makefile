SHELL=/bin/bash -o pipefail

#Collect All Source Files
PKG_SRCS := $(shell find $(PWD)/pkg -name '*.sv')
HDL_SRCS := $(shell find $(PWD)/hdl -name '*.sv')
HVL_SRCS := $(shell find $(PWD)/hvl -name '*.sv' -o -name '*.v')
SRCS := $(PKG_SRCS) $(HDL_SRCS) $(HVL_SRCS)

SYNTH_TCL := $(CURDIR)/synthesis.tcl

VCS_FLAGS= -full64 -lca -sverilog +lint=all,noNS -timescale=1ns/10ps -debug_acc+all -kdb -fsdb 

.PHONY: clean
.PHONY: run
.PHONY: synth

sim/simv: $(SRCS) $(ASM)
	mkdir -p sim
	cd sim && vcs $(SRCS) $(VCS_FLAGS) -msg_config=../warn.config -l compile.log -top mp3_tb

sim/cache_dut : $(SRCS)
	mkdir -p sim
	cd sim && vcs $(SRCS) $(VCS_FLAGS) -msg_config=../warn.config -l compile_dut.log -top cache_dut_tb -o cache_dut

run_cache_dut: sim/cache_dut
	cd sim && ./cache_dut -l simulation_dut.log

run: sim/simv $(ASM)
	bin/rv_load_memory.sh $(ASM) $(PWD)/sim/memory.lst 2>&1 | tee sim/asm.log
	cd sim && ./simv -l simulation.log

synth: $(SRCS) $(SYNTH_TCL) 
	mkdir -p synth/reports
	cd synth && dc_shell -f $(SYNTH_TCL)  2>&1 | tee synthesis.log
	@if grep -q -i -f synth-error-codes synth/synthesis.log; then \
		echo -e "\033[0;31m Fix errors/warnings below \033[0m"; \
		grep -H -i -n -f synth-error-codes synth/synthesis.log; exit 1; \
	else \
		echo -e "\033[0;32m Synthesis Successful \033[0m Check timing and power report under synth/reports/"; \
    fi

clean: 
	rm -rf sim synth
