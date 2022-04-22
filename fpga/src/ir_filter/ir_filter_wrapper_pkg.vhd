----------
-- file:        ir_filter_wrapper_pkg.vhd
-- description: wrapper for matlab generated impulse response fir filter
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

    -- component
    component ir_filter_wrapper
        port (
            i_clk_dsp_122M88    : in  std_ulogic; -- clock input
            i_rec               : in  t_ir_filter_wrapper_i_rec; -- input port record
            o_rec               : out t_ir_filter_wrapper_o_rec -- output port record
        );
    end component ir_filter_wrapper;

end package ir_filter_wrapper_pkg;