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

-- library shared_lib;

package tb_utils_pkg is
    ----- tb debug -----
    procedure print(
        constant str : in string    -- string to print
    );

    ----- tb assertions -----
    procedure assert_eq (
        constant actual     : in std_ulogic;     -- value under test
        constant expected   : in std_ulogic;     -- expected value
        constant err_msg    : in string -- error message
    );
    
    ----- tb timing -----
    procedure wait_clk(
        signal      clk         : std_ulogic;
        constant    comb_dly    : time;
        constant    num_clks    : positive
    );

    ----- random number generator -----
    subtype t_seed1 is positive range 1 to 2147483562;
    subtype t_seed2 is positive range 1 to 2147483398;
    
    type t_rand_gen is protected
        procedure init (
            constant s1 : in t_seed1;
            constant s2 : in t_seed2);
        procedure rand_int(
            signal rand_int_val : out integer;
            constant max : in integer);
        procedure rand_sulv(signal rand_sulv_val : out std_ulogic_vector);
    end protected t_rand_gen;
    
end package tb_utils_pkg;

package body tb_utils_pkg is
    ----- tb debug -----
    procedure print(str : in string) is
    begin
        report str severity note;
    end procedure print;
    
    ----- tb assertions -----
    procedure assert_eq(
        constant actual     : in std_ulogic;     -- value under test
        constant expected   : in std_ulogic;     -- expected value
        constant err_msg    : in string -- error message
    ) is
    begin
        assert actual = expected
            report "error with " & err_msg & LF &
            "    actual: " & to_string(actual) & ", expected: " & to_string(expected)
                severity failure; 
                
    end procedure assert_eq;

    ----- tb timing -----
    procedure wait_clk (
        signal      clk         : std_ulogic;
        constant    comb_dly    : time;
        constant    num_clks    : positive
    ) is
    begin
        for i in 0 to num_clks-1 loop
            wait until rising_edge(clk);
            wait for comb_dly;
        end loop;
        end procedure wait_clk;
        
    ----- random number generator -----
    type t_rand_gen is protected body
        variable seed1 : t_seed1 := 1;
        variable seed2 : t_seed2 := 2;
        
        procedure init (
            constant s1 : in t_seed1;
            constant s2 : in t_seed2) is
        begin
            seed1 := s1;
            seed2 := s2;
        end procedure init;

        procedure rand_int(
            signal rand_int_val : out integer;
            constant max : in integer) is
            variable rand_val : real;
        begin
            uniform(seed1, seed2, rand_val);
            rand_int_val <= integer(floor(rand_val*max));
        end procedure rand_int;
        
        procedure rand_sulv(signal rand_sulv_val : out std_ulogic_vector) is
            constant max : integer := (2**rand_sulv_val'length)-1;
            variable rand_val : real;
            variable rand_int_val : integer;
        begin
            uniform(seed1, seed2, rand_val);
            rand_int_val := integer(floor(rand_val*max));
            rand_sulv_val <= std_ulogic_vector(to_unsigned(rand_int_val, rand_sulv_val'length));
        end procedure rand_sulv;

    end protected body t_rand_gen;

end package body tb_utils_pkg;