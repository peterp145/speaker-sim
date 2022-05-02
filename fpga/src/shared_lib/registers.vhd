-------- reg --------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library shared_lib;
use shared_lib.registers_pkg.all;

entity reg is
    port (
        clk   : in  std_ulogic;  -- logic clock
        i_rec : in  t_reg_i_rec; -- input record
        o_rec : out t_reg_o_rec  -- output record
    );
end entity reg;

architecture rtl of reg is
    signal r_reg : std_ulogic_vector;
begin
    proc_name: process(clk)
    begin
        if rising_edge(clk) then
            if i_rec.clken then 
                if not i_rec.rst_n then
                    r_reg <= (others => '0');
                elsif i_rec.load_en then
                    r_reg <= i_rec.load_word;
                end if;
            end if;
        end if;
    end process proc_name;

    o_rec.word <= r_reg;
end architecture rtl;

-------- sreg --------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library shared_lib;
use shared_lib.utils_pkg.all;
use shared_lib.registers_pkg.all;

entity sreg is
    generic (g_RESET_BIT : std_ulogic := '0');
    port (
        clk   : in  std_ulogic;
        i_rec : in  t_sreg_i_rec; -- input record
        o_rec : out t_sreg_o_rec  -- output record
    );
end entity sreg;

architecture rtl of sreg is
    signal reg : std_ulogic_vector(i_rec.load_word'range) := (others => g_RESET_BIT);
begin
    proc_name: process(clk)
    begin
        if rising_edge(clk) then
            if i_rec.clken then
                if not i_rec.rst_n then
                    reg <= (others => g_RESET_BIT);
                elsif i_rec.load_en then
                    reg <= i_rec.load_word;
                elsif i_rec.shift_en then
                    reg <= reg(reg'length-2 downto 0) & i_rec.shift_bit;
                end if;
            end if;
        end if;
    end process proc_name;

    o_rec.word <= reg;
end architecture rtl;