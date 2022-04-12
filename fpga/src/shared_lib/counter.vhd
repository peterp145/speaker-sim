library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library shared_lib;
use shared_lib.utils_pkg.all;
use shared_lib.counter_pkg.all;

entity counter is
    generic (
        g_COUNT_MAX   : integer                           -- max count value
    --     g_NUM_BITS    : integer := num_bits(g_COUNT_MAX)    -- bit width of counter
    );
    port (
        clk     : in  std_ulogic;         -- clock input
        i_rec   : in  t_counter_i_rec;
        o_rec   : out t_counter_o_rec
    );
end entity counter;

architecture rtl of counter is
    signal r_count : unsigned(o_rec.count'range) := (others => '0');
    signal r_done  : std_ulogic := '0';
begin
    -- count
    proc_count: process(clk)
        variable v_done : std_ulogic;
    begin
        if rising_edge(clk) then
            if not i_rec.rst_n then
                r_count <= (others => '0');
                r_done  <= '0';
            elsif i_rec.en then
                v_done  := eq(r_count, g_COUNT_MAX);
                r_count <= (others => '0') when v_done else r_count + 1;
                r_done <= v_done;
            end if;
        end if;
    end process proc_count;
    
    -- done logic
    o_rec.count <= r_count;
    o_rec.done  <= r_done;
    
end architecture rtl;