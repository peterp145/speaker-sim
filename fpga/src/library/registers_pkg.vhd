----------
-- file:        registers_pkg.vhd
-- description: package containinging registers for reuse
-- author:      peter phelan
-- email:       peter@peterphelan.net
----------

library IEEE;
use IEEE.std_logic_1164.all;

-- library xil_defaultlib;
-- use xil_defaultlib.utils_pkg.all;

package registers_pkg is
    -- io types
    type trec_reg_in is record
        clk         : std_ulogic;
        load_word   : std_ulogic_vector;
        load_en     : std_ulogic;
        rst_n       : std_ulogic;
        rst_val     : std_ulogic_vector;
    end record trec_reg_in;

    type trec_sreg_in is record
        clk         : std_ulogic;
        load_word   : std_ulogic_vector;
        load_en     : std_ulogic;
        shift_bit   : std_ulogic;
        shift_en    : std_ulogic;
        rst_n       : std_ulogic;
        rst_val     : std_ulogic_vector;
    end record trec_sreg_in;

    subtype t_reg is std_ulogic_vector;

    procedure reg (
        signal i_reg_in : in    trec_reg_in;
        signal io_reg   : inout t_reg
    );

    procedure sreg_left (
        signal i_sreg_in    : in    trec_sreg_in;
        signal io_reg       : inout t_reg
    );
    
end package registers_pkg;

package body registers_pkg is
    -- register with load enable and active low reset
    procedure reg (
        signal i_reg_in : in    trec_reg_in;
        signal io_reg   : inout t_reg
    ) is
    begin
        -- wait until rising_edge(i_reg_in.clk);
        -- io_reg <=
        --     i_reg_in.rst_val    when not i_reg_in.rst_n else
        --     i_reg_in.load_word  when i_reg_in.load_en;
    end procedure reg;

    -- shift register, leftward shift
    procedure sreg_left (
        signal i_sreg_in    : in    trec_sreg_in;
        signal io_reg       : inout t_reg
    ) is
    begin
        -- wait until rising_edge(i_sreg_in.clk);
        -- io_reg <=
        --     i_sreg_in.rst_val                  when not i_sreg_in.rst_n else
        --     i_sreg_in.load_word                when i_sreg_in.load_en else
        --     io_reg(io_reg'length-2 downto 0) & i_sreg_in.shift_bit when i_sreg_in.shift_en;
    end procedure sreg_left;
    

end package body registers_pkg;