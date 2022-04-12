-------- d_ff ----------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;

library shared_lib;
use shared_lib.flip_flops_pkg.all;

entity dff is
    port (
        i_clk : in  std_ulogic; -- clock
        i_d   : in  std_ulogic; -- input
        o_q   : out std_ulogic  -- output
    );
    end entity dff;
    
    architecture rtl of dff is
        signal q : std_ulogic := '0';
    begin
        q <= i_d when rising_edge(i_clk);
        o_q <= q;
    end architecture rtl;
    
    -------- sr_ff ----------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;

library shared_lib;
use shared_lib.flip_flops_pkg.all;

entity srff is
    port (
        clk   : in  std_ulogic;   -- clock input
        i_rec : in  t_srff_i_rec; -- input record
        o_rec : out t_srff_o_rec  -- output record
    );
end entity srff;

architecture rtl of srff is
    signal q : std_ulogic := '0';
begin
    q <= (q or i_rec.s) and i_rec.r_n when rising_edge(clk);
    o_rec.q <= q;
end architecture rtl;

-------- cdc_ffs --------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;

library shared_lib;
use shared_lib.flip_flops_pkg.all;

entity cdcffs is
    port (
        i_clk : in  std_ulogic; -- clock
        i_d   : in  std_ulogic; -- input
        o_q   : out std_ulogic  -- output
    );
end entity cdcffs;

architecture rtl of cdcffs is
    signal q_meta, q : std_ulogic := '0';
begin
    q_meta <= i_d when rising_edge(i_clk);
    q <= q_meta   when rising_edge(i_clk);
    o_q <= q;
end architecture rtl;