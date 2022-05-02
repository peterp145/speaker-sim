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

    -- component dff is
    -- port (
    --     i_clk : in  std_ulogic; -- clock
    --     i_d   : in  std_ulogic; -- input
    --     o_q   : out std_ulogic  -- output
    -- );
    -- end component dff;
    
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

    type t_srff_rec is record
        i : t_srff_i_rec;
        o : t_srff_o_rec;
    end record;
    
    -- component srff is
    -- port (
    --     clk   : in  std_ulogic;   -- clock
    --     i_rec : in  t_srff_i_rec; -- input record
    --     o_rec : out t_srff_o_rec  -- output record
    -- );
    -- end component srff;
        
    ----- cdc -----
    type t_cdcffs_i_rec is record
        d   : std_ulogic; -- set input
    end record t_cdcffs_i_rec;

    type t_cdcffs_o_rec is record
        q : std_ulogic; -- output
    end record t_cdcffs_o_rec;

    type t_cdcffs_rec is record
        i : t_cdcffs_i_rec;
        o : t_cdcffs_o_rec;
    end record t_cdcffs_rec;

    -- component cdcffs is
    -- port (
    --     i_clk : in  std_ulogic; -- clock
    --     i_d   : in  std_ulogic; -- input
    --     o_q   : out std_ulogic  -- output
    -- );
    -- end component cdcffs;

end package flip_flops_pkg;