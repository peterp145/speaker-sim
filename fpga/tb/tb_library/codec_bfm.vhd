library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library speaker_sim_lib;
use speaker_sim_lib.codec_driver_pkg.all;

library tb_library;
use tb_library.codec_bfm_pkg.all;

entity codec_bfm is
    port (
        i_rec : in  t_codec_bfm_i_rec;
        o_rec : out t_codec_bfm_o_rec
    );
end entity codec_bfm;

architecture bfm of codec_bfm is
    ----- serial port -----
    signal ctrl_word : t_sport_word := (others => '0');
    signal adc_sample_flg, dac_sample_flg : std_ulogic := '0';

    ----- registers -----

    ----- adc -----
    signal adc_data_word, adc_data_word_dly : t_codec_data_word := (others => '0');
    
    ----- dac -----
    signal dac_data_word, dac_data_word_dly : t_codec_data_word := (others => '0');
    
begin
    ----- serial port ------
    -- serial port timing
    proc_sport : process
        variable v_din_sreg, v_dout_sreg : t_sport_word := (others => '0');
        variable v_adc_data_word, v_dac_data_word : t_codec_data_word := (others => '0');

        procedure shift_word is
        begin
            for i in t_sport_word'range loop
                -- dout write
                wait until i_rec.codec_dclk;
                wait for SPORT_DLY;
                o_rec.codec_dout <= v_dout_sreg(i);

                -- din read
                wait until not i_rec.codec_dclk;
                wait for SPORT_THD;
                v_din_sreg(i) := i_rec.codec_din;
            end loop;
        end procedure shift_word;
    begin
        loop_sync : loop
            -- wait for dfs
            o_rec.codec_dout <= 'Z';
            loop_dfs : loop
                wait until i_rec.codec_dclk;
                wait until not i_rec.codec_dclk;
                exit loop_dfs when i_rec.codec_dfs;
            end loop loop_dfs;
            adc_sample_flg <= '1';
            wait for 1 ns;
            adc_sample_flg <= '0';
            
            -- control word
            v_dout_sreg := (others => '0');
            shift_word;
            ctrl_word <= v_din_sreg;

            -- data word 0
            next loop_sync when not i_rec.codec_dfs;  -- check for next dfs
            v_dout_sreg := (others => '0');
            shift_word;

            -- data word 1 (codec_word(23:8))
            next loop_sync when not i_rec.codec_dfs;
            v_adc_data_word := adc_data_word_dly;
            v_dout_sreg := t_sport_word(v_adc_data_word(23 downto 8));
            shift_word;
            v_dac_data_word(23 downto 8) := signed(v_din_sreg);

            -- data word 2 (codec_word(7:0))
            next loop_sync when not i_rec.codec_dfs;
            v_dout_sreg := t_sport_word(v_adc_data_word(7 downto 0) & X"ZZ");
            shift_word;
            v_dac_data_word(7 downto 0) := signed(v_din_sreg(15 downto 8));
            dac_data_word <= v_dac_data_word;
            dac_sample_flg <= '1';
            wait for 1 ns;
            dac_sample_flg <= '0';
        end loop loop_sync;

    end process proc_sport;

    -- registers

    -- adc
    proc_adc : process
    begin
        wait until adc_sample_flg;
        adc_data_word  <= to_t_data_word(i_rec.v_adc_in);
        wait until not adc_sample_flg;
    end process proc_adc;

    adc_data_word_dly <= adc_data_word'delayed(ADC_GROUP_DELAY);
    o_rec.word_adc_out <= adc_data_word_dly;

    -- dac
    dac_data_word_dly  <= dac_data_word'delayed(DAC_GROUP_DELAY);
    proc_dac : process
    begin
        wait until dac_sample_flg;
        o_rec.word_dac_out <= dac_data_word_dly;
        o_rec.v_dac_out    <= to_t_codec_voltage(dac_data_word_dly);
        wait until not dac_sample_flg;
    end process proc_dac;
    
    
end architecture bfm;