library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_textio.all;

use std.textio.all;

library xil_defaultlib;
use xil_defaultlib.speaker_sim_pkg.all;
-- use xil_defaultlib.tb_utils_pkg.all;
-- use xil_defaultlib.speaker_sim_tb_pkg.all;

entity speaker_sim_tb is
end entity speaker_sim_tb;

architecture tb of speaker_sim_tb is
    
    -- testbench configuration
    constant COMB_DLY : time := 1ns;

    -- clock and reset
    constant CLK_125M_PER_ns : time := (1000.0/125.0) * 1ns;
    signal clk_125M : std_ulogic := '1';

    -- bfm
    signal bfm_en : boolean := true;

    -- dut io
    signal  codec_mclk  : std_ulogic;
    signal  codec_rst_n : std_ulogic;
    signal  codec_dclk  : std_ulogic;
    signal  codec_dfs   : std_ulogic;
    signal  codec_din   : std_ulogic;
    signal  codec_dout  : std_ulogic := 'Z';
    
    signal  leds : std_ulogic_vector(3 downto 0);
    
begin
    -- clock and reset
    clk_125M <= not clk_125M after CLK_125M_PER_ns/2;

    -- bfm
    proc_bfm : process
        variable samp_num : integer range 0 to (2**24)-1;
        -- variable adc_word_gen : t_adc_word_gen;
        variable adc_data : std_ulogic_vector(127 downto 0);
        variable dac_data : std_ulogic_vector(127 downto 0);
    begin
        -- adc_word_gen.p_init;
        samp_num := 0;
        while bfm_en loop
            -- set adc word
            adc_data := (others => 'Z');
            adc_data(127 downto 96) := X"FFFF_FFFF";
            adc_data(95  downto 72) := std_ulogic_vector(to_unsigned(samp_num,24));

            -- fs cycle
            for i in 127 downto 0 loop
                -- shift data out
                wait until rising_edge(codec_dclk);
                wait for COMB_DLY;
                codec_dout <= adc_data(i);

                wait until falling_edge(codec_dclk);
                wait for COMB_DLY;
                dac_data(i) := codec_din;
                
            end loop;
            samp_num := samp_num + 1;
        end loop;
        wait until bfm_en;
    end process proc_bfm;
            
    -- response checkers


    -- dut
    dut : speaker_sim
    port map(
        i_clk_125M => clk_125M,
        o_codec_mclk => codec_mclk,
        o_codec_rst_n => codec_rst_n,
        o_codec_dclk => codec_dclk,
        o_codec_dfs => codec_dfs,
        o_codec_din => codec_din,
        i_codec_dout => codec_dout,
        o_leds => leds
    );
    
end architecture tb;