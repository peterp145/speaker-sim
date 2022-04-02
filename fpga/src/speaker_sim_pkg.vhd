----------
-- file:        speaker sim.vhd
-- description: top level project package
-- author:      peter phelan
-- email:       peter@peterphelan.net
----------

library IEEE;
use IEEE.std_logic_1164.all;

-- my rtl
package speaker_sim_pkg is
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
            o_leds      : out   std_ulogic_vector(3 downto 0)
        );
    end component speaker_sim;
end package speaker_sim_pkg;