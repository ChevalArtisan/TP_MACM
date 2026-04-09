library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.NUMERIC_STD.all;

entity test_etagesEX is
end test_etagesEX;

architecture behavior of test_etagesEX is

    constant TIMEOUT : time := 150 ns;
    
    -- Signaux d'entrée (Entrées de l'étage EX) 
    signal E_Op1_EX, E_Op2_EX, E_Extlmm_EX : std_logic_vector(31 downto 0) := (others => '0');
    signal E_Res_fwd_ME, E_Res_fwd_ER       : std_logic_vector(31 downto 0) := (others => '0');
    signal E_Op3_EX                         : std_logic_vector(3 downto 0)  := (others => '0');
    signal E_EA_EX, E_EB_EX, E_ALUCtrl_EX   : std_logic_vector(1 downto 0)  := "00";
    signal E_ALUSrc_EX                      : std_logic := '0';

    -- Signaux de sortie (Sorties de l'étage EX) 
    signal E_CC, E_Op3_EX_out               : std_logic_vector(3 downto 0);
    signal E_Res_EX, E_WD_EX, E_npc_fw_br   : std_logic_vector(31 downto 0);

begin

    --------------------------------------------------
    -- Instanciation de l'étage Execute
    dut : entity work.etageEX(etageEX_arch)
        port map (
            Op1_EX       => E_Op1_EX,
            Op2_EX       => E_Op2_EX,
            Extlmm_EX    => E_Extlmm_EX,
            Res_fwd_ME   => E_Res_fwd_ME,
            Res_fwd_ER   => E_Res_fwd_ER,
            Op3_EX       => E_Op3_EX,
            EA_EX        => E_EA_EX,
            EB_EX        => E_EB_EX,
            ALUCtrl_EX   => E_ALUCtrl_EX,
            ALUSrc_EX    => E_ALUSrc_EX,
            CC           => E_CC,
            Op3_EX_out   => E_Op3_EX_out,
            Res_EX       => E_Res_EX,
            WD_EX        => E_WD_EX,
            npc_fw_br    => E_npc_fw_br
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
        -- Initialisation des valeurs de base
        E_Op1_EX      <= x"0000000A"; -- 10
        E_Op2_EX      <= x"00000005"; -- 5
        E_Extlmm_EX   <= x"00000064"; -- 100
        E_Res_fwd_ME  <= x"0000000F"; -- 15 (Forwarding de l'étage ME)
        E_Res_fwd_ER  <= x"00000014"; -- 20 (Forwarding de l'étage ER)
        E_Op3_EX      <= x"1";        -- Destination R1
        
        -- TEST 1 : Addition standard (R10 + R5)
        -- ALUCtrl = "00" (ADD), ALUSrc = '0' (Reg), EA/EB = "00" (No forwarding)
        E_ALUCtrl_EX <= "00";
        E_ALUSrc_EX  <= '0';
        E_EA_EX      <= "00";
        E_EB_EX      <= "00";
        wait for 10 ns; -- Résultat attendu : 10 + 5 = 15 (0xF)
        
        -- TEST 2 : Addition avec Immédiat (R10 + 100)
        -- ALUSrc = '1'
        E_ALUSrc_EX  <= '1';
        wait for 10 ns; -- Résultat attendu : 10 + 100 = 110 (0x6E)

        -- TEST 3 : Forwarding de l'étage ER sur Op1 (20 + 100)
        -- EA_EX = "01" (Prend Res_fwd_ER au lieu de Op1_EX) 
        E_EA_EX      <= "01";
        wait for 10 ns; -- Résultat attendu : 20 + 100 = 120 (0x78)

        -- TEST 4 : Soustraction avec Forwarding ME sur Op2 (20 - 15)
        -- ALUCtrl = "01" (SUB), EB_EX = "10" (Prend Res_fwd_ME), ALUSrc = '0'
        E_ALUCtrl_EX <= "01";
        E_ALUSrc_EX  <= '0';
        E_EB_EX      <= "10"; 
        wait for 10 ns; -- Résultat attendu : 20 - 15 = 5

        -- Fin des tests
        assert FALSE report "Fin de simulation EX - Verifiez les formes d'ondes" severity FAILURE;
        wait;
    end process P_TEST;

end architecture;