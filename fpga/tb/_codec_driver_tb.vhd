library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

entity codec_driver_tb is
end entity codec_driver_tb;

architecture tb of codec_driver_tb is
    -- testbench configuration
    constant REG_A_WORD : std_logic_vector(15 downto 0) := B"1000_0000_0111_1100";
    constant REG_C_WORD : std_logic_vector(15 downto 0) := B"1001_0000_0011_0101";

    -- clock and reset
    signal clk  : std_logic := '1';
    constant CLK_PER_ns : time := (1000.0/12.28814) * 1ns;

    signal rst_n    : std_logic := '0';

    -- bfm (stimulus)
    signal  adc_data        : unsigned(23 downto 0);

    -- dut io
    -- signal  ctrl_loopback   : std_logic := '0';
    -- signal  ctrl_busy       : std_logic;
    signal  codec_mclk      : std_logic;
    signal  codec_rst_n     : std_logic;
    signal  codec_dclk      : std_logic;
    signal  codec_dfs       : std_logic;
    signal  codec_din       : std_logic;
    signal  codec_dout      : std_logic := 'Z';

    -- response checker
    signal  codec_mclk_expected : std_logic;
    signal  codec_rst_n_expected: std_logic;
    signal  codec_dclk_expected : std_logic;
    signal  codec_dfs_expected  : std_logic;
    signal  codec_din_expected  : std_logic;
    signal  checker_en          : std_logic := '0';

    -- helper procedures
    procedure p_wait_clk is
    begin
        wait until clk = '1';
        wait for 1 ns;
    end p_wait_clk;

    procedure p_assert_eq(
        actual, expected: in std_logic;
        err_msg: in string) is
    begin
        assert actual = expected
            report "error with " & err_msg & LF &
                "    actual: " & to_string(actual) & ", expected: " & to_string(expected)
            severity failure; 

    end procedure p_assert_eq;

    -- dut compotnent
    component codec_driver is
        port (
            -- clock and reset
            i_clk_12M   :   in  std_logic;  -- 12.288MHz clock for logic and codec mclk
            i_rst_n     :   in  std_logic;  -- system reset
            -- controller if
            i_ctrl_dac_word : in std_logic_vector(23 downto 0);
            -- i_ctrl_loopback     :   in  std_logic;  -- enable to run codec in loopback mode (adc to dac)
            -- o_ctrl_busy         :   out std_logic;  -- high when codec transaction in progress
            -- codec hardware if
            o_codec_mclk    :   out std_logic;  -- codec master clock
            o_codec_rst_n   :   out std_logic;  -- codec reset signal
            o_codec_dclk    :   out std_logic;  -- codec serial clock
            o_codec_dfs     :   out std_logic;  -- codec dfs
            o_codec_din     :   out std_logic;  -- serial data to codec
            i_codec_dout    :   in  std_logic   -- serial data from codec
        );
    end component codec_driver;

begin
    -- clock generationQuick Access
    clk <= not clk after CLK_PER_ns/2;
    rst_n <= '1' after CLK_PER_ns * 5.5;

    -- codec bfm (stimulus)
    proc_bfm: process
    begin
        wait on adc_data'transaction;

        while true loop
            for i in 0 to 127 loop
                -- dclk hi
                p_wait_clk;
                case i is
                    when 1 to 32    =>  codec_dout  <=  '0';
                    -- when 33 to 56   =>  codec_dout  <=  '1';
                    when 33 to 56   =>  codec_dout  <=  adc_data(56-i);
                    when others     =>  codec_dout  <=  'Z';
                end case;

                -- dclk lo
                p_wait_clk;

            end loop;            
        end loop;
    end process proc_bfm;

    -- response checker expected results
    proc_checker: process
    begin
        wait until rst_n = '1';

        -- sCODEC_RESET_0
        codec_rst_n_expected    <= '0';
        codec_dclk_expected     <= '0';
        codec_dfs_expected      <= '0';
        codec_din_expected      <= '0';
        
        checker_en <= '1';
        for i in 0 to 9 loop
            p_wait_clk;
        end loop;

        -- sCODEC_RESET_1
        wait until falling_edge(clk);
        codec_rst_n_expected <= '1';
        for i in 0 to 9 loop
            p_wait_clk;
        end loop;
            
            -- sCODEC_RESET_2
        wait until falling_edge(clk);
        codec_din_expected <= 'Z';
        for i in 0 to (256*12)-1 loop
            p_wait_clk;
        end loop;

        -- reg a word
        for i in 0 to 127 loop
            -- dclk hi
            wait until falling_edge(clk);
            codec_dclk_expected <=  '1' when i /= 0 else '0';
            codec_dfs_expected  <=  '1' when i = 16 else '0';
            codec_din_expected  <=  REG_A_WORD(16-i)    when 1  <= i and i <= 16 else
                                    '0'                 when 17 <= i and i <= 32 else
                                    'Z';
            p_wait_clk;
            -- dclk lo
            wait until falling_edge(clk);
            codec_dclk_expected <= '0';
            p_wait_clk;
        end loop;
        
        -- reg c word
        for i in 0 to 127 loop
            -- dclk hi
            wait until falling_edge(clk);
            codec_dclk_expected <=  '1' ;
            codec_dfs_expected  <=  '1' when i = 0 or i = 16 else '0';
            codec_din_expected  <=  REG_C_WORD(16-i)    when 1  <= i and i <= 16 else
                                    '0'                 when 17 <= i and i <= 32 else
                                    'Z';
            p_wait_clk;

            -- dclk lo
            wait until falling_edge(clk);
            codec_dclk_expected <= '0';
            p_wait_clk;

        end loop;

        -- reg data words
        for j in 0 to 2**24-1 loop
            adc_data <= to_unsigned(j, 24);
            
            for i in 0 to 127 loop
                -- dclk hi
                wait until falling_edge(clk);
                codec_dclk_expected <=  '1' ;
                codec_dfs_expected  <=  '1' when i = 0 or i = 16 or i = 32 or i = 48 else '0';
                codec_din_expected  <=  '0' when 1 <= i and i <= 32 else
                                        adc_data(56-i) when 33 <= i and i <= 56 else
                                        'Z';
                p_wait_clk;
    
                -- dclk lo
                wait until falling_edge(clk);
                codec_dclk_expected <= '0';
                p_wait_clk;
    
            end loop;
        end loop;
        checker_en <= '0';

        wait for 10 * CLK_PER_ns;
        report "end of test" severity failure;
    end process proc_checker;

    -- response checkers
    prock_checkers: process
    begin
        p_WAIT_CLK;
        wait for 5 ns;
        if checker_en then
            p_assert_eq(codec_rst_n, codec_rst_n_expected, "codec_rst_n");
            p_assert_eq(codec_dclk,  codec_dclk_expected,  "codec_dclk");
            p_assert_eq(codec_dfs,   codec_dfs_expected,   "codec_dfs");
            p_assert_eq(codec_din,   codec_din_expected,   "codec_din");
        end if;
    end process prock_checkers;

    -- dut
    dut: codec_driver
        port map(
            i_clk_12M       => clk,
            i_rst_n         => rst_n,
            i_ctrl_dac_word => (others => '0'),
            o_codec_mclk    => codec_mclk,
            o_codec_rst_n   => codec_rst_n,
            o_codec_dclk    => codec_dclk,
            o_codec_dfs     => codec_dfs,
            o_codec_din     => codec_din,
            i_codec_dout    => codec_dout
        );

    -- dut (mock)
    -- proc_dut_mock: process
    --     variable din_sreg   : std_logic_vector(15 downto 0);
    --     variable din_ptr    : integer;
    -- begin
    --     wait;
    --     ref_codec_rst_n <= '1';
    --     ref_codec_dclk  <= 'U';
    --     ref_codec_dfs   <= '0';
    --     ref_codec_din   <= 'Z';
        
    --     -- sRESET
    --     wait until rst_n = '1';
    --     report "entering sRESET";
    --     p_wait_clk;
        
    --     -- sCODEC_RESET_0
    --     report "entering sCODEC_RESET_0";
    --     ref_codec_rst_n <= '0';
    --     ref_codec_dclk  <= '0';
    --     ref_codec_dfs   <= '0';
    --     ref_codec_din   <= '0';

    --     for i in 0 to 9 loop
    --         p_wait_clk;
    --     end loop;

    --     -- sCODEC_RESET_1
    --     report "entering sCODEC_RESET_1";
    --     ref_codec_rst_n <= '1';

    --     for i in 0 to 9 loop
    --         p_wait_clk;
    --     end loop;

    --     -- sCODEC_RESET_2
    --     report "entering sCODEC_RESET_2";
    --     ref_codec_din <= 'Z';
        
    --     for i in 0 to (256*12)-1 loop
    --         p_wait_clk;
    --     end loop;

    --     -- send reg a word
    --     din_sreg := REG_A_WORD;
    --     for i in 0 to 127 loop
    --         -- dclk hi
    --         ref_codec_dclk  <= '1';

    --         if i = 16 then
    --             ref_codec_dfs   <= '1';
    --         else
    --             ref_codec_dfs   <= '0';
    --         end if;

    --         case i is
    --             when 1 to 16    =>  ref_codec_din   <= din_sreg(16-i);
    --             when 17 to 32   =>  ref_codec_din   <= '0';  
    --             when others     =>  ref_codec_din   <= 'Z';
    --         end case;

    --         p_wait_clk;

    --         -- dclk lo
    --         ref_codec_dclk  <= '0';
    --         p_wait_clk;

    --     end loop;

    --     -- send reg c word
    --     for i in 0 to 127 loop
    --         -- dclk hi
    --         ref_codec_dclk  <= '1';

    --         if i = 0 or i = 16 then
    --             ref_codec_dfs   <= '1';
    --             din_sreg        := REG_C_WORD;
    --         else
    --             ref_codec_dfs   <= '0';
    --         end if;

    --         case i is
    --             when 1 to 16    =>  ref_codec_din   <= din_sreg(16-i);
    --             when 17 to 32   =>  ref_codec_din   <= '0';  
    --             when others     =>  ref_codec_din   <= 'Z';
    --         end case;

    --         p_wait_clk;

    --         -- dclk lo
    --         ref_codec_dclk  <= '0';
    --         p_wait_clk;

    --     end loop;

    --     -- 24 bit loopback mode
    --     while true loop
    --         for i in 0 to 127 loop
    --             -- dclk hi
    --         ref_codec_dclk  <= '1';

    --         if i = 0 or i = 16 or i = 32 or i = 48 then
    --             ref_codec_dfs   <= '1';
    --         else
    --             ref_codec_dfs   <= '0';
    --         end if;

    --         case i is
    --             when 1 to 32    =>  ref_codec_din   <= '0';
    --             when 33 to 56   =>  ref_codec_din   <= codec_dout;  
    --             when others     =>  ref_codec_din   <= 'Z';
    --         end case;

    --         p_wait_clk;

    --         -- dclk lo
    --         ref_codec_dclk  <= '0';
    --         p_wait_clk;
    --         end loop;
    --     end loop;

    --     wait;
    -- end process proc_dut_mock;

end architecture tb;