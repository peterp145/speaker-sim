-- -------------------------------------------------------------
-- 
-- File Name: hdl_prj\hdlsrc\fpga_fir_test\FilterTapSystolic.vhd
-- Created: 2022-04-20 22:27:05
-- 
-- Generated by MATLAB 9.12 and HDL Coder 3.20
-- 
-- -------------------------------------------------------------


-- -------------------------------------------------------------
-- 
-- Module: FilterTapSystolic
-- Source Path: fpga_fir_test/ir_filter/Discrete FIR Filter HDL Optimized/FilterTapSystolic
-- Hierarchy Level: 2
-- 
-- -------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY FilterTapSystolic IS
  PORT( i_clk_dsp_122M88                  :   IN    std_logic;
        en                                :   IN    std_logic;
        din_re                            :   IN    signed(23 DOWNTO 0);  -- sfix24_En23
        coeff                             :   IN    signed(15 DOWNTO 0);  -- sfix16_En18
        sumIn                             :   IN    signed(43 DOWNTO 0);  -- sfix44_En41
        syncReset                         :   IN    std_logic;
        sumOut                            :   OUT   signed(43 DOWNTO 0)  -- sfix44_En41
        );
END FilterTapSystolic;


ARCHITECTURE rtl OF FilterTapSystolic IS

  -- Signals
  SIGNAL fTap_din_reg1                    : signed(23 DOWNTO 0) := (OTHERS => '0');  -- sfix24
  SIGNAL fTap_coef_reg1                   : signed(15 DOWNTO 0) := (OTHERS => '0');  -- sfix16
  SIGNAL fTap_din_reg2                    : signed(23 DOWNTO 0) := (OTHERS => '0');  -- sfix24
  SIGNAL fTap_coef_reg2                   : signed(15 DOWNTO 0) := (OTHERS => '0');  -- sfix16
  SIGNAL fTap_mult_reg                    : signed(39 DOWNTO 0) := (OTHERS => '0');  -- sfix40
  SIGNAL fTap_addout_reg                  : signed(43 DOWNTO 0) := (OTHERS => '0');  -- sfix44
  SIGNAL fTap_addout_reg_next             : signed(43 DOWNTO 0);  -- sfix44_En41

BEGIN
  -- FilterTapSystolicS
  fTap_process : PROCESS (i_clk_dsp_122M88)
  BEGIN
    IF i_clk_dsp_122M88'EVENT AND i_clk_dsp_122M88 = '1' THEN
      IF en = '1' THEN
        IF syncReset = '1' THEN
          fTap_din_reg1 <= (OTHERS => '0');
          fTap_coef_reg1 <= (OTHERS => '0');
          fTap_din_reg2 <= (OTHERS => '0');
          fTap_coef_reg2 <= (OTHERS => '0');
          fTap_mult_reg <= (OTHERS => '0');
          fTap_addout_reg <= (OTHERS => '0');
        ELSE 
          fTap_addout_reg <= fTap_addout_reg_next;
          fTap_mult_reg <= fTap_din_reg2 * fTap_coef_reg2;
          fTap_din_reg2 <= fTap_din_reg1;
          fTap_coef_reg2 <= fTap_coef_reg1;
          fTap_din_reg1 <= din_re;
          fTap_coef_reg1 <= coeff;
        END IF;
      END IF;
    END IF;
  END PROCESS fTap_process;

  sumOut <= fTap_addout_reg;
  fTap_addout_reg_next <= (resize(fTap_mult_reg, 44)) + sumIn;

END rtl;
