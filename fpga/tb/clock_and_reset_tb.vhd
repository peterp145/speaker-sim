library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_textio.all;

library xil_defaultlib;
use xil_defaultlib.clock_and_reset_pkg.all;

entity clock_and_reset_tb is
end entity clock_and_reset_tb;

architecture tb of clock_and_reset_tb is
    -- testbench config
    
    -- clock
    constant CLK_125M_PER_ns : time := 8 ns;
    signal clk_125M : std_ulogic := '1';

    -- dut signals
    signal dut_clk_100M, dut_clk_12M, dut_pulse_100K, dut_sys_rst_n : std_ulogic;

begin
    -- clock generation
    clk_125M <= not clk_125M after CLK_125M_PER_ns/2;

    -- dut
    dut : clock_and_reset 
        port map (
            i_clk_125M      => clk_125M,
            o_clk_100M      => dut_clk_100M,
            o_clk_12M       => dut_clk_12M,
            o_pulse_100K    => dut_pulse_100K,
            o_sys_rst_n     => dut_sys_rst_n
        );
    
end architecture tb;