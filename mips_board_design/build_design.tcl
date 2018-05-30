# Copyright (C) 2017 Philipp Holzinger
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

set script_dir "[file dirname "[file normalize "[info script]"]"]"
source  "${script_dir}/../board_config.tcl"

# cleanup previous mess if exists
close_project -quiet
file delete -force "$script_dir/build_design"

##################################
# General Project Settings
#

# create project
set proj_obj [create_project "board_design" "$script_dir/build_design"]
set_property "target_language" "VHDL" $proj_obj

# set target part
set_property "part" "${PART_NAME}" $proj_obj
if {[info exists BOARD_NAME]} {
	set_property "board_part" "${BOARD_NAME}" $proj_obj
}

# enable xmp libraries (for virtex ultrascale)
set_property "XPM_LIBRARIES" {XPM_CDC XPM_MEMORY XPM_FIFO} $proj_obj

##################################
# Design
#

create_bd_design "board_design"

set_property  ip_repo_paths  {"../LibHSA/lib/" "../image_accelerator/" "../accelerator_backend/build/ip"} [current_project]
update_ip_catalog

# create ip cores

create_bd_cell -type ip -vlnv fau.de:hsa:fpga_cmd_processor:2.0 fpga_cmd_processor_0
create_bd_cell -type ip -vlnv fau.de:hsa:accelerator_backend:1.0 accelerator_backend_0
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_1
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.0 axi_bram_ctrl_0
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.0 axi_bram_ctrl_1
create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.3 blk_mem_gen_0
create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.3 blk_mem_gen_1
create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:5.4 clk_wiz_0
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0
set_property -dict [list CONFIG.C_IMEM_INIT_FILE "[file normalize "$script_dir/../LibHSA/lib/fpga_cmd_processor/sw/core/vsim/instr.hex"]"] [get_bd_cells fpga_cmd_processor_0]
set_property -dict [list CONFIG.C_DMEM_INIT_FILE "[file normalize "$script_dir/../LibHSA/lib/fpga_cmd_processor/sw/core/vsim/data.hex"]"] [get_bd_cells fpga_cmd_processor_0]
set_property -dict [list CONFIG.G_NUM_ACCELERATOR_CORES {1}] [get_bd_cells fpga_cmd_processor_0]
set_property -dict [list CONFIG.USE_RESET {false}] [get_bd_cells clk_wiz_0]
set_property -dict [list CONFIG.PHASESHIFT_MODE {LATENCY}] [get_bd_cells clk_wiz_0]
set_property -dict [list CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {100.000}] [get_bd_cells clk_wiz_0]
set_property -dict [list CONFIG.NUM_SI {2} CONFIG.NUM_MI {1}] [get_bd_cells axi_interconnect_0]
set_property -dict [list CONFIG.NUM_SI {2} CONFIG.NUM_MI {1}] [get_bd_cells axi_interconnect_1]
set_property -dict [list CONFIG.ENABLE_ADVANCED_OPTIONS {1} CONFIG.XBAR_DATA_WIDTH {64}] [get_bd_cells axi_interconnect_0]
set_property -dict [list CONFIG.ENABLE_ADVANCED_OPTIONS {1} CONFIG.XBAR_DATA_WIDTH {512}] [get_bd_cells axi_interconnect_1]
set_property -dict [list CONFIG.DATA_WIDTH {64} CONFIG.ECC_TYPE {0}] [get_bd_cells axi_bram_ctrl_0]
set_property -dict [list CONFIG.DATA_WIDTH {512} CONFIG.ECC_TYPE {0}] [get_bd_cells axi_bram_ctrl_1]
set_property -dict [list CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Assume_Synchronous_Clk {true} CONFIG.Enable_B {Use_ENB_Pin} CONFIG.Use_RSTB_Pin {true}] [get_bd_cells blk_mem_gen_0]
set_property -dict [list CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Assume_Synchronous_Clk {true} CONFIG.Enable_B {Use_ENB_Pin} CONFIG.Use_RSTB_Pin {true}] [get_bd_cells blk_mem_gen_1]

connect_bd_net [get_bd_pins fpga_cmd_processor_0/pp_halt] [get_bd_pins accelerator_backend_0/tp_halt]
create_bd_port -dir O -from 0 -to 0 ac_halt_lanes
connect_bd_net [get_bd_pins /fpga_cmd_processor_0/ac_halt_lanes] [get_bd_ports ac_halt_lanes]

# create clock and reset paths

apply_board_connection -board_interface "sys_diff_clock" -ip_intf "/clk_wiz_0/CLK_IN1_D" -diagram "board_design"
connect_bd_net [get_bd_pins clk_wiz_0/locked] [get_bd_pins proc_sys_reset_0/dcm_locked]
connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins proc_sys_reset_0/slowest_sync_clk]
connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins fpga_cmd_processor_0/tp_clk]
connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins fpga_cmd_processor_0/cmd_axi_aclk]
connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins fpga_cmd_processor_0/data_axi_aclk]
connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins accelerator_backend_0/clk]
connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins axi_bram_ctrl_0/s_axi_aclk]
connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins axi_bram_ctrl_1/s_axi_aclk]
connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins axi_interconnect_0/ACLK]
connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins axi_interconnect_0/S00_ACLK]
connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins axi_interconnect_0/S01_ACLK]
connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins axi_interconnect_0/M00_ACLK]
connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins axi_interconnect_1/ACLK]
connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins axi_interconnect_1/S00_ACLK]
connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins axi_interconnect_1/S01_ACLK]
connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins axi_interconnect_1/M00_ACLK]

apply_board_connection -board_interface "reset" -ip_intf "/proc_sys_reset_0/ext_reset" -diagram "board_design"
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins axi_bram_ctrl_1/s_axi_aresetn]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins accelerator_backend_0/rstn]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins fpga_cmd_processor_0/tp_rstn]
connect_bd_net [get_bd_pins proc_sys_reset_0/interconnect_aresetn] [get_bd_pins fpga_cmd_processor_0/cmd_axi_aresetn]
connect_bd_net [get_bd_pins proc_sys_reset_0/interconnect_aresetn] [get_bd_pins fpga_cmd_processor_0/data_axi_aresetn]
connect_bd_net [get_bd_pins proc_sys_reset_0/interconnect_aresetn] [get_bd_pins axi_interconnect_0/ARESETN]
connect_bd_net [get_bd_pins proc_sys_reset_0/interconnect_aresetn] [get_bd_pins axi_interconnect_0/S00_ARESETN]
connect_bd_net [get_bd_pins proc_sys_reset_0/interconnect_aresetn] [get_bd_pins axi_interconnect_0/S01_ARESETN]
connect_bd_net [get_bd_pins proc_sys_reset_0/interconnect_aresetn] [get_bd_pins axi_interconnect_0/M00_ARESETN]
connect_bd_net [get_bd_pins proc_sys_reset_0/interconnect_aresetn] [get_bd_pins axi_interconnect_1/ARESETN]
connect_bd_net [get_bd_pins proc_sys_reset_0/interconnect_aresetn] [get_bd_pins axi_interconnect_1/S00_ARESETN]
connect_bd_net [get_bd_pins proc_sys_reset_0/interconnect_aresetn] [get_bd_pins axi_interconnect_1/S01_ARESETN]
connect_bd_net [get_bd_pins proc_sys_reset_0/interconnect_aresetn] [get_bd_pins axi_interconnect_1/M00_ARESETN]

# connect interrupt signal paths

connect_bd_net [get_bd_pins fpga_cmd_processor_0/snd_aql_irq] [get_bd_pins accelerator_backend_0/rcv_aql_irq]
connect_bd_net [get_bd_pins fpga_cmd_processor_0/snd_dma_irq] [get_bd_pins accelerator_backend_0/rcv_dma_irq]
connect_bd_net [get_bd_pins fpga_cmd_processor_0/snd_cpl_irq] [get_bd_pins accelerator_backend_0/rcv_cpl_irq]
connect_bd_net [get_bd_pins fpga_cmd_processor_0/snd_add_irq] [get_bd_pins accelerator_backend_0/rcv_add_irq]
connect_bd_net [get_bd_pins fpga_cmd_processor_0/snd_rem_irq] [get_bd_pins accelerator_backend_0/rcv_rem_irq]
connect_bd_net [get_bd_pins fpga_cmd_processor_0/rcv_dma_irq] [get_bd_pins accelerator_backend_0/snd_dma_irq]
connect_bd_net [get_bd_pins fpga_cmd_processor_0/rcv_cpl_irq] [get_bd_pins accelerator_backend_0/snd_cpl_irq]
connect_bd_net [get_bd_pins fpga_cmd_processor_0/rcv_add_irq] [get_bd_pins accelerator_backend_0/snd_add_irq]
connect_bd_net [get_bd_pins fpga_cmd_processor_0/rcv_rem_irq] [get_bd_pins accelerator_backend_0/snd_rem_irq]
connect_bd_net [get_bd_pins fpga_cmd_processor_0/snd_aql_irq_ack] [get_bd_pins accelerator_backend_0/rcv_aql_irq_ack]
connect_bd_net [get_bd_pins fpga_cmd_processor_0/snd_dma_irq_ack] [get_bd_pins accelerator_backend_0/rcv_dma_irq_ack]
connect_bd_net [get_bd_pins fpga_cmd_processor_0/snd_cpl_irq_ack] [get_bd_pins accelerator_backend_0/rcv_cpl_irq_ack]
connect_bd_net [get_bd_pins fpga_cmd_processor_0/snd_add_irq_ack] [get_bd_pins accelerator_backend_0/rcv_add_irq_ack]
connect_bd_net [get_bd_pins fpga_cmd_processor_0/snd_rem_irq_ack] [get_bd_pins accelerator_backend_0/rcv_rem_irq_ack]
connect_bd_net [get_bd_pins fpga_cmd_processor_0/rcv_dma_irq_ack] [get_bd_pins accelerator_backend_0/snd_dma_irq_ack]
connect_bd_net [get_bd_pins fpga_cmd_processor_0/rcv_cpl_irq_ack] [get_bd_pins accelerator_backend_0/snd_cpl_irq_ack]
connect_bd_net [get_bd_pins fpga_cmd_processor_0/rcv_add_irq_ack] [get_bd_pins accelerator_backend_0/snd_add_irq_ack]
connect_bd_net [get_bd_pins fpga_cmd_processor_0/rcv_rem_irq_ack] [get_bd_pins accelerator_backend_0/snd_rem_irq_ack]

# connect AXI busses

connect_bd_intf_net [get_bd_intf_pins axi_bram_ctrl_0/S_AXI] -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M00_AXI]
connect_bd_intf_net [get_bd_intf_pins fpga_cmd_processor_0/cmd_axi] -boundary_type upper [get_bd_intf_pins axi_interconnect_0/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins accelerator_backend_0/M_CMD_AXI] -boundary_type upper [get_bd_intf_pins axi_interconnect_0/S01_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA] [get_bd_intf_pins blk_mem_gen_0/BRAM_PORTA]
connect_bd_intf_net [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTB] [get_bd_intf_pins blk_mem_gen_0/BRAM_PORTB]
connect_bd_intf_net [get_bd_intf_pins axi_bram_ctrl_1/S_AXI] -boundary_type upper [get_bd_intf_pins axi_interconnect_1/M00_AXI]
connect_bd_intf_net [get_bd_intf_pins fpga_cmd_processor_0/data_axi] -boundary_type upper [get_bd_intf_pins axi_interconnect_1/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins accelerator_backend_0/M_DATA_AXI] -boundary_type upper [get_bd_intf_pins axi_interconnect_1/S01_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_bram_ctrl_1/BRAM_PORTA] [get_bd_intf_pins blk_mem_gen_1/BRAM_PORTA]
connect_bd_intf_net [get_bd_intf_pins axi_bram_ctrl_1/BRAM_PORTB] [get_bd_intf_pins blk_mem_gen_1/BRAM_PORTB]

# assign address spaces

assign_bd_address [get_bd_addr_segs {axi_bram_ctrl_0/S_AXI/Mem0 }]
set_property range 4K [get_bd_addr_segs {fpga_cmd_processor_0/cmd_axi/SEG_axi_bram_ctrl_0_Mem0}]
assign_bd_address [get_bd_addr_segs {axi_bram_ctrl_1/S_AXI/Mem0 }]
set_property range 4M [get_bd_addr_segs {fpga_cmd_processor_0/data_axi/SEG_axi_bram_ctrl_1_Mem0}]
set_property range 4M [get_bd_addr_segs {accelerator_backend_0/M_DATA_AXI/SEG_axi_bram_ctrl_1_Mem0}]

# set project checkpoint mode

set_property synth_checkpoint_mode None [get_files  $script_dir/build_design/board_design.srcs/sources_1/bd/board_design/board_design.bd]

# package project

ipx::package_project -force -library hsa -taxonomy /UserIP -module board_design -import_files -vendor {fau.de} -taxonomy {/HSA} -root_dir "[get_property DIRECTORY [current_project]]/ip"
set_property core_revision 1 [ipx::current_core]
ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::save_core [ipx::current_core]

# create project HDL wrapper

make_wrapper -files [get_files $script_dir/build_design/board_design.srcs/sources_1/bd/board_design/board_design.bd] -top
add_files -norecurse "$script_dir/build_design/board_design.srcs/sources_1/bd/board_design/hdl/board_design_wrapper.vhd"
update_compile_order -fileset sources_1

