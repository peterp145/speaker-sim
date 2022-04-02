----------
-- file:        utils_pkg.vhd
-- description: package for simple shared utilities
-- author:      peter phelan
-- email:       peter@peterphelan.net
----------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_textio.all;

use IEEE.math_real.uniform;
use IEEE.math_real.floor;

use std.textio.all;

package tb_utils_pkg is
    -- constant SEED1_MAX : integer := 2147483561;
    -- constant SEED2_MAX : integer := 2147483397;

    -- random number generator
    -- type t_rand_gen is protected
    --     procedure p_init;
    --     -- procedure p_init(s1, s2 : positive);
    --     -- procedure _rand_int(constant max : in integer; variable result : out integer);
    --     -- procedure p_rand_unsigned(signal result : out unsigned);
    --     impure function  f_rand_sulv(constant word_width : integer) return std_ulogic_vector;
    --     -- procedure p_rand_sulv(signal result : out std_ulogic_vector);
    -- end protected t_rand_gen;
    
    -- testbench assertions
    procedure p_print(constant str : in string);

    procedure p_assert_eq(actual, expected: in std_ulogic; err_msg: in string);
    
    -- testchench timing
    procedure p_wait_clk(signal clk : std_ulogic; constant comb_dly : time);
    
end package tb_utils_pkg;

package body tb_utils_pkg is
    
    -- type t_rand_gen is protected body
    --     -- variables
    --     variable    seed1   : positive;
    --     variable    seed2   : positive;
        
    --     -- methods
    --     procedure p_init is
    --     begin
    --         report "rand init" severity note;
    --         seed1 := 1;
    --         seed2 := 2;
    --         report "rand init" severity note;
    --     end procedure p_init;
        
    --     -- procedure p_init(s1, s2 : positive) is
    --     -- begin
    --     --     seed1 := s1;
    --     --     seed2 := s2;
    --     -- end procedure p_init;
        
    --     -- procedure p_rand_int(constant max : in integer; variable result : out integer) is
    --     --     variable val : real;
    --     -- begin
    --     --     uniform(seed1, seed2, val);
    --     --     result := integer(floor(val * max));
    --     -- end procedure p_rand_int;
        
    --     -- procedure p_rand_unsigned(signal result : out unsigned) is
    --     --     variable real_val   : real;
    --     --     variable int_val    : integer;
    --     -- begin            report to_string(int_val);
    --     --     result <= to_unsigned(int_val, result'length);
    --     -- end procedure p_rand_unsigned;
        
    --     impure function  f_rand_sulv(constant word_width : integer) return std_ulogic_vector is
    --         variable real_val   : real;
    --         variable int_val    : integer;
    --     begin
    --         p_print("seed1: " & to_string(seed1));
    --         if seed1 > SEED1_MAX then
    --             seed1 := seed1 - SEED1_MAX;
    --         end if;
    --         if seed2 > SEED2_MAX then
    --             seed2 := seed2 - SEED2_MAX;
    --         end if;
    --         uniform(seed1, seed2, real_val);
    --         int_val := integer(floor(real_val * ((2**word_width)-1)));
    --         return std_ulogic_vector(to_unsigned(int_val, word_width));
    --     end function f_rand_sulv;

    --     -- procedure p_rand_sulv(signal result : out std_ulogic_vector) is
    --     --     variable real_val   : real;
    --     -- begin
    --     --     result <= f_rand_sulv(result'length);
    --     -- end procedure p_rand_sulv;
        
    -- end protected body t_rand_gen;

    procedure p_print(str : in string) is
    begin
        report str severity note;
    end procedure p_print;

    procedure p_assert_eq(actual, expected: in std_ulogic;err_msg: in string) is
    begin
        assert actual = expected
            report "error with " & err_msg & LF &
                "    actual: " & to_string(actual) & ", expected: " & to_string(expected)
                severity failure; 
                
    end procedure p_assert_eq;

    procedure p_wait_clk(signal clk : std_ulogic; constant comb_dly : time) is
    begin
        wait until rising_edge(clk);
        wait for comb_dly;
    end procedure p_wait_clk;
    
end package body tb_utils_pkg;