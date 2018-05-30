.PHONY: clean build debug

build: build/ip/component.xml

build/ip/component.xml:
	vivado -mode batch -source build.tcl

debug:
	vivado -mode batch -source debug_build.tcl

clean:
	rm -rf build/ .Xil/ vivado*

