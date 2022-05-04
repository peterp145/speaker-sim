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
        clken   : std_ulogic;   -- clock enable, inputs diabled when low
        rst_n   : std_ulogic;   -- counter reset, active low
        en      : std_ulogic;   -- count enable, increase count by one on rising edge
    end record t_counter_i_rec;

    type t_counter_o_rec is record
        count   : unsigned;     -- count register value
        done    : std_ulogic;   -- end of count flag, count rolls over to zero next
    end record t_counter_o_rec;
    
end package counter_pkg;