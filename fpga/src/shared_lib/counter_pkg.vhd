----------
-- file:        counters_pkg.vhd
-- description: package containinging counters for reuse
-- author:      peter phelan
-- email:       peter@peterphelan.net
----------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package counter_pkg is
    -- io records
    type t_counter_i_rec is record
        clk     : std_ulogic;   -- counter logic clock
        rst_n   : std_ulogic;   -- counter reset, active low
        en      : std_ulogic;   -- count enable, increase count by one on rising edge
    end record t_counter_i_rec;

    type t_counter_o_rec is record
        count   : unsigned;     -- count register value
        done    : std_ulogic;   -- end of count flag, count rolls over to zero next
    end record t_counter_o_rec;
    
    -- counter component
    component counter
        generic (
            g_COUNT_MAX   : integer    -- max count value
        --     g_NUM_BITS    : integer     -- bit width of counter
        );
        port (
            i_rec : in t_counter_i_rec;    -- input port record
            o_rec : out t_counter_o_rec     -- output port record
        );
    end component counter;
    
end package counter_pkg;