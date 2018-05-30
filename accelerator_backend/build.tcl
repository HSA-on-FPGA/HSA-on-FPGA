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
file delete -force "$script_dir/build"

##################################
# General Project Settings
#

# create project
set proj_obj [create_project "accelerator_backend" "$script_dir/build"]
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

create_bd_design "accelerator_backend"

set_property  ip_repo_paths  {"../LibHSA/lib/" "../image_accelerator/"} [current_project]
update_ip_catalog

# create ip cores

create_bd_cell -type ip -vlnv fau.de:hsa:packet_processor:2.0 packet_processor_0
set_property -dict [list CONFIG.C_IMEM_INIT_FILE "[file normalize "$script_dir/../LibHSA/lib/packet_processor/sw/core/vsim/instr.hex"]"] [get_bd_cells packet_processor_0]
set_property -dict [list CONFIG.C_DMEM_INIT_FILE "[file normalize "$script_dir/../LibHSA/lib/packet_processor/sw/core/vsim/data.hex"]"] [get_bd_cells packet_processor_0]
set_property -dict [list CONFIG.G_NUM_ACCELERATOR_CORES {1}] [get_bd_cells packet_processor_0]
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0
set_property -dict [list CONFIG.NUM_SI {1} CONFIG.NUM_MI {2}] [get_bd_cells axi_interconnect_0]
set_property -dict [list CONFIG.ENABLE_ADVANCED_OPTIONS {1} CONFIG.XBAR_DATA_WIDTH {64}] [get_bd_cells axi_interconnect_0]
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_1
set_property -dict [list CONFIG.NUM_SI {2} CONFIG.NUM_MI {1}] [get_bd_cells axi_interconnect_1]
set_property -dict [list CONFIG.ENABLE_ADVANCED_OPTIONS {1} CONFIG.XBAR_DATA_WIDTH {512}] [get_bd_cells axi_interconnect_1]
create_bd_cell -type ip -vlnv fau.de:hsa:image_accelerator:1.0 image_accelerator_0

create_bd_port -dir I tp_halt
connect_bd_net [get_bd_pins /packet_processor_0/tp_halt] [get_bd_ports tp_halt]

# create clock and reset paths

create_bd_port -dir I -type clk clk
connect_bd_net [get_bd_pins /packet_processor_0/tp_clk] [get_bd_ports clk]
connect_bd_net [get_bd_pins /packet_processor_0/cmd_axi_aclk] [get_bd_ports clk]
connect_bd_net [get_bd_pins /packet_processor_0/data_axi_aclk] [get_bd_ports clk]
create_bd_port -dir I -type rst rstn
connect_bd_net [get_bd_pins /packet_processor_0/tp_rstn] [get_bd_ports rstn]
connect_bd_net [get_bd_pins /packet_processor_0/cmd_axi_aresetn] [get_bd_ports rstn]
connect_bd_net [get_bd_pins /packet_processor_0/data_axi_aresetn] [get_bd_ports rstn]
connect_bd_net [get_bd_ports clk] [get_bd_pins axi_interconnect_0/ACLK]
connect_bd_net [get_bd_ports rstn] [get_bd_pins axi_interconnect_0/ARESETN]
connect_bd_net [get_bd_ports clk] [get_bd_pins axi_interconnect_0/S00_ACLK]
connect_bd_net [get_bd_ports rstn] [get_bd_pins axi_interconnect_0/S00_ARESETN]
connect_bd_net [get_bd_ports clk] [get_bd_pins axi_interconnect_0/M00_ACLK]
connect_bd_net [get_bd_ports rstn] [get_bd_pins axi_interconnect_0/M00_ARESETN]
connect_bd_net [get_bd_ports clk] [get_bd_pins axi_interconnect_0/M01_ACLK]
connect_bd_net [get_bd_ports rstn] [get_bd_pins axi_interconnect_0/M01_ARESETN]
connect_bd_net [get_bd_ports clk] [get_bd_pins axi_interconnect_1/ACLK]
connect_bd_net [get_bd_ports rstn] [get_bd_pins axi_interconnect_1/ARESETN]
connect_bd_net [get_bd_ports clk] [get_bd_pins axi_interconnect_1/S00_ACLK]
connect_bd_net [get_bd_ports rstn] [get_bd_pins axi_interconnect_1/S00_ARESETN]
connect_bd_net [get_bd_ports clk] [get_bd_pins axi_interconnect_1/S01_ACLK]
connect_bd_net [get_bd_ports rstn] [get_bd_pins axi_interconnect_1/S01_ARESETN]
connect_bd_net [get_bd_ports clk] [get_bd_pins axi_interconnect_1/M00_ACLK]
connect_bd_net [get_bd_ports rstn] [get_bd_pins axi_interconnect_1/M00_ARESETN]
connect_bd_net [get_bd_ports clk] [get_bd_pins /image_accelerator_0/clk]
connect_bd_net [get_bd_ports rstn] [get_bd_pins /image_accelerator_0/rstn]

# create interrupt signal paths

create_bd_port -dir I -type intr rcv_aql_irq
create_bd_port -dir I -type intr rcv_dma_irq
create_bd_port -dir I -type intr rcv_cpl_irq
create_bd_port -dir I -type intr rcv_add_irq
create_bd_port -dir I -type intr rcv_rem_irq
create_bd_port -dir O -type intr rcv_aql_irq_ack
create_bd_port -dir O -type intr rcv_dma_irq_ack
create_bd_port -dir O -type intr rcv_cpl_irq_ack
create_bd_port -dir O -type intr rcv_add_irq_ack
create_bd_port -dir O -type intr rcv_rem_irq_ack
create_bd_port -dir O -type intr snd_dma_irq
create_bd_port -dir O -type intr snd_cpl_irq
create_bd_port -dir O -type intr snd_add_irq
create_bd_port -dir O -type intr snd_rem_irq
create_bd_port -dir I -type intr snd_dma_irq_ack
create_bd_port -dir I -type intr snd_cpl_irq_ack
create_bd_port -dir I -type intr snd_add_irq_ack
create_bd_port -dir I -type intr snd_rem_irq_ack
connect_bd_net [get_bd_pins /packet_processor_0/rcv_aql_irq] [get_bd_ports rcv_aql_irq]
connect_bd_net [get_bd_pins /packet_processor_0/rcv_dma_irq] [get_bd_ports rcv_dma_irq]
connect_bd_net [get_bd_pins /packet_processor_0/rcv_cpl_irq] [get_bd_ports rcv_cpl_irq]
connect_bd_net [get_bd_pins /packet_processor_0/rcv_add_irq] [get_bd_ports rcv_add_irq]
connect_bd_net [get_bd_pins /packet_processor_0/rcv_rem_irq] [get_bd_ports rcv_rem_irq]
connect_bd_net [get_bd_pins /packet_processor_0/rcv_aql_irq_ack] [get_bd_ports rcv_aql_irq_ack]
connect_bd_net [get_bd_pins /packet_processor_0/rcv_dma_irq_ack] [get_bd_ports rcv_dma_irq_ack]
connect_bd_net [get_bd_pins /packet_processor_0/rcv_cpl_irq_ack] [get_bd_ports rcv_cpl_irq_ack]
connect_bd_net [get_bd_pins /packet_processor_0/rcv_add_irq_ack] [get_bd_ports rcv_add_irq_ack]
connect_bd_net [get_bd_pins /packet_processor_0/rcv_rem_irq_ack] [get_bd_ports rcv_rem_irq_ack]
connect_bd_net [get_bd_pins /packet_processor_0/snd_dma_irq] [get_bd_ports snd_dma_irq]
connect_bd_net [get_bd_pins /packet_processor_0/snd_cpl_irq] [get_bd_ports snd_cpl_irq]
connect_bd_net [get_bd_pins /packet_processor_0/snd_add_irq] [get_bd_ports snd_add_irq]
connect_bd_net [get_bd_pins /packet_processor_0/snd_rem_irq] [get_bd_ports snd_rem_irq]
connect_bd_net [get_bd_pins /packet_processor_0/snd_dma_irq_ack] [get_bd_ports snd_dma_irq_ack]
connect_bd_net [get_bd_pins /packet_processor_0/snd_cpl_irq_ack] [get_bd_ports snd_cpl_irq_ack]
connect_bd_net [get_bd_pins /packet_processor_0/snd_add_irq_ack] [get_bd_ports snd_add_irq_ack]
connect_bd_net [get_bd_pins /packet_processor_0/snd_rem_irq_ack] [get_bd_ports snd_rem_irq_ack]

connect_bd_net [get_bd_pins packet_processor_0/snd_acc_irq_lanes] [get_bd_pins image_accelerator_0/start_irq]
connect_bd_net [get_bd_pins packet_processor_0/rcv_acc_irq_lanes_ack] [get_bd_pins image_accelerator_0/finished_irq_ack]
connect_bd_net [get_bd_pins packet_processor_0/rcv_acc_irq_lanes] [get_bd_pins image_accelerator_0/finished_irq]
connect_bd_net [get_bd_pins packet_processor_0/snd_acc_irq_lanes_ack] [get_bd_pins image_accelerator_0/start_irq_ack]

# connect AXI busses

connect_bd_intf_net [get_bd_intf_pins packet_processor_0/cmd_axi] -boundary_type upper [get_bd_intf_pins axi_interconnect_0/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins packet_processor_0/data_axi] -boundary_type upper [get_bd_intf_pins axi_interconnect_1/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins image_accelerator_0/M_AXI] -boundary_type upper [get_bd_intf_pins axi_interconnect_1/S01_AXI]
connect_bd_intf_net [get_bd_intf_pins image_accelerator_0/S_AXI] -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M01_AXI]

create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_DATA_AXI
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_CMD_AXI
set_property CONFIG.ADDR_WIDTH 64 [get_bd_intf_ports M_DATA_AXI]
set_property CONFIG.DATA_WIDTH 512 [get_bd_intf_ports M_DATA_AXI]
set_property CONFIG.ADDR_WIDTH 64 [get_bd_intf_ports M_CMD_AXI]
set_property CONFIG.DATA_WIDTH 64 [get_bd_intf_ports M_CMD_AXI]
set_property -dict [list CONFIG.NUM_READ_OUTSTANDING [get_property CONFIG.NUM_READ_OUTSTANDING [get_bd_intf_pins axi_interconnect_1/xbar/M00_AXI]]] [get_bd_intf_ports M_DATA_AXI]
set_property -dict [list CONFIG.NUM_WRITE_OUTSTANDING [get_property CONFIG.NUM_WRITE_OUTSTANDING [get_bd_intf_pins axi_interconnect_1/xbar/M00_AXI]]] [get_bd_intf_ports M_DATA_AXI]
set_property -dict [list CONFIG.NUM_READ_OUTSTANDING [get_property CONFIG.NUM_READ_OUTSTANDING [get_bd_intf_pins axi_interconnect_0/xbar/M00_AXI]]] [get_bd_intf_ports M_CMD_AXI]
set_property -dict [list CONFIG.NUM_WRITE_OUTSTANDING [get_property CONFIG.NUM_WRITE_OUTSTANDING [get_bd_intf_pins axi_interconnect_0/xbar/M00_AXI]]] [get_bd_intf_ports M_CMD_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_1/M00_AXI] [get_bd_intf_ports M_DATA_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/M00_AXI] [get_bd_intf_ports M_CMD_AXI]

# assign address spaces

assign_bd_address [get_bd_addr_segs {M_CMD_AXI/Reg }]
set_property range 4K [get_bd_addr_segs {packet_processor_0/cmd_axi/SEG_M_CMD_AXI_Reg}]
set_property offset 0x0002000000000000 [get_bd_addr_segs {packet_processor_0/cmd_axi/SEG_M_CMD_AXI_Reg}]
assign_bd_address [get_bd_addr_segs {image_accelerator_0/S_AXI/reg0 }]
set_property range 4K [get_bd_addr_segs {packet_processor_0/cmd_axi/SEG_image_accelerator_0_reg0}]
set_property offset 0x0002000000001000 [get_bd_addr_segs {packet_processor_0/cmd_axi/SEG_image_accelerator_0_reg0}]
assign_bd_address [get_bd_addr_segs {M_DATA_AXI/Reg }]
set_property offset 0x0001000000000000 [get_bd_addr_segs {packet_processor_0/data_axi/SEG_M_DATA_AXI_Reg}]
set_property range 4G [get_bd_addr_segs {packet_processor_0/data_axi/SEG_M_DATA_AXI_Reg}]
set_property offset 0x0001000000000000 [get_bd_addr_segs {image_accelerator_0/M_AXI/SEG_M_DATA_AXI_Reg}]
set_property range 4G [get_bd_addr_segs {image_accelerator_0/M_AXI/SEG_M_DATA_AXI_Reg}]

# package project

ipx::package_project -force -library hsa -taxonomy /UserIP -module accelerator_backend -import_files -vendor {fau.de} -taxonomy {/HSA} -root_dir "[get_property DIRECTORY [current_project]]/ip"
set_property core_revision 1 [ipx::current_core]
ipx::remove_bus_parameter FREQ_HZ [ipx::get_bus_interfaces CLK.CLK -of_objects [ipx::current_core]]
ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::save_core [ipx::current_core]

