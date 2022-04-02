library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library xil_defaultlib;

use xil_defaultlib.counters_pkg.all;
use xil_defaultlib.clock_and_reset_pkg.all;
use xil_defaultlib.codec_driver_pkg.all;
use xil_defaultlib.codec_driver_cdc_pkg.all;
-- use xil_defaultlib.speaker_sim_pkg.all;

entity speaker_sim is
    port (
        -- system clock input
        i_clk_125M  : in    std_ulogic;

        -- audio codec
        o_codec_mclk    :   out std_ulogic;  -- codec master clock
        o_codec_rst_n   :   out std_ulogic;  -- codec reset signal
        o_codec_dclk    :   out std_ulogic;  -- codec serial clock
        o_codec_dfs     :   out std_ulogic;  -- codec dfs
        o_codec_din     :   out std_ulogic;  -- serial data to codec
        i_codec_dout    :   in  std_ulogic;  -- serial data from codec

        -- status leds
        o_leds      : out   std_ulogic_vector(3 downto 0)
    );
end entity speaker_sim;

architecture rtl of speaker_sim is
    -- signal definitions
    -- clocks
    signal clk_100M :   std_ulogic;
    signal clk_12M  :   std_ulogic;
    signal r_pulse_100k : std_ulogic;

    -- reset
    signal r_sys_rst_n  :   std_logic;

    -- leds
    signal r_led        :   std_logic := '0';
    signal r_count_done :   std_logic;
    constant COUNT_WIDTH : integer := 16;

    -- audio codec
    constant DAC_ZEROS : std_ulogic_vector(23 downto 0) := (others => '0');
    signal r_sys_rst_n_12M  : std_ulogic;
    signal r_codec_mclk     : std_ulogic;
    signal r_codec_rst_n    : std_ulogic;
    signal r_codec_dclk     : std_ulogic;
    signal r_codec_dfs      : std_ulogic;
    signal r_codec_din      : std_ulogic;
    
begin

    -- led drivers
    o_leds <= (0 => r_led, others => '0');

    process(clk_100M)
    begin
        if rising_edge(clk_100M) then
            if not r_sys_rst_n then
                r_led <= '0';
            elsif r_count_done then
                r_led <= not r_led;
            end if;
        end if;
    end process;

    -- component instances
    u_clock_and_reset : clock_and_reset
        port map(
            i_clk_125M      => i_clk_125M,
            o_clk_100M      => clk_100M,
            o_clk_12M       => clk_12M,
            o_pulse_100K    => r_pulse_100k,
            o_sys_rst_n     => r_sys_rst_n
        );

    u_led_counter: counter
        generic map(
            g_NUM_BITS  => COUNT_WIDTH,
            g_COUNT_MAX => 50000
        )
        port map(
            i_clk       => clk_100M,
            i_rst_n     => r_sys_rst_n,
            i_en        => r_pulse_100k,
            o_count     => open,
            o_done      => r_count_done
        );

    u_codec_driver_cdc : codec_driver_cdc
        port map (
            i_clk_100M  => clk_100M,
            i_clk_12M   => clk_12M,
            i_rst_n     => r_sys_rst_n,
            o_rst_n_12M => r_sys_rst_n_12M
        );

    u_codec_driver : codec_driver
        port map(
            i_clk_12M => clk_12M,
            i_rst_n => r_sys_rst_n_12M,
            i_ctrl_dac_word => DAC_ZEROS,
            o_codec_mclk    => r_codec_mclk,
            o_codec_rst_n   => r_codec_rst_n,
            o_codec_dclk    => r_codec_dclk,
            o_codec_dfs     => r_codec_dfs,
            o_codec_din     => r_codec_din,
            i_codec_dout    => i_codec_dout
        );

    -- output buffers
    o_codec_mclk  <= r_codec_mclk;
    o_codec_rst_n <= r_codec_rst_n;
    o_codec_dclk  <= r_codec_dclk;
    o_codec_dfs   <= r_codec_dfs;
    o_codec_din   <= r_codec_din;
    
end architecture rtl;