----------
-- file:        codec_driver_cdc_pkg.vhd
-- description: package component of codec clock domain crossing
-- author:      peter phelan
-- email:       peter@peterphelan.net
----------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package codec_driver_cdc_pkg is
    component codec_driver_cdc is
        port (
            -- clock and reset
            i_clk_100M  : in  std_ulogic; -- 100MHz system clock
            i_clk_12M   : in  std_ulogic; -- 12MHz codec clock
            -- system logic if
            i_rst_n     : in  std_ulogic; -- system reset, active low
            -- codec if
            o_rst_n_12M : out std_ulogic -- system reset 12M clock domain
        );
    end component codec_driver_cdc;
end package codec_driver_cdc_pkg;