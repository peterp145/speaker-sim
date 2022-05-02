library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- Library UNISIM;
-- use UNISIM.vcomponents.all;

library shared_lib;
use shared_lib.utils_pkg.all;
use shared_lib.flip_flops_pkg.all;
-- use shared_lib.dff;
-- use shared_lib.cdffs;
use shared_lib.registers_pkg.all;
-- use shared_lib.sreg;
use shared_lib.counter_pkg.all;

library speaker_sim_lib;
use speaker_sim_lib.clock_and_reset_pkg.all;

entity clock_and_reset is
    port (
        i_clk_125M : in  std_ulogic; -- input record
        o_rec      : out t_clock_and_reset_o_rec  -- output record
    );
end entity clock_and_reset;

architecture rtl of clock_and_reset is
    -- shared clock buffer for both mmcms
    -- signal bufg_clk_125M : std_ulogic;

    -- constant clk_gen_rstn : std_logic := '1';
    signal clk_gen_rst_n : std_ulogic := '1';
    signal clk_100M, r_clk_100M_locked : std_ulogic;    -- 100MHz MMCM
    signal clk_122M, r_clk_122M_locked : std_ulogic;    -- 122.88MHz MMCM
    
    -- clock enable counters
    constant CLKEN_100K_COUNT_MAX : integer := 999;
    signal clken_100k_counter     : t_counter_rec(o(count(num_bits(CLKEN_100K_COUNT_MAX)-1 downto 0)));
    constant CLKEN_12M_COUNT_MAX  : integer := 9;
    signal clken_12M_counter      : t_counter_rec(o(count(num_bits(CLKEN_12M_COUNT_MAX)-1  downto 0)));

    ----- clock ready -----
    constant READY_SREG_NUM_BITS : integer := 10;
    subtype t_sreg_word is std_ulogic_vector(READY_SREG_NUM_BITS-1 downto 0);
    subtype t_sreg_ready_rec is t_sreg_rec(              -- CLK100M reset sreg
        i( load_word(t_sreg_word'range) ), 
        o( word(t_sreg_word'range) )
    ); 

    -- 100MHz ready
    signal sreg_clk_100M_rdy  : t_sreg_ready_rec;
    signal dff_clk_100M_rdy_100M : std_ulogic;    -- CLK100M ready, system clock domain
        
    -- 122MHz ready
    signal sreg_clk_122M_rdy  : t_sreg_ready_rec; -- CLK122M reset sreg
    signal dff_clk_122M_rdy_122M   : std_ulogic;    -- CLK12M ready, system clock domain
    
    ----- system reset generation -----
    -- CLK100M domain
    signal cdcff_clk_122M_rdy_100M    : std_ulogic; -- 12M ready signal clock domain crossing
    signal dff_sys_rst_n_100M : std_ulogic;    -- system reset generation, 100M
    
    -- CLK12M domain
    signal cdcff_clk_100M_rdy_122M  : std_ulogic; -- 12M ready signal clock domain crossing
    signal dff_sys_rst_n_122M    : std_ulogic;    -- system reset generation, 100M
    
begin
    ----- clock and reset generation -----
    -- ip instantiations 
    -- u_bufg : bufg
    -- port map (bufg_clk_125M, i_clk_125M);

    u_clk_wiz_0 : clk_wiz_0
    port map(
        o_clk_100M  => clk_100M,        -- 100MHz clock for system
        resetn      => clk_gen_rst_n,             -- MMCM reset
        o_locked    => r_clk_100M_locked,    -- MMCM locked
        i_clk_125M  => i_clk_125M       -- on board 125M clock
    );

    u_clk_wiz_1 : clk_wiz_1
    port map(
        o_clk_122M88  => clk_122M,        -- 122MHz clock for dsp and codec
        resetn        => clk_gen_rst_n,             -- MMCM reset
        o_locked      => r_clk_122M_locked,    -- MMCM locked
        i_clk_125M    => i_clk_125M       -- on board 125M clock
    );

    ----- reset count logic -----
    -- reset shift register clocks in reset value, must be deasserted for set number of clock cycles
    -- before becoming valid
    -- ensures both clocks and reset input are stable
    
    -- 100M clock ready
    sreg_clk_100M_rdy.i.clken        <= '1';
    sreg_clk_100M_rdy.i.load_word    <= (others => '0');
    sreg_clk_100M_rdy.i.load_en      <= '0';
    sreg_clk_100M_rdy.i.shift_en     <= '1';
    sreg_clk_100M_rdy.i.rst_n        <= '1';
    sreg_clk_100M_rdy.i.shift_bit    <= r_clk_100M_locked;
    
    u_sreg_clk_100M_rdy : entity shared_lib.sreg
    port map (clk_100M, sreg_clk_100M_rdy.i, sreg_clk_100M_rdy.o);
    
    u_dff_clk_100M_rdy_100M : entity shared_lib.dff
    port map (clk_100M, is_ones(sreg_clk_100M_rdy.o.word), dff_clk_100M_rdy_100M);
        
    -- 122M clock ready
    sreg_clk_122M_rdy.i.clken        <= '1';
    sreg_clk_122M_rdy.i.load_word     <= (others => '0');
    sreg_clk_122M_rdy.i.load_en       <= '0';
    sreg_clk_122M_rdy.i.shift_en      <= '1';
    sreg_clk_122M_rdy.i.rst_n         <= '1';
    sreg_clk_122M_rdy.i.shift_bit     <= r_clk_122M_locked;
    
    u_sreg_clk_122M_rdy : entity shared_lib.sreg
    port map (clk_122M, sreg_clk_122M_rdy.i, sreg_clk_122M_rdy.o);
    
    u_dff_clk_122M_rdy_122M : entity shared_lib.dff
        port map (clk_122M, is_ones(sreg_clk_122M_rdy.o.word), dff_clk_122M_rdy_122M);
    
    ----- system resets -----
    -- 100M
    u_cdcffs_clk_122M_rdy_122to100M : entity shared_lib.cdcffs
    port map (clk_100M, dff_clk_122M_rdy_122M, cdcff_clk_122M_rdy_100M);

    u_dff_sys_rst_n_100M : entity shared_lib.dff
    port map (
        clk_100M,
        dff_clk_100M_rdy_100M and cdcff_clk_122M_rdy_100M,
        dff_sys_rst_n_100M)
    ;

    -- 122M reset
    u_cdcffs_clk_100_rdy_100to12M : entity shared_lib.cdcffs
        port map (clk_122M, dff_clk_100M_rdy_100M, cdcff_clk_100M_rdy_122M);

    u_dff_sys_rst_n_12M : entity shared_lib.dff
        port map (
            clk_122M,
            dff_clk_122M_rdy_122M and cdcff_clk_100M_rdy_122M,
            dff_sys_rst_n_122M);

    ----- clock enables -----
    -- counter for creating 100KHz clock enable in 100M domain
    clken_100k_counter.i <= ('1', dff_sys_rst_n_100M, '1');
    u_clken_100k_counter : entity shared_lib.counter 
    generic map (CLKEN_100K_COUNT_MAX)
    port map(clk_100M, clken_100k_counter.i, clken_100k_counter.o);

    -- counter for creating 12M clock enable in 122M domain
    clken_12M_counter.i <= ('1', dff_sys_rst_n_122M, '1');
    u_clken_12M_counter : entity shared_lib.counter 
    generic map (CLKEN_12M_COUNT_MAX)
    port map(clk_122M, clken_12M_counter.i, clken_12M_counter.o);

    -- ----- output drivers -----
    o_rec.clk_100M        <= clk_100M;
    o_rec.clk_122M        <= clk_122M;
    o_rec.clken_100M_100k <= clken_100k_counter.o.done;
    o_rec.clken_122M_12M  <= clken_12M_counter.o.done;
    o_rec.sys_rst_n_100M  <= dff_sys_rst_n_100M;
    o_rec.sys_rst_n_122M  <= dff_sys_rst_n_122M;
    
end architecture rtl;