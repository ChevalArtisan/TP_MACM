# 1. Analyse des fichiers (Compilation)
ghdl -a reg_bank.vhd
ghdl -a combi.vhd
ghdl -a mem.vhd
ghdl -a etages.vhd
ghdl -a control_unit.vhd
ghdl -a cond_unit.vhd
ghdl -a hazard_unit.vhd
ghdl -a proc.vhd
ghdl -a test_proc.vhd

# 2. Élaboration de l'entité de test
ghdl -e test_proc

# 3. Exécution de la simulation et génération du fichier de vagues (.vcd)
# On limite à 150ns comme défini dans votre constante TIMEOUT
ghdl -r test_proc --vcd=vagues.vcd --stop-time=150ns

# 4. Ouverture des résultats dans GTKWave
gtkwave vagues.vcd