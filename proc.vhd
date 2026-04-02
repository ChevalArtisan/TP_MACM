-------------------------------------------------------

-- Chemin de données

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;


entity dataPath is
  port(
    clk,  init, ALUSrc_EX, MemWr_Mem, MemWr_RE, PCSrc_ER, Bpris_EX, Gel_LI, Gel_DI, RAZ_DI, RegWR, Clr_EX, MemToReg_RE : in std_logic;
    RegSrc, EA_EX, EB_EX, immSrc, ALUCtrl_EX : in std_logic_vector(1 downto 0);
    instr_DE: out std_logic_vector(31 downto 0);
    a1, a2, rs1, rs2, CC, op3_EX_out, op3_ME_out, op3_RE_out: out std_logic_vector(3 downto 0)
);      
end entity;

architecture dataPath_arch of dataPath is
  signal Res_RE, npc_fwd_br, pc_plus_4, i_FE, i_DE, Op1_DE, Op2_DE, Op1_EX, Op2_EX, extImm_DE, extImm_EX, Res_EX, Res_ME, WD_EX, WD_ME, Res_Mem_ME, Res_Mem_RE, Res_ALU_ME, Res_ALU_RE, Res_fwd_ME : std_logic_vector(31 downto 0);
  signal Op3_DE, Op3_EX, a1_DE, a1_EX, a2_DE, a2_EX, Op3_EX_out_t, Op3_ME, Op3_ME_out_t, Op3_RE, Op3_RE_out_t : std_logic_vector(3 downto 0);
begin

  -- FE
  inst_FE : entity work.etageFE
    port map(
      npc :Res_RE,
      npc_fwd_br : npc_fw_br,
      PCSrc_ER : PCSrc_ER,
      Bpris_EX : Bpris_EX,
      Gel_LI : Gel_LI,
      pc_plus_4: pc_plus_4,
      i_FE: i_FE,
      clk:clk
    );
  -- DE
  inst_DE : entity work.etageDE
      port map(
        i_DE: i_FE,
        Op3_ER: Op3_ER_out,,
        WD_ER :Res_RE,
        pc_plus_4 :pc_plus_4,
        Reg1: rs1,
        Reg2: rs2,
        RegSrc: RegSrc,
        immSrc: immSrc,
        Op1:Op1,
        Op2: Op2,
        extlmm: extlmm,
        Op3_DE: Op3_DE
        clk:clk,
        RegWR: RegWR,
        Init: Init
    );
  -- EX
 inst_EX : entity work.etageEX
        port map(
          Op1_EX: Op1,
          Op2_EX: Op2,
          Res_fwd_ER:Res_RE,
          Res_fwd_ME: Res_fwd_ME,
          Extlmm_EX: extlmm,
          Op3_EX: Op3_DE,
          EA_EX:EA_EX,
          EB_EX:EB_EX,
          ALUSrc_EX:ALUSrc_EX,
          ALUCtrl_EX:ALUCtrl_EX,
          CC:CC,
          Res_EX:Res_EX,
          npc_fwd_br: npc_fwd_br,
          WD_EX: WD_EX,
          Op3_EX_out:Op3_EX_out
        );
  -- ME
 inst_ME : entity work.etageME
          port map(
            Res_ME : Res_EX,
            WD_ME : WD_EX,
            Op3_ME : Op3_EX_out,
            clk: clk
            MemWR_Mem : MemWr_Mem,
            Res_Mem_ME: Res_Mem_ME,
            Res_ALU_ME:Res_ALU_ME,
            Op3_ME_out:Op3_ME_out,
            Res_fwd_ME: Res_fwd_ME
          );
  -- RE
  intst_RE : entity work.etageRE
            port map (
              Res_Mem_RE: Res_Mem_ME
              Res_ALU_RE : Res_ALU_ME,
              Op3_RE :Op3_ME_out,
              MemToReg_RE :MemToReg_RE,
              Res_RE : Res_RE,
              Op3_RE_out: Op3_RE_out
            );
 
  
end architecture;
