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
  -- Logique des multiplexeurs (Schéma page 2 du PDF)

  
  -- Liaison de la sortie

begin

  sig_4 <= (2=>'1', others => '0');
  pc_inter  <= npc when PCSrc_ER = '1' else sig_pc_plus_4;
  pc_reg_in <= npc_fw_br when Bpris_EX = '1' else pc_inter;
  pc_plus_4 <= sig_pc_plus_4;

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
    --Multiplexeur 1
  pc_inter <= npc when PCSrc_ER = '1' else sig_pc_plus_4;
  
  --Multiplexeur 2
  pc_reg_in <= npc_fw_br when Bpris_EX = '1' else pc_inter;

  pc_plus_4<=sig_pc_plus_4;        




end architecture;

-------------------------------------------------

-- Etage DE

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

entity etageDE is
port(
   i_DE,WD_ER,pc_plus_4: in std_logic_vector(31 downto 0);
   Op3_ER: in std_logic_vector(3 downto 0);
   RegSrc, immSrc: in std_logic_vector(1 downto 0);
   RegWr,clk,Init : in std_logic;
   Reg1,Reg2: out std_logic_vector(3 downto 0);
   Op1,Op2,extlmm: out std_logic_vector(31 downto 0);
   Op3_DE : out std_logic_vector(3 downto 0)
);
end entity;

architecture etageDE_arch of etageDE is
  signal sigOp1, sigOp2,sig_15 :std_logic_vector(3 downto 0);
begin
  sig_15<=(others=>'1');
  
  --multiplexeurs
  sigOp1<=sig_15 when RegSrc(0)='1' else i_DE(19 downto 16);
  sigOp2<=i_DE(15 downto 12) when RegSrc(1)='1' else i_DE(3 downto 0);

    
  ext: entity work.extension
    port map(
      immIn => i_DE(23 downto 0),
      immSrc => immSrc,
      ExtOut => extlmm
    );

  bancderegistre: entity work.RegisterBank
      port map(
		    s_reg_0 => sigOp1,
		    data_o_0 => Op1,
        s_reg_1 => sigOp2,
        data_o_1 => Op2,
        dest_reg => Op3_ER,
        data_i => WD_ER,
        pc_in => pc_plus_4,
        init => Init,
        wr_reg => RegWr,
        clk => clk
	);
  Reg1<=sigOp1;
  Reg2<=sigOp2;
  Op3_DE<=i_DE(15 downto 12);
  

end architecture;
-------------------------------------------------

-- Etage EX

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

entity etageEX is
    port(
      Op1_EX,Op2_EX,Extlmm_EX,Res_fwd_ME,Res_fwd_ER: in std_logic_vector(31 downto 0);
      Op3_EX: in std_logic_vector(3 downto 0);
      EA_EX,EB_EX,ALUCtrl_EX: in std_logic_vector(1 downto 0);
      ALUSrc_EX: in std_logic;
      CC,Op3_EX_out: out std_logic_vector(3 downto 0);
      Res_EX,WD_EX,npc_fw_br : out std_logic_vector(31 downto 0)
    );

    architecture etageEX_arch of etageEX is
    signal ALUOp1,ALUOp2, Oper2, res: std_logic_vector(31 downto 0);
    begin
      ALUOp1 <= Op1_EX when EA_EX="00" else Res_fwd_ER when EA_EX ="01" else Res_fwd_ME when EA_EX="10" else (others=>'0');
      Oper2 <= Op2_EX when EB_EX="00" else Res_fwd_ER when EB_EX ="01" else Res_fwd_ME when EB_EX="10" else (others=>'0');
      ALUOp2 <= Extlmm_EX when ALUCtrl_EX = '1' else Oper2;
      
      op3_EX_out<=Op3_EX;
      WD_EX<=Op2_EX;
      
      ALU : entity work.ALU 
        port map(
          A <=ALUOp1,
          B <= ALUOp2,
          sel <= ALUCtrl_EX,
          Res <= res,
          CC <= CC
        );
      
      Res_EX<=res;
      npc_fw_br<=res;
    end architecture;

    
end entity
-------------------------------------------------

-- Etage ME

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

entity etageME is
    port(
      Res_ME,WD_ME : in std_logic_vector(31 downto 0);
      Op3_ME : in std_logic_vector(3 downto 0);
      clk, MemWR_Mem : in std_logic;
      Res_Mem_ME,Res_ALU_ME,Op3_ME_out,Res_fwd_ME: out std_logic_vector(31 downto 0);
      Op3_ME_out: out std_logic_vector(3 downto 0)
      );

      architecture etageME_arch of etageME
    begin
      Res_ALU_ME<=Res_ME;
      op3_ME_out<=op3_ME;
      Res_fwd_ME<=Res_ME;

      memoirededonnees: entity work.data_mem
      port map(
        addr<= Res_ME,
        WD <= WD_ME,
        clk<=clk,
        WR <= MemWr_Mem,
        data <= Res_Mem_ME
        );

    end architecture;
end entity;
-------------------------------------------------

-- Etage ER

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

entity etageER is
    port(
      Res_Mem_RE,Res_ALU_RE : in std_logic_vector(31 downto 0);
      Op3_RE : in std_logic_vector(3 downto 0);
      MemToReg_RE : in std_logic;
      Res_RE : out std_logic_vector(31 down to 0);
      Op3_RE_out: out std_logic_vector(3 downto 0)
    );

      architecture etageER_arch of etageER is
        
      begin
        Res_RE<= Res_Mem_ME when MemToReg_RE ='1' else Res_ALU_RE;
        op3_RE_out<= Op3_RE;
        
      end architecture etageER_arch;

end entity;
