.PHONY: clean build debug

build: build/ip/component.xml

debug: build/ip/component.xml

build/ip/component.xml:
	cd HSA-Accelerator/ && $(MAKE)
	vivado -mode batch -source build.tcl

clean:
	cd HSA-Accelerator/ && $(MAKE) clean
	rm -rf build/
	rm -rf .Xil/
	rm -f vivado*.log
	rm -f vivado*.jou
