library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library shared_lib;
use shared_lib.utils_pkg.all;
use shared_lib.flip_flops_pkg.all;
use shared_lib.registers_pkg.all;
use shared_lib.counter_pkg.all;

library speaker_sim_lib;
use speaker_sim_lib.codec_driver_pkg.all;

entity codec_driver is
    port (
        i_clk_12M : in  std_ulogic; -- 12.288MHz clock for logic and codec mclk
        i_rec     : in  t_codec_driver_i_rec; -- input record
        o_rec     : out t_codec_driver_o_rec  -- output record
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

    type t_fsm_io is record 
        din_sreg_load_sel   : integer range 0 to 4;
        din_output_en       : std_ulogic;
        din_loopback_en     : std_ulogic;
    end record t_fsm_io;
    signal fsm_io : t_fsm_io;

    -- FSM mclk counter
    constant MCLK_COUNTER_MAX : integer := 255;
    signal counter_mclk_i : t_counter_i_rec;
    signal counter_mclk_o : t_counter_o_rec(count(num_bits(MCLK_COUNTER_MAX)-1 downto 0));
    
    constant FS_COUNTER_MAX : integer := 11;
    signal counter_fs_i : t_counter_i_rec;
    signal counter_fs_o : t_counter_o_rec(count(num_bits(FS_COUNTER_MAX)-1 downto 0));

    -- fsm init regs
    signal srff_first_xfr   : t_srff_rec;
    -- signal srff_first_xfr   : t_srff_rec_o;
    signal srff_word_a_init : t_srff_rec;
    -- signal srff_word_a_init : t_srff_rec_o;
    signal srff_word_c_init : t_srff_rec;
    -- signal srff_word_c_init : t_srff_rec_o;
    signal srff_mode_24b    : t_srff_rec;
    -- signal srff_mode_24b    : t_srff_rec_o;

    -- dout sreg
    constant SREG_NUM_BITS : integer := 16;
    subtype t_sreg16_rec is t_sreg_rec(
        i(load_word(SREG_NUM_BITS-1 downto 0)),
        o(word(SREG_NUM_BITS-1 downto 0))
    );
    signal sreg_dout : t_sreg16_rec;
    
    -- din sreg
    -- constant REG_A_WORD     : std_ulogic_vector (15 downto 0) := B"1000_0000_0111_1100";
    -- constant REG_C_WORD     : std_ulogic_vector (15 downto 0) := B"1001_0000_0011_0101";
    signal sreg_din : t_sreg16_rec;

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
    r_state <= sRESET when not i_rec.rst_n else w_next_state when rising_edge(i_clk_12M);

   -- next r_state and control logic
    proc_fsm: process(all)
        -- variable counter : integer range 0 to 255;
        -- variable samp_counter : integer range 0 to 15;
    begin
        -- default assignments
        counter_mclk_i.en   <= '1';
        counter_fs_i.en     <= '0';

        srff_first_xfr.i.s     <= '0';
        srff_word_a_init.i.s   <= '0';
        srff_word_c_init.i.s   <= '0';
        srff_mode_24b.i.s     <= '0';

        sreg_dout.i.shift_en    <= '0';
        sreg_din.i.shift_en     <= '0';
        sreg_din.i.load_en  <= '0';
        fsm_io.din_sreg_load_sel <= 0;

        fsm_io.din_output_en     <= '0';
        fsm_io.din_loopback_en   <= '0';

        w_codec_rst_n   <= '1';
        w_codec_dfs     <= '0';

        case r_state is
            when sRESET =>
                counter_mclk_i.en <= '0';
                w_codec_dclk    <= '0';
                w_next_state <= sCODEC_RESET_0;

            when sCODEC_RESET_0 =>
                w_codec_rst_n   <= '0';
                w_codec_dclk    <= '0';
                fsm_io.din_output_en <= '1';
                if counter_mclk_o.count = 8 then
                    counter_mclk_i.en <= '0';
                    w_next_state <= sCODEC_RESET_1;
                else
                    w_next_state <= sCODEC_RESET_0;
                end if;

            when sCODEC_RESET_1 =>
                w_codec_dclk    <= '0';
                fsm_io.din_output_en <= '1';
                if counter_mclk_o.count = 9 then
                    counter_mclk_i.en <= '0';
                    w_next_state <= sCODEC_RESET_2;
                else
                    w_next_state <= sCODEC_RESET_1;
                end if;

            when sCODEC_RESET_2 =>
                w_codec_dclk <= not counter_mclk_o.count(0);
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
                w_codec_dclk <= '1';
                w_codec_dfs  <= '1';
                w_next_state <= sXFR_START_1;

            when sXFR_START_1 =>
                w_codec_dclk <= '0';
                w_codec_dfs  <= '1';
                sreg_din.i.load_en <= '1';

                if not srff_first_xfr.o.q then
                    srff_first_xfr.i.s <= '1';
                    fsm_io.din_sreg_load_sel  <= 0;
                elsif not srff_word_a_init.o.q then
                    srff_word_a_init.i.s <= '1';
                    fsm_io.din_sreg_load_sel <= 1;
                elsif not srff_word_c_init.o.q then
                    srff_word_c_init.i.s <= '1';
                    fsm_io.din_sreg_load_sel <= 2;
                elsif not srff_mode_24b.o.q then
                    srff_mode_24b.i.s <= '1';
                    fsm_io.din_sreg_load_sel <= 0;
                else 
                    fsm_io.din_sreg_load_sel <= 0;
                end if;

                w_next_state <= sXFR_SHIFT_0;

            when sXFR_SHIFT_0 =>
                w_codec_dclk    <= '1';
                sreg_dout.i.shift_en  <= '1';
                fsm_io.din_output_en <= '1';
                fsm_io.din_loopback_en <= '1' when counter_mclk_o.count >= 66 else '0';
                w_next_state    <= sXFR_SHIFT_1;

            when sXFR_SHIFT_1 =>
                w_codec_dclk    <= '0';
                sreg_din.i.shift_en   <= '1';
                fsm_io.din_output_en <= '1';
                fsm_io.din_loopback_en <= '1' when counter_mclk_o.count >= 66 else '0';
                case to_integer(counter_mclk_o.count) is
                    when 31     => w_next_state <= sXFR_DFS_0;
                    when 63     => w_next_state <= sXFR_DFS_0 when srff_mode_24b.o.q else sXFR_SHIFT_0;
                    when 65     => w_next_state <= sXFR_IDLE_0;
                    when 95     => w_next_state <= sXFR_DFS_0;
                    when 113    => w_next_state <= sXFR_IDLE_0;
                    when others => w_next_state <= sXFR_SHIFT_0;
                end case;

            when sXFR_DFS_0 =>
                w_codec_dclk    <= '1';
                w_codec_dfs     <= '1';
                sreg_dout.i.shift_en  <= '1';
                fsm_io.din_output_en <= '1';
                fsm_io.din_loopback_en   <= '1' when counter_mclk_o.count=96 else '0';
                w_next_state    <= sXFR_DFS_1;

            when sXFR_DFS_1 =>
                w_codec_dclk    <= '0';
                w_codec_dfs     <= '1';
                sreg_din.i.shift_en   <= '1';
                fsm_io.din_output_en <= '1';
                fsm_io.din_loopback_en <= '1' when counter_mclk_o.count=97 else '0';
                case to_integer(counter_mclk_o.count) is
                    when 65     =>  fsm_io.din_sreg_load_sel <= 3;
                    when 97     =>  fsm_io.din_sreg_load_sel <= 4;
                    when others =>  fsm_io.din_sreg_load_sel <= 0;
                end case;
                w_next_state    <= sXFR_SHIFT_0;

            when sXFR_IDLE_0 =>
                w_codec_dclk    <= '1';
                w_next_state    <= sXFR_IDLE_1;

            when sXFR_IDLE_1 =>
                w_codec_dclk    <= '0';
                if counter_mclk_o.count = 255 then
                    counter_mclk_i.en    <= '0';
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
    counter_mclk_i.rst_n <= counter_mclk_i.en;
    u_mclk_counter : counter 
        generic map (MCLK_COUNTER_MAX)
        port map(i_clk_12M, counter_mclk_i, counter_mclk_o);

    
    
    -- fs counter
    counter_fs_i.rst_n <= w_codec_rst_n;
    u_fs_counter : counter 
        generic map (FS_COUNTER_MAX)
        port map(i_clk_12M, counter_fs_i, counter_fs_o);

    -- init tracking regs
    srff_first_xfr.i.r_n <= w_codec_rst_n;
    u_srff_first_xfr : srff
        port map(i_clk_12M, srff_first_xfr.i, srff_first_xfr.o);
        
    srff_word_a_init.i.r_n <= w_codec_rst_n;
    u_srff_word_a_init: srff
        port map(i_clk_12M, srff_word_a_init.i, srff_word_a_init.o);
        
    srff_word_c_init.i.r_n <= w_codec_rst_n;
    u_srff_word_c_init : srff
        port map(i_clk_12M, srff_word_c_init.i, srff_word_c_init.o);
        --------------
    srff_mode_24b.i.r_n <= w_codec_rst_n;
    u_srff_mode_24b : srff
        port map(i_clk_12M, srff_mode_24b.i, srff_mode_24b.o);
    -- datapath --
    --------------

    -- codec dout shift register
    sreg_dout.i.load_word   <= (others => '0');
    sreg_dout.i.load_en     <= '0';
    sreg_dout.i.shift_bit   <= i_rec.codec_dout;
    sreg_dout.i.rst_n       <= w_codec_rst_n;
    u_sreg_dout : sreg port map (i_clk_12M, sreg_dout.i, sreg_dout.o);

    -- din word mux
    with fsm_io.din_sreg_load_sel select sreg_din.i.load_word <= 
        REG_A_WORD                          when 1,
        REG_C_WORD                          when 2,
        -- i_rec.ctrl_dac_word(23 downto 8)        when 3,
        -- i_rec.i_ctrl_dac_word(7 downto 0) & X"00" when 4,
        (others => '0')                     when others;

    -- codec din shift register
    sreg_din.i.shift_bit <= '0';
    sreg_din.i.rst_n     <= w_codec_rst_n;
    u_sreg_din : sreg
        generic map ('1')
        port map (i_clk_12M, sreg_din.i, sreg_din.o);

    -- loopback mux
    proc_loopback_mux : process(all)
    begin
        if not fsm_io.din_output_en then
            w_codec_din <=  'Z';
        elsif fsm_io.din_loopback_en then 
            w_codec_din <=  i_rec.codec_dout;
        else
            w_codec_din <= sreg_din.o.word(15);
        end if;
    end process;
    
    -- output assignment

    o_rec.codec_mclk    <= i_clk_12M;
    o_rec.codec_rst_n   <= w_codec_rst_n;
    o_rec.codec_dclk    <= w_codec_dclk;
    o_rec.codec_dfs     <= w_codec_dfs;
    o_rec.codec_din     <= w_codec_din;
    
end architecture rtl;