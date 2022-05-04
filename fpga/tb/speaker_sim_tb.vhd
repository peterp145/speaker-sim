----- standard library -----
library ieee;
-- standard types
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
-- file io
use std.textio.all;

----- shared libraries -----
library tb_library;

-- testbench utilities
use tb_library.tb_utils_pkg.all;
use tb_library.codec_bfm_pkg.all;
use tb_library.codec_bfm;

----- tb libraries -----
library speaker_sim_tb_lib;
-- top level
use speaker_sim_tb_lib.speaker_sim_tb_pkg.all;

-- project design libraries
library speaker_sim_lib;
-- use speaker_sim_lib.speaker_sim;

entity speaker_sim_tb is
end entity speaker_sim_tb;

architecture tb of speaker_sim_tb is
    
    -- clock and reset
    signal clk_125M : std_ulogic := '1';
    signal rst_n    : std_ulogic := '0';

    -- func gen
    signal adc_vin     : T_SAMPLE:=  0.0;
    signal func_gen_en : boolean := false;

    -- bfm
    signal codec_en : boolean := false;
    signal codec_bfm_i_rec : t_codec_bfm_i_rec := (v_adc_in => 0.0, others => '0');
    signal codec_bfm_o_rec : t_codec_bfm_o_rec;

    -- dut io
    -- signal  codec_mclk  : std_ulogic;
    -- signal  codec_rst_n : std_ulogic;
    -- signal  codec_dclk  : std_ulogic;
    -- signal  codec_dfs   : std_ulogic;
    -- signal  codec_din   : std_ulogic;
    signal  codec_dout  : std_ulogic := 'Z';
    
    signal  leds : std_ulogic_vector(3 downto 0);

    component speaker_sim is
        port (
            -- system clock input
            i_clk_125M  : in    std_ulogic;
    
            -- audio codec
            o_codec_mclk    :   out std_ulogic;  -- codec master clock
            o_codec_rst_n   :   out std_ulogic;  -- codec reset signal
            o_codec_dclk    :   out std_ulogic;  -- codec serial clock
            o_codec_dfs     :   out std_ulogic;  -- codec dfs
            o_codec_din     :   out std_ulogic;  -- serial data to codec
            i_codec_dout    :   in  std_ulogic;  -- serial data from codec
    
            -- status leds
            o_leds      : out   std_logic_vector(3 downto 0)
        );
    end component speaker_sim;
    
begin
    -- clock
    clk_125M <= not clk_125M after CLK_125M_PER_ns/2;

    -- testbench sequencing
    proc_tb_sequence : process
    begin
        wait for T_RESET_ns;
        rst_n <= '1';

        wait for 350 us;
        func_gen_en <= true;
        wait for 1000 ms;
        func_gen_en <= false;

        wait for 2000 ms;
        assert false report "end of test" severity failure;
        wait;
    end process proc_tb_sequence;

    -- function gen bfm
    proc_func_gen_bfm : process
        variable v_samples_real : real_array(0 to FUNC_GEN_N_SAMPLES-1) := (others => 0.0);
        variable v_samples : T_SAMPLE_ARR;
        variable v_idx : integer range v_samples_real'range := 0;
    begin
        -- initialize
        read_into_array(IMPULSE_FNAME, v_samples_real);
        v_samples := to_T_SAMPLE_ARR(v_samples_real);
        wait until rst_n;
        wait for 10 us;
        
        -- loop output
        loop
            wait for FUNC_GEN_PER;
            if func_gen_en then
                adc_vin <= v_samples(v_idx);
                v_idx    := v_idx + 1;
            end if;
        end loop;

        wait;
    end process proc_func_gen_bfm;

    -- data recorder
    proc_recorder : process
        variable v_samples : real_array(0 to RECORDER_N_SAMPLES-1);
    begin
        -- initial
        wait until rst_n;
        wait for RECORDER_START_DLY;

        -- loop record
        for i in v_samples'range loop
            wait for FUNC_GEN_PER;
            v_samples(i) := codec_bfm_o_rec.v_dac_out;
            print(to_string(codec_bfm_o_rec.v_dac_out, "%32.31f"));
        end loop;
        
        -- write output
        write_from_array(REC_FNAME, v_samples);
        
        -- end test
        assert false report "end of test (proc_recorder)" severity failure;

    end process proc_recorder;

    -- codec bfm
    codec_bfm_i_rec.v_adc_in <= adc_vin;
    u_codec_bfm : entity codec_bfm
    port map (
        codec_bfm_i_rec,
        codec_bfm_o_rec
    );

    -- response checkers

    -- dut
    dut : speaker_sim
    port map (
        i_clk_125M    => clk_125M,
        o_codec_mclk  => codec_bfm_i_rec.codec_mclk,
        o_codec_rst_n => codec_bfm_i_rec.codec_rst_n,
        o_codec_dclk  => codec_bfm_i_rec.codec_dclk,
        o_codec_dfs   => codec_bfm_i_rec.codec_dfs,
        o_codec_din   => codec_bfm_i_rec.codec_din,
        i_codec_dout  => codec_bfm_o_rec.codec_dout,
        o_leds        => leds
    );
    
end architecture tb;