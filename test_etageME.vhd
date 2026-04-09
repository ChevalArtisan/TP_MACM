library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.NUMERIC_STD.all;

entity test_etagesME is
end test_etagesME;

architecture behavior of test_etagesME is

    constant TIMEOUT  : time := 150 ns;
    constant clkpulse : time := 5 ns;

    -- Signaux d'entrée
    signal E_Res_ME    : std_logic_vector(31 downto 0) := (others => '0');
    signal E_WD_ME     : std_logic_vector(31 downto 0) := (others => '0');
    signal E_Op3_ME    : std_logic_vector(3 downto 0)  := (others => '0');
    signal E_clk       : std_logic := '0';
    signal E_MemWR_Mem : std_logic := '0';

    -- Signaux de sortie
    signal E_Res_Mem_ME : std_logic_vector(31 downto 0);
    signal E_Res_ALU_ME : std_logic_vector(31 downto 0);
    signal E_Res_fwd_ME : std_logic_vector(31 downto 0);
    signal E_Op3_ME_out : std_logic_vector(3 downto 0);

begin

    --------------------------
    -- Génération de l'horloge
    P_E_CLK: process
    begin
        E_clk <= '1';
        wait for clkpulse;
        E_clk <= '0';
        wait for clkpulse;
    end process P_E_CLK;

    -----------------------------------------
    -- Timeout de sécurité
    P_TIMEOUT: process
    begin
        wait for TIMEOUT;
        assert FALSE report "SIMULATION TIMEOUT!!!" severity FAILURE;
    end process P_TIMEOUT;

    --------------------------------------------------
    -- Instanciation de l'étage Memory
    dut : entity work.etageME(etageME_arch)
        port map (
            Res_ME     => E_Res_ME,
            WD_ME      => E_WD_ME,
            Op3_ME     => E_Op3_ME,
            clk        => E_clk,
            MemWR_Mem  => E_MemWR_Mem,
            Res_Mem_ME => E_Res_Mem_ME,
            Res_ALU_ME => E_Res_ALU_ME,
            Res_fwd_ME => E_Res_fwd_ME,
            Op3_ME_out => E_Op3_ME_out
        );

    -----------------------------
    -- Séquence de test
    P_TEST: process
    begin
        -- Initialisation
        E_Res_ME    <= x"00000004"; -- Adresse mémoire 4
        E_WD_ME     <= x"DEADBEEF"; -- Donnée à écrire
        E_Op3_ME    <= x"5";        -- Registre destination R5
        E_MemWR_Mem <= '0';
        wait for 15 ns;

        -- TEST 1 : Écriture en mémoire (Store)
        -- On active l'écriture sur un front montant
        wait until falling_edge(E_clk);
        E_MemWR_Mem <= '1';
        
        wait until falling_edge(E_clk);
        E_MemWR_Mem <= '0';
        E_WD_ME     <= x"00000000"; -- On efface le bus de donnée d'entrée

        -- TEST 2 : Lecture en mémoire (Load)
        -- On lit à la même adresse (0x4)
        -- Le résultat devrait apparaître sur Res_Mem_ME
        wait for 10 ns;
        
        -- TEST 3 : Vérification de la propagation (Passthrough)
        -- Res_ALU_ME et Res_fwd_ME doivent suivre Res_ME
        -- Op3_ME_out doit suivre Op3_ME
        E_Res_ME <= x"0000000A";
        E_Op3_ME <= x"F";
        wait for 10 ns;

        assert FALSE report "Fin de simulation ME - Verifiez les lectures memoire" severity FAILURE;
        wait;
    end process P_TEST;

end architecture;