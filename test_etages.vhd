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
    -- Initialisation : On laisse le PC s'incrémenter normalement (0, 4, 8...)
    E_GEL_LI    <= '1'; -- Autorise l'écriture du PC
    E_PCSrc_ER  <= '0';
    E_Bpris_EX  <= '0';
    E_npc       <= x"000000A0"; -- Adresse cible 1
    E_npc_fw_br <= x"000000F0"; -- Adresse cible 2
    
    wait for 30 ns; -- On laisse passer 3 cycles (0 -> 4 -> 8 -> 12)

    -- Saut avec PCSrc_ER 
    wait until falling_edge(E_CLK); 
    E_PCSrc_ER <= '1'; 
    
    wait until falling_edge(E_CLK);
    -- Ici, le PC doit être passé à 0x000000A0
    E_PCSrc_ER <= '0'; -- On désactive le saut pour reprendre l'incrémentation
    
    wait for 20 ns; -- On avance un peu (A0 -> A4 -> A8)

    -- Saut avec Bpris_EX
    wait until falling_edge(E_CLK);
    E_Bpris_EX <= '1'; 
    
    wait until falling_edge(E_CLK);
    -- Ici, le PC doit être passé à 0x000000F0
    E_Bpris_EX <= '0';

    -- Gel du pipeline (Stall)
    wait until falling_edge(E_CLK);
    E_GEL_LI <= '0'; -- On bloque le PC
    
    wait for 30 ns; 
    -- Le PC ne doit pas bouger pendant cette période
    E_GEL_LI <= '1';

    wait for 20 ns;

    assert FALSE report "Fin de simulation - Vérifiez les sauts sur GTKWave" severity FAILURE;
    wait;
end process P_TEST;
end behavior;