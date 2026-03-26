-- Definition des librairies
library IEEE;

-- Definition des portee d'utilisation
use IEEE.std_logic_1164.all;
use IEEE.NUMERIC_STD.all;

-- Definition de l'entite
entity test_etagesDE is
end test_etagesDE;

-- Definition de l'architecture
architecture behavior of test_etages is

-- definition des constantes de test
	constant TIMEOUT 	: time := 150 ns; -- timeout de la simulation

-- definition de constantes
constant clkpulse : Time := 5 ns; -- 1/2 periode horloge

-- definition de types

-- definition de ressources internes

-- definition de ressources externes
signal E_i_De, E_WD_ER, E_pc_plus_4: std_logic_vector(31 downto 0);
signal E_Op3_ER: std_logic_vector(3 downto 0);
signal E_RegSrc,E_immSrc: std_logic_vector(3 downto 0);
signal E_RegWr, E_clk, E_init: std_logic;
signal E_Reg1, E_Reg2, E_Op3_DE: std_logic_vector(3 downto 0);
signal E_Op1, E_Op2 E_extlmm : std_logic_vector(31 downto 0);

begin

--------------------------
-- definition de l'horloge
P_E_CLK: process
begin
	E_CLK <= '1';
	wait for clkpulse;
	E_CLK <= '0';
	wait for clkpulse;
end process P_E_CLK;

-----------------------------------------
-- definition du timeout de la simulation
P_TIMEOUT: process
begin
	wait for TIMEOUT;
	assert FALSE report "SIMULATION TIMEOUT!!!" severity FAILURE;
end process P_TIMEOUT;

--------------------------------------------------
-- instantiation et mapping du composant registres
etageDE0 : entity work.etageDE(etageDE_arch)
					port map (
                        i_DE=> E_i_De;
                        WD_ER=> E_WD_ER;
                        pc_plus_4=> E_pc_plus_4;
                        Op3_ER=> E_Op3_ER;
                        RegSrc=>E_RegSrc;
                        immSrc=>E_immSrc;
                        RegWr=> E_RegWr;
                        clk=> E_clk;
                        init=>E_init;
                        Reg1=>E_Reg1;
                        Reg2=>E_Reg2;
                        Op1=>E_Op1;
                        Op2=>E_Op2;
                        extlmm=>E_extlmm;
                        Op3_DE=>E_Op3_DE
                        );

-----------------------------
-- debut sequence de test
P_TEST: process
begin
    
    end process P_TEST;
end behavior;