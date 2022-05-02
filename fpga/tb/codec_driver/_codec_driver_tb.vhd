library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_textio.all;

use std.textio.all;

library shared_lib;
use shared_lib.tb_utils_pkg.all;

library speaker_sim_lib;
use speaker_sim_lib.codec_driver;
use speaker_sim_lib.codec_driver_pkg.all;

entity codec_driver_tb is
end entity codec_driver_tb;

architecture tb of codec_driver_tb is
    -- testbench configuration
    constant COMB_DLY  : time := 1 ns;
    constant NUM_TESTS : integer := 48000;

    -- clock and reset
    constant CLK_PER_ns : time := (1000.0/122.88584) * 1ns;
    constant CLKEN_DIV : integer := 10;

    signal clk   : std_ulogic := '1';
    signal clken : std_ulogic := '0';

    signal rst_n : std_ulogic := '0';

    -- bfm (stimulus)
    signal  adc_data : t_codec_data_word;

    -- dut io
    signal dut_rec : t_codec_driver_rec;

    -- response checker
    signal dut_expected_rec : t_codec_driver_o_rec;
    signal checker_en       : std_ulogic := '0';

    -- helper procedures
    procedure wait_clk_122M is
    begin
       wait_clk(clk, 1 ps, 1);
    end wait_clk_122M;

    procedure wait_clk_122M(constant num_clks : positive) is
    begin
       wait_clk(clk, 1 ps, num_clks);
    end wait_clk_122M;

begin
    -- clock generation
    clk <= not clk after CLK_PER_ns/2;

    proc_clken : process
    begin
        for i in 0 to CLKEN_DIV-1 loop
            wait_clk_122M;
            -- wait for 5 ns;
            clken <= '1' when i = CLKEN_DIV-1 else '0';
        end loop;
    end process proc_clken;

    rst_n <= '1' after CLK_PER_ns * 25;

    -- codec bfm (stimulus)
    proc_bfm: process
    begin
        dut_rec.i.codec_dout  <=  '0';
        wait on adc_data'transaction;

        while true loop
            for i in 0 to 127 loop
                -- dclk hi
                wait_clk_122M(10);
                case i is
                    when 1 to 32    =>  dut_rec.i.codec_dout  <=  '0';
                    -- when 33 to 56   =>  dut_rec.i.codec_dout  <=  '1';
                    when 33 to 56   =>  dut_rec.i.codec_dout  <=  adc_data(56-i);
                    when others     =>  dut_rec.i.codec_dout  <=  'Z';
                end case;

                -- dclk lo
                wait_clk_122M(10);

            end loop;            
        end loop;
    end process proc_bfm;

    -- response checker expected results
    proc_checker: process
        variable rand_gen : t_rand_gen;
    begin

        dut_expected_rec.codec_rst_n    <= '1';
        dut_expected_rec.codec_dclk     <= '0';
        dut_expected_rec.codec_dfs      <= '0';
        dut_expected_rec.codec_din      <= 'Z';
        wait until rst_n = '1';

        checker_en <= '1';

        -- sCODEC_RESET_0
        wait until clken;
        wait_clk_122M;
        dut_expected_rec.codec_rst_n    <= '0';
        dut_expected_rec.codec_din      <= '1';

        wait_clk_122M(100);

        -- sCODEC_RESET_1
        -- wait until falling_edge(clk);
        dut_expected_rec.codec_rst_n <= '1';
        wait_clk_122M(100);
            
            -- sCODEC_RESET_2
        dut_expected_rec.codec_din  <= 'Z';
        dut_expected_rec.codec_dclk <= '1';
        for i in 0 to 12*256-1 loop
            dut_expected_rec.codec_dclk <= not dut_expected_rec.codec_dclk;
            wait_clk_122M(10);
        end loop;


        -- reg a read
        adc_data <= signed(REG_A_WORD & X"00");
        for i in 0 to 127 loop
            -- dclk hi
            dut_expected_rec.codec_dclk <=  '1';-- when i /= 0 else '0';
            dut_expected_rec.codec_dfs  <=  '1' when i=0 or i=16 else '0';
            dut_expected_rec.codec_din  <=  '0' when i >= 1 and i <= 32 else 'Z';

            -- dclk lo
            wait_clk_122M(10);
            dut_expected_rec.codec_dclk <= '0';

            wait_clk_122M(10);

        end loop;

        -- reg a write
        adc_data <= signed(REG_A_WORD & X"00");
        for i in 0 to 127 loop
            -- dclk hi
            dut_expected_rec.codec_dclk <=  '1';-- when i /= 0 else '0';
            dut_expected_rec.codec_dfs  <=  '1' when i=0 or i=16 else '0';
            dut_expected_rec.codec_din  <=  REG_A_WORD(16-i)    when 1 <= i and i <= 16 else
                                    '0'                 when 17 <= i and i <= 32 else
                                    'Z';
            -- dclk lo
            wait_clk_122M(10);
            dut_expected_rec.codec_dclk <= '0';

            wait_clk_122M(10);

        end loop;
    
        -- reg c word
        adc_data <= signed(REG_C_WORD & X"00");
        for i in 0 to 127 loop
            -- dclk hi
            dut_expected_rec.codec_dclk <=  '1' ;
            dut_expected_rec.codec_dfs  <=  '1' when i = 0 or i = 16 else '0';
            dut_expected_rec.codec_din  <=  REG_C_WORD(16-i)    when 1  <= i and i <= 16 else
                                    '0'                 when 17 <= i and i <= 32 else
                                    'Z';
            wait_clk_122M(10);

            -- dclk lo
            dut_expected_rec.codec_dclk <= '0';
            wait_clk_122M(10);

        end loop;

        -- assert false report "end of test" severity failure;

        -- reg data words
        rand_gen.init(1,2);
        for j in 0 to NUM_TESTS-1 loop
            rand_gen.rand(adc_data);
            
            for i in 0 to 127 loop
                -- dclk hi
                dut_expected_rec.codec_dclk <=  '1' ;
                dut_expected_rec.codec_dfs  <=  '1' when i=0 or i=16 or i=32 or i=48 else '0';
                dut_expected_rec.codec_din  <=  '0' when 1<=i and i<=32 else
                                        adc_data(56-i) when 33<=i and i<=56 else
                                        'Z';
                wait_clk_122M(10);
    
                -- dclk lo
                dut_expected_rec.codec_dclk <= '0';
                wait_clk_122M(10);
    
            end loop;
        end loop;
        checker_en <= '0';

        wait for 10 * CLK_PER_ns;
        report "end of test" severity failure;
    end process proc_checker;

    -- response checkers
    prock_checkers: process
    begin
        wait_clk_122M;
        wait for 1ns;
        if checker_en then
            -- assert_eq(dut_rec.o, dut_expected_rec, "dut_rec.o");
            assert_eq(dut_rec.o.codec_rst_n, dut_expected_rec.codec_rst_n, "codec_rst_n");
            assert_eq(dut_rec.o.codec_dclk,  dut_expected_rec.codec_dclk,  "codec_dclk");
            assert_eq(dut_rec.o.codec_dfs,   dut_expected_rec.codec_dfs,   "codec_dfs");
            assert_eq(dut_rec.o.codec_din,   dut_expected_rec.codec_din,   "codec_din");
        end if;
    end process prock_checkers;

    -- dut
    dut_rec.i.rst_n  <=  rst_n;
    dut_rec.i.clken_12M <= clken;
    dut : entity codec_driver
    port map(clk, dut_rec.i, dut_rec.o);

end architecture tb;