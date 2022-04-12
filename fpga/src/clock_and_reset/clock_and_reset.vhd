library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library shared_lib;
use shared_lib.utils_pkg.all;
use shared_lib.flip_flops_pkg.all;
use shared_lib.registers_pkg.all;
use shared_lib.counter_pkg.all;

library speaker_sim_lib;
use speaker_sim_lib.clock_and_reset_pkg.all;
-- use speaker_sim_lib.clock_and_reset_pkg.t_clock_and_reset_i_rec;
-- use speaker_sim_lib.clock_and_reset_pkg.t_clock_and_reset_o_rec;

-- library xil_defaultlib;
-- use xil_defaultlib.clk_wiz_0;

entity clock_and_reset is
    port (
        i_clk_125M : in  std_ulogic; -- input record
        o_rec      : out t_clock_and_reset_o_rec  -- output record
    );
end entity clock_and_reset;

architecture rtl of clock_and_reset is
    ----- clock generation -----
    component clk_wiz_0 is
        port (
            -- Clock in ports
            i_clk_125M    : in     std_logic;
            -- Clock out ports
            o_clk_100M    : out    std_logic;
            o_clk_12M     : out    std_logic;
            -- Status and control signals
            resetn        : in     std_logic;
            o_locked      : out    std_logic
        );
    end component clk_wiz_0;

    -- constant clk_gen_rstn : std_logic := '1';
    signal clk_100M, clk_12M, r_clk_locked : std_ulogic;    -- MMCM outputs
    
    -- pulse counter
    constant PULSE_COUNTER_MAX : integer := 999;
    signal counter_pulse: t_counter_rec(o(count(num_bits(PULSE_COUNTER_MAX)-1 downto 0)));

    ----- clock ready -----
    constant READY_SREG_NUM_BITS : integer := 10;

    -- 100MHz ready
    signal sreg_clk_100_rdy  : t_sreg_rec(              -- CLK100M reset sreg
        i(load_word(READY_SREG_NUM_BITS-1 downto 0)), 
        o(word(READY_SREG_NUM_BITS-1 downto 0)));        
        
    signal dff_clk_100_rdy_100M : std_ulogic;    -- CLK100M ready, system clock domain
        
    -- 12MHz ready
    signal sreg_clk_12_rdy  : t_sreg_rec(              -- CLK12M reset sreg
        i(load_word(READY_SREG_NUM_BITS-1 downto 0)), 
        o(word(READY_SREG_NUM_BITS-1 downto 0)));        
    signal dff_clk_12_rdy_12M   : std_ulogic;    -- CLK12M ready, system clock domain
    
    ----- system reset generation -----
    -- CLK100M domain
    signal cdcff_clk_12_rdy_100M    : std_ulogic; -- 12M ready signal clock domain crossing
    signal dff_sys_rst_n_100M : std_ulogic;    -- system reset generation, 100M
    
    -- CLK12M domain
    signal cdcff_clk_100_rdy_12M  : std_ulogic; -- 12M ready signal clock domain crossing
    signal dff_sys_rst_n_12M    : std_ulogic;    -- system reset generation, 100M
    
begin
    ----- clock and reset generation -----
    -- ip instantiation
    u_clk_gen : clk_wiz_0
    port map(
        o_clk_100M  => clk_100M,        -- 100MHz clock for system
        o_clk_12M   => clk_12M,         -- 12.288MHz clock for audio codec
        resetn      => '1',    -- MMCM reset
        o_locked    => r_clk_locked,    -- MMCM locked
        i_clk_125M  => i_clk_125M -- on board 125M clock
    );

    ----- reset logic -----
    -- reset shift register clocks in reset value, must be deasserted for set number of clock cycles
    --    before becoming valid
    -- ensures both clocks and reset input are stable
    
    -- 100M clock ready
    sreg_clk_100_rdy.i.load_word    <= (others => '0');
    sreg_clk_100_rdy.i.load_en      <= '0';
    sreg_clk_100_rdy.i.shift_en     <= '1';
    sreg_clk_100_rdy.i.rst_n        <= '1';
    sreg_clk_100_rdy.i.shift_bit    <= r_clk_locked;
    
    u_sreg_clk_100_rdy : sreg
    port map (clk_100M, sreg_clk_100_rdy.i, sreg_clk_100_rdy.o);
    
    u_dff_clk_100_rdy_100M : dff
        port map (clk_100M, is_ones(sreg_clk_100_rdy.o.word), dff_clk_100_rdy_100M);
        
    -- 12M clock ready
    sreg_clk_12_rdy.i.load_word     <= (others => '0');
    sreg_clk_12_rdy.i.load_en       <= '0';
    sreg_clk_12_rdy.i.shift_en      <= '1';
    sreg_clk_12_rdy.i.rst_n         <= '1';
    sreg_clk_12_rdy.i.shift_bit     <= r_clk_locked;
    
    u_sreg_clk_12_rdy : sreg
    port map (clk_12M, sreg_clk_12_rdy.i, sreg_clk_12_rdy.o);
    
    u_dff_clk_12_rdy_12M : dff
        port map (clk_12M, is_ones(sreg_clk_12_rdy.o.word), dff_clk_12_rdy_12M);
        
    -- 100M reset
    u_cdcffs_clk_12_rdy_12to100M : cdcffs
        port map (clk_100M, dff_clk_12_rdy_12M, cdcff_clk_12_rdy_100M);

    u_dff_sys_rst_n_100M : dff
        port map (
            clk_100M,
            dff_clk_100_rdy_100M and cdcff_clk_12_rdy_100M,
            dff_sys_rst_n_100M);

    -- 12M reset
    u_cdcffs_clk_100_rdy_100to12M : cdcffs
        port map (clk_12M, dff_clk_100_rdy_100M, cdcff_clk_100_rdy_12M);

    u_dff_sys_rst_n_12M : dff
        port map (
            clk_12M,
            dff_clk_12_rdy_12M and cdcff_clk_100_rdy_12M,
            dff_sys_rst_n_12M);

    ----- pulse generator -----
    -- counter for creating 100KHz pulse
    counter_pulse.i <= (dff_sys_rst_n_100M, '1');
    pulse_counter : counter 
        generic map (PULSE_COUNTER_MAX)
        port map(clk_100M, counter_pulse.i, counter_pulse.o);

    -- ----- output drivers -----
    o_rec.clk_100M          <= clk_100M;
    o_rec.clk_12M           <= clk_12M;
    o_rec.pulse_100K        <= counter_pulse.o.done;
    o_rec.sys_rst_n_100M    <= dff_sys_rst_n_100M;
    o_rec.sys_rst_n_12M     <= dff_sys_rst_n_12M;
    
end architecture rtl;