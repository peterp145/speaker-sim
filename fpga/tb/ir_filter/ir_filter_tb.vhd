library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use std.textio.all;

library shared_lib;
use shared_lib.utils_pkg.all;
use shared_lib.tb_utils_pkg.all;

library matlab_lib;
use matlab_lib.ir_filter_wrapper_pkg.all;

library speaker_sim_lib;
use speaker_sim_lib.speaker_sim_pkg.all;

entity ir_filter_tb is 
end entity ir_filter_tb;

architecture tb of ir_filter_tb is
    -- testbench configuration
    constant CLK_PER_ns : time := (1000.0/122.88584) * 1 ns;
    constant COMB_DLY : time := 1 ns;

    constant N_taps : integer := 2560;
    constant N_samples : integer := N_taps * 2;

    type t_sample_mem is array(0 to N_samples-1) of t_codec_word;


    -- clock and reset
    signal clk_122M88 : std_ulogic := '1';
    signal rst_n : std_ulogic := '0';

    -- stimulus
    signal in_sample_mem : t_sample_mem := (
        1 => CODEC_WORD_MAX,
        others => (others => '0')
    );

    -- dut io
    signal dut_i_rec : t_ir_filter_wrapper_i_rec;
    signal dut_o_rec : t_ir_filter_wrapper_o_rec;

    -- response checker

    -- helper procedures
    procedure wait_clk_122M is
    begin
        wait_clk(clk_122M88, COMB_DLY, 1);
    end wait_clk_122M;
    
    procedure wait_clk_122M(constant num_clks : positive) is
    begin
        wait_clk(clk_122M88, COMB_DLY, num_clks);
    end wait_clk_122M;

begin
    -- clock generation
    clk_122M88 <= not clk_122M88 after CLK_PER_ns/2;
    rst_n <= '1' after CLK_PER_ns * 5.5;

    -- codec (bfm)
    proc_bfm: process
    begin
        dut_i_rec.data_in <= (others => '0');
        dut_i_rec.data_in_valid <= '0';

        for j in 0 to N_taps-1 loop
            for i in N_taps-1 downto 0 loop
                dut_i_rec.data_in <= in_sample_mem(j);
                dut_i_rec.data_in_valid <= '1' when i = 0 else '0';
                wait_clk_122M;
            end loop;
        end loop;
        report "end of test" severity failure;
        wait;
    end process proc_bfm;

    -- dut
    dut_i_rec.rst_n <= rst_n;
    u_dut: ir_filter_wrapper
        port map(clk_122M88, dut_i_rec, dut_o_rec);

end architecture tb;