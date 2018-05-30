# Copyright (C) 2017 Philipp Holzinger
# Copyright (C) 2017 Martin Stumpf
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


set script_directory "[file dirname "[file normalize "[info script]"]"]"

set bd_file [create_bd_design image_accelerator]
puts $bd_file
current_bd_design image_accelerator

########################################
# Ports
#

# Create interface ports
create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI
set_property -dict [ list \
    CONFIG.ADDR_WIDTH {32} \
    CONFIG.ARUSER_WIDTH {0} \
    CONFIG.AWUSER_WIDTH {0} \
    CONFIG.BUSER_WIDTH {0} \
    CONFIG.DATA_WIDTH {64} \
    CONFIG.HAS_BRESP {1} \
    CONFIG.HAS_BURST {1} \
    CONFIG.HAS_CACHE {1} \
    CONFIG.HAS_LOCK {1} \
    CONFIG.HAS_PROT {1} \
    CONFIG.HAS_QOS {0} \
    CONFIG.HAS_REGION {0} \
    CONFIG.HAS_RRESP {1} \
    CONFIG.HAS_WSTRB {1} \
    CONFIG.ID_WIDTH {1} \
    CONFIG.MAX_BURST_LENGTH {256} \
    CONFIG.NUM_READ_OUTSTANDING {2} \
    CONFIG.NUM_READ_THREADS {1} \
    CONFIG.NUM_WRITE_OUTSTANDING {2} \
    CONFIG.NUM_WRITE_THREADS {1} \
    CONFIG.PROTOCOL {AXI4} \
    CONFIG.READ_WRITE_MODE {READ_WRITE} \
    CONFIG.RUSER_BITS_PER_BYTE {0} \
    CONFIG.RUSER_WIDTH {0} \
    CONFIG.SUPPORTS_NARROW_BURST {1} \
    CONFIG.WUSER_BITS_PER_BYTE {0} \
    CONFIG.WUSER_WIDTH {0} \
] [get_bd_intf_ports S_AXI]

create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI
set_property -dict [ list \
    CONFIG.ADDR_WIDTH {64} \
    CONFIG.DATA_WIDTH {512} \
    CONFIG.HAS_BRESP {1} \
    CONFIG.HAS_BURST {1} \
    CONFIG.HAS_CACHE {1} \
    CONFIG.HAS_LOCK {1} \
    CONFIG.HAS_PROT {1} \
    CONFIG.HAS_QOS {0} \
    CONFIG.HAS_REGION {0} \
    CONFIG.HAS_RRESP {1} \
    CONFIG.HAS_WSTRB {1} \
    CONFIG.NUM_READ_OUTSTANDING {2} \
    CONFIG.NUM_WRITE_OUTSTANDING {2} \
    CONFIG.PROTOCOL {AXI4} \
    CONFIG.READ_WRITE_MODE {READ_WRITE} \
] [get_bd_intf_ports M_AXI]

# Create ports
create_bd_port -dir I -type clk clk
create_bd_port -dir I -type rst rstn
create_bd_port -dir O finished_irq
create_bd_port -dir I finished_irq_ack
create_bd_port -dir I start_irq
create_bd_port -dir O start_irq_ack


########################################
# IP Instances
#

  # Create instance: const_high, and set properties
    create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 const_high

  # Create instance: const_low, and set properties
    create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 const_low
    set_property -dict [list CONFIG.CONST_VAL {0}] [get_bd_cells const_low]

  # Create instance: accel_cmd_processor_0, and set properties
    create_bd_cell -type ip \
                   -vlnv fau.de:hsa:rom_accel_cmd_processor:1.0 accel_cmd_processor_0
    set_property -dict [ list \
        CONFIG.G_MEM_NUM_4K_DATA_MEMS {1} \
        CONFIG.G_MEM_NUM_4K_INSTR_MEMS {1} \
        CONFIG.G_NUM_HW_INTERRUPTS {2} \
        CONFIG.G_NUM_SND_INTERRUPTS {3} \
        CONFIG.C_IMEM_INIT_FILE "[file normalize "$script_directory/../LibHSA/lib/rom_accel_cmd_processor/sw/core0/vsim/instr.hex"]" \
        CONFIG.C_DMEM_INIT_FILE "[file normalize "$script_directory/../LibHSA/lib/rom_accel_cmd_processor/sw/core0/vsim/data.hex"]" \
    ] [get_bd_cells accel_cmd_processor_0]

  # Create instance: axi_intercon, and set properties
    create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 \
                    axi_intercon
    set_property -dict [ list \
        CONFIG.NUM_MI {3} \
    ] [get_bd_cells axi_intercon]

  # Create instance: axi_interconnect_0, and set properties
    create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0
    set_property -dict [list CONFIG.NUM_SI {2} CONFIG.NUM_MI {1}] [get_bd_cells axi_interconnect_0]

  # Create instance: axi_bram_ctrl_1, and set properties
    create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.0 axi_bram_ctrl_1
    set_property -dict [ list \
        CONFIG.PROTOCOL {AXI4} \
        CONFIG.SINGLE_PORT_BRAM {1} \
    ] [get_bd_cells axi_bram_ctrl_1]

  # Create instance: axi_bram_ctrl_4, and set properties
    create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.0 axi_bram_ctrl_4
    set_property -dict [ list \
        CONFIG.DATA_WIDTH {64} \
        CONFIG.SINGLE_PORT_BRAM {1} \
    ] [get_bd_cells axi_bram_ctrl_4]

  # Create instance: datamover_0, and set properties
    create_bd_cell -type ip -vlnv fau.de:hsa:datamover:1.1 datamover_0

  # Create instance: dualclock_bram_0, and set properties
    create_bd_cell -type ip -vlnv fau.de:hsa:dualclock_bram:1.0 dualclock_bram_0
    set_property -dict [ list \
        CONFIG.ADDR {12} \
        CONFIG.DATA_A {64} \
        CONFIG.DATA_B {32} \
        CONFIG.SIZE {4096} \
    ] [get_bd_cells dualclock_bram_0]

  # Create instance: image_pe_0, and set properties
    create_bd_cell -type ip -vlnv fau.de:hsa:image_pe:1.0 image_pe_0
    #if {[info exists PART_IS_ULTRASCALE]} {
    #  set_property -dict [ list \
          CONFIG.c_dev_ultra ${PART_IS_ULTRASCALE} \
      ] [get_bd_cells image_pe_0]
    #} else {
    #  set_property -dict [ list \
          CONFIG.c_dev_ultra false \
      ] [get_bd_cells image_pe_0]
    #}

  # Create instance: xlconcat_0, and set properties
    create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_0
    set_property -dict [ list \
        CONFIG.NUM_PORTS {3} \
    ] [get_bd_cells xlconcat_0]

  # Create instance: xlconcat_1, and set properties
    create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_1
    set_property -dict [ list \
        CONFIG.NUM_PORTS {2} \
    ] [get_bd_cells xlconcat_1]

  # Create instance: xlslice_0, and set properties
    create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_0
    set_property -dict [ list \
        CONFIG.DIN_FROM {0} \
        CONFIG.DIN_TO {0} \
        CONFIG.DIN_WIDTH {3} \
    ] [get_bd_cells xlslice_0]

  # Create instance: xlslice_1, and set properties
    create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_1
    set_property -dict [ list \
        CONFIG.DIN_FROM {1} \
        CONFIG.DIN_TO {1} \
        CONFIG.DIN_WIDTH {2} \
        CONFIG.DOUT_WIDTH {1} \
    ] [get_bd_cells xlslice_1]

  # Create instance: xlslice_2, and set properties
    create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_2
    set_property -dict [ list \
        CONFIG.DIN_FROM {1} \
        CONFIG.DIN_TO {1} \
        CONFIG.DIN_WIDTH {3} \
        CONFIG.DOUT_WIDTH {1} \
    ] [get_bd_cells xlslice_2]

  # Create instance: xlslice_3, and set properties
    create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_3 
    set_property -dict [ list \
        CONFIG.DIN_FROM {2} \
        CONFIG.DIN_TO {2} \
        CONFIG.DIN_WIDTH {3} \
        CONFIG.DOUT_WIDTH {1} \
    ] [get_bd_cells xlslice_3]

  # Create instance: xlslice_4, and set properties
    create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_4
    set_property -dict [ list \
        CONFIG.DIN_FROM {0} \
        CONFIG.DIN_TO {0} \
        CONFIG.DIN_WIDTH {2} \
        CONFIG.DOUT_WIDTH {1} \
    ] [get_bd_cells xlslice_4]


########################################
# Connections
#

  # Create interface connections
  connect_bd_intf_net [get_bd_intf_ports S_AXI] [get_bd_intf_pins axi_bram_ctrl_4/S_AXI]
  connect_bd_intf_net [get_bd_intf_pins accel_cmd_processor_0/data_axi] [get_bd_intf_pins axi_intercon/S00_AXI]
  connect_bd_intf_net [get_bd_intf_pins axi_intercon/M00_AXI] [get_bd_intf_pins datamover_0/axi_cfg]
  connect_bd_intf_net [get_bd_intf_pins axi_bram_ctrl_1/S_AXI] [get_bd_intf_pins axi_intercon/M01_AXI]
  connect_bd_intf_net [get_bd_intf_pins axi_intercon/M02_AXI] [get_bd_intf_pins image_pe_0/S_AXI]
  connect_bd_intf_net [get_bd_intf_pins datamover_0/axi_stream_out] [get_bd_intf_pins image_pe_0/S_AXIS]
  connect_bd_intf_net [get_bd_intf_pins datamover_0/axi_stream_in] [get_bd_intf_pins image_pe_0/M_AXIS]
  connect_bd_intf_net [get_bd_intf_pins axi_bram_ctrl_4/BRAM_PORTA] [get_bd_intf_pins dualclock_bram_0/BRAM_PORTA]
  connect_bd_intf_net [get_bd_intf_pins axi_bram_ctrl_1/BRAM_PORTA] [get_bd_intf_pins dualclock_bram_0/BRAM_PORTB]
  connect_bd_intf_net [get_bd_intf_pins datamover_0/axi_mem_in] [get_bd_intf_pins axi_interconnect_0/S00_AXI]
  connect_bd_intf_net [get_bd_intf_pins datamover_0/axi_mem_out] [get_bd_intf_pins axi_interconnect_0/S01_AXI]
  connect_bd_intf_net [get_bd_intf_ports M_AXI] [get_bd_intf_pins axi_interconnect_0/M00_AXI]

  # Create port connections
  connect_bd_net [get_bd_ports clk] [get_bd_pins accel_cmd_processor_0/data_axi_aclk]
  connect_bd_net [get_bd_ports clk] [get_bd_pins accel_cmd_processor_0/tp_clk]
  connect_bd_net [get_bd_ports clk] [get_bd_pins axi_bram_ctrl_1/s_axi_aclk]
  connect_bd_net [get_bd_ports clk] [get_bd_pins axi_intercon/ACLK]
  connect_bd_net [get_bd_ports clk] [get_bd_pins axi_intercon/M00_ACLK]
  connect_bd_net [get_bd_ports clk] [get_bd_pins axi_intercon/M01_ACLK]
  connect_bd_net [get_bd_ports clk] [get_bd_pins axi_intercon/M02_ACLK]
  connect_bd_net [get_bd_ports clk] [get_bd_pins axi_intercon/S00_ACLK]
  connect_bd_net [get_bd_ports clk] [get_bd_pins datamover_0/axi_aclk]
  connect_bd_net [get_bd_ports clk] [get_bd_pins datamover_0/axi_cfg_aclk]
  #connect_bd_net [get_bd_ports clk] [get_bd_pins image_pe_0/M_AXIS_ACLK]
  #connect_bd_net [get_bd_ports clk] [get_bd_pins image_pe_0/S_AXIS_ACLK]
  connect_bd_net [get_bd_ports clk] [get_bd_pins image_pe_0/S_AXI_ACLK]
  connect_bd_net [get_bd_ports clk] [get_bd_pins axi_interconnect_0/ACLK]
  connect_bd_net [get_bd_ports clk] [get_bd_pins axi_interconnect_0/S00_ACLK]
  connect_bd_net [get_bd_ports clk] [get_bd_pins axi_interconnect_0/S01_ACLK]
  connect_bd_net [get_bd_ports clk] [get_bd_pins axi_interconnect_0/M00_ACLK]
  connect_bd_net [get_bd_ports clk] [get_bd_pins axi_bram_ctrl_4/s_axi_aclk]
  connect_bd_net [get_bd_ports rstn] [get_bd_pins accel_cmd_processor_0/data_axi_aresetn]
  connect_bd_net [get_bd_ports rstn] [get_bd_pins axi_intercon/ARESETN]
  connect_bd_net [get_bd_ports rstn] [get_bd_pins accel_cmd_processor_0/tp_rstn]
  connect_bd_net [get_bd_ports rstn] [get_bd_pins axi_bram_ctrl_1/s_axi_aresetn]
  connect_bd_net [get_bd_ports rstn] [get_bd_pins axi_intercon/M00_ARESETN]
  connect_bd_net [get_bd_ports rstn] [get_bd_pins axi_intercon/M01_ARESETN]
  connect_bd_net [get_bd_ports rstn] [get_bd_pins axi_intercon/M02_ARESETN]
  connect_bd_net [get_bd_ports rstn] [get_bd_pins axi_intercon/S00_ARESETN]
  connect_bd_net [get_bd_ports rstn] [get_bd_pins datamover_0/axi_aresetn]
  connect_bd_net [get_bd_ports rstn] [get_bd_pins datamover_0/axi_cfg_aresetn]
  #connect_bd_net [get_bd_ports rstn] [get_bd_pins image_pe_0/M_AXIS_ARESETN]
  #connect_bd_net [get_bd_ports rstn] [get_bd_pins image_pe_0/S_AXIS_ARESETN]
  connect_bd_net [get_bd_ports rstn] [get_bd_pins image_pe_0/S_AXI_ARESETN]
  #connect_bd_net [get_bd_ports rstn] [get_bd_pins image_pe_0/rst_n]
  connect_bd_net [get_bd_ports rstn] [get_bd_pins axi_interconnect_0/ARESETN]
  connect_bd_net [get_bd_ports rstn] [get_bd_pins axi_interconnect_0/S00_ARESETN]
  connect_bd_net [get_bd_ports rstn] [get_bd_pins axi_interconnect_0/S01_ARESETN]
  connect_bd_net [get_bd_ports rstn] [get_bd_pins axi_interconnect_0/M00_ARESETN]
  connect_bd_net [get_bd_ports rstn] [get_bd_pins axi_bram_ctrl_4/s_axi_aresetn]
  connect_bd_net [get_bd_pins const_high/dout] [get_bd_pins image_pe_0/en]
  connect_bd_net [get_bd_pins const_low/dout] [get_bd_pins accel_cmd_processor_0/tp_halt]
  connect_bd_net [get_bd_pins accel_cmd_processor_0/rcv_irq_ack] [get_bd_pins xlslice_1/Din]
  connect_bd_net [get_bd_pins accel_cmd_processor_0/rcv_irq_ack] [get_bd_pins xlslice_4/Din]
  connect_bd_net [get_bd_pins accel_cmd_processor_0/snd_irq] [get_bd_pins xlslice_0/Din] [get_bd_pins xlslice_2/Din] [get_bd_pins xlslice_3/Din]
  connect_bd_net [get_bd_pins datamover_0/int_finished] [get_bd_pins xlconcat_1/In0]
  connect_bd_net [get_bd_pins datamover_0/int_finished_ack] [get_bd_pins xlslice_4/Dout]
  connect_bd_net [get_bd_ports finished_irq_ack] [get_bd_pins xlconcat_0/In2]
  connect_bd_net [get_bd_ports start_irq] [get_bd_pins xlconcat_1/In1]
  connect_bd_net [get_bd_pins accel_cmd_processor_0/snd_irq_ack] [get_bd_pins xlconcat_0/dout]
  connect_bd_net [get_bd_pins accel_cmd_processor_0/rcv_irq] [get_bd_pins xlconcat_1/dout]
  connect_bd_net [get_bd_pins datamover_0/int_start] [get_bd_pins xlconcat_0/In0] [get_bd_pins xlslice_0/Dout]
  connect_bd_net [get_bd_ports start_irq_ack] [get_bd_pins xlslice_1/Dout]
  connect_bd_net [get_bd_pins image_pe_0/start_read] [get_bd_pins xlconcat_0/In1] [get_bd_pins xlslice_2/Dout]
  connect_bd_net [get_bd_ports finished_irq] [get_bd_pins xlslice_3/Dout]

########################################
# Addresses Space Config
#

# accel_cmd_processor_0/data_axi
set parent [get_bd_addr_spaces accel_cmd_processor_0/data_axi]

# Create address segments
create_bd_addr_seg -range 0x00001000 -offset 0x11000000 \
    $parent [get_bd_addr_segs axi_bram_ctrl_1/S_AXI/Mem0]\
    SEG_axi_bram_ctrl_1_Mem0

create_bd_addr_seg -range 0x00100000 -offset 0x13000000 \
    $parent [get_bd_addr_segs datamover_0/axi_cfg/reg0]\
    SEG_datamover_0_reg0

create_bd_addr_seg -range 0x00010000 -offset 0x12000000 \
    $parent [get_bd_addr_segs image_pe_0/S_AXI/reg0]\
    SEG_image_pe_0_reg0


create_bd_addr_seg -range 0x0000000100000000 -offset 0x0001000000000000 \
    [get_bd_addr_spaces datamover_0/axi_mem_in]\
    [get_bd_addr_segs M_AXI/Reg]\
    SEG_M_AXI_Reg

create_bd_addr_seg -range 0x0000000100000000 -offset 0x0001000000000000 \
    [get_bd_addr_spaces datamover_0/axi_mem_out]\
    [get_bd_addr_segs M_AXI/Reg]\
    SEG_M_AXI_Reg

create_bd_addr_seg -range 0x00001000 -offset 0x00000000 \
    [get_bd_addr_spaces S_AXI]\
    [get_bd_addr_segs axi_bram_ctrl_4/S_AXI/Mem0]\
    SEG_axi_bram_ctrl_4_Mem0


########################################
# Final touches
#

# Beautify
regenerate_bd_layout
regenerate_bd_layout -routing

# Save
save_bd_design

# Generate Files
generate_target all [get_files [get_property FILE_NAME $bd_file]]

# Generate Wrapper
add_files [make_wrapper -top [get_files [get_property FILE_NAME $bd_file]]]
