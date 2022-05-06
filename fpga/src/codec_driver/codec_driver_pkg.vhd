----------
-- file:        codec_driver_pkg.vhd
-- description: package containinging codec_driver constants and records
-- author:      peter phelan
-- email:       peter@peterphelan.net
----------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library speaker_sim_lib;
use speaker_sim_lib.speaker_sim_pkg.all;

package codec_driver_pkg is
    constant REG_A_WORD : t_codec_word := B"1000_0000_0111_1100_0000_0000";
    constant REG_C_WORD : t_codec_word := B"1001_0000_0011_0101_0000_0000";

    type t_codec_driver_i_rec is record
        rst_n               : std_ulogic;   -- system reset
        clken_12M           : std_ulogic;   -- 12.288 MHz clock enable
        codec_dout          : std_ulogic;   -- codec adc data from codec
        dsp_dac_word        : t_codec_word; -- word to write to codec dac
        dsp_dac_word_valid  : std_ulogic;   -- new codec dac word valid flag
    end record t_codec_driver_i_rec;

    type t_codec_driver_o_rec is record
        codec_mclk          : std_ulogic;   -- codec master clock
        codec_rst_n         : std_ulogic;   -- codec reset
        codec_dclk          : std_ulogic;   -- codec serial port clock
        codec_dfs           : std_ulogic;   -- codec serial port sync
        codec_din           : std_ulogic;   -- dac data to codec
        dsp_adc_word        : t_codec_word; -- word read from adc
        dsp_adc_word_valid  : std_ulogic;   -- adc word is ready
    end record t_codec_driver_o_rec;
end package codec_driver_pkg;