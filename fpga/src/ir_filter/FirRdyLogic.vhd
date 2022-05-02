-- -------------------------------------------------------------
-- 
-- File Name: hdl_prj\hdlsrc\fpga_fir_test\FirRdyLogic.vhd
-- Created: 2022-04-25 23:07:42
-- 
-- Generated by MATLAB 9.12 and HDL Coder 3.20
-- 
-- -------------------------------------------------------------


-- -------------------------------------------------------------
-- 
-- Module: FirRdyLogic
-- Source Path: fpga_fir_test/ir_filter/fir_filter_hdl/FirRdyLogic
-- Hierarchy Level: 2
-- 
-- -------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY FirRdyLogic IS
  PORT( i_clk_dsp_122M88                  :   IN    std_logic;
        en                                :   IN    std_logic;
        dataIn                            :   IN    signed(23 DOWNTO 0);  -- sfix24_En15
        validIn                           :   IN    std_logic;
        readySM                           :   OUT   std_logic;
        dinSM                             :   OUT   signed(23 DOWNTO 0);  -- sfix24_En15
        dinVldSM                          :   OUT   std_logic
        );
END FirRdyLogic;


ARCHITECTURE rtl OF FirRdyLogic IS

  -- Functions
  -- HDLCODER_TO_STDLOGIC 
  FUNCTION hdlcoder_to_stdlogic(arg: boolean) RETURN std_logic IS
  BEGIN
    IF arg THEN
      RETURN '1';
    ELSE
      RETURN '0';
    END IF;
  END FUNCTION;


  -- Signals
  SIGNAL firRdy_xdin                      : signed(23 DOWNTO 0) := (OTHERS => '0');  -- sfix24
  SIGNAL firRdy_xdinVld                   : std_logic := '0';
  SIGNAL firRdy_state                     : unsigned(2 DOWNTO 0) := (OTHERS => '0');  -- ufix3
  SIGNAL firRdy_readyReg                  : std_logic := '1';
  SIGNAL firRdy_count                     : unsigned(11 DOWNTO 0) := (OTHERS => '0');  -- ufix12
  SIGNAL firRdy_xdin_next                 : signed(23 DOWNTO 0);  -- sfix24_En15
  SIGNAL firRdy_xdinVld_next              : std_logic;
  SIGNAL firRdy_state_next                : unsigned(2 DOWNTO 0);  -- ufix3
  SIGNAL firRdy_readyReg_next             : std_logic;
  SIGNAL firRdy_count_next                : unsigned(11 DOWNTO 0);  -- ufix12

BEGIN
  -- rdyLogic
  firRdy_process : PROCESS (i_clk_dsp_122M88)
  BEGIN
    IF i_clk_dsp_122M88'EVENT AND i_clk_dsp_122M88 = '1' THEN
      IF en = '1' THEN
        firRdy_xdin <= firRdy_xdin_next;
        firRdy_xdinVld <= firRdy_xdinVld_next;
        firRdy_state <= firRdy_state_next;
        firRdy_readyReg <= firRdy_readyReg_next;
        firRdy_count <= firRdy_count_next;
      END IF;
    END IF;
  END PROCESS firRdy_process;

  firRdy_output : PROCESS (dataIn, firRdy_count, firRdy_readyReg, firRdy_state, firRdy_xdin,
       firRdy_xdinVld, validIn)
    VARIABLE out2 : std_logic;
  BEGIN
    firRdy_xdin_next <= firRdy_xdin;
    firRdy_xdinVld_next <= firRdy_xdinVld;
    firRdy_state_next <= firRdy_state;
    firRdy_readyReg_next <= firRdy_readyReg;
    firRdy_count_next <= firRdy_count;
    CASE firRdy_state IS
      WHEN "000" =>
        dinSM <= dataIn;
        out2 := validIn;
        firRdy_state_next <= (OTHERS => '0');
        firRdy_readyReg_next <= '1';
        firRdy_xdin_next <= (OTHERS => '0');
        firRdy_xdinVld_next <= '0';
        IF validIn = '1' THEN 
          firRdy_state_next <= (0 => '1', OTHERS => '0');
          firRdy_readyReg_next <= '0';
        END IF;
      WHEN "001" =>
        dinSM <= (OTHERS => '0');
        out2 := '0';
        firRdy_state_next <= (2 => '0', OTHERS => '1');
        IF validIn = '1' THEN 
          firRdy_state_next <= (1 => '1', OTHERS => '0');
          firRdy_xdin_next <= dataIn;
          firRdy_xdinVld_next <= '1';
        END IF;
      WHEN "010" =>
        dinSM <= (OTHERS => '0');
        out2 := '0';
        firRdy_state_next <= (1 => '1', OTHERS => '0');
        IF firRdy_count = to_unsigned(16#9FF#, 12) THEN 
          firRdy_state_next <= (2 => '1', OTHERS => '0');
        END IF;
        firRdy_readyReg_next <= '0';
      WHEN "011" =>
        IF firRdy_count = to_unsigned(16#9FF#, 12) THEN 
          firRdy_readyReg_next <= '1';
          firRdy_state_next <= (OTHERS => '0');
        END IF;
        dinSM <= (OTHERS => '0');
        out2 := '0';
      WHEN "100" =>
        firRdy_state_next <= (2 => '0', OTHERS => '1');
        dinSM <= firRdy_xdin;
        out2 := firRdy_xdinVld;
        firRdy_xdin_next <= dataIn;
        firRdy_xdinVld_next <= validIn;
      WHEN OTHERS => 
        dinSM <= (OTHERS => '0');
        out2 := '0';
        firRdy_state_next <= (OTHERS => '0');
        firRdy_xdin_next <= (OTHERS => '0');
        firRdy_xdinVld_next <= '0';
        firRdy_readyReg_next <= '1';
    END CASE;
    IF ((validIn OR hdlcoder_to_stdlogic(firRdy_count > to_unsigned(16#000#, 12))) OR out2) = '1' THEN 
      IF firRdy_count = to_unsigned(16#9FF#, 12) THEN 
        firRdy_count_next <= (OTHERS => '0');
      ELSE 
        firRdy_count_next <= firRdy_count + to_unsigned(16#001#, 12);
      END IF;
    END IF;
    readySM <= firRdy_readyReg;
    dinVldSM <= out2;
  END PROCESS firRdy_output;


END rtl;

