SHELL := /bin/bash

MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
CURRENT_DIR := $(dir $(MKFILE_PATH))

BACKEND_DIRS = LibHSA/ accelerator_backend/ image_accelerator/
MIPS_DESIGN_DIR = mips_board_design/
TAPASCO_DIR = $(abspath $(CURRENT_DIR)Tapasco)

.PHONY: all install hardware build_backend setup_tapasco bitstream build_mips_platform clean distclean

all: install hardware

install: setup_tapasco

hardware: bitstream

build_backend:
	for dir in $(BACKEND_DIRS); do \
		$(MAKE) -C $$dir; \
	done

bitstream: build_backend
	source $(TAPASCO_DIR)/setup.sh \
	&& export FAU_HOME=$(CURRENT_DIR) \
	&& tapasco hls counter -p vc709 \
	&& tapasco compose '[ counter x 1]' @ 100MHz -p vc709 --features 'HSA (enabled = true)' \
	&& cp $(TAPASCO_DIR)/bd/axi4mm/vc709/counter/002/100.0+BlueDMA+HSA/axi4mm-vc709--counter_2--100.0.bit vc709_bitstream.bit

setup_tapasco:
	source $(TAPASCO_DIR)/setup.sh \
	&& cd $(TAPASCO_DIR) \
	&& sbt assembly \
	&& tapasco-build-libs

build_mips_platform: build_backend
	$(MAKE) -C $(MIPS_DESIGN_DIR)

clean:
	rm -f vivado*.jou
	rm -f vivado*.log
	rm -rf .Xil/
	rm -rf $(TAPASCO_DIR)/build/
	$(MAKE) -C $(MIPS_DESIGN_DIR) clean
	for dir in $(BACKEND_DIRS); do \
		$(MAKE) -C $$dir clean; \
	done

distclean: clean
	rm -f imgproc
	rm -f vc709_bitstream.bit

