library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity HazardUnit is
    port (
        -- Entrées pour le Forwarding (étage EX)
        a1, a2           : in  std_logic_vector(3 downto 0);
        Op3_ME_out       : in  std_logic_vector(3 downto 0);
        Op3_RE_out       : in  std_logic_vector(3 downto 0);
        RegWr_ME         : in  std_logic;
        RegWr_RE         : in  std_logic;

        -- Entrées pour le Stall LDR (étage DE)
        Reg1, Reg2       : in  std_logic_vector(3 downto 0);
        Op3_EX_out       : in  std_logic_vector(3 downto 0);
        MemToReg_EX      : in  std_logic;

        -- Entrées pour Aléas de Contrôle
        PCSrc_DE         : in  std_logic;
        PCSrc_EX         : in  std_logic;
        PCSrc_ME         : in  std_logic;
        PCSrc_ER         : in  std_logic;
        Bpris_EX         : in  std_logic;

        -- Sorties de Contrôle
        EA_EX, EB_EX     : out std_logic_vector(1 downto 0);
        Gel_LI           : out std_logic;
        Gel_DI           : out std_logic;
        RAZ_DI           : out std_logic;
        Clr_EX           : out std_logic
    );
end entity;

architecture Behavioral of HazardUnit is
    signal LDRStall : std_logic;
begin
    -- 1. Logique de Forwarding (Priorité à l'étage ME car donnée plus fraîche)
    EA_EX <= "10" when (a1 = Op3_ME_out and RegWr_ME = '1') else
             "01" when (a1 = Op3_RE_out and RegWr_RE = '1') else
             "00";

    EB_EX <= "10" when (a2 = Op3_ME_out and RegWr_ME = '1') else
             "01" when (a2 = Op3_RE_out and RegWr_RE = '1') else
             "00";

    -- 2. Détection d'aléa LDR (donnée non prête à l'étage EX)
    LDRStall <= '1' when ((Reg1 = Op3_EX_out or Reg2 = Op3_EX_out) and MemToReg_EX = '1') else '0';

    -- 3. Signaux de contrôle du Pipeline
    -- Gel_LI : Bloque le PC si LDRStall ou si une instruction modifie le PC (jusqu'à ME)
    Gel_LI <= not (LDRStall or PCSrc_DE or PCSrc_EX or PCSrc_ME);
    
    -- Gel_DI : Bloque l'étage DE en cas de LDRStall
    Gel_DI <= not LDRStall;
    
    -- RAZ_DI : Flush FE/DE si instruction modifie le PC ou Branchement pris
    RAZ_DI <= not (PCSrc_DE or PCSrc_EX or PCSrc_ME or PCSrc_ER or Bpris_EX);
    
    -- Clr_EX : Flush DE/EX si LDRStall (insertion de NOP) ou Branchement pris
    Clr_EX <= not (LDRStall or Bpris_EX);

end architecture;