-- -------------------------------------------------------------
-- 
-- File Name: hdl_prj\hdlsrc\fpga_fir_test\ir_filter.vhd
-- Created: 2022-04-20 22:27:05
-- 
-- Generated by MATLAB 9.12 and HDL Coder 3.20
-- 
-- 
-- -------------------------------------------------------------
-- Rate and Clocking Details
-- -------------------------------------------------------------
-- Model base rate: 8.13802e-09
-- Target subsystem base rate: 8.13802e-09
-- 
-- 
-- Clock Enable  Sample Time
-- -------------------------------------------------------------
-- ce_out        8.13802e-09
-- -------------------------------------------------------------
-- 
-- 
-- Output Signal                 Clock Enable  Sample Time
-- -------------------------------------------------------------
-- o_data_out                    ce_out        8.13802e-09
-- o_data_out_valid              ce_out        8.13802e-09
-- o_data_in_ready               ce_out        8.13802e-09
-- -------------------------------------------------------------
-- 
-- -------------------------------------------------------------


-- -------------------------------------------------------------
-- 
-- Module: ir_filter
-- Source Path: fpga_fir_test/ir_filter
-- Hierarchy Level: 0
-- 
-- -------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY ir_filter IS
  PORT( i_clk_dsp_122M88                  :   IN    std_logic;
        reset                             :   IN    std_logic;
        clk_enable                        :   IN    std_logic;
        i_rst_n                           :   IN    std_logic;
        i_data_in                         :   IN    signed(23 DOWNTO 0);  -- sfix24_En23
        i_data_in_valid                   :   IN    std_logic;
        ce_out                            :   OUT   std_logic;
        o_data_out                        :   OUT   signed(23 DOWNTO 0);  -- sfix24_En23
        o_data_out_valid                  :   OUT   std_logic;
        o_data_in_ready                   :   OUT   std_logic
        );
END ir_filter;


ARCHITECTURE rtl OF ir_filter IS

  -- Component Declarations
  COMPONENT Discrete_FIR_Filter_HDL_Optimized
    PORT( i_clk_dsp_122M88                :   IN    std_logic;
          reset                           :   IN    std_logic;
          en                              :   IN    std_logic;
          en_1_1_1                        :   IN    std_logic;
          dataIn                          :   IN    signed(23 DOWNTO 0);  -- sfix24_En23
          validIn                         :   IN    std_logic;
          syncReset                       :   IN    std_logic;
          dataOut                         :   OUT   signed(23 DOWNTO 0);  -- sfix24_En23
          validOut                        :   OUT   std_logic;
          ready                           :   OUT   std_logic
          );
  END COMPONENT;

  COMPONENT s_and_h
    PORT( i_clk_dsp_122M88                :   IN    std_logic;
          reset                           :   IN    std_logic;
          en                              :   IN    std_logic;
          In_rsvd                         :   IN    signed(23 DOWNTO 0);  -- sfix24_En23
          Trigger                         :   IN    std_logic;
          alpha                           :   OUT   signed(23 DOWNTO 0)  -- sfix24_En23
          );
  END COMPONENT;

  -- Component Configuration Statements
  FOR ALL : Discrete_FIR_Filter_HDL_Optimized
    USE ENTITY work.Discrete_FIR_Filter_HDL_Optimized(rtl);

  FOR ALL : s_and_h
    USE ENTITY work.s_and_h(rtl);

  -- Signals
  SIGNAL en                               : std_logic;
  SIGNAL Delay2_out1                      : signed(23 DOWNTO 0) := (OTHERS => '0');  -- sfix24_En23
  SIGNAL Delay2_out1_1                    : signed(23 DOWNTO 0) := (OTHERS => '0');  -- sfix24_En23
  SIGNAL Delay1_out1                      : std_logic := '0';
  SIGNAL Delay1_out1_1                    : std_logic := '0';
  SIGNAL Delay_out1                       : std_logic := '0';
  SIGNAL Logical_Operator_out1            : std_logic;
  SIGNAL Logical_Operator_out1_1          : std_logic := '0';
  SIGNAL Discrete_FIR_Filter_HDL_Optimized_out1 : signed(23 DOWNTO 0);  -- sfix24_En23
  SIGNAL Discrete_FIR_Filter_HDL_Optimized_out2 : std_logic;
  SIGNAL Discrete_FIR_Filter_HDL_Optimized_out3 : std_logic;
  SIGNAL Discrete_FIR_Filter_HDL_Optimized_out1_1 : signed(23 DOWNTO 0) := (OTHERS => '0');  -- sfix24_En23
  SIGNAL Discrete_FIR_Filter_HDL_Optimized_out2_1 : std_logic := '0';
  SIGNAL s_and_h_out1                     : signed(23 DOWNTO 0);  -- sfix24_En23
  SIGNAL Discrete_FIR_Filter_HDL_Optimized_out3_1 : std_logic := '0';

BEGIN
  u_Discrete_FIR_Filter_HDL_Optimized : Discrete_FIR_Filter_HDL_Optimized
    PORT MAP( i_clk_dsp_122M88 => i_clk_dsp_122M88,
              reset => reset,
              en => clk_enable,
              en_1_1_1 => clk_enable,
              dataIn => Delay2_out1_1,  -- sfix24_En23
              validIn => Delay1_out1_1,
              syncReset => Logical_Operator_out1_1,
              dataOut => Discrete_FIR_Filter_HDL_Optimized_out1,  -- sfix24_En23
              validOut => Discrete_FIR_Filter_HDL_Optimized_out2,
              ready => Discrete_FIR_Filter_HDL_Optimized_out3
              );

  u_s_and_h : s_and_h
    PORT MAP( i_clk_dsp_122M88 => i_clk_dsp_122M88,
              reset => reset,
              en => clk_enable,
              In_rsvd => Discrete_FIR_Filter_HDL_Optimized_out1_1,  -- sfix24_En23
              Trigger => Discrete_FIR_Filter_HDL_Optimized_out2_1,
              alpha => s_and_h_out1  -- sfix24_En23
              );

  en <= clk_enable;

  Delay2_process : PROCESS (i_clk_dsp_122M88)
  BEGIN
    IF i_clk_dsp_122M88'EVENT AND i_clk_dsp_122M88 = '1' THEN
      IF en = '1' THEN
        Delay2_out1 <= i_data_in;
      END IF;
    END IF;
  END PROCESS Delay2_process;


  Discrete_FIR_Filter_HDL_Optimized_in0_buff_in_pipe_process : PROCESS (i_clk_dsp_122M88)
  BEGIN
    IF i_clk_dsp_122M88'EVENT AND i_clk_dsp_122M88 = '1' THEN
      IF en = '1' THEN
        Delay2_out1_1 <= Delay2_out1;
      END IF;
    END IF;
  END PROCESS Discrete_FIR_Filter_HDL_Optimized_in0_buff_in_pipe_process;


  Delay1_process : PROCESS (i_clk_dsp_122M88)
  BEGIN
    IF i_clk_dsp_122M88'EVENT AND i_clk_dsp_122M88 = '1' THEN
      IF en = '1' THEN
        Delay1_out1 <= i_data_in_valid;
      END IF;
    END IF;
  END PROCESS Delay1_process;


  Discrete_FIR_Filter_HDL_Optimized_in1_buff_in_pipe_process : PROCESS (i_clk_dsp_122M88)
  BEGIN
    IF i_clk_dsp_122M88'EVENT AND i_clk_dsp_122M88 = '1' THEN
      IF en = '1' THEN
        Delay1_out1_1 <= Delay1_out1;
      END IF;
    END IF;
  END PROCESS Discrete_FIR_Filter_HDL_Optimized_in1_buff_in_pipe_process;


  Delay_process : PROCESS (i_clk_dsp_122M88)
  BEGIN
    IF i_clk_dsp_122M88'EVENT AND i_clk_dsp_122M88 = '1' THEN
      IF en = '1' THEN
        Delay_out1 <= i_rst_n;
      END IF;
    END IF;
  END PROCESS Delay_process;


  Logical_Operator_out1 <=  NOT Delay_out1;

  Discrete_FIR_Filter_HDL_Optimized_in2_buff_in_pipe_process : PROCESS (i_clk_dsp_122M88)
  BEGIN
    IF i_clk_dsp_122M88'EVENT AND i_clk_dsp_122M88 = '1' THEN
      IF en = '1' THEN
        Logical_Operator_out1_1 <= Logical_Operator_out1;
      END IF;
    END IF;
  END PROCESS Discrete_FIR_Filter_HDL_Optimized_in2_buff_in_pipe_process;


  Discrete_FIR_Filter_HDL_Optimized_out3_buff_out_pipe_process : PROCESS (i_clk_dsp_122M88)
  BEGIN
    IF i_clk_dsp_122M88'EVENT AND i_clk_dsp_122M88 = '1' THEN
      IF en = '1' THEN
        Discrete_FIR_Filter_HDL_Optimized_out1_1 <= Discrete_FIR_Filter_HDL_Optimized_out1;
      END IF;
    END IF;
  END PROCESS Discrete_FIR_Filter_HDL_Optimized_out3_buff_out_pipe_process;


  Discrete_FIR_Filter_HDL_Optimized_out4_buff_out_pipe_process : PROCESS (i_clk_dsp_122M88)
  BEGIN
    IF i_clk_dsp_122M88'EVENT AND i_clk_dsp_122M88 = '1' THEN
      IF en = '1' THEN
        Discrete_FIR_Filter_HDL_Optimized_out2_1 <= Discrete_FIR_Filter_HDL_Optimized_out2;
      END IF;
    END IF;
  END PROCESS Discrete_FIR_Filter_HDL_Optimized_out4_buff_out_pipe_process;


  Discrete_FIR_Filter_HDL_Optimized_out5_buff_out_pipe_process : PROCESS (i_clk_dsp_122M88)
  BEGIN
    IF i_clk_dsp_122M88'EVENT AND i_clk_dsp_122M88 = '1' THEN
      IF en = '1' THEN
        Discrete_FIR_Filter_HDL_Optimized_out3_1 <= Discrete_FIR_Filter_HDL_Optimized_out3;
      END IF;
    END IF;
  END PROCESS Discrete_FIR_Filter_HDL_Optimized_out5_buff_out_pipe_process;


  ce_out <= clk_enable;

  o_data_out <= s_and_h_out1;

  o_data_out_valid <= Discrete_FIR_Filter_HDL_Optimized_out2_1;

  o_data_in_ready <= Discrete_FIR_Filter_HDL_Optimized_out3_1;

END rtl;
