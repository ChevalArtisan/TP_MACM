library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ControlUnit is
    port(
        instr   : in  std_logic_vector(31 downto 0); -- L'instruction complète
        CC      : in  std_logic_vector(3 downto 0);  -- Drapeaux N, Z, C, V
        -- Signaux vers le Datapath
        RegWr   : out std_logic;
        RegSrc  : out std_logic_vector(1 downto 0);
        ALUSrc  : out std_logic;
        ALUCtrl : out std_logic_vector(1 downto 0);
        MemWr   : out std_logic;
        MemToReg: out std_logic;
        ImmSrc  : out std_logic_vector(1 downto 0);
        PCSrc   : out std_logic;
        -- Signal interne pour la mise à jour des flags
        CCWr    : out std_logic
    );
end entity;

architecture behavior of ControlUnit is
    signal Cond     : std_logic_vector(3 downto 0);
    signal Op       : std_logic_vector(1 downto 0);
    signal Funct    : std_logic_vector(5 downto 0);
    signal Rd       : std_logic_vector(3 downto 0);
    signal CondEx   : std_logic; -- Indique si la condition est remplie
    signal Branch   : std_logic; -- Signal interne de branchement
    signal RegWr_int: std_logic; -- Signal interne d'écriture registre
begin

    -- Extraction des champs de l'instruction
    Cond  <= instr(31 downto 28);
    Op    <= instr(27 downto 26);
    Funct <= instr(25 downto 20); -- I, Cmd(4), S
    Rd    <= instr(15 downto 12);

    -----------------------------------------------------
    -- LOGIQUE DE DÉCODAGE PRINCIPALE
    -----------------------------------------------------
    process(Op, Funct, Rd)
    begin
        -- Valeurs par défaut
        Branch   <= '0';
        RegWr_int<= '0';
        RegSrc   <= "00";
        ALUSrc   <= '0';
        ALUCtrl  <= "00";
        MemWr    <= '0';
        MemToReg <= '0';
        ImmSrc   <= "00";
        CCWr     <= '0';

        case Op is
            when "00" => -- DATA PROCESSING
                RegWr_int <= '1';
                ALUSrc    <= Funct(5); -- Bit 'I'
                ALUCtrl   <= Funct(4 downto 3); -- Simplification Cmd
                CCWr      <= Funct(0); -- Bit 'S'
                ImmSrc    <= "00";

            when "01" => -- MEMORY (LDR/STR)
                ALUSrc    <= '1'; -- On ajoute l'immédiat à l'adresse
                ImmSrc    <= "01";
                if Funct(0) = '1' then -- LDR
                    RegWr_int <= '1';
                    MemToReg  <= '1';
                else                   -- STR
                    MemWr     <= '1';
                    RegSrc(1) <= '1'; -- Rd en 2ème source registre
                end if;

            when "10" => -- BRANCH (B)
                Branch    <= '1';
                ALUSrc    <= '1';
                ImmSrc    <= "10";
                RegSrc    <= "01"; -- Pas utilisé pour B mais souvent défini

            when others => null;
        end case;
    end process;

    -----------------------------------------------------
    -- LOGIQUE DES CONDITIONS (II.2)
    -----------------------------------------------------
    -- N=CC(3), Z=CC(2), C=CC(1), V=CC(0)
    process(Cond, CC)
    begin
        case Cond is
            when "0000" => CondEx <= CC(2);          -- EQ (Z=1)
            when "0001" => CondEx <= not CC(2);      -- NE (Z=0)
            when "0010" => CondEx <= CC(1);          -- CS (C=1)
            when "0011" => CondEx <= not CC(1);      -- CC (C=0)
            when "0100" => CondEx <= CC(3);          -- MI (N=1)
            when "0101" => CondEx <= not CC(3);      -- PL (N=0)
            when "0110" => CondEx <= CC(0);          -- VS (V=1)
            when "0111" => CondEx <= not CC(0);      -- VC (V=0)
            when "1010" =>                           -- GE
                if CC(3) = CC(0) then CondEx <= '1'; else CondEx <= '0'; end if;
            when "1110" => CondEx <= '1';            -- AL (Always)
            when others => CondEx <= '0';
        end case;
    end process;

    -----------------------------------------------------
    -- CALCUL FINAL DES SIGNAUX
    -----------------------------------------------------
    -- Une instruction n'écrit ou ne branche QUE si la condition est vraie
    RegWr <= RegWr_int and CondEx;
    
    -- PCSrc = Branch pris OU (Ecriture registre dans R15/PC)
    PCSrc <= (Branch and CondEx) or (RegWr_int and CondEx when Rd = "1111" else '0');

end architecture;