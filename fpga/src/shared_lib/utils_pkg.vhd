----------
-- file:        utils_pkg.vhd
-- description: package for simple shared utilities
-- author:      peter phelan
-- email:       peter@peterphelan.net
----------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

package utils_pkg is
    -- types

    -- helper functions
    function shift_l(
        i_reg   : std_ulogic_vector;
        i_bit   : std_ulogic
    ) return std_ulogic_vector;

    function eq (reg : unsigned;            val : integer) return std_ulogic;
    function eq (reg : std_ulogic_vector;   val : integer) return std_ulogic;

    function is_zeros( reg : std_ulogic_vector) return std_ulogic;
    function is_ones(  reg : std_ulogic_vector) return std_ulogic;

    function num_bits(val : integer) return integer;    -- number of bits needed to store an integer


end package utils_pkg;

package body utils_pkg is
    
    -- helper functions
    function shift_l(i_reg : std_ulogic_vector; i_bit : std_ulogic) return std_ulogic_vector is
    begin
        return std_ulogic_vector(i_reg(i_reg'LENGTH-2 downto 0) & i_bit);
    end function shift_l;

    function eq(reg : unsigned; val : integer) return std_ulogic is
        variable is_eq : std_ulogic;
    begin
        is_eq := '1' when (reg = to_unsigned(val,reg'length)) else '0';
        return is_eq;
    end function eq;

    function eq(reg : std_ulogic_vector; val : integer) return std_ulogic is
    begin
        return eq(unsigned(reg), val);
    end function eq;

    function is_zeros(reg : std_ulogic_vector) return std_ulogic is
    begin
        return eq(reg, 0);
    end function is_zeros;
    
    function is_ones(reg : std_ulogic_vector) return std_ulogic is
    begin
        return eq(reg, (2**reg'length)-1);
    end function is_ones;

    function num_bits(val : integer) return integer is
    begin
        return integer(ceil(log2(real(val))));
    end function num_bits;
    
end package body utils_pkg;