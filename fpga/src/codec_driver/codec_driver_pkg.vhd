----------
-- file:        codec_driver_pkg.vhd
-- description: package containinging counters for reuse
-- author:      peter phelan
-- email:       peter@peterphelan.net
----------

library IEEE;
use IEEE.std_logic_1164.all;

package codec_driver_pkg is
    type t_codec_driver_i_rec is record
        rst_n               : std_ulogic;   -- system reset
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

    type t_codec_driver_rec is record
        i : t_codec_driver_i_rec;
        o : t_codec_driver_o_rec;
    end record t_codec_driver_rec;
    
    constant REG_A_WORD     : std_ulogic_vector (15 downto 0) := B"1000_0000_0111_1100";
    constant REG_C_WORD     : std_ulogic_vector (15 downto 0) := B"1001_0000_0011_0101";
    
    component codec_driver is
        port (
            i_clk_122M88 : in  std_ulogic; -- 122.88MHz clock for logic and codec mclk
            i_rec        : in  t_codec_driver_i_rec; -- input record
            o_rec        : out t_codec_driver_o_rec  -- output record
        );
    end component codec_driver;
end package codec_driver_pkg;