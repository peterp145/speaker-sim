----------
-- file:        registers_pkg.vhds
-- description: package containinging registers for reuse
-- author:      peter phelan
-- email:       peter@peterphelan.net
----------

library IEEE;
use IEEE.std_logic_1164.all;

-- library xil_defaultlib;
-- use xil_defaultlib.utils_pkg.all;

package registers_pkg is
    -------- reg --------
    type t_reg_i_rec is record
        load_word   : std_ulogic_vector; -- word to load into reg
        load_en     : std_ulogic;        -- load enable
        rst_n       : std_ulogic;        -- reset
    end record t_reg_i_rec;

    type t_reg_o_rec is record
        word : std_ulogic_vector; -- register
    end record t_reg_o_rec;
    
    type t_reg_rec is record
        i : t_reg_i_rec;
        o : t_reg_o_rec;
    end record t_reg_rec;

    component reg is
        port (
            clk   : in  std_ulogic;  -- logic clock
            i_rec : in  t_reg_i_rec; -- input record
            o_rec : out t_reg_o_rec  -- output record
        );
    end component reg;
        
    -------- sreg --------
    type t_sreg_i_rec is record
        load_word   : std_ulogic_vector;
        load_en     : std_ulogic;
        shift_bit   : std_ulogic;
        shift_en    : std_ulogic;
        rst_n       : std_ulogic;
    end record t_sreg_i_rec;

    type t_sreg_o_rec is record
        word : std_ulogic_vector;
    end record t_sreg_o_rec;

    type t_sreg_rec is record
        i : t_sreg_i_rec;
        o : t_sreg_o_rec;
    end record t_sreg_rec;

    component sreg is
        generic (g_RESET_BIT : std_ulogic := '0');
        port (
            clk   : in  std_ulogic;
            i_rec : in  t_sreg_i_rec;
            o_rec : out t_sreg_o_rec
        );
    end component sreg;
    
end package registers_pkg;