# SPDX-FileCopyrightText: 2020 Efabless Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# SPDX-License-Identifier: Apache-2.0

set script_dir [file dirname [file normalize [info script]]]

set ::env(DESIGN_NAME) user_proj_example

set ::env(VERILOG_FILES) "\
	$script_dir/../../caravel/verilog/rtl/defines.v \
        $script_dir/../../verilog/rtl/ptc/ptc_defines.v \
        $script_dir/../../verilog/rtl/ptc/ptc_top.v \
        $script_dir/../../verilog/rtl/i2c/i2c_master_defines.v \
        $script_dir/../../verilog/rtl/i2c/i2c_master_bit_ctrl.v \
        $script_dir/../../verilog/rtl/i2c/i2c_master_byte_ctrl.v \
        $script_dir/../../verilog/rtl/i2c/i2c_master_top.v \
        $script_dir/../../verilog/rtl/fpu/except.v \
        $script_dir/../../verilog/rtl/fpu/post_norm.v \
        $script_dir/../../verilog/rtl/fpu/pre_norm_fmul.v \
        $script_dir/../../verilog/rtl/fpu/pre_norm.v \
        $script_dir/../../verilog/rtl/fpu/primitives.v \
        $script_dir/../../verilog/rtl/fpu/fpu.v \
	$script_dir/../../verilog/rtl/user_proj_example.v"
	
set ::env(CLOCK_PORT) "wb_clk_i"
set ::env(CLOCK_NET) "wb_clk_i"
set ::env(CLOCK_PERIOD) "10"

set ::env(DESIGN_IS_CORE) 0
set ::env(FP_PDN_CORE_RING) 0
set ::env(GLB_RT_MAXLAYER) 5
set ::env(FP_PIN_ORDER_CFG) $script_dir/pin_order.cfg

set ::env(VDD_NETS) [list {vccd1} {vccd2} {vdda1} {vdda2}]
set ::env(GND_NETS) [list {vssd1} {vssd2} {vssa1} {vssa2}]

set ::env(SYNTH_MAX_FANOUT) 6
set ::env(FP_CORE_UTIL) 20
set ::env(PL_TARGET_DENSITY) [ expr ($::env(FP_CORE_UTIL)+4) / 100.0 ]
set ::env(CELL_PAD) 4

set ::env(DIODE_INSERTION_STRATEGY) 0
#set ::env(SYNTH_STRATEGY) 2
#set ::env(SYNTH_STRATEGY) "DELAY 1"
set ::env(SYNTH_NO_FLAT) 0

set ::env(ROUTING_CORES) 16

set ::env(MAGIC_DRC_USE_GDS) 1
set ::env(LVS_INSERT_POWER_PINS) 1

