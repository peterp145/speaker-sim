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
    procedure d_ff (
        signal clk  : in  std_logic;
        signal q    : out std_logic;
        signal d    : in  std_logic
    );

    procedure sr_ff (
        signal q            : inout std_logic;
        signal s, r_n, clk  : in    std_logic
    );

end package flip_flops_pkg;

package body flip_flops_pkg is
    -- d flip flop clocked on rising edge
    procedure d_ff (
        signal clk  : in  std_logic;
        signal q    : out std_logic;
        signal d    : in  std_logic
    ) is
    begin
        q <= d when rising_edge(clk);
    end procedure d_ff;

    -- set/reset flip flop clocked on rising edge
    -- reset active low and has precedence
    procedure sr_ff (
        signal q            : inout std_logic;
        signal s, r_n, clk  : in    std_logic
    ) is
    begin
        q <= (q or s) and r_n when rising_edge(clk);
    end procedure sr_ff;

    -- flip flop for clock domain crossings with edge detection
    -- procedure sync_ffs (
    --     signal clk  : in    std_logic;
    --     signal q    : inout std_logic_vector(2 downto 0);
    --     signal d    : in    std_logic;
    --     signal r_n  : in    std_logic
    -- ) is
    -- begin
    --     wait until rising_edge(i_clk_100M);
    --     q <= (others => '0') when not r_n else
    --         q(1 downto 0) & d;
    -- end procedure sync_ffs;
end package body flip_flops_pkg;