-- Definition des librairies
library IEEE;

-- Definition des portee d'utilisation
use IEEE.std_logic_1164.all;
use IEEE.NUMERIC_STD.all;

-- Definition de l'entite
entity test_etagesDE is
end test_etagesDE;

-- Definition de l'architecture
architecture behavior of test_etagesDE is

-- definition des constantes de test
	constant TIMEOUT 	: time := 150 ns; -- timeout de la simulation

-- definition de constantes
constant clkpulse : Time := 5 ns; -- 1/2 periode horloge

-- definition de types

-- definition de ressources internes

-- definition de ressources externes
signal E_i_De, E_WD_ER, E_pc_plus_4: std_logic_vector(31 downto 0):=(others=>'0');
signal E_Op3_ER: std_logic_vector(3 downto 0):=(others=>'0');
signal E_RegSrc,E_immSrc: std_logic_vector(1 downto 0):="00";
signal E_RegWr, E_clk, E_init: std_logic:='0';
signal E_Reg1, E_Reg2, E_Op3_DE: std_logic_vector(3 downto 0);
signal E_Op1, E_Op2, E_extlmm : std_logic_vector(31 downto 0);

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
                        i_DE => E_i_De,
                        WD_ER => E_WD_ER,
                        pc_plus_4 => E_pc_plus_4,
                        Op3_ER => E_Op3_ER,
                        RegSrc =>E_RegSrc,
                        immSrc =>E_immSrc,
                        RegWr => E_RegWr,
                        clk => E_clk,
                        init => E_init,
                        Reg1 => E_Reg1,
                        Reg2 => E_Reg2,
                        Op1 => E_Op1,
                        Op2 => E_Op2,
                        extlmm => E_extlmm,
                        Op3_DE => E_Op3_DE
                        );

-----------------------------
-- debut sequence de test
P_TEST: process
begin
    -- 1. Initialisation du banc de registres
        E_init <= '1';
        wait for 10 ns;
        E_init <= '0';
        
        -- 2. Test écriture dans un registre (R1)
        -- On simule un retour de l'étage ER : Write R1 (0x1) avec la valeur 0xAAAA5555
        wait until falling_edge(E_clk);
        E_RegWr  <= '1';
        E_Op3_ER <= x"1";
        E_WD_ER  <= x"AAAA5555";
        
        wait until falling_edge(E_clk);
        E_RegWr  <= '0';

        -- 3. Test lecture de registre (Lecture de R1 via i_DE)
        -- Instruction factice : ADD R0, R1, R2 (Rn=R1=bits 19-16, Rd=R0=bits 15-12, Rm=R2=bits 3-0)
        -- i_DE = 0x00010002
        E_i_DE   <= x"00010002"; 
        E_RegSrc <= "00"; -- Sélection standard (Rn et Rm)
        
        wait for 10 ns;
        -- Ici E_Op1 doit valoir 0xAAAA5555 (contenu de R1)
        
        -- 4. Test extension immédiat (Type DATA_IMM)
        -- Instruction avec immédiat 12 bits : 0xFFF (bits 11-0)
        E_i_DE   <= x"00000FFF";
        E_immSrc <= "00"; -- Extension 12 bits
        
        wait for 10 ns;
        -- E_extlmm doit valoir 0x00000FFF

        assert FALSE report "Fin de simulation DE" severity FAILURE;
        wait;
    end process P_TEST;
end behavior;