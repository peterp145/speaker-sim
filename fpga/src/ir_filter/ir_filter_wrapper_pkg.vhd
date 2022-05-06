----------
-- file:        ir_filter_wrapper_pkg.vhd
-- description: package wrapper for matlab generated impulse response fir filter
-- author:      peter phelan
-- email:       peter@peterphelan.net
----------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library speaker_sim_lib;
use speaker_sim_lib.speaker_sim_pkg.all;

package ir_filter_wrapper_pkg is
    -- io records
    type t_ir_filter_wrapper_i_rec is record
        rst_n           : std_ulogic;   -- system reset, active low
        data_in         : t_codec_word; -- codec adc word
        data_in_valid   : std_ulogic;   -- codec adc word new data valid
    end record t_ir_filter_wrapper_i_rec;

    type t_ir_filter_wrapper_o_rec is record
        data_out        : t_codec_word;
        data_out_valid  : std_ulogic;
    end record t_ir_filter_wrapper_o_rec;

end package ir_filter_wrapper_pkg;