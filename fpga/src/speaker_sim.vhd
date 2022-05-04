library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library shared_lib;
use shared_lib.utils_pkg.all;
use shared_lib.counter_pkg.all;
use shared_lib.registers_pkg.all;

library speaker_sim_lib;
use speaker_sim_lib.speaker_sim_pkg.all;
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
    signal r_leds      : std_ulogic_vector(3 downto 0) := X"0";
    signal counter_led_i : t_counter_i_rec := (others => '0');
    signal counter_led_o : t_counter_o_rec(count(num_bits(COUNT_MAX)-1 downto 0));

    -- audio codec
    signal codec_driver_i : t_codec_driver_i_rec := (dsp_dac_word => (others => '0'), others => '0');
    signal codec_driver_o : t_codec_driver_o_rec;

    -- fir filter
    
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
    counter_led_i.clken <= clken_100M_100k;
    counter_led_i.en    <= '1';
    counter_led_i.rst_n <= '1';
    u_led_counter: entity shared_lib.counter
        generic map(COUNT_MAX)
        port map(clk_100M, counter_led_i, counter_led_o);

    process(clk_100M)
    begin
        if rising_edge(clk_100M)  then
            if not sys_rst_n_100M  then
                r_leds(0) <= '0';
            elsif counter_led_o.done and clken_100M_100k then
                r_leds(0) <= not r_leds(0);
            end if;
        end if;
    end process;

    ----- audio codec driver -----
    codec_driver_i.rst_n <= sys_rst_n_122M;
    codec_driver_i.clken_12M <= clken_122M_12M;
    codec_driver_i.codec_dout <= i_codec_dout;
    u_codec_driver : entity codec_driver
        port map(clk_122M, codec_driver_i, codec_driver_o);

    ------ fir filter implementation ------
    u_fir_proc : process(clk_122M)
        constant DELAY : integer := 2417;

        type t_sreg_bit is array (integer range 0 to DELAY-1) of std_ulogic;
        variable v_sreg_valid : t_sreg_bit := (others => '0');

        type t_sreg_word_array is array (integer range 0 to DELAY-1) of t_codec_word;
        variable v_sreg_word : t_sreg_word_array := (others => (others => '0'));
    begin
        if rising_edge(clk_122M) then
            codec_driver_i.dsp_dac_word <= v_sreg_word(DELAY-1);
            codec_driver_i.dsp_dac_word_valid <= v_sreg_valid(DELAY-1);
            for i in DELAY-1 downto 1 loop
                v_sreg_word(i) := v_sreg_word(i-1);
                v_sreg_valid(i)  := v_sreg_valid(i-1);
            end loop;
            v_sreg_word(0) := codec_driver_o.dsp_adc_word;
            v_sreg_valid(0) := codec_driver_o.dsp_adc_word_valid;
        end if;
    end process u_fir_proc;

    -- output buffers
    o_codec_mclk    <= codec_driver_o.codec_mclk;
    o_codec_rst_n   <= codec_driver_o.codec_rst_n;
    o_codec_dclk    <= codec_driver_o.codec_dclk;
    o_codec_dfs     <= codec_driver_o.codec_dfs;
    o_codec_din     <= codec_driver_o.codec_din;
    o_leds          <= r_leds;
    
end architecture rtl;