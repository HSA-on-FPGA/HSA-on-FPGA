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

set script_dir "[file dirname "[file normalize "[info script]"]"]"
source  "${script_dir}/../board_config.tcl"

# cleanup previous mess if exists
close_project -quiet
file delete -force "$script_dir/build"


##################################
# General Project Settings 
#

# create project
set proj_obj [create_project "image_accelerator" "$script_dir/build"]
set_property "target_language" "VHDL" $proj_obj

# set target board
set_property "part" "${PART_NAME}" $proj_obj
if {[info exists BOARD_NAME]} {
	set_property "board_part" "${BOARD_NAME}" $proj_obj
}

# enable xmp libraries (for virtex ultrascale)
set_property "XPM_LIBRARIES" {XPM_CDC XPM_MEMORY XPM_FIFO} $proj_obj

# add external ip libraries
set_property "ip_repo_paths" {\
    "../LibHSA/"\
    "HSA-Accelerator/build/ip"\
} $proj_obj
update_ip_catalog


##################################
# Design 
#

# add blockdesign
source "image_accelerator.tcl"

# set toplevel entity
set_property "top" "image_accelerator_wrapper" [get_filesets sources_1]
update_compile_order -fileset sources_1


##################################
# Simulation 
#

# add files
#add_files "sim_top.vhd" -fileset sim_1

# set top
#set_property "top" "sim_top" [get_filesets sim_1]
#update_compile_order -fileset sim_1

# set simulation config
#add_files "simulation.wcfg" -fileset sim_1
#set_property "xsim.view" "simulation.wcfg" [get_filesets sim_1]


##################################
# IP Creation
#

source "ip.tcl"
