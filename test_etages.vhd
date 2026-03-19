-- Definition des librairies
library IEEE;

-- Definition des portee d'utilisation
use IEEE.std_logic_1164.all;
use IEEE.NUMERIC_STD.all;

-- Definition de l'entite
entity test_etages is
end test_etages;

-- Definition de l'architecture
architecture behavior of test_etages is

-- definition des constantes de test
	constant TIMEOUT 	: time := 150 ns; -- timeout de la simulation

-- definition de constantes
constant clkpulse : Time := 5 ns; -- 1/2 periode horloge

-- definition de types

-- definition de ressources internes

-- definition de ressources externes
signal E_npc, E_npc_fw_br: std_logic_vector(31 downto 0);
signal E_PCSrc_ER,E_Bpris_EX, E_GEL_LI,E_CLK : std_logic;
signal E_pc_plus_4,E_i_FE: std_logic_vector(31 downto 0);

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
etageFE0 : entity work.etageFE(etageFE_arch)
					port map (
                        npc => E_npc,
                        npc_fw_br =>E_npc_fw_br,
                        PCSrc_ER => E_PCSrc_ER,
                        Bpris_EX => E_Bpris_EX,
                        GEL_LI => E_GEL_LI,
                        clk => E_CLK,
                        pc_plus_4 => E_pc_plus_4,
                        i_FE => E_i_FE
                        );

-----------------------------
-- debut sequence de test
P_TEST: process
begin

        E_PCSrc_ER<=0;
        E_GEL_LI<=0;
        E_Bpris_EX<=0;
        E_npc<=(others => '0');
        E_npc_fw_br<=(others => '0');


-- Exemple : test de l'incrémentation simple (PC+4)
        E_GEL_LI <= '1'; -- On ne gèle pas
        E_PCSrc_ER <= '0';
        E_Bpris_EX <= '0';
        
        wait for 20 ns;
        
        -- Exemple : Forcer un saut (npc)
        E_npc <= x"00000020";
        E_PCSrc_ER <= '1';
        wait for 10 ns;
        E_PCSrc_ER <= '0';

        wait;
end process;
end behavior;