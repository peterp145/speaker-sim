----------
-- file:        clock_and_reset_pkg.vhd
-- description: clock and reset and mmcm component definition
-- author:      peter phelan
-- email:       peter@peterphelan.net
----------
library IEEE;
use IEEE.std_logic_1164.all;

package clock_and_reset_pkg is

    type t_clock_and_reset_o_rec is record
        clk_100M        : std_ulogic; -- 100MHz system logic clock 
        clk_122M        : std_ulogic; -- 122.88MHz dsp and audio codec clock
        clken_100M_100k : std_ulogic; -- 100KHz clock enable in 100M domain
        clken_122M_12M  : std_ulogic; -- 12.288MHz clock enable for codec
        sys_rst_n_100M  : std_ulogic; -- system reset output
        sys_rst_n_122M  : std_ulogic; -- system reset output
    end record t_clock_and_reset_o_rec;

    -- ip instantiations 
    component clk_wiz_0 is
    port (
        o_clk_100M : out std_logic; -- 100MHz clock for system
        resetn     : in  std_logic; -- MMCM reset
        o_locked   : out std_logic; -- MMCM locked
        i_clk_125M : in  std_logic  -- on board 125M clock
    );
    end component;

    component clk_wiz_1 is
    port (
        o_clk_122M88 : out std_logic; -- 122MHz clock for dsp and codec
        resetn       : in  std_logic; -- MMCM reset
        o_locked     : out std_logic; -- MMCM locked
        i_clk_125M   : in  std_logic-- on board 125M clock
    );
    end component;

    component clock_and_reset is
    port (
        i_clk_125M : in  std_ulogic; -- input record
        o_rec      : out t_clock_and_reset_o_rec  -- output record
    );
    end component clock_and_reset;

end package clock_and_reset_pkg;