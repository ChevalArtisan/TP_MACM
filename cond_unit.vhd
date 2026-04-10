library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity ConditionUnit is
    port (
        Cond     : in  std_logic_vector(3 downto 0); -- Code condition EX 
        CC_EX    : in  std_logic_vector(3 downto 0); -- N, Z, C, V sauvegardés
        CC       : in  std_logic_vector(3 downto 0); -- N, Z, C, V de l'ALU
        CCWr_EX  : in  std_logic;                     -- Signal mise à jour
        CC_out   : out std_logic_vector(3 downto 0); -- Nouvelle valeur CC'
        CondEx   : out std_logic                      -- Autorisation exécution
    );
end entity;

architecture Behavioral of ConditionUnit is
    signal N, Z, C, V : std_logic;
    signal res_cond   : std_logic;
begin
    -- Extraction des bits de CC_EX
    N <= CC_EX(3);
    Z <= CC_EX(2);
    C <= CC_EX(1);
    V <= CC_EX(0);

    process(Cond, N, Z, C, V)
    begin
        case Cond is
            when "0000" => res_cond <= Z;               -- EQ 
            when "0001" => res_cond <= not Z;           -- NE 
            when "0010" => res_cond <= C;               -- CS/HS 
            when "0011" => res_cond <= not C;           -- CC/LO
            when "0100" => res_cond <= N;               -- MI 
            when "0101" => res_cond <= not N;           -- PL 
            when "0110" => res_cond <= V;               -- VS 
            when "0111" => res_cond <= not V;           -- VC 
            when "1000" => res_cond <= C and (not Z);   -- HI 
            when "1001" => res_cond <= (not C) or Z;    -- LS 
            when "1010" => res_cond <= N and V;   -- GE 
            when "1011" => res_cond <= N nand V;         -- LT
            when "1100" => res_cond <= (not Z) and (N and V);-- GT
            when "1101" => res_cond <= Z or (N nand V);  -- LE
            when "1110" => res_cond <= '1';             -- AL
            when others => res_cond <= '1';
        end case;
    end process;

    CondEx <= res_cond;

    -- CC' vaut CC si CCWr_EX et CondEx sont à 1, sinon CC_EX
    CC_out <= CC when (CCWr_EX = '1' and res_cond = '1') else CC_EX;

end architecture;