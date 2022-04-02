library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library xil_defaultlib;
-- use xil_defaultlib.tb_utils_pkg.all;
use xil_defaultlib.codec_driver_pkg.all;

package speaker_sim_tb_pkg is
    type t_adc_word_gen is protected
        procedure p_init;
        impure function f_get_adc_word return std_ulogic_vector;
    end protected t_adc_word_gen;

end package speaker_sim_tb_pkg;

package body speaker_sim_tb_pkg is
    type t_adc_word_gen is protected body
        -- variable a_init : std_ulogic;
        -- variable c_init : std_ulogic;
        -- variable rand_gen : t_rand_gen;

        procedure p_init is
        begin
            -- rand_gen.p_init;
            a_init := '0';
            c_init := '0';
            p_print("adc word gen init");
        end procedure p_init;

        impure function f_get_adc_word return std_ulogic_vector is
            variable adc_word : std_ulogic_vector(127 downto 0);
        begin
            if not a_init then
                adc_word := (
                    127 downto 112 => REG_A_WORD,
                    111 downto 96 => X"0000",
                    others => 'Z'
                );
                a_init := '1';
            elsif not c_init then
                adc_word := (
                    127 downto 112 => REG_C_WORD,
                    111 downto 96 => X"0000",
                    others => 'Z'
                );
                c_init := '1';
            else
                adc_word := (
                    127 downto 96 => X"0000_0000",
                    95  downto 72 => rand_gen.f_rand_sulv(24),
                    others => 'Z'
                );                    
                end if;
            return adc_word;
        end function f_get_adc_word;
    
    end protected body t_adc_word_gen;
end package body speaker_sim_tb_pkg;