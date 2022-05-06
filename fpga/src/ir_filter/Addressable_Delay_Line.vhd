-- -------------------------------------------------------------
-- 
-- File Name: hdl_prj\hdlsrc\fpga_fir_test\Addressable_Delay_Line.vhd
-- Created: 2022-05-05 15:23:58
-- 
-- Generated by MATLAB 9.12 and HDL Coder 3.20
-- 
-- -------------------------------------------------------------


-- -------------------------------------------------------------
-- 
-- Module: Addressable_Delay_Line
-- Source Path: fpga_fir_test/ir_filter/fir_filter_hdl/Addressable Delay Line
-- Hierarchy Level: 2
-- 
-- Addressable Delay Line
-- 
-- -------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY Addressable_Delay_Line IS
  PORT( i_clk_dsp_122M88                  :   IN    std_logic;
        reset                             :   IN    std_logic;
        en                                :   IN    std_logic;
        en_1_1_1                          :   IN    std_logic;
        dataIn                            :   IN    signed(15 DOWNTO 0);  -- sfix16_En15
        wrEn                              :   IN    std_logic;
        wrAddr                            :   IN    unsigned(11 DOWNTO 0);  -- ufix12
        rdAddr                            :   IN    unsigned(11 DOWNTO 0);  -- ufix12
        delayLineEnd                      :   OUT   signed(15 DOWNTO 0);  -- sfix16_En15
        dataOut                           :   OUT   signed(15 DOWNTO 0)  -- sfix16_En15
        );
END Addressable_Delay_Line;


ARCHITECTURE rtl OF Addressable_Delay_Line IS

  -- Component Declarations
  COMPONENT Delay_Line_Memory_Wrapper_generic
    GENERIC( AddrWidth                    : integer;
             DataWidth                    : integer
             );
    PORT( i_clk_dsp_122M88                :   IN    std_logic;
          reset                           :   IN    std_logic;
          en                              :   IN    std_logic;
          en_1_1_1                        :   IN    std_logic;
          wr_din                          :   IN    signed(DataWidth - 1 DOWNTO 0);  -- generic width
          wr_addr                         :   IN    unsigned(AddrWidth - 1 DOWNTO 0);  -- generic width
          wr_en                           :   IN    std_logic;
          rd_addr                         :   IN    unsigned(AddrWidth - 1 DOWNTO 0);  -- generic width
          rd_dout                         :   OUT   signed(DataWidth - 1 DOWNTO 0)  -- generic width
          );
  END COMPONENT;

  -- Component Configuration Statements
  FOR ALL : Delay_Line_Memory_Wrapper_generic
    USE ENTITY work.Delay_Line_Memory_Wrapper_generic(rtl);

  -- Signals
  SIGNAL relop_relop1                     : std_logic;
  SIGNAL dataEndEn                        : std_logic := '0';
  SIGNAL wrEnN                            : std_logic;
  SIGNAL dataEndEnS                       : std_logic;
  SIGNAL delayedSignals                   : signed(15 DOWNTO 0);  -- sfix16_En15

BEGIN
  u_Delay_Line_Memory_Wrapper_generic : Delay_Line_Memory_Wrapper_generic
    GENERIC MAP( AddrWidth => 12,
                 DataWidth => 16
                 )
    PORT MAP( i_clk_dsp_122M88 => i_clk_dsp_122M88,
              reset => reset,
              en => en,
              en_1_1_1 => en_1_1_1,
              wr_din => dataIn,
              wr_addr => wrAddr,
              wr_en => wrEn,
              rd_addr => rdAddr,
              rd_dout => delayedSignals
              );

  
  relop_relop1 <= '1' WHEN wrAddr = rdAddr ELSE
      '0';

  dataOutReg_process : PROCESS (i_clk_dsp_122M88)
  BEGIN
    IF i_clk_dsp_122M88'EVENT AND i_clk_dsp_122M88 = '1' THEN
      IF en = '1' THEN
        dataEndEn <= relop_relop1;
      END IF;
    END IF;
  END PROCESS dataOutReg_process;


  wrEnN <=  NOT dataEndEn;

  dataEndEnS <= relop_relop1 AND wrEnN;

  dataOutReg_1_process : PROCESS (i_clk_dsp_122M88)
  BEGIN
    IF i_clk_dsp_122M88'EVENT AND i_clk_dsp_122M88 = '1' THEN
      IF en = '1' AND dataEndEnS = '1' THEN
        delayLineEnd <= delayedSignals;
      END IF;
    END IF;
  END PROCESS dataOutReg_1_process;


  dataOut <= delayedSignals;

END rtl;

