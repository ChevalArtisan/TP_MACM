library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity proc_tb is
end entity;

architecture bhv of proc_tb is
    -- Signaux du testbench
    signal clk   : std_logic := '0';
    signal init  : std_logic := '1';
    
    -- Période de l'horloge (10 ns = 100 MHz)
    constant CLK_PERIOD : time := 10 ns;

begin
    -- Instanciation du processeur
    uut: entity work.dataPath
        port map (
            clk  => clk,
            init => init
            -- Ajoutez ici les autres ports de votre entité dataPath si nécessaire
        );

    -- Générateur d'horloge
    clk_process : process
    begin
        while now < 1000 ns loop -- Simule pendant 1µs
            clk <= '0';
            wait for CLK_PERIOD / 2;
            clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
        wait;
    end process;

    -- Stimuli
    stim_proc : process
    begin
        init <= '1';
        wait for 25 ns;
        init <= '0'; -- Libère le processeur
        wait;
    end process;

end architecture;