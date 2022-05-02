-------------------------------------------------------------------------------
-- file:        speaker_sim_tb_pkg.vhd
-- description: configuration, types, and imports for top level speaker_sim.vhd simulation
-- author:      peter phelan
-- email:       peter@peterphelan.net
-------------------------------------------------------------------------------

-------- imports --------------------------------
------ standard libraray ------
library ieee;
-- standard types
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-- use ieee.std_logic_textio.all;
-- file io
-- use std.textio.all;

------ shared tb library ------
library tb_library;
use tb_library.tb_utils_pkg.real_array;

------ project design library ------
-- library speaker_sim_lib;


-------- pkg declaration ----------------------------------------------------------------
package speaker_sim_tb_pkg is
    ----- testbench configuration -----
    -- simulation settings
    constant COMB_DLY : time := 1ns;

    -- clock and reset
    constant CLK_125M_PER_ns : time := (1000.0/125.0) * 1ns;
    constant T_RESET_ns : time := 5.5 * CLK_125M_PER_ns;

    ------ func gen bfm ------
    -- timing
    constant FUNC_GEN_FS  : integer := 48000;
    constant FUNC_GEN_PER : time    := 1e9 ns / FUNC_GEN_FS; 

    -- sample file name and config
    constant RAMP_FNAME : string := "ess_1s_48khz.txt";
    constant FUNC_GEN_N_SAMPLES : integer := 48000;
    constant SAMP_V_MAX : real :=  1.0;
    constant SAMP_V_MIN : real := -1.0;

    ------ data recorder ------
    constant REC_FNAME : string := "recorder_48khz.txt";
    constant RECORDER_N_SAMPLES : integer := 5000;
    constant RECORDER_START_DLY : time := 350 us;


    -- sample file types
    subtype T_SAMPLE is real range SAMP_V_MIN to SAMP_V_MAX;
    type T_SAMPLE_ARR is array (integer range 0 to FUNC_GEN_N_SAMPLES-1) of T_SAMPLE;
    function to_T_SAMPLE_ARR(real_vals : real_array) return T_SAMPLE_ARR;

    ------ package imports ------
    -- declarations

    -- usages

end package speaker_sim_tb_pkg;

-------- pkg body ----------------------------------------------------------------
package body speaker_sim_tb_pkg is
    
    -------- function definitions --------
    function to_T_SAMPLE_ARR(
        real_vals : real_array
    ) return T_SAMPLE_ARR is
        variable sample_array : T_SAMPLE_ARR := (others => 0.0);
    begin
        for i in sample_array'range loop
            sample_array(i) := T_SAMPLE(real_vals(i));
        end loop;
        return sample_array;
    end function to_T_SAMPLE_ARR;
    
end package body speaker_sim_tb_pkg;