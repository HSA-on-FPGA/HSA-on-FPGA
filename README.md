# HSA-on-FPGA

Main repository of the HSA-on-FPGA demonstrator project. The design uses the
[LibHSA](https://github.com/HSA-on-FPGA/LibHSA) library described by
[Reichenbach et al.](https://ieeexplore.ieee.org/document/8122108/) to connect
an x86 host CPU via [David de la Chevallerie's PCIe interface](https://dl.acm.org/citation.cfm?id=2927971)
to a custom image processing accelerator. All kernels are dispatched according to the
[HSA Foundation standards](http://www.hsafoundation.com/).

## Prerequisites

* Vivado (tested with 2017.2)
* All prerequisites of [Tapasco](https://github.com/HSA-on-FPGA/Tapasco)
* Installation of [png++](https://www.nongnu.org/pngpp/) for the host program

## Install

1. Make sure all submodules are correctly initialized
2. Install both [custom MIPS compiler toolchains](https://github.com/HSA-on-FPGA/HSA-PacketProcessor)
3. Set the paths to both installed compilers in `LibHSA/global_conf.sh` (MIPS(32/64)_GCC_PATH)
4. Setup Tapasco with `make install`

## setup image processing test case

* compile the x86 host program with `make software`
* create the FPGA bitstream with `make hardware`

## running a test case

1. setup the Tapasco environment `source Tapasco/setup.sh`
2. load driver and bitstream `tapasco-load-bitstream --reload-driver vc709_bitstream.bit`
3. run the host program `./imgproc --operation=GAUSS3x3 image.png`

More options of the host program can be explored with `./imgproc --help`
