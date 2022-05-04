----------
-- file:        speaker sim.vhd
-- description: top level project package
-- author:      peter phelan
-- email:       peter@peterphelan.net
----------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- my rtl
package speaker_sim_pkg is
    -- constants and types
    constant CODEC_WORD_WIDTH : integer := 24;
    subtype t_codec_word is signed(CODEC_WORD_WIDTH-1 downto 0);
    constant CODEC_WORD_MAX : t_codec_word := (CODEC_WORD_WIDTH-1 => '0', others => '1');
    constant CODEC_WORD_MIN : t_codec_word := (CODEC_WORD_WIDTH-1 => '1', others => '0');
    
    
    -- types
    
end package speaker_sim_pkg;