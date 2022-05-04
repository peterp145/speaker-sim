-------- dff ----------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;

library shared_lib;
use shared_lib.flip_flops_pkg.all;

entity dff is
    generic (
        RESET_VAL : std_ulogic := '0'
    );
    port (
        i_clk : in  std_ulogic; -- clock
        i_d   : in  std_ulogic; -- input
        o_q   : out std_ulogic  -- output
    );
end entity dff;
    
architecture rtl of dff is
    signal q : std_ulogic := RESET_VAL;
begin
    q <= i_d when rising_edge(i_clk);
    o_q <= q;
end architecture rtl;
    
-------- dff_clken ----------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;

library shared_lib;
use shared_lib.flip_flops_pkg.all;

entity dff_clken is
    generic (
        RESET_VAL : std_ulogic := '0'
    );
    port (
        i_clk   : in  std_ulogic;   -- clock input
        i_rec : in  t_dff_clken_i_rec; -- input record
        o_rec : out t_dff_clken_o_rec  -- output record
    );
end entity dff_clken;
    
architecture rtl of dff_clken is
    signal q : std_ulogic := RESET_VAL;
begin
    dff_clken_proc : process(i_clk)
    begin
        if rising_edge(i_clk) then 
            q <= i_rec.d when i_rec.clken;
        end if;
    end process dff_clken_proc;
    o_rec.q <= q;
end architecture rtl;

-------- dff_clken ----------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;

library shared_lib;
use shared_lib.flip_flops_pkg.all;

entity dff_ons is
    generic (
        RESET_VAL : std_ulogic := '0'
    );
    port (
        i_clk : in  std_ulogic;   -- clock input
        i_rec : in  t_dff_clken_i_rec; -- input record
        o_rec : out t_dff_clken_o_rec  -- output record
    );
end entity dff_ons;
    
architecture rtl of dff_ons is
    signal q, q_last : std_ulogic := RESET_VAL;
begin
    dff_clken_proc : process(i_clk)
    begin
        if rising_edge(i_clk) then
            if i_rec.clken then
                q      <= i_rec.d;
                q_last <= q;
            end if;
        end if;
    end process dff_clken_proc;
    o_rec.q <= q and not q_last;
end architecture rtl;
    
    -------- sr_ff ----------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;

library shared_lib;
use shared_lib.flip_flops_pkg.all;

entity srff is
    generic (
        RESET_VAL : std_ulogic := '0'
    );
    port (
        clk   : in  std_ulogic;   -- clock input
        i_rec : in  t_srff_i_rec; -- input record
        o_rec : out t_srff_o_rec  -- output record
    );
end entity srff;

architecture rtl of srff is
    signal q : std_ulogic := RESET_VAL;
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
    generic (
        RESET_VAL : std_ulogic := '0'
    );
    port (
        i_clk : in  std_ulogic; -- clock
        i_d   : in  std_ulogic; -- input
        o_q   : out std_ulogic  -- output
    );
end entity cdcffs;

architecture rtl of cdcffs is
    signal q_meta, q : std_ulogic := RESET_VAL;
begin
    cdcffs_proc : process(i_clk)
    begin
        q_meta <= i_d when rising_edge(i_clk);
        q <= q_meta   when rising_edge(i_clk);
    end process cdcffs_proc;
    o_q <= q;
end architecture rtl;