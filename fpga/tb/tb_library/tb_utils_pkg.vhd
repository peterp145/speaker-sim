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
    procedure assert_eq(
        constant actual     : in std_ulogic;    -- value under test
        constant expected   : in std_ulogic;    -- expected value
        constant err_msg    : in string         -- error message
    );
    
    ----- tb timing -----
    procedure wait_clk(
        signal      clk         : std_ulogic;
        constant    comb_dly    : time;
        constant    num_clks    : positive
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
        constant actual     : in std_ulogic;
        constant expected   : in std_ulogic;
        constant err_msg    : in string
    ) is
    begin
        assert actual = expected
            report "error with " & err_msg & LF &
                "    actual: " & to_string(actual) & ", expected: " & to_string(expected)
                severity failure; 
                
    end procedure assert_eq;

    ----- tb timing -----
    procedure wait_clk(
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
    
end package body tb_utils_pkg;