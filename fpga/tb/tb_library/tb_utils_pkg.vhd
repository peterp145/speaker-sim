----------
-- file:        utils_pkg.vhd
-- description: package for simple shared utilities
-- author:      peter phelan
-- email:       peter@peterphelan.net
----------
use std.textio.all;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_textio.all;

use IEEE.math_real.uniform;
use IEEE.math_real.floor;


-- library shared_lib;
library tb_library;
use tb_library.codec_bfm_pkg;

package tb_utils_pkg is
    use codec_bfm_pkg.all;

    -- types
    type real_array is array (integer range <>) of real;

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
        constant    comb_dly    : time
    );

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
            constant s2 : in t_seed2
        );
        procedure rand (
            signal rand_int_val : out integer;
            constant max : in integer
        );
        procedure rand(
            signal rand_sulv_val : out std_ulogic_vector
        );
        procedure rand(
            signal rand_val : out signed
        );
    end protected t_rand_gen;
    
    -- file io
    procedure read_into_array (
        constant fname      : in  string;
        variable dest_array : out real_array
    );
    
    procedure write_from_array (
        constant fname     : in  string;
        variable src_array : out real_array
    );

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
        constant    comb_dly    : time
    ) is
    begin
        wait until rising_edge(clk);
        wait for comb_dly;
    end procedure wait_clk;

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
            constant s2 : in t_seed2
        ) is
        begin
            seed1 := s1;
            seed2 := s2;
        end procedure init;

        procedure rand (
            signal rand_int_val : out integer;
            constant max : in integer
        ) is
            variable rand_val : real;
        begin
            uniform(seed1, seed2, rand_val);
            rand_int_val <= integer(floor(rand_val*max));
        end procedure rand;
        
        procedure rand (
            signal rand_sulv_val : out std_ulogic_vector
        ) is
            constant max : integer := (2**rand_sulv_val'length)-1;
            variable rand_val : real;
            variable rand_int_val : integer;
        begin
            uniform(seed1, seed2, rand_val);
            rand_int_val := integer(floor(rand_val*max));
            rand_sulv_val <= std_ulogic_vector(to_unsigned(rand_int_val, rand_sulv_val'length));
        end procedure rand;

        procedure rand (
            signal rand_val : out signed
        ) is
            constant len : integer := rand_val'length;
            constant max : integer := (2**len)-1;
            variable rand_real : real;
            variable rand_int_val : integer;
        begin
            uniform(seed1, seed2, rand_real);
            rand_int_val := integer(floor(rand_real*max));
            rand_val <= signed(std_ulogic_vector(to_unsigned(rand_int_val, len)));
        end procedure rand;

    end protected body t_rand_gen;

    -- file io
    procedure read_into_array (
        constant fname : in string;
        variable dest_array : out real_array
    ) is
        file     f : text open read_mode is fname;
        variable l : line;
        variable val : real;
        variable sample_array : real_array(dest_array'range)
            := (others => 0.0);
    begin
        for i in dest_array'range loop
            exit when endfile(f);
            readline(f, l);
            read(l, val);
            sample_array(i) := val;
        end loop;
        dest_array := sample_array;
    end procedure read_into_array;
    
    procedure write_from_array (
        constant fname : in string;
        variable src_array : out real_array
    ) is
        file     f : text open write_mode is fname;
        variable l : line;
        variable val : real;
        -- variable sample_array : real_array(dest_array'range)
        --     := (others => 0.0);
    begin
        for i in src_array'range loop
            write(l, to_string(src_array(i), "%32.31f"));
            writeline(f, l);
        end loop;
    end procedure write_from_array;

end package body tb_utils_pkg;