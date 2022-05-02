-- Copyright 1986-2021 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2021.2.1 (lin64) Build 3414424 Sun Dec 19 10:57:14 MST 2021
-- Date        : Sun May  1 19:09:51 2022
-- Host        : peter-ubuntu-20 running 64-bit Ubuntu 20.04.4 LTS
-- Command     : write_vhdl -force -mode synth_stub
--               /home/peter/speaker-sim/fpga/vivado/speaker-sim-project/speaker-sim-project.runs/clk_wiz_0_synth_1/clk_wiz_0_stub.vhdl
-- Design      : clk_wiz_0
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7z020clg400-1
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity clk_wiz_0 is
  Port ( 
    o_clk_100M : out STD_LOGIC;
    resetn : in STD_LOGIC;
    o_locked : out STD_LOGIC;
    i_clk_125M : in STD_LOGIC
  );

end clk_wiz_0;

architecture stub of clk_wiz_0 is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "o_clk_100M,resetn,o_locked,i_clk_125M";
begin
end;
