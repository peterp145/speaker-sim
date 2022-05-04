----------
-- file:        flip_flops_pkg.vhd
-- description: package containinging flip flops for reuse
-- author:      peter phelan
-- email:       peter@peterphelan.net
----------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package flip_flops_pkg is
    ----- dff -----
    type t_dff_rec is record
        d : std_ulogic;
        q : std_ulogic;
    end record t_dff_rec;

    ------ dff_clken ------
    type t_dff_clken_i_rec is record
        clken : std_ulogic;
        d     : std_ulogic;
    end record t_dff_clken_i_rec;
    
    type t_dff_clken_o_rec is record
        q : std_ulogic;
    end record t_dff_clken_o_rec;

    ----- sr_ff -----
    -- set/reset flip flop clocked on rising edge
    -- reset active low and has precedence
    type t_srff_i_rec is record
        s   : std_ulogic; -- set input
        r_n : std_ulogic; -- reset input, active low
    end record t_srff_i_rec;

    type t_srff_o_rec is record
        q : std_ulogic; -- output
    end record t_srff_o_rec;

end package flip_flops_pkg;