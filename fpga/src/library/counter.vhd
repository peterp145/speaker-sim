library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library xil_defaultlib;
use xil_defaultlib.utils_pkg.all;

entity counter is
    generic (
        g_NUM_BITS    : integer;
        g_COUNT_MAX   : integer := 2**g_NUM_BITS-1
    );
    port (
        i_clk : in std_ulogic;
        i_rst_n : in std_ulogic;
        i_en : in std_ulogic;
        o_count : out unsigned(g_NUM_BITS-1 downto 0);
        o_done : out std_ulogic
    );
end entity counter;

architecture rtl of counter is
    signal r_count : unsigned(g_NUM_BITS-1 downto 0) := (others => '0');
    signal r_done  : std_ulogic := '0';
begin
    -- count
    proc_count: process(i_clk)
        variable v_done : std_ulogic;
    begin
        if rising_edge(i_clk) then
            if not i_rst_n then
                r_count <= (others => '0');
                r_done  <= '0';
            elsif i_en then
                v_done  := eq(r_count, g_COUNT_MAX-1);
                r_count <= (others => '0') when v_done else r_count + to_unsigned(1, g_NUM_BITS);
                r_done <= v_done;
            end if;
        end if;
    end process proc_count;
    
    -- done logic
    o_count <= r_count;
    o_done  <= r_done;
    
end architecture rtl;