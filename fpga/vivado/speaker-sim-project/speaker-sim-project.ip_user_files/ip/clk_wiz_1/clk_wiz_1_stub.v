// Copyright 1986-2021 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2021.2.1 (lin64) Build 3414424 Sun Dec 19 10:57:14 MST 2021
// Date        : Thu Apr 21 23:58:02 2022
// Host        : peter-ubuntu-20 running 64-bit Ubuntu 20.04.4 LTS
// Command     : write_verilog -force -mode synth_stub
//               /home/peter/speaker-sim/fpga/vivado/speaker-sim-project/speaker-sim-project.runs/clk_wiz_1_synth_1/clk_wiz_1_stub.v
// Design      : clk_wiz_1
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7z020clg400-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module clk_wiz_1(clk_122M88, resetn, locked, clk_125M)
/* synthesis syn_black_box black_box_pad_pin="clk_122M88,resetn,locked,clk_125M" */;
  output clk_122M88;
  input resetn;
  output locked;
  input clk_125M;
endmodule
