###############################################################################
# Copyright (C) 2021 Xilinx, Inc
# SPDX-License-Identifier: BSD-3-Clause
###############################################################################

###############################################################################
#
#
# @file bdc_dfx.tcl
#
# Vivado tcl script to generate block design containers and DFX regions
#
# <pre>
# MODIFICATION HISTORY:
#
# Ver   Who  Date       Changes
# ----- --- -------- -----------------------------------------------
#
# 1.00a mr   04/11/2022 File created, 4 BDC and corresponding DFX
#
# </pre>
#
###############################################################################


# Set clock and reset names
set family [get_property FAMILY [get_parts [get_property PART_NAME [current_board_part]]]]
if {${family} == "zynq"} {
   set mem_type "auto"
   set dfx_clk "clk_142M"
   set dfx_rst "periph_resetn_clk142M"
} else {
   set mem_type "ultra"
   set dfx_clk "clk_300MHz"
   set dfx_rst "clk_300MHz_aresetn"
}

##################################################################
# PR 0 Block Design Container and DFX Regions
##################################################################
set pr_0_dilate_erode "composable_pr_0_dilate_erode"

set curdesign [current_bd_design]
create_bd_design -cell [get_bd_cells /composable/pr_0] ${pr_0_dilate_erode}
current_bd_design $curdesign
set new_cell [create_bd_cell -type container -reference ${pr_0_dilate_erode} composable/pr_0_temp]
replace_bd_cell [get_bd_cells /composable/pr_0] $new_cell
delete_bd_objs  [get_bd_cells /composable/pr_0]
set_property name pr_0 $new_cell

current_bd_design [get_bd_designs ${pr_0_dilate_erode}]
validate_bd_design
save_bd_design
current_bd_design [get_bd_designs ${design_name}]
validate_bd_design
save_bd_design

## Freeze boundaries
set_property -dict [list CONFIG.LOCK_PROPAGATE {true}] [get_bd_cells composable/pr_0]
## Enable DFX
set_property -dict [list CONFIG.ENABLE_DFX {true}] [get_bd_cells composable/pr_0]



## PR 0 reconfigurable module 1
set pr_0_fast_fifo "composable_pr_0_fast_fifo"
set curdesign [current_bd_design]
create_bd_design -boundary_from_container [get_bd_cells /composable/pr_0] ${pr_0_fast_fifo}
current_bd_design $curdesign
current_bd_design [get_bd_designs ${pr_0_fast_fifo}]

set asr [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_register_slice:2.1 asr ]
create_bd_cell -type ip -vlnv xilinx.com:hls:fast_accel:1.0 fast_accel
set axis_data_fifo_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 axis_data_fifo_0 ]
set_property -dict [list \
  CONFIG.TDATA_NUM_BYTES {3} \
  CONFIG.TUSER_WIDTH {1} \
  CONFIG.FIFO_DEPTH {4096} \
  CONFIG.HAS_TLAST {1} \
  CONFIG.FIFO_MEMORY_TYPE ${mem_type} \
] ${axis_data_fifo_0}

connect_bd_intf_net [get_bd_intf_ports s_axi_control] [get_bd_intf_pins asr/S_AXI]
connect_bd_intf_net [get_bd_intf_pins asr/M_AXI] [get_bd_intf_pins fast_accel/s_axi_control]
connect_bd_intf_net [get_bd_intf_ports stream_in0] [get_bd_intf_pins fast_accel/stream_in]
connect_bd_intf_net [get_bd_intf_ports stream_out0] [get_bd_intf_pins fast_accel/stream_out]
connect_bd_net [get_bd_ports ${dfx_clk}] [get_bd_pins fast_accel/ap_clk] [get_bd_pins axis_data_fifo_0/s_axis_aclk] [get_bd_pins asr/aclk]
connect_bd_net [get_bd_ports ${dfx_rst}] [get_bd_pins fast_accel/ap_rst_n] [get_bd_pins axis_data_fifo_0/s_axis_aresetn] [get_bd_pins asr/aresetn]
connect_bd_intf_net [get_bd_intf_ports stream_in1] [get_bd_intf_pins axis_data_fifo_0/S_AXIS]
connect_bd_intf_net [get_bd_intf_ports stream_out1] [get_bd_intf_pins axis_data_fifo_0/M_AXIS]
assign_bd_address
set_property range 32K [get_bd_addr_segs {s_axi_control/SEG_fast_accel_Reg}]
validate_bd_design
save_bd_design
current_bd_design [get_bd_designs ${design_name}]
validate_bd_design
save_bd_design


## PR 0 reconfigurable module 2
set pr_0_filter2d_fifo "composable_pr_0_filter2d_fifo"
set curdesign [current_bd_design]
create_bd_design -boundary_from_container [get_bd_cells /composable/pr_0] ${pr_0_filter2d_fifo}
current_bd_design $curdesign
current_bd_design [get_bd_designs ${pr_0_filter2d_fifo}]

create_bd_cell -type ip -vlnv xilinx.com:hls:filter2d_accel:1.0 filter2d_accel
set asr [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_register_slice:2.1 asr ]
set axis_data_fifo_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 axis_data_fifo_0 ]
set_property -dict [list \
  CONFIG.TDATA_NUM_BYTES {3} \
  CONFIG.TUSER_WIDTH {1} \
  CONFIG.FIFO_DEPTH {4096} \
  CONFIG.HAS_TLAST {1} \
  CONFIG.FIFO_MEMORY_TYPE ${mem_type} \
] ${axis_data_fifo_0}

connect_bd_intf_net [get_bd_intf_ports s_axi_control] [get_bd_intf_pins asr/S_AXI]
connect_bd_intf_net [get_bd_intf_pins asr/M_AXI] [get_bd_intf_pins filter2d_accel/s_axi_control]
connect_bd_intf_net [get_bd_intf_ports stream_in0] [get_bd_intf_pins filter2d_accel/stream_in]
connect_bd_intf_net [get_bd_intf_ports stream_out0] [get_bd_intf_pins filter2d_accel/stream_out]
connect_bd_net [get_bd_ports ${dfx_clk}] [get_bd_pins filter2d_accel/ap_clk] [get_bd_pins axis_data_fifo_0/s_axis_aclk] [get_bd_pins asr/aclk]
connect_bd_net [get_bd_ports ${dfx_rst}] [get_bd_pins filter2d_accel/ap_rst_n] [get_bd_pins axis_data_fifo_0/s_axis_aresetn] [get_bd_pins asr/aresetn]
connect_bd_intf_net [get_bd_intf_ports stream_in1] [get_bd_intf_pins axis_data_fifo_0/S_AXIS]
connect_bd_intf_net [get_bd_intf_ports stream_out1] [get_bd_intf_pins axis_data_fifo_0/M_AXIS]
assign_bd_address
set_property range 32K [get_bd_addr_segs {s_axi_control/SEG_filter2d_accel_Reg}]
validate_bd_design
save_bd_design

current_bd_design [get_bd_designs ${design_name}]
# Define synthesis sources
set list_rm "${pr_0_dilate_erode} ${pr_0_fast_fifo} ${pr_0_filter2d_fifo}"
set bds "${pr_0_dilate_erode}.bd:${pr_0_fast_fifo}.bd:${pr_0_filter2d_fifo}.bd"
set_property -dict [list CONFIG.LIST_SYNTH_BD ${bds}] [get_bd_cells /composable/pr_0]
validate_bd_design
update_compile_order -fileset sources_1


##################################################################
# PR 1 Block Design Container and DFX Regions
##################################################################
set pr_1_dilate_erode "composable_pr_1_dilate_erode"

set curdesign [current_bd_design]
create_bd_design -cell [get_bd_cells /composable/pr_1] ${pr_1_dilate_erode}
current_bd_design $curdesign
set new_cell [create_bd_cell -type container -reference ${pr_1_dilate_erode} composable/pr_1_temp]
replace_bd_cell [get_bd_cells /composable/pr_1] $new_cell
delete_bd_objs  [get_bd_cells /composable/pr_1]
set_property name pr_1 $new_cell

current_bd_design [get_bd_designs ${pr_1_dilate_erode}]
validate_bd_design
save_bd_design
current_bd_design [get_bd_designs ${design_name}]
validate_bd_design
save_bd_design

## Freeze boundaries
set_property -dict [list CONFIG.LOCK_PROPAGATE {true}] [get_bd_cells composable/pr_1]
## Enable DFX
set_property -dict [list CONFIG.ENABLE_DFX {true}] [get_bd_cells composable/pr_1]


## PR 1 reconfigurable module 1
set pr_1_cornerharris "composable_pr_1_cornerharris_fifo"
set curdesign [current_bd_design]
create_bd_design -boundary_from_container [get_bd_cells /composable/pr_1] ${pr_1_cornerharris}
current_bd_design $curdesign
current_bd_design [get_bd_designs ${pr_1_cornerharris}]

set asr [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_register_slice:2.1 asr ]
create_bd_cell -type ip -vlnv xilinx.com:hls:cornerHarris_accel:1.0 cornerHarris_accel
set axis_data_fifo_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 axis_data_fifo_0 ]
set_property -dict [list \
  CONFIG.TDATA_NUM_BYTES {3} \
  CONFIG.TUSER_WIDTH {1} \
  CONFIG.FIFO_DEPTH {4096} \
  CONFIG.HAS_TLAST {1} \
  CONFIG.FIFO_MEMORY_TYPE {auto} \
] ${axis_data_fifo_0}

connect_bd_intf_net [get_bd_intf_ports s_axi_control] [get_bd_intf_pins asr/S_AXI]
connect_bd_intf_net [get_bd_intf_pins asr/M_AXI] [get_bd_intf_pins cornerHarris_accel/s_axi_control]
connect_bd_intf_net [get_bd_intf_ports stream_in0] [get_bd_intf_pins cornerHarris_accel/stream_in]
connect_bd_intf_net [get_bd_intf_ports stream_out0] [get_bd_intf_pins cornerHarris_accel/stream_out]
connect_bd_net [get_bd_ports ${dfx_clk}] [get_bd_pins cornerHarris_accel/ap_clk] [get_bd_pins axis_data_fifo_0/s_axis_aclk] [get_bd_pins asr/aclk]
connect_bd_net [get_bd_ports ${dfx_rst}] [get_bd_pins cornerHarris_accel/ap_rst_n] [get_bd_pins axis_data_fifo_0/s_axis_aresetn] [get_bd_pins asr/aresetn]
connect_bd_intf_net [get_bd_intf_ports stream_in1] [get_bd_intf_pins axis_data_fifo_0/S_AXIS]
connect_bd_intf_net [get_bd_intf_ports stream_out1] [get_bd_intf_pins axis_data_fifo_0/M_AXIS]
assign_bd_address
set_property range 32K [get_bd_addr_segs {s_axi_control/SEG_cornerHarris_accel_Reg}]
validate_bd_design
save_bd_design
current_bd_design [get_bd_designs ${design_name}]

# Define synthesis sources
lappend list_rm ${pr_1_dilate_erode} ${pr_1_cornerharris}
set bds "${pr_1_dilate_erode}.bd:${pr_1_cornerharris}.bd"
set_property -dict [list CONFIG.LIST_SYNTH_BD ${bds}] [get_bd_cells /composable/pr_1]
validate_bd_design
save_bd_design
update_compile_order -fileset sources_1



##################################################################
# PR Join Block Design Container and DFX Regions
##################################################################
set pr_join_subtract "composable_pr_join_subtract"
set curdesign [current_bd_design]
create_bd_design -cell [get_bd_cells /composable/pr_join] ${pr_join_subtract}
current_bd_design $curdesign
set new_cell [create_bd_cell -type container -reference ${pr_join_subtract} composable/pr_join_temp]
replace_bd_cell [get_bd_cells /composable/pr_join] $new_cell
delete_bd_objs  [get_bd_cells /composable/pr_join]
set_property name pr_join $new_cell

current_bd_design [get_bd_designs ${pr_join_subtract}]
validate_bd_design
save_bd_design
current_bd_design [get_bd_designs ${design_name}]
validate_bd_design
save_bd_design

## Freeze boundaries
set_property -dict [list CONFIG.LOCK_PROPAGATE {true}] [get_bd_cells composable/pr_join]
## Enable DFX
set_property -dict [list CONFIG.ENABLE_DFX {true}] [get_bd_cells composable/pr_join]


## PR Join reconfigurable module 1
set pr_join_absdiff "composable_pr_join_absdiff"
set curdesign [current_bd_design]
create_bd_design -boundary_from_container [get_bd_cells /composable/pr_join] ${pr_join_absdiff}
current_bd_design $curdesign
current_bd_design [get_bd_designs ${pr_join_absdiff}]

set asr [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_register_slice:2.1 asr ]
create_bd_cell -type ip -vlnv xilinx.com:hls:absdiff_accel:1.0 absdiff_accel

connect_bd_intf_net [get_bd_intf_ports s_axi_control] [get_bd_intf_pins asr/S_AXI]
connect_bd_intf_net [get_bd_intf_pins asr/M_AXI] [get_bd_intf_pins absdiff_accel/s_axi_control]
connect_bd_intf_net [get_bd_intf_ports stream_in0] [get_bd_intf_pins absdiff_accel/stream_in]
connect_bd_intf_net [get_bd_intf_ports stream_out] [get_bd_intf_pins absdiff_accel/stream_out]
connect_bd_net [get_bd_ports ${dfx_clk}] [get_bd_pins absdiff_accel/ap_clk] [get_bd_pins asr/aclk]
connect_bd_net [get_bd_ports ${dfx_rst}] [get_bd_pins absdiff_accel/ap_rst_n] [get_bd_pins asr/aresetn]
assign_bd_address

validate_bd_design
save_bd_design
current_bd_design [get_bd_designs ${design_name}]
validate_bd_design
save_bd_design


## PR Join reconfigurable module 2
set pr_join_add "composable_pr_join_add"
set curdesign [current_bd_design]
create_bd_design -boundary_from_container [get_bd_cells /composable/pr_join] ${pr_join_add}
current_bd_design $curdesign
current_bd_design [get_bd_designs ${pr_join_add}]

set asr [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_register_slice:2.1 asr ]
create_bd_cell -type ip -vlnv xilinx.com:hls:add_accel:1.0 add_accel

connect_bd_intf_net [get_bd_intf_ports s_axi_control] [get_bd_intf_pins asr/S_AXI]
connect_bd_intf_net [get_bd_intf_pins asr/M_AXI] [get_bd_intf_pins add_accel/s_axi_control]
connect_bd_intf_net [get_bd_intf_ports stream_in0] [get_bd_intf_pins add_accel/stream_in]
connect_bd_intf_net [get_bd_intf_ports stream_out] [get_bd_intf_pins add_accel/stream_out]
connect_bd_net [get_bd_ports ${dfx_clk}] [get_bd_pins add_accel/ap_clk] [get_bd_pins asr/aclk]
connect_bd_net [get_bd_ports ${dfx_rst}] [get_bd_pins add_accel/ap_rst_n] [get_bd_pins asr/aresetn]
assign_bd_address

validate_bd_design
save_bd_design
current_bd_design [get_bd_designs ${design_name}]
validate_bd_design
save_bd_design


## PR Join reconfigurable module 3
set pr_join_bitand "composable_pr_join_bitand"
set curdesign [current_bd_design]
create_bd_design -boundary_from_container [get_bd_cells /composable/pr_join] ${pr_join_bitand}
current_bd_design $curdesign
current_bd_design [get_bd_designs ${pr_join_bitand}]

set asr [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_register_slice:2.1 asr ]
create_bd_cell -type ip -vlnv xilinx.com:hls:bitwise_and_accel:1.0 bitwise_and_accel

connect_bd_intf_net [get_bd_intf_ports s_axi_control] [get_bd_intf_pins asr/S_AXI]
connect_bd_intf_net [get_bd_intf_pins asr/M_AXI] [get_bd_intf_pins bitwise_and_accel/s_axi_control]
connect_bd_intf_net [get_bd_intf_ports stream_in0] [get_bd_intf_pins bitwise_and_accel/stream_in]
connect_bd_intf_net [get_bd_intf_ports stream_out] [get_bd_intf_pins bitwise_and_accel/stream_out]
connect_bd_net [get_bd_ports ${dfx_clk}] [get_bd_pins bitwise_and_accel/ap_clk] [get_bd_pins asr/aclk]
connect_bd_net [get_bd_ports ${dfx_rst}] [get_bd_pins bitwise_and_accel/ap_rst_n] [get_bd_pins asr/aresetn]
assign_bd_address

validate_bd_design
save_bd_design

current_bd_design [get_bd_designs ${design_name}]
# Define synthesis sources
lappend list_rm ${pr_join_subtract} ${pr_join_absdiff} ${pr_join_add} ${pr_join_bitand}
set bds "${pr_join_subtract}.bd:${pr_join_absdiff}.bd:${pr_join_add}.bd:${pr_join_bitand}.bd"
set_property -dict [list CONFIG.LIST_SYNTH_BD ${bds}] [get_bd_cells /composable/pr_join]
validate_bd_design
save_bd_design
update_compile_order -fileset sources_1


##################################################################
# PR Fork Block Design Container and DFX Regions
##################################################################
set pr_fork_duplicate "composable_pr_fork_duplicate"
set curdesign [current_bd_design]
create_bd_design -cell [get_bd_cells /composable/pr_fork] ${pr_fork_duplicate}
current_bd_design $curdesign
set new_cell [create_bd_cell -type container -reference ${pr_fork_duplicate} composable/pr_fork_temp]
replace_bd_cell [get_bd_cells /composable/pr_fork] $new_cell
delete_bd_objs  [get_bd_cells /composable/pr_fork]
set_property name pr_fork $new_cell

current_bd_design [get_bd_designs ${pr_fork_duplicate}]
validate_bd_design
save_bd_design
current_bd_design [get_bd_designs ${design_name}]
validate_bd_design
save_bd_design

## Freeze boundaries
set_property -dict [list CONFIG.LOCK_PROPAGATE {true}] [get_bd_cells composable/pr_fork]
## Enable DFX
set_property -dict [list CONFIG.ENABLE_DFX {true}] [get_bd_cells composable/pr_fork]


## PR Fork reconfigurable module 1
set pr_fork_rgb2xyz "composable_pr_fork_rgb2xyz"
set curdesign [current_bd_design]
create_bd_design -boundary_from_container [get_bd_cells /composable/pr_fork] ${pr_fork_rgb2xyz}
current_bd_design $curdesign
current_bd_design [get_bd_designs ${pr_fork_rgb2xyz}]

set asr [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_register_slice:2.1 asr ]
create_bd_cell -type ip -vlnv xilinx.com:hls:rgb2xyz_accel:1.0 rgb2xyz_accel

connect_bd_intf_net [get_bd_intf_ports s_axi_control] [get_bd_intf_pins asr/S_AXI]
connect_bd_intf_net [get_bd_intf_pins asr/M_AXI] [get_bd_intf_pins rgb2xyz_accel/s_axi_control]
connect_bd_intf_net [get_bd_intf_ports stream_in] [get_bd_intf_pins rgb2xyz_accel/stream_in]
connect_bd_intf_net [get_bd_intf_ports stream_out0] [get_bd_intf_pins rgb2xyz_accel/stream_out]
connect_bd_net [get_bd_ports ${dfx_clk}] [get_bd_pins rgb2xyz_accel/ap_clk] [get_bd_pins asr/aclk]
connect_bd_net [get_bd_ports ${dfx_rst}] [get_bd_pins rgb2xyz_accel/ap_rst_n] [get_bd_pins asr/aresetn]
assign_bd_address

validate_bd_design
save_bd_design
current_bd_design [get_bd_designs ${design_name}]

# Define synthesis sources
lappend list_rm ${pr_fork_duplicate} ${pr_fork_rgb2xyz}
set bds "${pr_fork_duplicate}.bd:${pr_fork_rgb2xyz}.bd"
set_property -dict [list CONFIG.LIST_SYNTH_BD ${bds}] [get_bd_cells /composable/pr_fork]
validate_bd_design
save_bd_design
update_compile_order -fileset sources_1


# Save top-level and validate bd design
current_bd_design [get_bd_designs ${design_name}]
save_bd_design
validate_bd_design

# Generate output products
generate_target all [get_files  ./${prj_name}/${prj_name}.srcs/sources_1/bd/${design_name}/${design_name}.bd]

# Make a wrapper file and add it
make_wrapper -files [get_files ./${prj_name}/${prj_name}.srcs/sources_1/bd/${design_name}/${design_name}.bd] -top
add_files -norecurse ./${prj_name}/${prj_name}.srcs/sources_1/bd/${design_name}/hdl/${design_name}_wrapper.v
set_property top ${design_name}_wrapper [current_fileset]
update_compile_order -fileset sources_1

# Create configurations and run the implementation
create_pr_configuration -name config_1 -partitions \
   [list \
      video_cp_i/composable/pr_0:${pr_0_dilate_erode}_inst_0 \
      video_cp_i/composable/pr_1:${pr_1_dilate_erode}_inst_0 \
      video_cp_i/composable/pr_fork:${pr_fork_duplicate}_inst_0 \
      video_cp_i/composable/pr_join:${pr_join_subtract}_inst_0\
   ]

create_pr_configuration -name config_2 -partitions \
   [list \
      video_cp_i/composable/pr_0:${pr_0_fast_fifo}_inst_0 \
      video_cp_i/composable/pr_1:${pr_1_cornerharris}_inst_0 \
      video_cp_i/composable/pr_fork:${pr_fork_rgb2xyz}_inst_0 \
      video_cp_i/composable/pr_join:${pr_join_absdiff}_inst_0\
   ]

create_pr_configuration -name config_3 -partitions \
   [list \
      video_cp_i/composable/pr_0:${pr_0_filter2d_fifo}_inst_0 \
      video_cp_i/composable/pr_join:${pr_join_add}_inst_0\
   ] -greyboxes [list \
      video_cp_i/composable/pr_1 \
      video_cp_i/composable/pr_fork\
   ]

create_pr_configuration -name config_4 -partitions \
   [list \
      video_cp_i/composable/pr_join:${pr_join_bitand}_inst_0 \
   ] -greyboxes [list \
      video_cp_i/composable/pr_0 \
      video_cp_i/composable/pr_1 \
      video_cp_i/composable/pr_fork\
   ]

set_property PR_CONFIGURATION config_1 [get_runs impl_1]
create_run child_0_impl_1 -parent_run impl_1 -flow {Vivado Implementation 2022} -strategy Performance_NetDelay_low -pr_config config_2
create_run child_1_impl_1 -parent_run impl_1 -flow {Vivado Implementation 2022} -strategy Performance_NetDelay_low -pr_config config_3
create_run child_2_impl_1 -parent_run impl_1 -flow {Vivado Implementation 2022} -strategy Performance_NetDelay_low -pr_config config_4

# Change global implementation strategy
set_property strategy Performance_Explore [get_runs impl_1]
set_property report_strategy {UltraFast Design Methodology Reports} [get_runs impl_1]

launch_runs impl_1 -to_step write_bitstream -jobs 16
wait_on_run impl_1
launch_runs child_0_impl_1 -to_step write_bitstream -jobs 16
wait_on_run child_0_impl_1
launch_runs child_1_impl_1 child_2_impl_1 -to_step write_bitstream -jobs 16
wait_on_run child_1_impl_1
wait_on_run child_2_impl_1

# create bitstreams directory
set dest_dir "./overlay"
exec mkdir $dest_dir -p
set bithier "${design_name}_i_composable"

# Copy DFX regions hwh files
foreach pr ${list_rm} {
   catch {exec cp ./${prj_name}/${prj_name}.gen/sources_1/bd/${design_name}/bd/${pr}_inst_0/hw_handoff/${pr}_inst_0.hwh ${dest_dir}/${prj_name}_${pr}_partial.hwh}
}
catch {exec cp ./${prj_name}/${prj_name}.gen/sources_1/bd/$design_name/hw_handoff/$design_name.hwh ./${dest_dir}/${prj_name}.hwh}

# copy bitstreams
# impl1 having full and partial bitstreams
catch {exec cp ./${prj_name}/${prj_name}.runs/impl_1/${bithier}_pr_0_${pr_0_dilate_erode}_inst_0_partial.bit ./${dest_dir}/${prj_name}_${pr_0_dilate_erode}_partial.bit}
catch {exec cp ./${prj_name}/${prj_name}.runs/impl_1/${bithier}_pr_join_${pr_join_subtract}_inst_0_partial.bit ./${dest_dir}/${prj_name}_${pr_join_subtract}_partial.bit}
catch {exec cp ./${prj_name}/${prj_name}.runs/impl_1/${bithier}_pr_fork_${pr_fork_duplicate}_inst_0_partial.bit ./${dest_dir}/${prj_name}_${pr_fork_duplicate}_partial.bit}
catch {exec cp ./${prj_name}/${prj_name}.runs/impl_1/${bithier}_pr_1_${pr_1_dilate_erode}_inst_0_partial.bit ./${dest_dir}/${prj_name}_${pr_1_dilate_erode}_partial.bit}
catch {exec cp ./${prj_name}/${prj_name}.runs/impl_1/video_cp_wrapper.bit ./${dest_dir}/${prj_name}.bit}
# child_0_impl_1
catch {exec cp ./${prj_name}/${prj_name}.runs/child_0_impl_1/${bithier}_pr_0_${pr_0_fast_fifo}_inst_0_partial.bit ./${dest_dir}/${prj_name}_${pr_0_fast_fifo}_partial.bit}
catch {exec cp ./${prj_name}/${prj_name}.runs/child_0_impl_1/${bithier}_pr_1_${pr_1_cornerharris}_inst_0_partial.bit ./${dest_dir}/${prj_name}_${pr_1_cornerharris}_partial.bit}
catch {exec cp ./${prj_name}/${prj_name}.runs/child_0_impl_1/${bithier}_pr_join_${pr_join_absdiff}_inst_0_partial.bit ./${dest_dir}/${prj_name}_${pr_join_absdiff}_partial.bit}
catch {exec cp ./${prj_name}/${prj_name}.runs/child_0_impl_1/${bithier}_pr_fork_${pr_fork_rgb2xyz}_inst_0_partial.bit ./${dest_dir}/${prj_name}_${pr_fork_rgb2xyz}_partial.bit}
# child_1_impl_1
catch {exec cp ./${prj_name}/${prj_name}.runs/child_1_impl_1/${bithier}_pr_0_${pr_0_filter2d_fifo}_inst_0_partial.bit ./${dest_dir}/${prj_name}_${pr_0_filter2d_fifo}_partial.bit}
catch {exec cp ./${prj_name}/${prj_name}.runs/child_1_impl_1/${bithier}_pr_join_${pr_join_add}_inst_0_partial.bit ./${dest_dir}/${prj_name}_${pr_join_add}_partial.bit}
# child_2_impl_1
catch {exec cp ./${prj_name}/${prj_name}.runs/child_2_impl_1/${bithier}_pr_join_${pr_join_bitand}_inst_0_partial.bit ./${dest_dir}/${prj_name}_${pr_join_bitand}_partial.bit}