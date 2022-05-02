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
    ----- testbench configuration -----
    -- 122M88 clock
    constant CLK_PER_ns : time := (1000.0/122.88584) * 1 ns;
    constant COMB_DLY : time := 1 ns;

    -- fir filter configuration
    constant N_coeff_bits : integer := 16;
    constant N_coeffs     : integer := 2560;
    
    subtype t_coeff is signed(N_coeff_bits-1 downto 0);

    constant N_samples    : integer := 48000;
    constant COEFF_FNAME  : string := "v30_ir_f16s18_48khz.txt";
    constant ESS_FNAME    : string := "ess_s24f23_48khz.txt";

    type t_sample_mem is array (0 to N_samples-1) of t_codec_word;

    ----- testbench signals -----
    -- clock and reset
    signal clk_122M88 : std_ulogic := '1';
    signal rst_n : std_ulogic := '0';

    -- stimulus
    signal din_mem : t_sample_mem;

    -- dut io
    signal dut_i_rec : t_ir_filter_wrapper_i_rec := (rst_n, (others => '0'), '0');
    signal dut_o_rec, dut_o_expected_rec : t_ir_filter_wrapper_o_rec;

    -- response predictor
    signal dout_expected_mem : t_sample_mem := (others => (others => 'U'));
    signal checker_en : std_ulogic := '0';

    ----- helper procedures -----
    -- timing
    procedure wait_clk_122M is
    begin
        wait_clk(clk_122M88, COMB_DLY);
    end wait_clk_122M;
    
    procedure wait_clk_122M(constant num_clks : positive) is
    begin
        wait_clk(clk_122M88, COMB_DLY, num_clks);
    end wait_clk_122M;

    function to_string(o_rec : t_ir_filter_wrapper_o_rec) return string is
    begin
        return to_string(o_rec.data_out) & ", " & to_string(o_rec.data_out_valid);
    end function to_string;

    procedure assert_eq(
        constant actual     : in t_ir_filter_wrapper_o_rec;     -- value under test
        constant expected   : in t_ir_filter_wrapper_o_rec;     -- expected value
        constant err_msg    : in string -- error message
    ) is
    begin
        assert actual = expected report "error with " & err_msg & LF severity failure;         
    end procedure assert_eq;

begin
    -- clock generation
    clk_122M88 <= not clk_122M88 after CLK_PER_ns/2;
    rst_n <= '1' after CLK_PER_ns * 5.5;

    
    -- codec adc bfm
    proc_bfm: process
        file     f : text;
        variable l : line;
        variable sample : t_codec_word;
    begin
        -- initialization
        -- read coefficient memory
        file_open(f, ESS_FNAME, read_mode);
        for i in 0 to N_samples-1 loop
            readline(f, l);
            hread(l, sample);
            din_mem(i) <= sample;
        end loop;
        file_close(f);

        wait until rst_n;

        -- loop through adc words
        for j in 0 to N_samples-1 loop
            for i in N_coeffs-1 downto 0 loop
                dut_i_rec.data_in <= din_mem(j);
                dut_i_rec.data_in_valid <= '1' when i = 0 else '0';
                wait_clk_122M;
            end loop;
        end loop;
        wait;
    end process proc_bfm;

    -- response predictor
    proc_response: process
        file     f : text;
        variable l : line;
        variable coeff : t_coeff;
        variable dout_expected : t_codec_word;
    begin
        ----- initialization -----
        -- read coefficient memory
        file_open(f, COEFF_FNAME, read_mode);
        for i in 0 to N_coeffs-1 loop
            readline(f, l);
            hread(l, coeff);
            dout_expected := (23 downto 19 => coeff(15), 2 downto 0 => not coeff(15), others => '0');
            dout_expected(18 downto 3) := coeff;
            dout_expected_mem(i) <= dout_expected;
        end loop;
        file_close(f);

        -- set exptected outputs
        dut_o_expected_rec <= ((others => '0'), '0');

        -- reset released
        wait until rst_n;
        checker_en <= '1';

        -- wait for output first sample
        for i in 0 to 1 loop
            loop
                wait_clk_122M;
                if dut_i_rec.data_in_valid = '1' then
                    exit;
                end if;
            end loop;
        end loop;

        wait_clk_122M(7);
        dut_o_expected_rec <= ((others => '0'), '1');
        

        -- loop through each coefficient
        for i in 0 to N_samples-1 loop
            for j in 0 to N_coeffs-2 loop -- 
                wait_clk_122M;
                dut_o_expected_rec <= (dut_o_rec.data_out, '0');
                -- if i=0 then
                --     dut_o_expected_rec <= ((others => '0'), '0');
                -- else
                --     dut_o_expected_rec <= (dout_expected_mem(i-1), '0');
                -- end if;
            end loop;

            wait_clk_122M;
            dut_o_expected_rec <= (dut_o_rec.data_out, '1');
        end loop;

        wait;
    end process proc_response;

    -- response checker
    proc_checker : process

    begin
        loop
            wait_clk_122M;
            wait for 1 ns;
            if checker_en then
                assert_eq(
                    dut_o_rec,
                    dut_o_expected_rec,
                    "    actual: " & to_string(dut_o_rec.data_out) & "," & to_string(dut_o_rec.data_out_valid) &
                    ", expected: " & to_string(dut_o_expected_rec.data_out) & "," & to_string(dut_o_expected_rec.data_out_valid));
            end if;
        end loop;
        wait;
    end process proc_checker;

    -- dut
    dut_i_rec.rst_n <= rst_n;
    u_dut: ir_filter_wrapper
        port map(clk_122M88, dut_i_rec, dut_o_rec);

end architecture tb;