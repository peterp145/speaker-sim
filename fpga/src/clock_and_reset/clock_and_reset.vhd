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
    signal clk_100M, r_clk_100M_locked : std_ulogic := '0';    -- 100MHz MMCM
    signal clk_122M, r_clk_122M_locked : std_ulogic := '0';    -- 122.88MHz MMCM
    
    -- clock enable counters
    constant CLKEN_100K_COUNT_MAX :  integer := 999;
    signal clken_100k_counter_i : t_counter_i_rec
        := ('0', '0', '0');
    signal clken_100k_counter_o : t_counter_o_rec (count(num_bits(CLKEN_100K_COUNT_MAX)-1 downto 0))
        := ((others => '0'), '0');
        
    constant CLKEN_12M_COUNT_MAX  :  integer := 9;
    signal clken_12M_counter_i : t_counter_i_rec
        := ('0', '0', '0');
    signal clken_12M_counter_o : t_counter_o_rec (count(num_bits(CLKEN_12M_COUNT_MAX)-1 downto 0))
        := ((others => '0'), '0');

    ----- clock ready -----
    constant READY_SREG_NUM_BITS : integer := 10;
    subtype t_sreg_word is std_ulogic_vector(READY_SREG_NUM_BITS-1 downto 0);
    subtype t_sreg_ready_i_rec is t_sreg_i_rec( load_word(t_sreg_word'range) );
    subtype t_sreg_ready_o_rec is t_sreg_o_rec( word(t_sreg_word'range) ); 

    -- 100MHz ready
    signal sreg_clk_100M_rdy_i : t_sreg_ready_i_rec
        := ( load_word => (others => '0'), others => '0' );
    signal sreg_clk_100M_rdy_o : t_sreg_ready_o_rec
        := ( word => (others => '0'));

    signal dff_clk_100M_rdy_100M : t_dff_rec := (others => '0');    -- CLK100M ready, system clock domain
        
    -- 122MHz ready
    signal sreg_clk_122M_rdy_i : t_sreg_ready_i_rec
        := ( load_word => (others => '0'), others => '0' );
    signal sreg_clk_122M_rdy_o : t_sreg_ready_o_rec
        := ( word => (others => '0'));

    signal dff_clk_122M_rdy_122M : t_dff_rec := (others => '0');    -- CLK12M ready, system clock domain
    
    ----- system reset generation -----
    -- CLK100M domain
    signal cdcff_clk_122M_rdy_100M    : t_dff_rec := (others => '0'); -- 12M ready signal clock domain crossing
    signal dff_sys_rst_n_100M : t_dff_rec := (others => '0');    -- system reset generation, 100M
    
    -- CLK12M domain
    signal cdcff_clk_100M_rdy_122M  : t_dff_rec; -- 12M ready signal clock domain crossing
    signal dff_sys_rst_n_122M : t_dff_rec := (others => '0');    -- system reset generation, 100M
    
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
    sreg_clk_100M_rdy_i.clken        <= '1';
    sreg_clk_100M_rdy_i.load_word    <= (others => '0');
    sreg_clk_100M_rdy_i.load_en      <= '0';
    sreg_clk_100M_rdy_i.shift_en     <= '1';
    sreg_clk_100M_rdy_i.rst_n        <= '1';
    sreg_clk_100M_rdy_i.shift_bit    <= r_clk_100M_locked;
    
    u_sreg_clk_100M_rdy : entity shared_lib.sreg
    port map (
        clk_100M,
        sreg_clk_100M_rdy_i,
        sreg_clk_100M_rdy_o
    );
    
    dff_clk_100M_rdy_100M.d <= is_ones(sreg_clk_100M_rdy_o.word);
    u_dff_clk_100M_rdy_100M : entity shared_lib.dff
    port map (
        clk_100M,
        dff_clk_100M_rdy_100M.d,
        dff_clk_100M_rdy_100M.q
    );
        
    -- 122M clock ready
    sreg_clk_122M_rdy_i.clken        <= '1';
    sreg_clk_122M_rdy_i.load_word     <= (others => '0');
    sreg_clk_122M_rdy_i.load_en       <= '0';
    sreg_clk_122M_rdy_i.shift_en      <= '1';
    sreg_clk_122M_rdy_i.rst_n         <= '1';
    sreg_clk_122M_rdy_i.shift_bit     <= r_clk_122M_locked;
    
    u_sreg_clk_122M_rdy : entity shared_lib.sreg
    port map (
        clk_122M,
        sreg_clk_122M_rdy_i,
        sreg_clk_122M_rdy_o
    );
    
    dff_clk_122M_rdy_122M.d <= is_ones(sreg_clk_122M_rdy_o.word);
    u_dff_clk_122M_rdy_122M : entity shared_lib.dff
    port map (
        clk_122M,
        dff_clk_122M_rdy_122M.d,
        dff_clk_122M_rdy_122M.q
    );
    
    ----- system resets -----
    -- 100M
    cdcff_clk_122M_rdy_100M.d <= dff_clk_122M_rdy_122M.q;
    u_cdcffs_clk_122M_rdy_122to100M : entity shared_lib.cdcffs
    port map (
        clk_100M,
        cdcff_clk_122M_rdy_100M.d,
        cdcff_clk_122M_rdy_100M.q
    );

    u_dff_sys_rst_n_100M : entity shared_lib.dff
    port map (
        clk_100M,
        dff_clk_100M_rdy_100M.q and cdcff_clk_122M_rdy_100M.q,
        dff_sys_rst_n_100M.q
    );

    -- 122M reset
    cdcff_clk_100M_rdy_122M.d <= dff_clk_100M_rdy_100M.q;
    u_cdcffs_clk_100_rdy_100to12M : entity shared_lib.cdcffs
    port map (
        clk_122M,
        cdcff_clk_100M_rdy_122M.d,
        cdcff_clk_100M_rdy_122M.q
    );

    dff_sys_rst_n_122M.d <= dff_clk_122M_rdy_122M.q and cdcff_clk_100M_rdy_122M.q;
    u_dff_sys_rst_n_12M : entity shared_lib.dff
    port map (
        clk_122M,
        dff_sys_rst_n_122M.d,
        dff_sys_rst_n_122M.q
    );

    ----- clock enables -----
    -- counter for creating 100KHz clock enable in 100M domain
    clken_100k_counter_i <= ('1', dff_sys_rst_n_100M.q, '1');
    u_clken_100k_counter : entity shared_lib.counter 
    generic map (CLKEN_100K_COUNT_MAX)
    port map(clk_100M, clken_100k_counter_i, clken_100k_counter_o);

    -- counter for creating 12M clock enable in 122M domain
    clken_12M_counter_i <= ('1', dff_sys_rst_n_122M.q, '1');
    u_clken_12M_counter : entity shared_lib.counter 
    generic map (CLKEN_12M_COUNT_MAX)
    port map(clk_122M, clken_12M_counter_i, clken_12M_counter_o);

    -- ----- output drivers -----
    o_rec.clk_100M        <= clk_100M;
    o_rec.clk_122M        <= clk_122M;
    o_rec.clken_100M_100k <= clken_100k_counter_o.done;
    o_rec.clken_122M_12M  <= clken_12M_counter_o.done;
    o_rec.sys_rst_n_100M  <= dff_sys_rst_n_100M.q;
    o_rec.sys_rst_n_122M  <= dff_sys_rst_n_122M.q;
    
end architecture rtl;