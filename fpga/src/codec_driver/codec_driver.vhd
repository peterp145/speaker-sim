library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library xil_defaultlib;
use xil_defaultlib.flip_flops_pkg.all;
-- use xil_defaultlib.registers_pkg.all;
use xil_defaultlib.counters_pkg.all;

entity codec_driver is
    port (
        -- clock and reset
        i_clk_12M   :   in  std_ulogic;  -- 12.288MHz clock for logic and codec mclk
        i_rst_n     :   in  std_ulogic;  -- system reset
        -- controller if
        i_ctrl_dac_word :   in  std_ulogic_vector(23 downto 0);
        -- o_ctrl_adc_word :   in  std_ulogic_vector(23 downto 0);
        -- i_ctrl_loopback     :   in  std_ulogic;  -- enable to run codec in loopback mode (adc to dac)
        -- o_ctrl_busy         :   out std_ulogic;  -- high when codec transaction in progress
        -- codec hardware if
        o_codec_mclk    :   out std_ulogic;  -- codec master clock
        o_codec_rst_n   :   out std_ulogic;  -- codec reset signal
        o_codec_dclk    :   out std_ulogic;  -- codec serial clock
        o_codec_dfs     :   out std_ulogic;  -- codec dfs
        o_codec_din     :   out std_ulogic;  -- serial data to codec
        i_codec_dout    :   in  std_ulogic   -- serial data from codec
    );
end entity codec_driver;

architecture rtl of codec_driver is

    ----- FSM -----
    type t_state is (
        sRESET,         -- power on reset state
        sCODEC_RESET_0, -- set din for AD74111 slave mode
        sCODEC_RESET_1, -- assert reset 
        sCODEC_RESET_2, -- wait for codec to initialize
        sXFR_START_0,   -- start of transfer, dclk high
        sXFR_START_1,   -- end of transfer, dclk low
        sXFR_SHIFT_0,
        sXFR_SHIFT_1,
        sXFR_DFS_0,
        sXFR_DFS_1,
        sXFR_IDLE_0,
        sXFR_IDLE_1
    );
    signal r_state        : t_state := sRESET;  -- fsm state register
    signal w_next_state   : t_state := sRESET;  -- next state

    -- FSM dclk counter
    signal r_mclk_counter    : unsigned(7 downto 0); 
    signal r_mclk_counter_en : std_ulogic;      
    
    signal r_samp_counter      : unsigned (3 downto 0);
    signal w_samp_counter_en   : std_ulogic;

    -- fsm init regs
    signal r_first_xfr      : std_ulogic := '0';
    signal w_first_xfr_set  : std_ulogic;

    signal r_word_a_init       : std_ulogic := '0';
    signal w_word_a_init_set   : std_ulogic;

    signal r_word_c_init       : std_ulogic := '0';
    signal w_word_c_init_set   : std_ulogic;

    signal r_24b_ready          : std_ulogic := '0';
    signal w_24b_ready_set      : std_logic;

    -- dout sreg
    signal w_dout_sreg_shift_en   : std_ulogic;
    signal r_dout_sreg      : std_ulogic_vector (15 downto 0) := (others => '0');
    
    -- din sreg
    constant REG_A_WORD     : std_ulogic_vector (15 downto 0) := B"1000_0000_0111_1100";
    constant REG_C_WORD     : std_ulogic_vector (15 downto 0) := B"1001_0000_0011_0101";
    
    signal w_din_sreg_load_sel : integer range 0 to 4;
    signal w_din_sreg_load_en : std_ulogic;
    signal w_din_sreg_shift_en : std_ulogic;
    signal w_din_sreg_in    : std_ulogic_vector (15 downto 0);
    signal r_din_sreg       : std_ulogic_vector (15 downto 0) := (others => '1');

    -- din selection
    signal w_din_output_en      : std_ulogic;
    signal w_din_loopback_en    : std_ulogic;

    -- codec outputs
    signal w_codec_rst_n    : std_ulogic;
    signal w_codec_dclk     : std_ulogic;
    signal w_codec_dfs      : std_ulogic;
    signal w_codec_din      : std_ulogic;

begin
    ----------------
    -- controller --
    ----------------

    -- FSM r_state reg
    r_state <= sRESET when not i_rst_n else w_next_state when rising_edge(i_clk_12M);

   -- next r_state and control logic
    proc_fsm: process(all)
        variable counter : integer range 0 to 255;
        variable samp_counter : integer range 0 to 15;
    begin
        -- default assignments
        r_mclk_counter_en        <= '1';
        w_samp_counter_en   <= '0';

        w_first_xfr_set     <= '0';
        w_word_a_init_set   <= '0';
        w_word_c_init_set   <= '0';
        w_24b_ready_set     <= '0';

        w_dout_sreg_shift_en    <= '0';

        w_din_sreg_shift_en <= '0';

        w_din_sreg_load_en  <= '0';
        w_din_sreg_load_sel <= 0;

        w_din_output_en     <= '0';
        w_din_loopback_en   <= '0';

        w_codec_rst_n   <= '1';
        w_codec_dfs     <= '0';

        case r_state is
            when sRESET =>
                r_mclk_counter_en <= '0';
                w_codec_dclk    <= '0';
                w_next_state <= sCODEC_RESET_0;

            when sCODEC_RESET_0 =>
                w_codec_rst_n   <= '0';
                w_codec_dclk    <= '0';
                w_din_output_en <= '1';
                if r_mclk_counter = 9 then
                    r_mclk_counter_en <= '0';
                    w_next_state <= sCODEC_RESET_1;
                else
                    w_next_state <= sCODEC_RESET_0;
                end if;

            when sCODEC_RESET_1 =>
                w_codec_dclk    <= '0';
                w_din_output_en <= '1';
                if r_mclk_counter = 9 then
                    r_mclk_counter_en <= '0';
                    w_next_state <= sCODEC_RESET_2;
                else
                    w_next_state <= sCODEC_RESET_1;
                end if;

            when sCODEC_RESET_2 =>
                w_codec_dclk <= not r_mclk_counter(0);
                if r_mclk_counter = 255 then
                    r_mclk_counter_en <= '0';
                    w_samp_counter_en <= '1';
                    if r_samp_counter = 12 then
                        w_next_state <= sXFR_START_0;
                    else
                        w_next_state <= sCODEC_RESET_2;
                    end if;
                else
                    w_next_state <= sCODEC_RESET_2;
                end if;

            when sXFR_START_0 =>
                w_codec_dclk <= '1';
                w_codec_dfs  <= '1';
                w_next_state <= sXFR_START_1;

            when sXFR_START_1 =>
                w_codec_dclk <= '0';
                w_codec_dfs  <= '1';
                w_din_sreg_load_en <= '1';

                if not r_first_xfr then
                    w_first_xfr_set <= '1';
                    w_din_sreg_load_sel  <= 0;
                elsif not r_word_a_init then
                    w_word_a_init_set <= '1';
                    w_din_sreg_load_sel <= 1;
                elsif not r_word_c_init then
                    w_word_c_init_set <= '1';
                    w_din_sreg_load_sel <= 2;
                elsif not r_24b_ready then
                    w_24b_ready_set <= '1';
                    w_din_sreg_load_sel <= 0;
                else 
                    w_din_sreg_load_sel <= 0;
                end if;

                w_next_state <= sXFR_SHIFT_0;

            when sXFR_SHIFT_0 =>
                w_codec_dclk    <= '1';
                w_dout_sreg_shift_en  <= '1';
                w_din_output_en <= '1';
                w_din_loopback_en <= '1' when counter >= 66 else '0';
                w_next_state    <= sXFR_SHIFT_1;

            when sXFR_SHIFT_1 =>
                w_codec_dclk    <= '0';
                w_din_sreg_shift_en   <= '1';
                w_din_output_en <= '1';
                w_din_loopback_en <= '1' when counter >= 66 else '0';
                case counter is
                    when 31     => w_next_state <= sXFR_DFS_0;
                    when 63     => w_next_state <= sXFR_DFS_0 when r_24b_ready else sXFR_SHIFT_0;
                    when 65     => w_next_state <= sXFR_IDLE_0;
                    when 95     => w_next_state <= sXFR_DFS_0;
                    when 113    => w_next_state <= sXFR_IDLE_0;
                    when others => w_next_state <= sXFR_SHIFT_0;
                end case;

            when sXFR_DFS_0 =>
                w_codec_dclk    <= '1';
                w_codec_dfs     <= '1';
                w_dout_sreg_shift_en  <= '1';
                w_din_output_en <= '1';
                w_din_loopback_en   <= '1' when counter=96 else '0';
                w_next_state    <= sXFR_DFS_1;

            when sXFR_DFS_1 =>
                w_codec_dclk    <= '0';
                w_codec_dfs     <= '1';
                w_din_sreg_shift_en   <= '1';
                w_din_output_en <= '1';
                w_din_loopback_en <= '1' when counter=97 else '0';
                case counter is
                    when 65     =>  w_din_sreg_load_sel <= 3;
                    when 97     =>  w_din_sreg_load_sel <= 4;
                    when others =>  w_din_sreg_load_sel <= 0;
                end case;
                w_next_state    <= sXFR_SHIFT_0;

            when sXFR_IDLE_0 =>
                w_codec_dclk    <= '1';
                w_next_state    <= sXFR_IDLE_1;

            when sXFR_IDLE_1 =>
                w_codec_dclk    <= '0';
                if counter = 255 then
                    r_mclk_counter_en    <= '0';
                    w_next_state    <= sXFR_START_0;
                else
                    w_next_state    <= sXFR_IDLE_0;
                end if;

            when others  =>
                w_codec_dclk    <= '0';
                w_next_state    <= sRESET;

        end case;
    end process proc_fsm;

    -- mclk counter
    mclk_counter : counter 
    generic map (g_NUM_BITS => r_mclk_counter'length)
    port map(
        i_clk => i_clk_12M,
        i_rst_n => r_mclk_counter_en,
        i_en => r_mclk_counter_en,
        o_count => r_mclk_counter
    );

    -- sample counter
    samp_counter : counter 
    generic map (g_NUM_BITS => r_samp_counter'length)
    port map(
        i_clk => i_clk_12M,
        i_rst_n => w_codec_rst_n,
        i_en => w_samp_counter_en,
        o_count => r_samp_counter
    );

    -- init tracking regs
    sr_ff(r_first_xfr,   w_first_xfr_set,   w_codec_rst_n, i_clk_12M);
    sr_ff(r_word_a_init, w_word_a_init_set, w_codec_rst_n, i_clk_12M);
    sr_ff(r_word_c_init, w_word_c_init_set, w_codec_rst_n, i_clk_12M);
    sr_ff(r_24b_ready,   w_24b_ready_set,   w_codec_rst_n, i_clk_12M);

    --------------
    -- datapath --
    --------------

    -- codec dout shift register
    proc_dout_sreg: process(i_clk_12M)
    begin
        if rising_edge(i_clk_12M) then
            if not w_codec_rst_n then
                r_dout_sreg <= (others => '0');
            elsif w_dout_sreg_shift_en then 
                r_dout_sreg <= r_dout_sreg(14 downto 0) & i_codec_dout;
            end if;
        end if;
    end process proc_dout_sreg;
    -- r_dout_sreg <= (r_dout_sreg(14 downto 0) & i_codec_dout) when w_dout_sreg_shift_en else
    --     r_dout_sreg
    --     when rising_edge(i_clk_12M);

    -- din word mux
    with w_din_sreg_load_sel select
        w_din_sreg_in <=
            REG_A_WORD                          when 1,
            REG_C_WORD                          when 2,
            i_ctrl_dac_word(23 downto 8)        when 3,
            i_ctrl_dac_word(7 downto 0) & X"00" when 4,
            (others => '0')                     when others;

    -- codec din shift register
    proc_din_sreg: process(i_clk_12M)
    begin
        if rising_edge(i_clk_12M) then
            if not w_codec_rst_n then
                r_din_sreg <= (others => '1');
            elsif w_din_sreg_load_en then
                r_din_sreg <= w_din_sreg_in;
            elsif w_din_sreg_shift_en then 
                r_din_sreg <= r_din_sreg(14 downto 0) & "0";
            end if;
        end if;
    end process proc_din_sreg;
    -- r_din_sreg <= w_din_sreg_in when w_din_sreg_load_en else
    --     r_din_sreg(14 downto 0) & "0" when w_din_sreg_shift_en else
    --     r_din_sreg
    --     wait on rising_edge(i_clk_12M);

    -- loopback mux
    proc_loopback_mux : process(all)
    begin
        if not w_din_output_en then
            w_codec_din <=  'Z';
        elsif w_din_loopback_en then 
            w_codec_din <=  i_codec_dout;
        else
            w_codec_din <= r_din_sreg(15);
        end if;
    end process;
    
    -- output assignment

    o_codec_mclk    <= i_clk_12M;
    o_codec_rst_n   <= w_codec_rst_n;
    o_codec_dclk    <= w_codec_dclk;
    o_codec_dfs     <= w_codec_dfs;
    o_codec_din     <= w_codec_din;
    
end architecture rtl;