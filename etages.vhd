-------------------------------------------------

-- Etage FE

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

entity etageFE is
  port(
    npc, npc_fw_br : in std_logic_vector(31 downto 0);
    PCSrc_ER, Bpris_EX, GEL_LI, clk : in std_logic;
    pc_plus_4, i_FE : out std_logic_vector(31 downto 0)
);
end entity;


architecture etageFE_arch of etageFE is
  signal pc_inter, pc_reg_in, pc_reg_out, sig_pc_plus_4, sig_4: std_logic_vector(31 downto 0);
begin

  sig_4 <= (2=>'1', others => '0');
  
  -- Architecture à compléter
  
  adder : entity work.addComplex
    port map (
      A => pc_reg_out,
      B => sig_4,
      cin => '0',
      s => sig_pc_plus_4,
      c30 => open,
      c31 => open
    );

  bancderegistre : entity work.Reg32
      port map (
        source=> pc_reg_in,
        output => pc_reg_out,
        clk=>clk,
        wr=> GEL_LI,
        raz=>'1'
      );
  
  memoireinstruscteur : entity work.inst_mem
        port map(
          addr=> pc_reg_out,
          instr=> i_FE
        );

end architecture;

-- -------------------------------------------------

-- -- Etage DE

-- LIBRARY IEEE;
-- USE IEEE.STD_LOGIC_1164.ALL;
-- USE IEEE.NUMERIC_STD.ALL;

-- entity etageDE is
-- port(
--    i_DE,WD_ER,pc_plus_4: in std_logic_vector(31 down 0);
--    Op3_ER: in std_logic_vector(3 downto 0);
--    RegSrc, immSrc: in std_logic_vector(1 downto 0);
--    RegWr,clk,Init : in std_logic;
--    Reg1,Reg2: out std_logic_vector(3 downto 0);
--    Op1,Op2,extlmm: out std_logic_vector(31 downto 0);
--    Op3_DE : out std_logic_vector(3 downto 0)
--);
-- end entity;

-- -------------------------------------------------

-- -- Etage EX

-- LIBRARY IEEE;
-- USE IEEE.STD_LOGIC_1164.ALL;
-- USE IEEE.NUMERIC_STD.ALL;

-- entity etageEX is
--     port(
--       Op1_EX,Op2_EX,Extlmm_EX,Res_fwd_ME,Res_fwd_ER: in std_logic_vector(31 downto 0);
--       Op3_EX: in std_logic_vector(3 downto 0);
--       EA_EX,EB_EX,ALUCtrl_EX: in std_logic_vector(1 downto 0);
--       ALUSrc_EX: in std_logic;
--       CC,Op3_EX_out: out std_logic_vector(3 downto 0);
--       Res_EX,WD_EX,npc_fw_br : out std_logic_vector(31 downto 0)
--     );
-- -- end entity
-- -------------------------------------------------

-- -- Etage ME

-- LIBRARY IEEE;
-- USE IEEE.STD_LOGIC_1164.ALL;
-- USE IEEE.NUMERIC_STD.ALL;

-- entity etageME is
    -- port(
    --   Res_ME,WD_ME : in std_logic_vector(31 downto 0);
    --   Op3_ME : in std_logic_vector(3 downto 0);
    --   clk, MemWR_Mem : in std_logic;
    --   Res_Mem_ME,Res_ALU_ME,Op3_ME_out,Res_fwd_ME: out std_logic_vector(31 downto 0);
    --   Op3_ME_out: out std_logic_vector(3 downto 0)
    --   );
-- end entity;
-- -------------------------------------------------

-- -- Etage ER

-- LIBRARY IEEE;
-- USE IEEE.STD_LOGIC_1164.ALL;
-- USE IEEE.NUMERIC_STD.ALL;

-- entity etageER is
    -- port(
    --   Res_Mem_RE,Res_ALU_RE : in std_logic_vector(31 downto 0);
    --   Op3_RE : in std_logic_vector(3 downto 0);
    --   MemToReg_RE : in std_logic;
    --   Res_RE : out std_logic_vector(31 down to 0);
    --   Op3_RE_out: out std_logic_vector(3 downto 0)
    -- );
-- end entity;
