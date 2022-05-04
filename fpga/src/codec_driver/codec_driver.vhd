library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library shared_lib;
use shared_lib.utils_pkg.all;
use shared_lib.flip_flops_pkg.all;
use shared_lib.registers_pkg.all;
use shared_lib.counter_pkg.all;

library speaker_sim_lib;
use speaker_sim_lib.speaker_sim_pkg.all;
use speaker_sim_lib.codec_driver_pkg.all;

entity codec_driver is
    port (
        i_clk_122M : in  std_ulogic; -- 12.288MHz clock for logic and codec mclk
        i_rec      : in  t_codec_driver_i_rec; -- input record
        o_rec      : out t_codec_driver_o_rec  -- output record
    );
end entity codec_driver;

architecture rtl of codec_driver is

    ------ mclk ------
    constant MCLK_GEN_COUNT_MAX : integer := 9;
    signal counter_mclk_gen_i : t_counter_i_rec := ('1', '1', '1');
    signal counter_mclk_gen_o : t_counter_o_rec(count(num_bits(MCLK_GEN_COUNT_MAX)-1 downto 0));

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

    type t_fsm_io is record 
        din_sreg_load_sel   : integer range 0 to 4;
        din_output_en       : std_ulogic;
        din_loopback_en     : std_ulogic;
        din_reset_en        : std_ulogic;
    end record t_fsm_io;
    signal fsm_io : t_fsm_io := (0, '0', '0', '0');

    -- FSM mclk counter
    constant MCLK_COUNTER_MAX : integer := 255;
    signal counter_mclk_i : t_counter_i_rec := ('0', '1', '1');
    signal counter_mclk_o : t_counter_o_rec(count(num_bits(MCLK_COUNTER_MAX)-1 downto 0));
    
    constant FS_COUNTER_MAX : integer := 12;
    signal counter_fs_i : t_counter_i_rec := ('0', '0', '0');
    signal counter_fs_o : t_counter_o_rec(count(num_bits(FS_COUNTER_MAX)-1 downto 0));

    -- fsm init regs
    signal srff_first_xfr_i   : t_srff_i_rec := ('0', '0');
    signal srff_first_xfr_o   : t_srff_o_rec;
    signal srff_word_a_init_i : t_srff_i_rec := ('0', '0');
    signal srff_word_a_init_o : t_srff_o_rec;
    signal srff_word_c_init_i : t_srff_i_rec := ('0', '0');
    signal srff_word_c_init_o : t_srff_o_rec;
    signal srff_mode_24b_i    : t_srff_i_rec := ('0', '0');
    signal srff_mode_24b_o    : t_srff_o_rec;

    -- dout sreg
    constant SREG_NUM_BITS : integer := CODEC_WORD_WIDTH;
    subtype t_sreg_data_i_rec is t_sreg_i_rec(load_word(SREG_NUM_BITS-1 downto 0));
    subtype t_sreg_data_o_rec is t_sreg_o_rec(word(SREG_NUM_BITS-1 downto 0));

    signal sreg_dout_i : t_sreg_data_i_rec
        := (load_word => (others => '0'), others => '0');
    signal sreg_dout_o : t_sreg_data_o_rec;
    
    -- din sreg
    signal sreg_din_i : t_sreg_data_i_rec
        := (load_word => (others => '0'), others => '0');
    signal sreg_din_o : t_sreg_data_o_rec;

    ------ io ------
    -- codec output regs
    signal dff_clken_codec_mclk_i  : t_dff_clken_i_rec := ('1', '0');
    signal dff_clken_codec_mclk_o  : t_dff_clken_o_rec;
    signal dff_clken_codec_rst_n_i : t_dff_clken_i_rec := ('1', '1');
    signal dff_clken_codec_rst_n_o : t_dff_clken_o_rec;
    signal dff_clken_codec_dclk_i  : t_dff_clken_i_rec := ('1', '0');
    signal dff_clken_codec_dclk_o  : t_dff_clken_o_rec;
    signal dff_clken_codec_dfs_i   : t_dff_clken_i_rec := ('1', '0');
    signal dff_clken_codec_dfs_o   : t_dff_clken_o_rec;
    signal dff_clken_codec_din_i   : t_dff_clken_i_rec := ('1', 'Z');
    signal dff_clken_codec_din_o   : t_dff_clken_o_rec;
    signal dff_clken_codec_dout_i  : t_dff_clken_i_rec := ('1', '0');
    signal dff_clken_codec_dout_o  : t_dff_clken_o_rec;

    -- dsp if
    subtype t_reg_codec_data_i_rec is t_reg_i_rec(load_word(t_codec_word'range));
    subtype t_reg_codec_data_o_rec is t_reg_o_rec(word(t_codec_word'range));

    -- adc
    signal dff_ons_dsp_adc_word_valid_i : t_dff_clken_i_rec := ('1', '0');
    signal dff_ons_dsp_adc_word_valid_o : t_dff_clken_o_rec;
    signal reg_dsp_adc_word_i : t_reg_codec_data_i_rec := (
        clken     => '1',
        load_word => (others => '0'),
        load_en   => '0', 
        rst_n     => '1'
    );
    signal reg_dsp_adc_word_o : t_reg_codec_data_o_rec;
    
    -- dac
    signal dff_ons_dsp_dac_word_valid_i : t_dff_clken_i_rec := ('1', '0');
    signal dff_ons_dsp_dac_word_valid_o : t_dff_clken_o_rec;
    signal reg_dsp_dac_word_i : t_reg_codec_data_i_rec := (
        clken     => '1',
        load_word => (others => '0'),
        load_en   => '0', 
        rst_n     => '1'
    );
    signal reg_dsp_dac_word_o : t_reg_codec_data_o_rec;

begin
    ----------------
    -- controller --
    u_mclk_gen_counter :  entity shared_lib.counter 
        generic map (MCLK_GEN_COUNT_MAX)
        port map(i_clk_122M, counter_mclk_gen_i, counter_mclk_gen_o);

    -- FSM r_state reg
    proc_state : process(i_clk_122M)
    begin
        if rising_edge(i_clk_122M) then
            if i_rec.clken_12M then
                r_state <= sRESET when not i_rec.rst_n else w_next_state;
            end if;
        end if;
    end process proc_state;

   -- next r_state and control logic
    proc_fsm: process(all)
        -- variable counter : integer range 0 to 255;
        -- variable samp_counter : integer range 0 to 15;
    begin
        -- default assignments
        counter_mclk_i.en   <= '1';
        counter_fs_i.en     <= '0';

        srff_first_xfr_i.s     <= '0';
        srff_word_a_init_i.s   <= '0';
        srff_word_c_init_i.s   <= '0';
        srff_mode_24b_i.s     <= '0';

        sreg_dout_i.shift_en    <= '0';
        sreg_din_i.shift_en     <= '0';
        sreg_din_i.load_en  <= '0';
        fsm_io.din_sreg_load_sel <= 0;

        fsm_io.din_output_en     <= '0';
        fsm_io.din_loopback_en   <= '0';
        fsm_io.din_reset_en      <= '0';

        dff_clken_codec_rst_n_i.d   <= '1';
        dff_clken_codec_dfs_i.d     <= '0';

        -- adc
        dff_ons_dsp_adc_word_valid_i.d <= '0';
        reg_dsp_adc_word_i.load_en <= '0';

        -- dac 

        case r_state is
            when sRESET =>
                dff_clken_codec_dclk_i.d     <= '0';
                dff_clken_codec_rst_n_i.d    <= '0';
                if counter_mclk_o.count = 9 then
                    counter_mclk_i.en <= '0';
                    w_next_state <= sCODEC_RESET_0;
                else
                    w_next_state <= sRESET;
                end if;

            when sCODEC_RESET_0 =>
                dff_clken_codec_rst_n_i.d    <= '0';
                dff_clken_codec_dclk_i.d     <= '0';
                fsm_io.din_output_en <= '1';
                fsm_io.din_reset_en  <= '1';
                if counter_mclk_o.count = 9 then
                    counter_mclk_i.en <= '0';
                    w_next_state <= sCODEC_RESET_1;
                else
                    w_next_state <= sCODEC_RESET_0;
                end if;

            when sCODEC_RESET_1 =>
                dff_clken_codec_dclk_i.d    <= '0';
                fsm_io.din_output_en <= '1';
                fsm_io.din_reset_en  <= '1';
                if counter_mclk_o.count = 9 then
                    counter_mclk_i.en <= '0';
                    w_next_state <= sCODEC_RESET_2;
                else
                    w_next_state <= sCODEC_RESET_1;
                end if;

            when sCODEC_RESET_2 =>
                dff_clken_codec_dclk_i.d <= not counter_mclk_o.count(0);
                if counter_mclk_o.count = 255 then
                    counter_mclk_i.en <= '0';
                    counter_fs_i.en <= '1';
                    if counter_fs_o.count = 11 then
                        w_next_state <= sXFR_START_0;
                    else
                        w_next_state <= sCODEC_RESET_2;
                    end if;
                else
                    w_next_state <= sCODEC_RESET_2;
                end if;

            when sXFR_START_0 =>
                dff_clken_codec_dclk_i.d <= '1';
                dff_clken_codec_dfs_i.d <= '1';
                w_next_state <= sXFR_START_1;

            when sXFR_START_1 =>
                dff_clken_codec_dclk_i.d <= '0';
                dff_clken_codec_dfs_i.d <= '1';
                sreg_din_i.load_en <= '1';


                if srff_first_xfr_o.q = '0' then
                    srff_first_xfr_i.s <= i_rec.clken_12M;
                    fsm_io.din_sreg_load_sel  <= 0;
                elsif srff_word_a_init_o.q = '0' then
                    srff_word_a_init_i.s <= i_rec.clken_12M;
                    fsm_io.din_sreg_load_sel <= 1;
                elsif srff_word_c_init_o.q = '0'  then
                    srff_word_c_init_i.s <= i_rec.clken_12M;
                    fsm_io.din_sreg_load_sel <= 2;
                elsif srff_mode_24b_o.q = '0' then
                    srff_mode_24b_i.s <= i_rec.clken_12M;
                    fsm_io.din_sreg_load_sel <= 0;
                else 
                    fsm_io.din_sreg_load_sel <= 0;
                end if;

                w_next_state <= sXFR_SHIFT_0;

            when sXFR_SHIFT_0 =>
                dff_clken_codec_dclk_i.d    <= '1';
                sreg_dout_i.shift_en  <= '1';
                fsm_io.din_output_en <= '1';
                -- fsm_io.din_loopback_en <= '1' when counter_mclk_o.count >= 66 else '0';
                w_next_state    <= sXFR_SHIFT_1;

            when sXFR_SHIFT_1 =>
                dff_clken_codec_dclk_i.d    <= '0';
                sreg_din_i.shift_en   <= '1';
                fsm_io.din_output_en <= '1';
                -- fsm_io.din_loopback_en <= '1' when counter_mclk_o.count >= 66 else '0';
                reg_dsp_adc_word_i.load_en <= srff_mode_24b_o.q and counter_mclk_gen_o.count ?= 0 and counter_mclk_o.count ?= 113;

                case to_integer(counter_mclk_o.count) is
                    when 31     => w_next_state <= sXFR_DFS_0;
                    when 63     => w_next_state <= sXFR_DFS_0 when srff_mode_24b_o.q else sXFR_SHIFT_0;
                    when 65     => w_next_state <= sXFR_IDLE_0;
                    when 95     => w_next_state <= sXFR_DFS_0;
                    when 113    => w_next_state <= sXFR_IDLE_0;
                    when others => w_next_state <= sXFR_SHIFT_0;
                end case;

            when sXFR_DFS_0 =>
                dff_clken_codec_dclk_i.d    <= '1';
                dff_clken_codec_dfs_i.d    <= '1';
                sreg_dout_i.shift_en  <= '1';
                fsm_io.din_output_en <= '1';
                -- fsm_io.din_loopback_en   <= '1' when counter_mclk_o.count=96 else '0';
                w_next_state    <= sXFR_DFS_1;

            when sXFR_DFS_1 =>
                dff_clken_codec_dclk_i.d    <= '0';
                dff_clken_codec_dfs_i.d    <= '1';
                sreg_din_i.shift_en   <= '1';
                fsm_io.din_output_en <= '1';
                -- fsm_io.din_loopback_en <= '1' when counter_mclk_o.count=97 else '0';
                

                case to_integer(counter_mclk_o.count) is
                    when 65     =>  fsm_io.din_sreg_load_sel <= 3;
                                    sreg_din_i.load_en <= '1';
                    -- when 97     =>  fsm_io.din_sreg_load_sel <= 4;
                    when others =>  fsm_io.din_sreg_load_sel <= 0;
                end case;

                w_next_state    <= sXFR_SHIFT_0;

            when sXFR_IDLE_0 =>
                dff_clken_codec_dclk_i.d    <= '1';
                dff_ons_dsp_adc_word_valid_i.d <= srff_mode_24b_o.q;

                w_next_state    <= sXFR_IDLE_1;
                
                when sXFR_IDLE_1 =>
                dff_clken_codec_dclk_i.d    <= '0';
                dff_ons_dsp_adc_word_valid_i.d <= srff_mode_24b_o.q;

                if counter_mclk_o.count = 255 then
                    counter_mclk_i.en    <= '0';
                    w_next_state    <= sXFR_START_0;
                else
                    w_next_state    <= sXFR_IDLE_0;
                end if;

            when others  =>
                dff_clken_codec_dclk_i.d    <= '0';
                w_next_state    <= sRESET;

        end case;
    end process proc_fsm;

    -- mclk counter
    counter_mclk_i.rst_n <= counter_mclk_i.en;
    counter_mclk_i.clken <= i_rec.clken_12M;
    u_mclk_counter :  entity shared_lib.counter 
        generic map (MCLK_COUNTER_MAX)
        port map(i_clk_122M, counter_mclk_i, counter_mclk_o);
    
    -- fs counter
    counter_fs_i.rst_n <= dff_clken_codec_rst_n_i.d;
    counter_fs_i.clken <= i_rec.clken_12M;
    u_fs_counter :  entity shared_lib.counter 
        generic map (FS_COUNTER_MAX)
        port map(i_clk_122M, counter_fs_i, counter_fs_o);

    -- init tracking regs
    srff_first_xfr_i.r_n <= dff_clken_codec_rst_n_i.d;
    u_srff_first_xfr : entity shared_lib.srff
        port map(i_clk_122M, srff_first_xfr_i, srff_first_xfr_o);

    srff_word_a_init_i.r_n <= dff_clken_codec_rst_n_i.d;
    u_srff_word_a_init : entity shared_lib.srff
        port map(i_clk_122M, srff_word_a_init_i, srff_word_a_init_o);

    srff_word_c_init_i.r_n <= dff_clken_codec_rst_n_i.d;
    u_srff_word_c_init : entity shared_lib.srff
        port map(i_clk_122M, srff_word_c_init_i, srff_word_c_init_o);

        -----------dff--
    srff_mode_24b_i.r_n <= dff_clken_codec_rst_n_i.d;
    u_srff_mode_24b : entity shared_lib.srff
        port map(i_clk_122M, srff_mode_24b_i, srff_mode_24b_o);
    -- datapathdff--
    --------------

    -- codec dout shift register
    sreg_dout_i.clken       <= i_rec.clken_12M;
    sreg_dout_i.load_word   <= (others => '0');
    sreg_dout_i.load_en     <= '0';
    sreg_dout_i.shift_bit   <= dff_clken_codec_dout_o.q;
    sreg_dout_i.rst_n       <= dff_clken_codec_rst_n_i.d;
    u_sreg_dout : entity shared_lib.sreg
        port map (i_clk_122M, sreg_dout_i, sreg_dout_o);

    -- din word mux
    with fsm_io.din_sreg_load_sel select sreg_din_i.load_word <= 
        (others => '0') when 0,
        std_ulogic_vector(REG_A_WORD)      when 1,
        std_ulogic_vector(REG_C_WORD)      when 2,
        reg_dsp_dac_word_o.word when 3,
        -- i_rec.ctrl_dac_word(23 downto 8)        when 3,
        -- i_rec_i_ctrl_dac_word(7 downto 0) & X"00" when 4,
        (others => '0') when others;

    -- codec din shift register
    sreg_din_i.clken     <= i_rec.clken_12M;
    sreg_din_i.shift_bit <= '0';
    sreg_din_i.rst_n     <= dff_clken_codec_rst_n_i.d;
    u_sreg_din :  entity shared_lib.sreg
        port map (i_clk_122M, sreg_din_i, sreg_din_o);

    -- loopback mux
    dff_clken_codec_din_i.d <=
        'Z'              when not fsm_io.din_output_en else
        '1'              when fsm_io.din_reset_en else
        -- dff_clken_codec_dout_o.q when fsm_io.din_loopback_en else
        sreg_din_o.word(CODEC_WORD_WIDTH-1);

    -- input registers
    dff_clken_codec_dout_i.d  <= i_rec.codec_dout;
    u_dff_dout : entity shared_lib.dff_clken
        port map(i_clk_122M, dff_clken_codec_dout_i, dff_clken_codec_dout_o);
    
    -- output assignment and registers
    -- codec
    dff_clken_codec_mclk_i.d <= counter_mclk_gen_o.count ?>2 and counter_mclk_gen_o.count ?<8;
    u_dff_mclk  : entity shared_lib.dff_clken
        port map(i_clk_122M, dff_clken_codec_mclk_i,  dff_clken_codec_mclk_o);
    u_dff_rst_n : entity shared_lib.dff_clken
        generic map('1')
        port map(i_clk_122M, dff_clken_codec_rst_n_i, dff_clken_codec_rst_n_o);
    u_dff_dclk  : entity shared_lib.dff_clken
        port map(i_clk_122M, dff_clken_codec_dclk_i,  dff_clken_codec_dclk_o);
    u_dff_dfs   : entity shared_lib.dff_clken
        port map(i_clk_122M, dff_clken_codec_dfs_i,   dff_clken_codec_dfs_o);
    u_dff_din   : entity shared_lib.dff_clken
        generic map('Z')
        port map(i_clk_122M, dff_clken_codec_din_i,   dff_clken_codec_din_o);

    o_rec.codec_mclk    <= dff_clken_codec_mclk_o.q;
    o_rec.codec_rst_n   <= dff_clken_codec_rst_n_o.q;
    o_rec.codec_dclk    <= dff_clken_codec_dclk_o.q;
    o_rec.codec_dfs     <= dff_clken_codec_dfs_o.q;
    o_rec.codec_din     <= dff_clken_codec_din_o.q;

    -- dsp if
    -- adc
    u_dff_ons_dsp_adc_word_valid : entity shared_lib.dff_ons
        port map(i_clk_122M, dff_ons_dsp_adc_word_valid_i, dff_ons_dsp_adc_word_valid_o);

    reg_dsp_adc_word_i.load_word <= sreg_dout_o.word;
    u_reg_dsp_adc_word : entity shared_lib.reg
        port map(i_clk_122M, reg_dsp_adc_word_i, reg_dsp_adc_word_o);

    o_rec.dsp_adc_word_valid <= dff_ons_dsp_adc_word_valid_o.q;
    o_rec.dsp_adc_word <= t_codec_word(reg_dsp_adc_word_o.word);

    -- dac
    dff_ons_dsp_dac_word_valid_i.d <= i_rec.dsp_dac_word_valid;
    u_dff_ons_dsp_dac_word_valid : entity shared_lib.dff_ons
        port map(i_clk_122M, dff_ons_dsp_dac_word_valid_i, dff_ons_dsp_dac_word_valid_o);

    reg_dsp_dac_word_i.load_word <= std_ulogic_vector(i_rec.dsp_dac_word);
    reg_dsp_dac_word_i.load_en <= dff_ons_dsp_dac_word_valid_o.q;
    u_reg_dsp_dac_word : entity shared_lib.reg
        port map(i_clk_122M, reg_dsp_dac_word_i, reg_dsp_dac_word_o);

    
end architecture rtl;