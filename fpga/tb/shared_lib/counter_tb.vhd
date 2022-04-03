library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library shared_lib;
use shared_lib.utils_pkg.all;
use shared_lib.tb_utils_pkg.all;
use shared_lib.counter_pkg.all;

entity counter_tb is
end entity counter_tb;

architecture tb of counter_tb is
    -- test settings
    constant COMB_DLY_ns : time := 1 ns;
    constant COUNT_MAX : integer := 15;

    -- clock and reset
    signal clk_100M          :   std_logic   := '1';
    constant clk_100M_PER_ns :   time        := 10 ns;
    signal rst_n        :   std_logic   := '0';

    -- dut signals
    constant COUNTER_NUM_BITS : integer := num_bits(COUNT_MAX);
    signal counter_i_rec : t_counter_i_rec;
    signal counter_o_rec : t_counter_o_rec(count(COUNTER_NUM_BITS-1 downto 0));

    -- helper procedures
    procedure wait_clk_100M(constant num_clks : positive := 0) is
    begin
        wait_clk(clk_100M, COMB_DLY_ns, num_clks);
    end procedure wait_clk_100M;

begin
    ----- clock generation -----
    clk_100M <= not clk_100M after clk_100M_PER_ns/2;

    ----- stiumulus -----
    proc_stimulus : process is
    begin
        -- initialization
        counter_i_rec.en <= '0';
        print("start of simulation");
        
        wait_clk_100M(5);
        print("releasing reset");
        rst_n <= '1';
        wait_clk_100M(5);

        counter_i_rec.en <= '1';

        wait_clk_100M(50);
        report("end of simulation");
        wait;
    end process;

    ----- dut -----
    -- dut signal assignment
    counter_i_rec.clk <= clk_100M;
    counter_i_rec.rst_n <= rst_n;

    -- dut instantiation
    dut : counter
    generic map (COUNT_MAX)
    port map (counter_i_rec, counter_o_rec);
    
end architecture tb;