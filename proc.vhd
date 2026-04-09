architecture dataPath_arch of dataPath is

  -- Signaux de transition entre étages
  signal sig_i_FE, sig_pc_plus_4_FE : std_logic_vector(31 downto 0);
  signal sig_i_DE, sig_pc_plus_4_DE : std_logic_vector(31 downto 0);
  
  signal sig_Op1_DE, sig_Op2_DE, sig_extImm_DE : std_logic_vector(31 downto 0);
  signal sig_Op3_DE : std_logic_vector(3 downto 0);
  
  signal sig_Op1_EX, sig_Op2_EX, sig_extImm_EX : std_logic_vector(31 downto 0);
  signal sig_Op3_EX : std_logic_vector(3 downto 0);
  
  signal sig_Res_EX, sig_WD_EX, sig_npc_fw_br : std_logic_vector(31 downto 0);
  signal sig_Op3_EX_out : std_logic_vector(3 downto 0);
  
  signal sig_Res_ME, sig_WD_ME : std_logic_vector(31 downto 0);
  signal sig_Op3_ME : std_logic_vector(3 downto 0);
  
  signal sig_Res_Mem_ME, sig_Res_ALU_ME, sig_Res_fwd_ME : std_logic_vector(31 downto 0);
  signal sig_Op3_ME_out : std_logic_vector(3 downto 0);
  
  signal sig_Res_Mem_ER, sig_Res_ALU_ER : std_logic_vector(31 downto 0);
  signal sig_Op3_ER : std_logic_vector(3 downto 0);
  
  signal sig_Res_RE : std_logic_vector(31 downto 0);
  signal sig_Op3_RE_out : std_logic_vector(3 downto 0);

  -- Signaux pour les indices de registres (Unité de gestion des aléas)
  signal sig_Reg1, sig_Reg2 : std_logic_vector(3 downto 0);

begin

  ---------------------------------------------------------------------------
  -- ETAGE 1 : FETCH (FE)
  ---------------------------------------------------------------------------
  inst_FE : entity work.etageFE
    port map (
      npc       => sig_Res_RE,      -- Retour du Write-Back
      npc_fw_br => sig_npc_fw_br,   -- Retour de l'étage Execute
      PCSrc_ER  => PCSrc_ER,
      Bpris_EX  => Bpris_EX,
      GEL_LI    => Gel_LI,
      clk       => clk,
      pc_plus_4 => sig_pc_plus_4_FE,
      i_FE      => sig_i_FE
    );

  -- Registre de Pipeline FE/DE
  reg_FE_DE_inst : entity work.Reg32sync 
    port map (source => sig_i_FE, output => sig_i_DE, gel => Gel_DI, raz => RAZ_DI, clk => clk);
  reg_FE_DE_pc   : entity work.Reg32sync 
    port map (source => sig_pc_plus_4_FE, output => sig_pc_plus_4_DE, gel => Gel_DI, raz => '1', clk => clk);

  ---------------------------------------------------------------------------
  -- ETAGE 2 : DECODE (DE)
  ---------------------------------------------------------------------------
  inst_DE : entity work.etageDE
    port map (
      i_DE      => sig_i_DE,
      WD_ER     => sig_Res_RE,      -- Donnée à écrire
      pc_plus_4 => sig_pc_plus_4_DE,
      Op3_ER    => sig_Op3_RE_out,  -- Index destination
      RegSrc    => RegSrc,
      immSrc    => immSrc,
      RegWr     => RegWR,
      clk       => clk,
      Init      => init,
      Reg1      => sig_Reg1,
      Reg2      => sig_Reg2,
      Op1       => sig_Op1_DE,
      Op2       => sig_Op2_DE,
      extlmm    => sig_extImm_DE,
      Op3_DE    => sig_Op3_DE
    );

  -- Registres de Pipeline DE/EX
  reg_DE_EX_op1  : entity work.Reg32sync 
    port map (source => sig_Op1_DE, output => sig_Op1_EX, gel => '1', raz => Clr_EX, clk => clk);
  reg_DE_EX_op2  : entity work.Reg32sync 
    port map (source => sig_Op2_DE, output => sig_Op2_EX, gel => '1', raz => Clr_EX, clk => clk);
  reg_DE_EX_imm  : entity work.Reg32sync 
    port map (source => sig_extImm_DE, output => sig_extImm_EX, gel => '1', raz => Clr_EX, clk => clk);
  -- Pour l'index de registre (4 bits), on peut utiliser une logique similaire
  process(clk) begin
    if rising_edge(clk) then
        if Clr_EX = '0' then sig_Op3_EX <= (others => '0');
        else sig_Op3_EX <= sig_Op3_DE; end if;
    end if;
  end process;

  ---------------------------------------------------------------------------
  -- ETAGE 3 : EXECUTE (EX)
  ---------------------------------------------------------------------------
  inst_EX : entity work.etageEX
    port map (
      Op1_EX     => sig_Op1_EX,
      Op2_EX     => sig_Op2_EX,
      Extlmm_EX  => sig_extImm_EX,
      Res_fwd_ME => sig_Res_fwd_ME, -- Forwarding de ME
      Res_fwd_ER => sig_Res_RE,     -- Forwarding de ER
      Op3_EX     => sig_Op3_EX,
      EA_EX      => EA_EX,
      EB_EX      => EB_EX,
      ALUCtrl_EX => ALUCtrl_EX,
      ALUSrc_EX  => ALUSrc_EX,
      CC         => CC,
      Op3_EX_out => sig_Op3_EX_out,
      Res_EX     => sig_Res_EX,
      WD_EX      => sig_WD_EX,
      npc_fw_br  => sig_npc_fw_br
    );

  -- Registres de Pipeline EX/ME
  reg_EX_ME_res : entity work.Reg32sync 
    port map (source => sig_Res_EX, output => sig_Res_ME, gel => '1', raz => '1', clk => clk);
  reg_EX_ME_wd  : entity work.Reg32sync 
    port map (source => sig_WD_EX, output => sig_WD_ME, gel => '1', raz => '1', clk => clk);
  process(clk) begin
    if rising_edge(clk) then sig_Op3_ME <= sig_Op3_EX_out; end if;
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
      MemWR_Mem  => MemWr_Mem,
      Res_Mem_ME => sig_Res_Mem_ME,
      Res_ALU_ME => sig_Res_ALU_ME,
      Res_fwd_ME => sig_Res_fwd_ME,
      Op3_ME_out => sig_Op3_ME_out
    );

  -- Registres de Pipeline ME/ER
  reg_ME_ER_mem : entity work.Reg32sync 
    port map (source => sig_Res_Mem_ME, output => sig_Res_Mem_ER, gel => '1', raz => '1', clk => clk);
  reg_ME_ER_alu : entity work.Reg32sync 
    port map (source => sig_Res_ALU_ME, output => sig_Res_ALU_ER, gel => '1', raz => '1', clk => clk);
  process(clk) begin
    if rising_edge(clk) then sig_Op3_ER <= sig_Op3_ME_out; end if;
  end process;

  ---------------------------------------------------------------------------
  -- ETAGE 5 : WRITE-BACK (ER)
  ---------------------------------------------------------------------------
  inst_ER : entity work.etageER
    port map (
      Res_Mem_RE  => sig_Res_Mem_ER,
      Res_ALU_RE  => sig_Res_ALU_ER,
      Op3_RE      => sig_Op3_ER,
      MemToReg_RE => MemToReg_RE,
      Res_RE      => sig_Res_RE,
      Op3_RE_out  => sig_Op3_RE_out
    );

  ---------------------------------------------------------------------------
  -- SORTIES DU DATAPATH
  ---------------------------------------------------------------------------
  instr_DE    <= sig_i_DE;
  a1          <= sig_Reg1;
  a2          <= sig_Reg2;
  rs1         <= sig_Reg1; -- Souvent identiques à a1/a2 pour l'unité d'aléa
  rs2         <= sig_Reg2;
  op3_EX_out  <= sig_Op3_EX_out;
  op3_ME_out  <= sig_Op3_ME_out;
  op3_RE_out  <= sig_Op3_RE_out;

end architecture;