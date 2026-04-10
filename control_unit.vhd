library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity ControlUnit is
    port (
        instr    : in  std_logic_vector(31 downto 0);
        PCSrc    : out std_logic;
        RegWr    : out std_logic;
        MemToReg : out std_logic;
        MemWr    : out std_logic;
        AluCtrl  : out std_logic_vector(1 downto 0);
        Branch   : out std_logic;
        CCWr     : out std_logic;
        AluSrc   : out std_logic;
        ImmSrc   : out std_logic_vector(1 downto 0);
        RegSrc   : out std_logic_vector(1 downto 0);
        Cond     : out std_logic_vector(3 downto 0) 
    );
end entity;

architecture Behavioral of ControlUnit is
    signal op     : std_logic_vector(1 downto 0);
    signal funct  : std_logic_vector(5 downto 0);
    signal rd     : std_logic_vector(3 downto 0);
    signal s_bit  : std_logic;
begin
    -- Découpage de l'instruction
    Cond   <= instr(31 downto 28);
    op     <= instr(27 downto 26);
    funct  <= instr(25 downto 20);
    rd     <= instr(15 downto 12);
    s_bit  <= instr(20);

    process(op, funct, rd, s_bit)
    begin
        -- Valeurs par défaut
        Branch   <= '0';
        MemToReg <= '0';
        MemWr    <= '0';
        AluSrc   <= '0';
        RegWr    <= '0';
        AluCtrl  <= "00";
        ImmSrc   <= "00";
        RegSrc   <= "00";

        case op is
            when "00" => -- Instructions de Calcul
                RegWr  <= '1';
                AluSrc <= funct(5);
                if funct(4 downto 1) = "1010" then -- CMP
                    RegWr <= '0';
                    AluCtrl <= "01";
                elsif funct(4 downto 1) = "0100" then -- ADD
                    AluCtrl <= "00";
                elsif funct(4 downto 1) = "0010" then -- SUB
                    AluCtrl <= "01";
                elsif funct(4 downto 1) = "0000" then -- AND
                    AluCtrl <= "10";
                elsif funct(4 downto 1) = "1100" then -- ORR
                    AluCtrl <= "11";
                end if;

            when "01" => -- Instructions Mémoire (LDR/STR)
                AluSrc <= '1';
                ImmSrc <= "01";
                if funct(0) = '1' then -- LDR (bit 20 = 1)
                    RegWr    <= '1';
                    MemToReg <= '1';
                else -- STR (bit 20 = 0)
                    MemWr    <= '1';
                    RegSrc(1)<= '1';
                end if;

            when "10" => -- Branchement (B)
                Branch <= '1';
                AluSrc <= '1';
                ImmSrc <= "10";
                RegSrc <= "01";
                RegWr  <= '0';
                AluCtrl<= "00";

            when others => null;
        end case;
    end process;

    

    PCSrc <= '1' when (rd = "1111" and op = "00")  or 
                      (op = "01" and funct(0) = '1') 
                      else '0';

    CCWr <= '1' when (op = "00" and s_bit = '1') else '0';

end architecture;