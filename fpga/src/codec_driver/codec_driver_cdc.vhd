library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity codec_driver_cdc is
    port (
        -- clock and reset
        i_clk_100M : in std_ulogic; -- 100MHz system clock
        i_clk_12M : in std_ulogic; -- 12MHz codec clock
        -- system logic if
        i_rst_n : in std_ulogic; -- system reset, active low
        -- codec if
        o_rst_n_12M : out std_ulogic -- system reset 12M clock domain
    );
end entity codec_driver_cdc;

architecture rtl of codec_driver_cdc is
    signal r_rst_n_meta_12M : std_ulogic := '0';
    signal r_rst_n_12M      : std_ulogic := '0';
begin
    -- reset metastability
    proc_name: process(i_clk_12M)
    begin
        if rising_edge(i_clk_12M) then
            r_rst_n_meta_12M <= i_rst_n;
            r_rst_n_12M <= r_rst_n_meta_12M;
        end if;
    end process proc_name;

    -- output drivers
    o_rst_n_12M <= r_rst_n_12M;
    
end architecture rtl;