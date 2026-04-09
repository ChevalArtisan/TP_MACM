library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.NUMERIC_STD.all;

entity test_etagesER is
end test_etagesER;

architecture behavior of test_etagesER is

    constant TIMEOUT : time := 100 ns;

    -- Signaux d'entrée
    signal E_Res_Mem_RE : std_logic_vector(31 downto 0) := (others => '0');
    signal E_Res_ALU_RE : std_logic_vector(31 downto 0) := (others => '0');
    signal E_Op3_RE     : std_logic_vector(3 downto 0)  := (others => '0');
    signal E_MemToReg_RE: std_logic := '0';

    -- Signaux de sortie
    signal E_Res_RE     : std_logic_vector(31 downto 0);
    signal E_Op3_RE_out : std_logic_vector(3 downto 0);

begin

    --------------------------------------------------
    -- Instanciation de l'étage ER
    dut : entity work.etageER(etageER_arch)
        port map (
            Res_Mem_RE  => E_Res_Mem_RE,
            Res_ALU_RE  => E_Res_ALU_RE,
            Op3_RE      => E_Op3_RE,
            MemToReg_RE => E_MemToReg_RE,
            Res_RE      => E_Res_RE,
            Op3_RE_out  => E_Op3_RE_out
        );

    -----------------------------------------
    -- Timeout de sécurité
    P_TIMEOUT: process
    begin
        wait for TIMEOUT;
        assert FALSE report "SIMULATION TIMEOUT!!!" severity FAILURE;
    end process P_TIMEOUT;

    -----------------------------
    -- Séquence de test
    P_TEST: process
    begin
        -- Valeurs de test
        E_Res_ALU_RE <= x"AAAA5555"; -- Résultat d'un calcul
        E_Res_Mem_RE <= x"12345678"; -- Résultat d'un Load mémoire
        E_Op3_RE     <= x"7";        -- Destination : Registre R7
        
        -- TEST 1 : Sélection du résultat ALU (MemToReg = 0)
        E_MemToReg_RE <= '0';
        wait for 10 ns;
        -- E_Res_RE doit valoir AAAA5555
        
        -- TEST 2 : Sélection du résultat Mémoire (MemToReg = 1)
        E_MemToReg_RE <= '1';
        wait for 10 ns;
        -- E_Res_RE doit valoir 12345678

        -- TEST 3 : Changement de registre de destination
        E_Op3_RE <= x"E";
        wait for 10 ns;
        -- E_Op3_RE_out doit valoir E

        assert FALSE report "Fin de simulation ER - OK" severity FAILURE;
        wait;
    end process P_TEST;

end architecture;