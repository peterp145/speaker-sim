library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library speaker_sim_lib;
use speaker_sim_lib.speaker_sim_pkg.all;


package codec_bfm_pkg is
    -- constants and types
    -- analog io
    subtype t_codec_voltage is real range -1.0 to 1.0;

    -- serial port
    constant SPORT_TSU : time := 5 ns;
    constant SPORT_THD : time := 15 ns;
    constant SPORT_DLY : time := 30 ns;

    subtype t_sport_word is std_ulogic_vector(15 downto 0);
    function to_t_data_word(
        val : t_codec_voltage
        ) return t_codec_word;
    function to_t_codec_voltage(
        val : t_codec_word
        ) return t_codec_voltage;

    -- registers

    -- adc
    constant ADC_GROUP_DELAY : time := 505 us;

    -- dac
    constant DAC_GROUP_DELAY : time := 910 us;

    -- io records
    type t_codec_bfm_i_rec is record
        codec_mclk  : std_ulogic;
        codec_rst_n : std_ulogic;
        codec_dclk  : std_ulogic;
        codec_dfs   : std_ulogic;
        codec_din   : std_ulogic;
        v_adc_in    : t_codec_voltage;
    end record t_codec_bfm_i_rec;

    type t_codec_bfm_o_rec is record
        codec_dout    : std_ulogic;
        v_dac_out     : t_codec_voltage;
        word_dac_out  : t_codec_word;
        word_adc_out  : t_codec_word;
    end record t_codec_bfm_o_rec;

    ------ helper functions/procedures ------
    
end package codec_bfm_pkg;

package body codec_bfm_pkg is
    function to_t_data_word(
        val : t_codec_voltage
        ) return t_codec_word is

        variable real_max   : real
            := real(to_integer(CODEC_WORD_MAX));
        variable val_real   : real
            := real_max * val;
        variable val_int    : integer
            := integer(round(val_real));
        variable val_signed : signed(t_codec_word'range)
            := to_signed(val_int, t_codec_word'length);
    begin
        return t_codec_word(val_signed);
    end function to_t_data_word;

    function to_t_codec_voltage(
        val : t_codec_word
        ) return t_codec_voltage is

        variable real_max   : real
            := real(to_integer(CODEC_WORD_MAX));
        variable val_signed : signed(t_codec_word'range)
            := signed(val);
        variable val_int    : integer
            := to_integer(val_signed);
        variable val_real   : real
            := real(val_int)/real_max;

    begin
        return t_codec_voltage(val_real);
    end function to_t_codec_voltage;
    
end package body codec_bfm_pkg;