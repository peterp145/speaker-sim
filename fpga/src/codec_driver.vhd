library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity codec_driver is
    port (
        -- clock and reset
        i_clk_12M   :   in  std_logic;  -- 12.288MHz clock for logic and codec mclk
        i_rst_n     :   in  std_logic;  -- system reset
        -- controller if
        i_ctrl_dac_word :   in  std_logic_vector(23 downto 0);
        o_ctrl_adc_word :   in  std_logic_vector(23 downto 0);
        i_ctrl_loopback     :   in  std_logic;  -- enable to run codec in loopback mode (adc to dac)
        o_ctrl_busy         :   out std_logic;  -- high when codec transaction in progress
        -- codec hardware if
        o_codec_mclk    :   out std_logic;  -- codec master clock
        o_codec_rst_n   :   out std_logic;  -- codec reset signal
        o_codec_dclk    :   out std_logic;  -- codec serial clock
        o_codec_dfs     :   out std_logic;  -- codec dfs
        o_codec_din     :   out std_logic;  -- serial data to codec
        i_codec_dout    :   in  std_logic   -- serial data from codec
    );
end entity codec_driver;

architecture rtl of codec_driver is
    -- FSM
    type t_state is (
        sRESET,
        sCODEC_RESET_0,
        sCODEC_RESET_1,
        sCODEC_RESET_2,
        sXFR_START_0,
        sXFR_START_1,
        sXFR_SHIFT_0,
        sXFR_SHIFT_1,
        sXFR_DFS_0,
        sXFR_DFS_1,
        sXFR_IDLE_0,
        sXFR_IDLE_1
    );
    signal r_state        : t_state := sRESET;
    signal w_next_state   : t_state := sRESET;

    -- FSM counter
    signal r_counter    : integer range 0 to 255    := 0;
    signal w_counter_en : std_logic                 := '0';

    signal r_samp_counter    : integer range 0 to 255   := 0;
    signal w_samp_counter_en : std_logic                := '0';

    -- fsm init regs
    signal r_word_a_init       : std_logic := '0';
    signal w_word_a_init_set   : std_logic;

    signal r_word_c_init       : std_logic := '0';
    signal w_word_c_init_set   : std_logic;

    signal r_24b_ready          : std_logic := '0';
    signal w_24b_ready_set      : std_logic;

    -- dout sreg
    signal r_dout_sreg      : std_logic_vector (15 downto 0) := (others => '0');
    signal w_dout_sreg_en   : std_logic;

    -- din sreg
    constant REG_A_WORD         : std_logic_vector (15 downto 0) := B"1000_0000_0111_1100";
    constant REG_C_WORD         : std_logic_vector (15 downto 0) := B"1001_0000_0011_0101";
    signal r_din_sreg           : std_logic_vector (15 downto 0) := (others => '0');
    signal w_din_sreg_en        : std_logic;
    signal w_din_sreg_load_word : std_logic_vector (15 downto 0);
    signal w_din_sreg_load      : std_logic;
    signal w_din_sreg_load_sel  : integer range 0 to 4;

    -- din selection
    signal w_din_output_en      : std_logic;
    signal w_din_loopback_en    : std_logic;

    -- codec outputs
    signal w_codec_rst_n    : std_logic;
    signal w_codec_dclk     : std_logic;
    signal w_codec_dfs      : std_logic;
    signal w_codec_din      : std_logic;

begin
    ----------------
    -- controller --
    ----------------

    -- FSM r_state reg
    r_state <= sRESET when not i_rst_n else w_next_state when rising_edge(i_clk_12M);

   -- next r_state and control logic
    proc_fsm: process(all)
    begin
        -- default assignments
        w_counter_en        <= '1';
        w_samp_counter_en   <= '0';

        w_word_a_init_set   <= '0';
        w_word_c_init_set   <= '0';
        w_24b_ready_set     <= '0';r
        w_din_sreg_load_sel  <= 0;

        w_din_output_en     <= '0';
        w_din_loopback_en   <= '0';

        w_codec_rst_n   <= '1';
        w_codec_dfs     <= '0';

        case r_state is
            when sRESET =>
                w_counter_en <= '0';
                w_next_state <= sCODEC_RESET_0;

            when sCODEC_RESET_0 =>
                w_codec_rst_n   <= '0';
                w_codec_dclk    <= '0';
                w_din_output_en <= '1';
                if r_counter = 9 then
                    w_counter_en <= '0';
                    w_next_state <= sCODEC_RESET_1;
                else
                    w_next_state <= sCODEC_RESET_0;
                end if;

            when sCODEC_RESET_1 =>
                w_codec_dclk    <= '0';
                w_din_output_en <= '1';
                if r_counter = 9 then
                    w_counter_en <= '0';
                    w_next_state <= sCODEC_RESET_2;
                else
                    w_next_state <= sCODEC_RESET_1;
                end if;

            when sCODEC_RESET_2 =>
                w_codec_dclk <= '0';
                if r_counter = 255 then
                    w_counter_en <= '0';
                    w_samp_counter_en <= '1';
                    if r_samp_counter = 11 then
                        w_next_state <= sXFR_START_0;
                    else
                        w_next_state <= sCODEC_RESET_2;
                    end if;
                else
                    w_next_state <= sCODEC_RESET_2;
                end if;

            when sXFR_START_0 =>
                w_codec_dclk <= r_word_a_init;
                w_codec_dfs  <= r_word_a_init;
                w_next_state <= sXFR_START_1;

            when sXFR_START_1 =>
                w_codec_dclk <= '0';
                w_codec_dfs  <= r_word_a_init;
                w_din_sreg_load <= '1';

                if not r_word_a_init then
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
                w_dout_sreg_en  <= '1';
                w_din_output_en <= '1';
                w_din_loopback_en <= '1' when r_counter >= 66 else '0';
                w_next_state    <= sXFR_SHIFT_1;

            when sXFR_SHIFT_1 =>
                w_codec_dclk    <= '0';
                w_din_sreg_en   <= '1';
                w_din_output_en <= '1';
                w_din_loopback_en <= '1' when r_counter >= 66 else '0';
                case r_counter is
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
                w_dout_sreg_en  <= '1';
                w_din_output_en <= '1';
                w_din_loopback_en   <= '1' when r_counter=96 else '0';
                w_next_state    <= sXFR_DFS_1;

            when sXFR_DFS_1 =>
                w_codec_dclk    <= '0';
                w_codec_dfs     <= '1';
                w_din_sreg_en   <= '1';
                w_din_output_en <= '1';
                case r_counter is
                    when 65     =>  w_din_sreg_load_sel <= 3;
                    when 97     =>  w_din_sreg_load_sel <= 4;
                                    w_din_loopback_en <= '1';
                    when others =>  w_din_sreg_load_sel <= 0;
                end case;
                w_next_state    <= sXFR_SHIFT_0;

            when sXFR_IDLE_0 =>
                w_codec_dclk    <= '1';
                w_next_state    <= sXFR_IDLE_1;

            when sXFR_IDLE_1 =>
                w_codec_dclk    <= '0';
                if r_counter = 255 then
                    w_counter_en    <= '0';
                    w_next_state    <= sXFR_START_0;
                else
                    w_next_state    <= sXFR_IDLE_0;
                end if;

            when others  =>
                w_next_state    <= sRESET;

        end case;
    end process proc_fsm;

    -- mclk counter
    r_counter   <= 0 when not w_counter_en else r_counter+1
                    when rising_edge(clk);

    -- sample counter
    r_samp_counter  <= 0 when not w_codec_rst_n else r_samp_counter+1 when w_samp_counter_en
                        when rising_edge(i_clk_12M);

    -- init tracking regs
    r_word_a_init   <= (r_word_a_init or w_word_a_init_set) and w_codec_rst_n
                        when rising_edge(i_clk_12M);
    r_word_c_init   <= (r_word_c_init or w_word_c_init_set) and w_codec_rst_n
                        when rising_edge(i_clk_12M);
    r_24b_ready     <= (r_24b_ready or w_24b_ready_set)     and w_codec_rst_n
                        when rising_edge(i_clk_12M);

    --------------
    -- datapath --
    --------------

    -- codec dout shift register
    r_dout_sreg <= r_dout_sreg(14 downto 0) & i_codec_dout when w_dout_sreg_en
                    when rising_edge(i_clk_12M);

    -- codec din shift register
    w_
    proc_din_sreg: process(i_clk_12M)
    begin
        if rising_edge(i_clk_12M) then
            if w_din_sreg_load = '1' then
                case w_din_sreg_load_sel is
                    when 1 =>       r_din_sreg <= REG_A_WORD;
                    when 2 =>       r_din_sreg <= REG_C_WORD;
                    -- when 3 =>       r_din_sreg <= i_ctrl_dac_word(23 downto 8);
                    -- when 4 =>       r_din_sreg <= i_ctrl_dac_word(7 downto 0) & X"00";
                    when others =>  r_din_sreg <= (others => '0');
                end case;
            elsif w_din_sreg_en = '1' then
                r_din_sreg <= r_din_sreg(14 downto 0) & "0";
            end if;
        end if;
    end process proc_din_sreg;

    -- loopback mux
    w_codec_din <=  'Z'             when w_din_output_en = '0'      else
                    i_codec_dout    when w_din_loopback_en  = '1'   else
                    r_din_sreg(15);
    
    -- output assignment
    o_codec_mclk    <= i_clk_12M;
    o_codec_rst_n   <= w_codec_rst_n;
    o_codec_dclk    <= w_codec_dclk;
    o_codec_dfs     <= w_codec_dfs;
    o_codec_din     <= w_codec_din;
    
end architecture rtl;