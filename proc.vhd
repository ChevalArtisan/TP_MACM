library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;


architecture dataPath_arch of dataPath is

  ---------------------------------------------------------------------------
  -- DÉCLARATION DES SIGNAUX INTERNES
  ---------------------------------------------------------------------------
  
  -- Etage FE (Fetch)
  signal sig_i_FE, sig_pc_plus_4_FE : std_logic_vector(31 downto 0);
  
  -- Etage DE (Decode)
  signal sig_i_DE, sig_pc_plus_4_DE : std_logic_vector(31 downto 0);
  signal sig_Op1_DE, sig_Op2_DE, sig_extImm_DE : std_logic_vector(31 downto 0);
  signal sig_Op3_DE : std_logic_vector(3 downto 0);
  signal sig_Reg1, sig_Reg2 : std_logic_vector(3 downto 0);

  -- Signaux de contrôle (DE)
  signal sig_PCSrc_DE, sig_RegWr_DE, sig_MemToReg_DE, sig_MemWR_DE : std_logic;
  signal sig_Branch_DE, sig_CCWr_DE, sig_AluSrc_DE : std_logic;
  signal sig_AluCtrl_DE, sig_ImmSrc_DE, sig_RegSrc_DE : std_logic_vector(1 downto 0);
  signal sig_Cond_DE : std_logic_vector(3 downto 0);

  -- Etage EX (Execute)
  signal sig_Op1_EX, sig_Op2_EX, sig_extImm_EX : std_logic_vector(31 downto 0);
  signal sig_Op3_EX, sig_Op3_EX_out : std_logic_vector(3 downto 0);
  signal sig_Res_EX, sig_WD_EX, sig_npc_fw_br : std_logic_vector(31 downto 0);
  
  -- Signaux de contrôle pipelinés (EX)
  signal sig_RegWr_EX, sig_MemToReg_EX, sig_MemWR_EX, sig_CCWr_EX : std_logic;
  signal sig_AluCtrl_EX : std_logic_vector(1 downto 0);
  signal sig_AluSrc_EX, sig_Branch_EX, sig_PCSrc_EX : std_logic;
  signal sig_Cond_EX : std_logic_vector(3 downto 0);
  
  -- Gestion des drapeaux (CPSR)
  signal sig_CondEx_EX : std_logic;
  signal sig_CC_EX_reg : std_logic_vector(3 downto 0) := (others => '0'); 
  signal sig_CC_out_EX : std_logic_vector(3 downto 0);

  -- Etage ME (Memory)
  signal sig_Res_ME, sig_WD_ME : std_logic_vector(31 downto 0);
  signal sig_Op3_ME, sig_Op3_ME_out : std_logic_vector(3 downto 0);
  signal sig_Res_Mem_ME, sig_Res_ALU_ME, sig_Res_fwd_ME : std_logic_vector(31 downto 0);
  signal sig_RegWr_ME, sig_MemToReg_ME, sig_MemWR_ME : std_logic;

  -- Etage ER (Write-Back)
  signal sig_Res_Mem_ER, sig_Res_ALU_ER : std_logic_vector(31 downto 0);
  signal sig_Op3_ER, sig_Op3_RE_out : std_logic_vector(3 downto 0);
  signal sig_RegWr_ER, sig_MemToReg_ER : std_logic;
  signal sig_Res_RE : std_logic_vector(31 downto 0);

  -- Signaux pour l'unité de gestion des aléas
  signal sig_EA_EX, sig_EB_EX : std_logic_vector(1 downto 0);
  signal sig_Gel_LI, sig_Gel_DI, sig_RAZ_DI, sig_Clr_EX : std_logic;
  signal sig_Bpris_EX : std_logic;

begin

  ---------------------------------------------------------------------------
  -- GESTIONNAIRE DES ALÉAS (HAZARD UNIT)
  ---------------------------------------------------------------------------
  inst_Hazard : entity work.HazardUnit
    port map (
      a1          => sig_Reg1, 
      a2          => sig_Reg2, 
      Op3_ME_out  => sig_Op3_ME_out, Op3_RE_out => sig_Op3_RE_out,
      RegWr_ME    => sig_RegWr_ME, RegWr_RE => sig_RegWr_ER,
      Reg1        => sig_Reg1, Reg2 => sig_Reg2, -- Indices pour LDRStall
      Op3_EX_out  => sig_Op3_EX_out, MemToReg_EX => sig_MemToReg_EX,
      PCSrc_DE    => sig_PCSrc_DE, PCSrc_EX => sig_PCSrc_EX,
      PCSrc_ME    => sig_MemToReg_ME, -- ou PCSrc pipeliné si présent
      PCSrc_ER    => sig_RegWr_ER, -- Adapter selon votre signal PCSrc_ER final
      Bpris_EX    => sig_Bpris_EX,
      EA_EX       => sig_EA_EX, EB_EX => sig_EB_EX,
      Gel_LI      => sig_Gel_LI, Gel_DI => sig_Gel_DI,
      RAZ_DI      => sig_RAZ_DI, Clr_EX => sig_Clr_EX
    );

  sig_Bpris_EX <= sig_Branch_EX and sig_CondEx_EX;
  ---------------------------------------------------------------------------
  -- ETAGE 1 : FETCH (FE)
  ---------------------------------------------------------------------------
  inst_FE : entity work.etageFE
    port map (
      npc       => sig_Res_RE,
      npc_fw_br => sig_npc_fw_br,
      PCSrc_ER  => sig_PCSrc_EX and sig_CondEx_EX, -- PC change si instruction cible R15 ET Cond valide
      Bpris_EX  => sig_Branch_EX and sig_CondEx_EX, -- Branchement pris si Branch ET Cond valide
      GEL_LI    => sig_Gel_LI,
      clk       => clk,
      pc_plus_4 => sig_pc_plus_4_FE,
      i_FE      => sig_i_FE
    );

  -- Pipeline FE/DE
  reg_FE_DE_inst : entity work.Reg32sync 
    port map (source => sig_i_FE, output => sig_i_DE, gel => sig_Gel_DI, raz => RAZ_DI, clk => clk);
  reg_FE_DE_pc   : entity work.Reg32sync 
    port map (source => sig_pc_plus_4_FE, output => sig_pc_plus_4_DE, gel => sig_Gel_DI, raz => '1', clk => clk);

  ---------------------------------------------------------------------------
  -- ETAGE 2 : DECODE (DE)
  ---------------------------------------------------------------------------
  
  -- Instanciation de votre nouveau décodeur externe
  inst_CU : entity work.ControlUnit
    port map (
      instr    => sig_i_DE,
      PCSrc    => sig_PCSrc_DE,
      RegWr    => sig_RegWr_DE,
      MemToReg => sig_MemToReg_DE,
      MemWR    => sig_MemWR_DE,
      AluCtrl  => sig_AluCtrl_DE,
      Branch   => sig_Branch_DE,
      CCWr     => sig_CCWr_DE,
      AluSrc   => sig_AluSrc_DE,
      ImmSrc   => sig_ImmSrc_DE,
      RegSrc   => sig_RegSrc_DE,
      Cond     => sig_Cond_DE
    );

  inst_DE : entity work.etageDE
    port map (
      i_DE      => sig_i_DE,
      WD_ER     => sig_Res_RE,
      pc_plus_4 => sig_pc_plus_4_DE,
      Op3_ER    => sig_Op3_RE_out,
      RegSrc    => sig_RegSrc_DE,
      immSrc    => sig_ImmSrc_DE,
      RegWr     => sig_RegWr_ER, -- Feedback du Write-Back
      clk       => clk,
      Init      => init,
      Reg1      => sig_Reg1,
      Reg2      => sig_Reg2,
      Op1       => sig_Op1_DE,
      Op2       => sig_Op2_DE,
      extlmm    => sig_extImm_DE,
      Op3_DE    => sig_Op3_DE
    );

---------------------------------------------------------------------------
  -- REGISTRE DE PIPELINE DE / EX (Contrôle et Données)
  ---------------------------------------------------------------------------
  process(clk) begin
    if rising_edge(clk) then
      -- sig_Clr_EX est piloté par la Hazard Unit
      -- Si '0', on injecte un NOP (on met à 0 les signaux d'écriture)
      if sig_Clr_EX = '0' then 
        sig_RegWr_EX    <= '0';
        sig_MemWR_EX    <= '0';
        sig_Branch_EX   <= '0';
        sig_CCWr_EX     <= '0';
        sig_PCSrc_EX    <= '0';
        sig_MemToReg_EX <= '0';
      else
        -- Sinon, on propage normalement les signaux de contrôle
        sig_RegWr_EX    <= sig_RegWr_DE;
        sig_MemWR_EX    <= sig_MemWR_DE;
        sig_Branch_EX   <= sig_Branch_DE;
        sig_CCWr_EX     <= sig_CCWr_DE;
        sig_PCSrc_EX    <= sig_PCSrc_DE;
        sig_MemToReg_EX <= sig_MemToReg_DE;
        sig_AluCtrl_EX  <= sig_AluCtrl_DE;
        sig_AluSrc_EX   <= sig_AluSrc_DE;
        sig_Cond_EX     <= sig_Cond_DE;
        
        -- On propage aussi les données lues dans les registres / immédiat
        sig_Op1_EX      <= sig_Op1_DE;
        sig_Op2_EX      <= sig_Op2_DE;
        sig_extImm_EX   <= sig_extImm_DE;
        sig_Op3_EX      <= sig_Op3_DE;
      end if;
    end if;
  end process;

  ---------------------------------------------------------------------------
  -- ETAGE 3 : EXECUTE (EX)
  ---------------------------------------------------------------------------
  
  -- Instanciation de votre nouvelle unité de condition externe
  inst_Cond : entity work.ConditionUnit
    port map (
      Cond    => sig_Cond_EX,
      CC_EX   => sig_CC_EX_reg, -- Drapeaux actuels
      CC      => CC,           -- Drapeaux venant de l'ALU
      CCWr_EX => sig_CCWr_EX,
      CC_out  => sig_CC_out_EX,
      CondEx  => sig_CondEx_EX
    );

  inst_EX : entity work.etageEX
    port map (
      Op1_EX     => sig_Op1_EX,
      Op2_EX     => sig_Op2_EX,
      Extlmm_EX  => sig_extImm_EX,
      Res_fwd_ME => sig_Res_fwd_ME,
      Res_fwd_ER => sig_Res_RE,
      Op3_EX     => sig_Op3_EX,
      EA_EX      => sig_EA_EX,
      EB_EX      => sig_EB_EX,
      ALUCtrl_EX => sig_AluCtrl_EX,
      ALUSrc_EX  => sig_AluSrc_EX,
      CC         => CC,
      Op3_EX_out => sig_Op3_EX_out,
      Res_EX     => sig_Res_EX,
      WD_EX      => sig_WD_EX,
      npc_fw_br  => sig_npc_fw_br
    );
  
  

  -- Registre d'état CPSR (Flags)
  process(clk) begin
    if rising_edge(clk) then
      if init = '1' then
        sig_CC_EX_reg <= (others => '0');
      else
        sig_CC_EX_reg <= sig_CC_out_EX; -- Mise à jour conditionnelle via CC_out
      end if;
    end if;
  end process;


  -- Pipeline EX/ME
  process(clk) begin
    if rising_edge(clk) then
      sig_Res_ME      <= sig_Res_EX;
      sig_WD_ME       <= sig_WD_EX;
      sig_Op3_ME      <= sig_Op3_EX_out;
      sig_MemToReg_ME <= sig_MemToReg_EX;
      -- Propage l'écriture que si la condition est vraie
      sig_RegWr_ME    <= sig_RegWr_EX and sig_CondEx_EX;
      sig_MemWR_ME    <= sig_MemWR_EX and sig_CondEx_EX;
    end if;
  end process;

  ---------------------------------------------------------------------------
  -- ETAGE 4 : MEMORY (ME)
  ---------------------------------------------------------------------------
  inst_ME : entity work.etageME
    port map (
      Res_ME     => sig_Res_ME,
      WD_ME      => sig_WD_ME,
      Op3_ME     => sig_Op3_ME,
      clk        => clk,
      MemWR_Mem  => sig_MemWR_ME, -- Déjà validé par CondEx
      Res_Mem_ME => sig_Res_Mem_ME,
      Res_ALU_ME => sig_Res_ALU_ME,
      Res_fwd_ME => sig_Res_fwd_ME,
      Op3_ME_out => sig_Op3_ME_out
    );

  -- Pipeline ME/ER
  process(clk) begin
    if rising_edge(clk) then
      sig_Res_Mem_ER <= sig_Res_Mem_ME;
      sig_Res_ALU_ER <= sig_Res_ALU_ME;
      sig_Op3_ER     <= sig_Op3_ME_out;
      sig_RegWr_ER   <= sig_RegWr_ME;
      sig_MemToReg_ER <= sig_MemToReg_ME;
    end if;
  end process;

  ---------------------------------------------------------------------------
  -- ETAGE 5 : WRITE-BACK (ER)
  ---------------------------------------------------------------------------
  inst_ER : entity work.etageER
    port map (
      Res_Mem_RE  => sig_Res_Mem_ER,
      Res_ALU_RE  => sig_Res_ALU_ER,
      Op3_RE      => sig_Op3_ER,
      MemToReg_RE => sig_MemToReg_ER,
      Res_RE      => sig_Res_RE,
      Op3_RE_out  => sig_Op3_RE_out
    );

  ---------------------------------------------------------------------------
  -- MAPPING DES SORTIES VERS LE TOP-LEVEL
  ---------------------------------------------------------------------------
  instr_DE   <= sig_i_DE;
  a1         <= sig_Reg1;
  a2         <= sig_Reg2;
  rs1        <= sig_Reg1;
  rs2        <= sig_Reg2;
  op3_EX_out <= sig_Op3_EX_out;
  op3_ME_out <= sig_Op3_ME_out;
  op3_RE_out <= sig_Op3_RE_out;

end architecture;