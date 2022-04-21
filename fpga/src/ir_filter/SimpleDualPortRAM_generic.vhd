-- -------------------------------------------------------------
-- 
-- File Name: hdl_prj\hdlsrc\fpga_fir_test\SimpleDualPortRAM_generic.vhd
-- Created: 2022-04-20 22:27:05
-- 
-- Generated by MATLAB 9.12 and HDL Coder 3.20
-- 
-- -------------------------------------------------------------


-- -------------------------------------------------------------
-- 
-- Module: SimpleDualPortRAM_generic
-- Source Path: fpga_fir_test/ir_filter/Discrete FIR Filter HDL Optimized/Addressable Delay Line/Delay Line Memory_Wrapper_generic/SimpleDualPortRAM_generic
-- Hierarchy Level: 4
-- 
-- -------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY SimpleDualPortRAM_generic IS
  GENERIC( AddrWidth                      : integer := 1;
           DataWidth                      : integer := 1
           );
  PORT( i_clk_dsp_122M88                  :   IN    std_logic;
        wr_din                            :   IN    signed(DataWidth - 1 DOWNTO 0);  -- generic width
        wr_addr                           :   IN    unsigned(AddrWidth - 1 DOWNTO 0);  -- generic width
        wr_en                             :   IN    std_logic;  -- ufix1
        rd_addr                           :   IN    unsigned(AddrWidth - 1 DOWNTO 0);  -- generic width
        rd_dout                           :   OUT   signed(DataWidth - 1 DOWNTO 0)  -- generic width
        );
END SimpleDualPortRAM_generic;


ARCHITECTURE rtl OF SimpleDualPortRAM_generic IS

  -- Local Type Definitions
  TYPE ram_type IS ARRAY (2**AddrWidth - 1 DOWNTO 0) of std_logic_vector(DataWidth - 1 DOWNTO 0);

  -- Signals
  SIGNAL ram                              : ram_type := (OTHERS => (OTHERS => '0'));
  SIGNAL data_int                         : std_logic_vector(DataWidth - 1 DOWNTO 0) := (OTHERS => '0');

BEGIN
  Delay Line Memory_Wrapper_generic_process: PROCESS (i_clk_dsp_122M88)
  BEGIN
    IF i_clk_dsp_122M88'event AND i_clk_dsp_122M88 = '1' THEN
      IF wr_en = '1' THEN
        ram(to_integer(wr_addr)) <= std_logic_vector(wr_din);
      END IF;
      data_int <= ram(to_integer(rd_addr));
    END IF;
  END PROCESS Delay Line Memory_Wrapper_generic_process;

  rd_dout <= signed(data_int);

END rtl;
