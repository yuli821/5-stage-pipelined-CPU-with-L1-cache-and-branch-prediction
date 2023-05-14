SHELL = /bin/bash -o pipefail

#Collect All Source Files
PKG_SRCS := $(shell find $(PWD)/pkg -name '*.sv')
HDL_SRCS := $(shell find $(PWD)/hdl -name '*.sv')
HVL_SRCS := $(shell find $(PWD)/hvl -name '*.sv' -o -name '*.v')
SRCS := $(PKG_SRCS) $(HDL_SRCS) $(HVL_SRCS)

SYNTH_TCL := $(CURDIR)/synthesis.tcl

VCS_FLAGS= -full64 -lca -sverilog +lint=all,noNS -timescale=1ns/10ps -debug_acc+all -kdb -fsdb -msg_config=../warn.config -l compile.log +incdir+../pkg +incdir+../hvl -top mp4_tb

sim/simv: $(SRCS)
	mkdir -p sim
	cd sim && vcs $(SRCS) $(VCS_FLAGS) 

sim/lc_branch_dut: $(SRCS)
	make clean
	mkdir -p sim
	cd sim && vcs $(SRCS) $(VCS_FLAGS) -msg_config=../warn.config -l compile_lc_branch_dut.log -top lc_branch_dut_tb -o lc_branch_dut

run_lc_branch_dut: sim/lc_branch_dut
	cd sim && ./lc_branch_dut -l simulation_lc_branch_dut.log

sim/gl_branch_dut: $(SRCS)
	make clean
	mkdir -p sim
	cd sim && vcs $(SRCS) $(VCS_FLAGS) -msg_config=../warn.config -l compile_gl_branch_dut.log -top gl_branch_dut_tb -o gl_branch_dut

run_gl_branch_dut: sim/gl_branch_dut
	cd sim && ./gl_branch_dut -l simulation_gl_branch_dut.log

sim/tn_branch_dut: $(SRCS)
	make clean
	mkdir -p sim
	cd sim && vcs $(SRCS) $(VCS_FLAGS) -msg_config=../warn.config -l compile_tn_branch_dut.log -top tn_branch_dut_tb -o tn_branch_dut

run_tn_branch_dut: sim/tn_branch_dut
	cd sim && ./tn_branch_dut -l simulation_tn_branch_dut.log

sim/plru_dut: $(SRCS)
	make clean
	mkdir -p sim
	cd sim && vcs $(SRCS) $(VCS_FLAGS) -msg_config=../warn.config -l compile_plru_dut.log -top pseudoLRU_dut_tb -o plru_dut

run_plru_dut: sim/plru_dut
	cd sim && ./plru_dut -l simulation_plru_dut.log

sim/ras_dut: $(SRCS)
	make clean
	mkdir -p sim
	cd sim && vcs $(SRCS) $(VCS_FLAGS) -msg_config=../warn.config -l compile_ras_dut.log -top RAS_dut_tb -o ras_dut

run_ras_dut: sim/ras_dut
	cd sim && ./ras_dut -l simulation_ras_dut.log

run: sim/simv $(ASM)
	bin/generate_memory_file.sh $(ASM) 2>&1 | tee sim/asm.log
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

report_power: $(ASM) run
	cd sim && fsdb2saif dump.fsdb
	cd synth && dc_shell -f ../report_power.tcl 2>&1 | tee report_power.log

clean: 
	rm -rf sim synth

.PHONY: clean
.PHONY: run
