library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity counter is
    generic (
        g_COUNT_WIDTH : integer := 32
    );
    port (
        -- clock and reset
        i_clk_100M  : in  std_logic;
        i_rst_n     : in  std_logic;
        -- controls
        i_enable    : in  std_logic;
        i_preset    : in  std_logic_vector(g_COUNT_WIDTH-1 downto 0);
        o_done      : out std_logic
    );
end entity counter;

architecture rtl of counter is
    
    signal r_count  : unsigned(g_COUNT_WIDTH-1 downto 0);
    
begin
    
    process(i_clk_100M)
    begin
        if rising_edge(i_clk_100M) then
            if i_rst_n = '0' then
               r_count <= (others => '0');
            elsif i_enable = '1' then
                if r_count = 0 then 
                    r_count <= unsigned(i_preset)-1;
                    o_done <= '1';
                else
                    r_count <= r_count-1;
                    o_done <= '0';
                end if;
            end if;
        end if;
   end process;
    
end architecture rtl;