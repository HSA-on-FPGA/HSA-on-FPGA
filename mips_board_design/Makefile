.PHONY: clean all sim design debug

all: sim design

debug: sim design

design:
	vivado -mode batch -source build_design.tcl

sim:
	vivado -mode batch -source build_sim.tcl

clean:
	rm -rf build_design/ build_sim/ .Xil/ vivado*

