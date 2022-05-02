library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package func_gen_bfm_pkg is
    generic (
        N_SAMPLES : positive;
        type        T_SAMPLE
    );

    type T_SAMPLE_ARR is array (integer range 0 to N_SAMPLES-1) of T_SAMPLE;

    -- bfm
    type func_gen_bfm is protected
        -- procedure init(samples : in t_sample_array);
        -- impure function next_sample return t_sample;
    end protected func_gen_bfm;

end package func_gen_bfm_pkg;

package body func_gen_bfm_pkg is
    type func_gen_bfm is protected body
        -- variables
        variable v_samples : T_SAMPLE_ARR;
        -- variable v_idx : integer range t_sample_array'range;

        -- implementation
        -- procedure init (samples : in t_sample_array) is
        -- begin
        --     v_samples := samples;
        --     v_idx := 0;
        -- end;

        -- impure function next_sample return t_sample is
        --     variable v : t_sample;
        -- begin
        --     v := v_samples(v_idx);
        --     v_idx := v_idx + 1;
        --     return v;
        -- end;

    end protected body func_gen_bfm; 

end package body func_gen_bfm_pkg;