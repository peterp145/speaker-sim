library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_textio.all;

library speaker_sim_lib;
use speaker_sim_lib.clock_and_reset_pkg.all;

entity clock_and_reset_tb is
end entity clock_and_reset_tb;

architecture tb of clock_and_reset_tb is
    -- testbench config
    
    -- clock
    constant CLK_125M_PER_ns : time := 8 ns;
    signal clk_125M : std_ulogic := '1';

    -- dut signals
    signal dut_i_rec : t_clock_and_reset_i_rec;
    signal dut_o_rec : t_clock_and_reset_o_rec;

begin
    -- clock generation
    clk_125M <= not clk_125M after CLK_125M_PER_ns/2;

    -- dut
    dut_i_rec.clk_125M <= clk_125M;
    dut : clock_and_reset 
        port map (dut_i_rec, dut_o_rec);
    
end architecture tb;