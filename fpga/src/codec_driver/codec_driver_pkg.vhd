----------
-- file:        codec_driver_pkg.vhd
-- description: package containinging counters for reuse
-- author:      peter phelan
-- email:       peter@peterphelan.net
----------

library IEEE;
use IEEE.std_logic_1164.all;

package codec_driver_pkg is
    constant REG_A_WORD     : std_ulogic_vector (15 downto 0) := B"1000_0000_0111_1100";
    constant REG_C_WORD     : std_ulogic_vector (15 downto 0) := B"1001_0000_0011_0101";
    
    component codec_driver is
        port (
            -- clock and reset
            i_clk_12M   :   in  std_ulogic;  -- 12.288MHz clock for logic and codec mclk
            i_rst_n     :   in  std_ulogic;  -- system reset
            -- controller if
            i_ctrl_dac_word :   in  std_ulogic_vector(23 downto 0);
            o_codec_mclk    :   out std_ulogic;  -- codec master clock
            o_codec_rst_n   :   out std_ulogic;  -- codec reset signal
            o_codec_dclk    :   out std_ulogic;  -- codec serial clock
            o_codec_dfs     :   out std_ulogic;  -- codec dfs
            o_codec_din     :   out std_ulogic;  -- serial data to codec
            i_codec_dout    :   in  std_ulogic   -- serial data from codec
        );
    end component codec_driver;
end package codec_driver_pkg;