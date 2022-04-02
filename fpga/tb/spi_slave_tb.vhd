library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

entity spi_slave_tb is
end entity spi_slave_tb;

architecture tb of spi_slave_tb is
    -- testbench settings
    constant WORD_WIDTH     :   integer := 8;
    constant COMB_DELAY_ns  :   time    := 1ns;

    -- clock and reset
    signal clk                  :   std_logic   := '1';
    constant CLK_PER_ns         :   time        := 10 ns;
    constant SPI_SCLK_PER_ns    :   time        := 100 ns;

    signal rst_n        :   std_logic   := '0';

    -- xfr signals
    type t_xfr_data is record
        mosi_word:  std_logic_vector(WORD_WIDTH-1 downto 0);
        miso_word:  std_logic_vector(WORD_WIDTH-1 downto 0);
    end record t_xfr_data;

    signal xfr_data:    t_xfr_data;
    signal xfr_done:    boolean := false;

    -- dut signals
    signal spi_cs_n, spi_sclk, spi_mosi, spi_miso   :   std_logic;
    signal regmap_tx_load, regmap_rx_valid, regmap_busy :   std_logic;
    signal regmap_tx_word, regmap_rx_word   :   std_logic_vector(WORD_WIDTH-1 downto 0);

    -- helper procedures
    procedure p_WAIT_CLK is begin
        wait until clk = '1';
        wait for 1 ns;
    end p_WAIT_CLK;

    -- dut component
    component spi_slave is
        generic (
            g_WORD_WIDTH : integer
        );
        port (
            -- clock and reset
            i_clk_100M  : in    std_logic;  -- system clock
            i_rst_n     : in    std_logic;  -- system reset
            -- external spi if
            i_cs_n  : in    std_logic;  -- spi chip select
            i_sclk  : in    std_logic;  -- spi serial clock
            i_mosi  : in    std_logic;  -- spi serial data input
            o_miso  : out   std_logic;  -- spi serial data output
            -- register map if
            i_tx_load   :   in  std_logic;  -- synchronous load into output register
            i_tx_word   :   in  std_logic_vector(g_WORD_WIDTH-1 downto 0); -- data to load into output register
            o_rx_valid  :   out std_logic;  -- complete word has been shifted in and is ready to read
            o_rx_word   :   out std_logic_vector(g_WORD_WIDTH-1 downto 0); -- data received
            o_busy      :   out std_logic   -- flag active during spi transactions
        );
    end component spi_slave;

begin
    -- clock generation
    clk <= not clk after CLK_PER_ns/2;

    -- reset
    rst_n <= '1' after 50 ns;

    -- stimulus
    stimulus: process
        variable word: std_logic_vector(WORD_WIDTH-1 downto 0);
    begin
        wait until rst_n = '1';
        for i in 0 to (2**WORD_WIDTH)-1 loop
            word := std_logic_vector(to_unsigned(i, WORD_WIDTH));
            p_WAIT_CLK;
            xfr_data <= (word, not word);   -- setting this kicks off driver (tick)
            report "stimulus: setting transaction data";
            wait on xfr_done'transaction;
        end loop;
        report "end of test" severity failure;
        wait;
    end process;

    -- spi master bfm (driver)
    driver: process
        variable mosi_word: std_logic_vector(WORD_WIDTH-1 downto 0);
    begin
        -- initialize stimulus
        regmap_tx_load <= '0';
        regmap_tx_word <= (others => '-');
        spi_cs_n <= '1';
        spi_sclk <= '0';
        spi_mosi <= 'Z';

        -- wait for new transaction data
        wait on xfr_data'transaction;       -- sent by stimulus
        report "driver: starting transaction";

        -- load spi master tx word
        mosi_word := xfr_data.mosi_word;

        -- load dut tx word
        p_WAIT_CLK;
        regmap_tx_word <= xfr_data.miso_word;   -- set data word
        p_WAIT_CLK;
        regmap_tx_load <= '1';                  -- toggle load flag
        p_WAIT_CLK;
        regmap_tx_load <= '0';

        -- spi master transaction
        spi_cs_n <= '0';
        
        for i in (WORD_WIDTH-1) downto 0 loop
            -- report "driver: sclk negedge(" & integer'image(i) & ")";
            spi_sclk <= '0';            -- serial clock negative edge
            spi_mosi <= mosi_word(i);   -- shift out mosi data
            wait for SPI_SCLK_PER_ns/2;
            
            -- report "driver: sclk posedge(" & integer'image(i) & ")";
            spi_sclk <= '1';            -- serial clock positive edge
            wait for SPI_SCLK_PER_ns/2;
        end loop;

        spi_sclk <= '0';
        spi_mosi <= 'Z';
        wait for SPI_SCLK_PER_ns/2;
        spi_cs_n <= '1';
        wait for SPI_SCLK_PER_ns/2;
        report "driver: end of transaction";
        xfr_done <= true;

    end process driver;

    -- response checker
    checker: process
        variable miso_sreg, mosi_sreg, miso_expected: std_logic_vector(WORD_WIDTH-1 downto 0); 
    begin
        -- initialize
        miso_sreg := (others => '-');

        -- wait for transaction data
        wait on xfr_data'transaction;
        miso_expected := xfr_data.miso_word;

        -- wait for spi transaction
        wait until spi_cs_n = '0';

        -- sample mosi and miso on rising edge
        for i in (WORD_WIDTH-1) downto 0 loop
            wait until spi_sclk = '1';
            -- report "checker: sampling miso bit " & integer'image(i);
            mosi_sreg(i) := spi_mosi;
            miso_sreg(i) := spi_miso;
        end loop;

        wait until regmap_rx_valid = '1';

        -- check mosi
        if mosi_sreg = regmap_rx_word then
            report "checker: mosi pass";
        else
            report "checker: error in mosi test" & LF &
                "mosi rx:"  & integer'image(to_integer(unsigned(regmap_rx_word))) &
                ", expected: " & integer'image(to_integer(unsigned(mosi_sreg)))
            severity failure;
        end if;

        -- check miso
        if miso_sreg = miso_expected then
            report "checker: miso pass";
        else
            report "checker: error in miso test" & LF &
                "miso tx: "  & integer'image(to_integer(unsigned(miso_sreg))) &
                ", expected: " & integer'image(to_integer(unsigned(miso_expected)))
            severity failure;
        end if;
       
    end process checker;

    -- dut
    dut: spi_slave
        generic map(WORD_WIDTH)
        port map(
            i_clk_100M  =>  clk,
            i_rst_n     =>  rst_n,
            i_cs_n      =>  spi_cs_n,
            i_sclk      =>  spi_sclk,
            i_mosi      =>  spi_mosi,
            o_miso      =>  spi_miso,
            i_tx_load   =>  regmap_tx_load,
            i_tx_word   =>  regmap_tx_word,
            o_rx_valid  =>  regmap_rx_valid,
            o_rx_word   =>  regmap_rx_word,
            o_busy      =>  regmap_busy);
    
end architecture tb;