library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.registers_pkg.all;

entity spi_slave is
    generic (
        g_WORD_WIDTH : integer := 8
    );
    port (
        -- clock and reset
        i_clk_100M  : in    std_logic;  -- system clock
        i_rst_n     : in    std_logic;  -- system reset
        -- external spi if
        i_spi_cs_n  : in    std_logic;  -- spi chip select
        i_spi_sclk  : in    std_logic;  -- spi serial clock
        i_spi_mosi  : in    std_logic;  -- spi serial data input
        o_spi_miso  : out   std_logic;  -- spi serial data output
        -- register map if
        i_miso_word     : in  std_logic_vector(g_WORD_WIDTH-1 downto 0); -- data to load into output register
        i_miso_word_load     : in  std_logic;  -- synchronous load into output register
        o_miso_word     : out std_logic_vector(g_WORD_WIDTH-1 downto 0); -- data received
        o_mosi_ready    : out std_logic   -- complete word has been shift d in and is ready to read
    );
end entity spi_slave;

architecture rtl of spi_slave is
    -- helper packages
    package regs_8_pkg is new work.registers_pkg (g_WIDTH => g_WORD_WIDTH);
    package bit_counter_pkg is new work.counters_pkg (g_COUNT => g_WORD_WIDTH);

    signal r_sync_cs_n, r_sync_sclk, r_sync_mosi    :   std_logic_vector(2 downto 0);   -- sregs for metastability and edge detection
    signal r_spi_cs_n, r_spi_sclk, r_spi_mosi       :   std_logic;                      -- synchronized spi inputs
    signal w_spi_cs : std_logic;

    signal w_sclk_rising_edge, w_sclk_falling_edge  : std_logic; -- edge detection logic

    signal r_bit_count      : integer range 0 to g_WORD_WIDTH-1 := 0;  -- bit count
    signal r_bit_count_done : std_logic;

    signal r_miso_sreg, r_mosi_sreg : std_logic_vector(g_WORD_WIDTH-1 downto 0); -- transaction shift registers
    
    signal r_mosi_word      : std_logic_vector(g_WORD_WIDTH-1 downto 0);
    signal r_mosi_word_load : std_logic;
    signal r_mosi_ready     : std_logic;

begin
    ----------------
    -- controller --
    ----------------

    -----
    -- bit counting and end of word
    -----
    bit_counter_pkg.counter(
        clk     => i_clk_100M,    
        q       => r_bit_count,
        en      => w_sclk_rising_edge,
        r_n     => w_spi_cs,
        done    => r_bit_count_done
    );

    -- bit_count: process(i_clk_100M)
    -- begin
    --     if rising_edge(i_clk_100M) then
    --         if i_rst_n = '0' then
    --             r_bit_count <= (0 => '1', others => '0');
    --         elsif r_spi_cs_n = '1' then
    --             r_bit_count <= (0 => '1', others => '0');
    --         elsif w_sclk_falling_edge = '1' then
    --             r_bit_count <= r_bit_count(g_WORD_WIDTH-1 downto 0) & "0";
    --         end if;
    --     end if;
    -- end process bit_count;
    
    -----
    -- done
    -----
    -- done: process(i_clk_100M)
    -- begin
    --     if rising_edge(i_clk_100M) then
    --         if i_rst_n = '0' then
    --             r_bit_count_done <= '0';
    --         elsif r_spi_cs_n = '0' then 
    --             r_bit_count_done <= r_bit_count(g_WORD_WIDTH-1);
    --         end if;
    --     end if;
    -- end process done;
    
    -- mosi flags
    work.flip_flops_pkg.d_ff(i_clk_100M, r_mosi_word_load, r_spi_sclk and r_bit_count_done);
    work.flip_flops_pkg.d_ff(i_clk_100M, r_mosi_ready, r_mosi_word_load);

    --------------
    -- datapath --
    --------------

    -----
    -- input sync --
    -----
    r_sync_cs_n <= r_sync_cs_n(1 downto 0) & i_spi_cs_n when rising_edge(i_clk_100M);
    r_sync_cs_n <= r_sync_sclk(1 downto 0) & i_spi_sclk when rising_edge(i_clk_100M);
    r_sync_cs_n <= r_sync_mosi(1 downto 0) & i_spi_sclk when rising_edge(i_clk_100M);
    
    r_spi_cs_n  <= r_sync_cs_n(1);
    r_spi_sclk  <= r_sync_sclk(1);
    r_spi_mosi  <= r_sync_mosi(1);

    w_spi_cs <= not r_spi_cs_n;

    -----
    -- sclk edge detection
    ----
    w_sclk_rising_edge  <= not r_sync_sclk(2) and r_sync_sclk(1);
    w_sclk_falling_edge <= r_sync_sclk(2) and not r_sync_sclk(1);

    -----
    -- mosi shift reg
    -----
    regs_8_pkg.sreg_left(
        clk         => i_clk_100M,
        q           => r_mosi_sreg,
        load_word   => (others => '0'),
        load_en     => '0',
        shift_bit   => r_spi_mosi,
        shift_en    => w_sclk_rising_edge,
        rst_n       => w_spi_cs,
        rst_val     => (others => '0')
    );
    -- rx: process(i_clk_100M)
    -- begin
    --     if rising_edge(i_clk_100M) then
    --         if i_rst_n = '0' then
    --             r_rx_sreg <= (others => '0');
    --         elsif w_sclk_rising_edge = '1' and r_spi_cs_n = '0' then
    --             r_rx_sreg <= r_rx_sreg(g_WORD_WIDTH-2 downto 0) & i_mosi;
    --         end if;
    --     end if;
    -- end process rx;

    -----
    -- miso shift reg
    -----
    regs_8_pkg.sreg_left(
        clk         => i_clk_100M,
        q           => r_miso_sreg,
        load_word   => i_miso_word,
        load_en     => i_miso_word_load,
        shift_bit   => '0',
        shift_en    => w_sclk_falling_edge,
        rst_n       => w_spi_cs,
        rst_val     => (others => '0')
    );
    -- tx: process(i_clk_100M)
    -- begin
    --     if rising_edge(i_clk_100M) then
    --         if i_rst_n = '0' then
    --             r_tx_sreg <= (others => '0');
    --         elsif r_spi_cs_n = '1' and i_miso_load '1' then
    --             r_tx_sreg <= i_miso_word;
    --         elsif r_spi_cs_n = '0' and w_sclk_falling_edge = '1' then
    --             r_tx_sreg <= r_tx_sreg(g_WORD_WIDTH-2 downto 0) & "0";
    --         end if;
    --     end if;
    -- end process tx;

    -----
    -- mosi output reg
    -----

    regs_8_pkg.reg(
        clk     => i_clk_100M,
        q       => r_mosi_word,
        d       => r_mosi_sreg,
        load_en => r_mosi_word_load,
        rst_n   => i_rst_n,
        rst_val => (others => '0')
    );
    -- rx_output: process(i_clk_100M)
    -- begin
    --     if rising_edge(i_clk_100M) then
    --         if i_rst_n = '0' then
    --             r_rx_word <= (others => '0');
    --         elsif r_bit_count(g_WORD_WIDTH-1) = '1' then
    --             r_rx_word <= r_rx_sreg;
    --         end if;
    --     end if;
    -- end process rx_output;

    -----
    -- output
    -----
    o_spi_miso <= r_miso_sreg(g_WORD_WIDTH-1);
    o_mosi_ready <= r_mosi_ready;
    o_miso_word <= r_miso_word;
    -- o_busy <= not r_spi_cs_n;
    
end architecture rtl;