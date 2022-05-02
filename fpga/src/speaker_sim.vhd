library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library shared_lib;
use shared_lib.utils_pkg.all;
use shared_lib.counter_pkg.all;

library speaker_sim_lib;
use speaker_sim_lib.clock_and_reset_pkg.all;
use speaker_sim_lib.codec_driver_pkg.all;
use speaker_sim_lib.codec_driver;

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
    ----- clock and reset -----
    signal clock_and_reset_o : t_clock_and_reset_o_rec;

    -- clocks
    signal clk_100M, clken_100M_100k : std_ulogic;
    signal clk_122M, clken_122M_12M  : std_ulogic;

    -- reset
    signal sys_rst_n_100M : std_logic;
    signal sys_rst_n_122M  : std_ulogic;

    -- leds
    constant COUNT_MAX : integer := 49999;
    signal r_led        :   std_logic := '0';
    signal counter_led : t_counter_rec(o(count(num_bits(COUNT_MAX)-1 downto 0)));

    -- audio codec
    constant DAC_ZEROS : std_ulogic_vector(23 downto 0) := (others => '0');
    signal codec_driver_rec : t_codec_driver_rec;
    
begin

    ----- clock and reset -----
    u_clock_and_reset : clock_and_reset
    port map(i_clk_125M, clock_and_reset_o);

    clk_100M        <= clock_and_reset_o.clk_100M;
    clk_122M        <= clock_and_reset_o.clk_122M;
    clken_100M_100k <= clock_and_reset_o.clken_100M_100k;
    clken_122M_12M  <= clock_and_reset_o.clken_122M_12M;
    sys_rst_n_100M  <= clock_and_reset_o.sys_rst_n_100M;
    sys_rst_n_122M  <= clock_and_reset_o.sys_rst_n_122M;

    ----- status leds -----
    counter_led.i.clken <= clken_100M_100k;
    counter_led.i.en    <= '1';
    counter_led.i.rst_n <= '1';
    u_led_counter: entity shared_lib.counter
        generic map(COUNT_MAX)
        port map(clk_100M, counter_led.i, counter_led.o);

    process(clk_100M)
    begin
        if rising_edge(clk_100M)  then
            if not sys_rst_n_100M  then
                r_led <= '0';
            elsif counter_led.o.done and clken_100M_100k then
                r_led <= not r_led;
            end if;
        end if;
    end process;

    ----- audio codec driver -----
    codec_driver_rec.i.rst_n <= sys_rst_n_122M;
    codec_driver_rec.i.clken_12M <= clken_122M_12M;
    codec_driver_rec.i.codec_dout <= i_codec_dout;
    u_codec_driver : entity codec_driver
    port map(clk_122M, codec_driver_rec.i, codec_driver_rec.o);

    -- output buffers
    o_codec_mclk    <= codec_driver_rec.o.codec_mclk;
    o_codec_rst_n   <= codec_driver_rec.o.codec_rst_n;
    o_codec_dclk    <= codec_driver_rec.o.codec_dclk;
    o_codec_dfs     <= codec_driver_rec.o.codec_dfs;
    o_codec_din     <= codec_driver_rec.o.codec_din;
    o_leds          <= (0 => r_led, others => '0');
    
end architecture rtl;