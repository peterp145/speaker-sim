library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity counter_tb is
end entity counter_tb;

architecture tb of counter_tb is
    -- clock and reset
    signal clk          :   std_logic   := '1';
    constant CLK_PER_ns :   time        := 10 ns;
    signal rst_n        :   std_logic   := '0';

    -- dut signals
    constant COUNT_WIDTH : integer := 4;
    signal enable   :   std_logic := '1';
    signal preset   :   std_logic_vector(COUNT_WIDTH-1 downto 0) := x"A";
    signal done : std_logic;

    -- dut component
    component counter is
        generic (
            COUNT_WIDTH : integer := 32
        );
        port (
            i_clk_100M  : in  std_logic;
            i_rst_n     : in  std_logic;
            i_enable    : in  std_logic;
            i_preset    : in  std_logic_vector(COUNT_WIDTH-1 downto 0);
            o_done      : out std_logic
        );
    end component counter;

begin
    -- clock generation
    clk <= not clk after CLK_PER_ns/2;

    -- stiumulus
    process
    begin
        report("start of simulation");
        wait for 5 * CLK_PER_ns + 1 ns;
        rst_n <= '1';
        wait for 5 * CLK_PER_ns;
        report("end of simulation");
        wait;
    end process;

    -- dut
    dut: counter
        generic map (COUNT_WIDTH)
        port map (clk, rst_n, enable, preset, done);
    
end architecture tb;