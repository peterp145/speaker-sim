----------
-- file:        clock_and_reset_pkg.vhd
-- description: clock and reset and mmcm component definition
-- author:      peter phelan
-- email:       peter@peterphelan.net
----------
library IEEE;
use IEEE.std_logic_1164.all;

library xil_defaultlib;

package clock_and_reset_pkg is

    type t_clock_and_reset_o_rec is record
        clk_100M        : std_ulogic; -- 100MHz system logic clock 
        clk_12M         : std_ulogic; -- 12.288MHz audio codec clock
        pulse_100k      : std_ulogic; -- 100KHz pulse in 100M domain
        sys_rst_n_100M  : std_ulogic; -- system reset output
        sys_rst_n_12M   : std_ulogic; -- system reset output
    end record t_clock_and_reset_o_rec;

    type t_clock_and_reset_rec is record
        -- i : t_clock_and_reset_i_rec;
        o : t_clock_and_reset_o_rec;
    end record t_clock_and_reset_rec;

    component clock_and_reset is
        port (
            i_clk_125M : in  std_ulogic; -- input record
            o_rec      : out t_clock_and_reset_o_rec  -- output record
        );
    end component clock_and_reset;

end package clock_and_reset_pkg;