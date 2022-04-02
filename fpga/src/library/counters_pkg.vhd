----------
-- file:        counters_pkg.vhd
-- description: package containinging counters for reuse
-- author:      peter phelan
-- email:       peter@peterphelan.net
----------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package counters_pkg is
    -- counter models
    component counter
        generic (
            g_NUM_BITS    : integer;
            g_COUNT_MAX   : integer := 2**g_NUM_BITS
        );
        port (
            i_clk : in std_ulogic;
            i_rst_n : in std_ulogic;
            i_en : in std_ulogic;
            o_count : out unsigned(g_NUM_BITS-1 downto 0);
            o_done : out std_ulogic
        );
    end component counter;
    
end package counters_pkg;