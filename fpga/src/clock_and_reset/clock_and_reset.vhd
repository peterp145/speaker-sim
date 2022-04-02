library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library xil_defaultlib;
use xil_defaultlib.utils_pkg.all;
use xil_defaultlib.counters_pkg.all;
use xil_defaultlib.clock_and_reset_pkg.all;

entity clock_and_reset is
    port (
        i_clk_125M      : in  std_ulogic;   -- 125MHz clock input from board
        o_clk_100M      : out std_ulogic;   -- 100MHz system logic clock
        o_clk_12M       : out std_ulogic;   -- audio codec clock
        o_pulse_100K    : out std_ulogic;   -- 100KHz pulse 
        o_sys_rst_n     : out std_ulogic    -- system reset, active low
    );
end entity clock_and_reset;

architecture rtl of clock_and_reset is
    signal clk_100M, clk_12M, r_clk_locked : std_ulogic;
    constant clk_gen_rstn : std_logic := '1';
    
    signal r_pulse  : std_ulogic;

    signal r_rst_sreg_100, r_rst_sreg_12   : std_ulogic_vector(9 downto 0) := (others => '0');
    signal r_100_rdy_100M   : std_ulogic := '0';
    signal r_12_rdy_12M     : std_ulogic := '0';
    signal r_12_rdy_meta_100M   : std_ulogic := '0';
    signal r_12_rdy_100M        : std_ulogic := '0';
    signal r_sys_rst_n  : std_ulogic := '0';
    
begin
    -- ip instantiation
    clk_gen: clk_wiz_0
    port map(
        o_clk_100M  => clk_100M,
        o_clk_12M   => clk_12M,
        resetn      => clk_gen_rstn,
        o_locked    => r_clk_locked,
        i_clk_125M  => i_clk_125M
    );

    -- reset logic
    proc_rst_100M : process(clk_100M)
    begin
        if rising_edge(clk_100M) then
            r_rst_sreg_100 <= r_rst_sreg_100(r_rst_sreg_100'length-2 downto 0) & r_clk_locked;
            r_100_rdy_100M <= is_ones(r_rst_sreg_100);
        end if;
    end process proc_rst_100M;

    proc_rst_12M : process(clk_12M)
    begin
        if rising_edge(clk_12M) then
            r_rst_sreg_12 <= r_rst_sreg_12(r_rst_sreg_12'length-2 downto 0) & r_clk_locked;
            r_12_rdy_12M <= is_ones(r_rst_sreg_12);
        end if;
    end process proc_rst_12M;

    -- clock domain crossing for detecting both clocks have locked
    proc_sys_rst : process(clk_100M) 
    begin
        if rising_edge(clk_100M) then
            r_12_rdy_meta_100M  <= r_12_rdy_12M;
            r_12_rdy_100M       <= r_12_rdy_meta_100M;
            r_sys_rst_n         <= r_100_rdy_100M and r_12_rdy_100M;
        end if;
    end process proc_sys_rst;

    -- pulse pulse generator
    samp_counter : counter 
    generic map (
        g_NUM_BITS => 10,
        g_COUNT_MAX => 999
    )
    port map(
        i_clk => clk_100M,
        i_rst_n => r_sys_rst_n,
        i_en => '1',
        o_done => r_pulse
    );

    -- output drivers
    o_clk_100M      <= clk_100M;
    o_clk_12M       <= clk_12M;
    o_pulse_100K    <= r_pulse;
    o_sys_rst_n     <= r_sys_rst_n;
    
end architecture rtl;