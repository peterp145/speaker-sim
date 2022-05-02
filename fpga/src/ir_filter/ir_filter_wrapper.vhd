----------
-- file:        ir_filter_wrappe.vhd
-- description: wrapper for matlab generated impulse response fir filter
-- author:      peter phelan
-- email:       peter@peterphelan.net
----------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library matlab_lib;
use matlab_lib.ir_filter_wrapper_pkg.all;

entity ir_filter_wrapper is
    port (
        i_clk_dsp_122M88    : in  std_ulogic; -- clock input
        i_rec               : in  t_ir_filter_wrapper_i_rec; -- input port record
        o_rec               : out t_ir_filter_wrapper_o_rec -- output port record
    );
end entity ir_filter_wrapper;

architecture rtl of ir_filter_wrapper is
    component ir_filter IS
        PORT(
            i_clk_dsp_122M88  :   IN    std_logic;
            reset             :   IN    std_logic;
            clk_enable        :   IN    std_logic;
            data_in           :   IN    signed(23 DOWNTO 0);  -- sfix24_En23
            data_in_valid     :   IN    std_logic;
            ce_out            :   OUT   std_logic;
            data_out          :   OUT   signed(23 DOWNTO 0);  -- sfix24_En23
            data_out_valid    :   OUT   std_logic;
            data_in_ready     :   OUT   std_logic
        );
    END component ir_filter;
begin
    
    -- ir_filter instance
    u_ir_filter :ir_filter
        port map(
            i_clk_dsp_122M88 => i_clk_dsp_122M88,
            reset => not i_rec.rst_n,
            clk_enable => '1',
            data_in => i_rec.data_in,
            data_in_valid => i_rec.data_in_valid,
            ce_out => open,
            data_out => o_rec.data_out,
            data_out_valid => o_rec.data_out_valid,
            data_in_ready => open
        );

end architecture rtl;