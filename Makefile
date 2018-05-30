MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
CURRENT_DIR := $(dir $(MKFILE_PATH))

BACKEND_DIRS = LibHSA/ image_accelerator/ accelerator_backend/
MIPS_DESIGN_DIR = mips_board_design/
TAPASCO_DIR = $(abspath $(CURRENT_DIR)Tapasco)

.PHONY: all install software hardware build_backend setup_tapasco setup_testcase bitstream build_mips_platform clean distclean

all: setup_testcase hardware

install: setup_tapasco

setup_testcase: software

hardware: bitstream

build_backend:
	for dir in $(BACKEND_DIRS); do \
		$(MAKE) -C $$dir clean; \
		$(MAKE) -C $$dir; \
	done

bitstream:
	export TAPASCO_HOME=$(TAPASCO_DIR) \
	&& export PATH=$$TAPASCO_HOME/bin:$$PATH \
	&& export FAU_HOME=$(CURRENT_DIR) \
	&& tapasco --jobsFile x86_system_conf.json
	cp $(TAPASCO_DIR)/bd/axi4mm/vc709/counter/002/100.0+BlueDMA+HSA/axi4mm-vc709--counter_2--100.0.bit vc709_bitstream.bit

setup_tapasco:
	echo 'addSbtPlugin("com.eed3si9n" % "sbt-assembly" % "0.14.5")' > $(TAPASCO_DIR)/project/assembly.sbt
	echo 'addSbtPlugin("org.scalastyle" %% "scalastyle-sbt-plugin" % "1.0.0")' > $(TAPASCO_DIR)/project/sbt-scalastyle.sbt
	echo '' >> $(TAPASCO_DIR)/project/sbt-scalastyle.sbt
	echo 'resolvers += "sonatype-releases" at "https://oss.sonatype.org/content/repositories/releases/"' >> $(TAPASCO_DIR)/project/sbt-scalastyle.sbt
	cd $(TAPASCO_DIR) \
	&& export TAPASCO_HOME=$(TAPASCO_DIR) \
	&& export PATH=$$TAPASCO_HOME/bin:$$PATH \
	&& export FAU_HOME=$(CURRENT_DIR) \
	&& sbt compile && sbt assembly \
	&& tapasco-build-libs

software:
	export TAPASCO_HOME=$(TAPASCO_DIR) && export PATH=$$TAPASCO_HOME/bin:$$PATH \
	&& cd $(TAPASCO_DIR)/examples/image_processing/ && mkdir -p build/ && cd build && cmake .. && make
	cp $(TAPASCO_DIR)/examples/image_processing/build/imgproc .

build_mips_platform: build_backend
	$(MAKE) -C $(MIPS_DESIGN_DIR)

clean:
	rm -f vivado*.jou
	rm -f vivado*.log
	rm -rf .Xil/
	rm -rf $(TAPASCO_DIR)/examples/image_processing/build/
	$(MAKE) -C $(MIPS_DESIGN_DIR) clean
	for dir in $(BACKEND_DIRS); do \
		$(MAKE) -C $$dir clean; \
	done

distclean: clean
	rm -f imgproc
	rm -f vc709_bitstream.bit

