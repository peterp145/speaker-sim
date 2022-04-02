----------
-- file:        clock_and_reset_pkg.vhd
-- description: clock and reset generation
-- author:      peter phelan
-- email:       peter@peterphelan.net
----------
library IEEE;
use IEEE.std_logic_1164.all;

package clock_and_reset_pkg is
    component clock_and_reset is
        port (
            i_clk_125M      : in  std_ulogic;
            o_clk_100M      : out std_ulogic;
            o_clk_12M       : out std_ulogic;
            o_pulse_100K    : out std_ulogic;
            o_sys_rst_n     : out std_ulogic
        );
    end component clock_and_reset;
    
    -- ip component
    component clk_wiz_0 is
        port (
            -- Clock in ports
            i_clk_125M    : in     std_logic;
            -- Clock out ports
            o_clk_100M    : out    std_logic;
            o_clk_12M     : out    std_logic;
            -- Status and control signals
            resetn        : in     std_logic;
            o_locked      : out    std_logic
        );
    end component clk_wiz_0;
    
    
end package clock_and_reset_pkg;