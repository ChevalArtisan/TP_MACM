#!/bin/bash

# Arrêter le script à la moindre erreur
set -e

# Vérifier si l'utilisateur a bien fourni un fichier en argument
if [ -z "$1" ]; then
  echo "Erreur : Tu dois préciser le fichier de test à lancer."
  echo "Utilisation : ./lance.sh <nom_du_fichier_test.vhd>"
  echo "Exemple     : ./lance.sh tb_etageFE.vhd"
  exit 1
fi

# Récupérer le nom du fichier et le nom de l'entité (sans l'extension .vhd)
FICHIER_TEST=$1
ENTITE=$(basename "$FICHIER_TEST" .vhd)

echo "========================================="
echo "   Lancement de la simulation pour : $ENTITE"
echo "========================================="

echo "[1/5] Nettoyage des anciens fichiers..."
rm -f *.o *.cf resultats.vcd "$ENTITE"

echo "[2/5] Compilation des fichiers de base (l'ordre est strict)..."
ghdl -a combi.vhd
ghdl -a mem.vhd
ghdl -a reg_bank.vhd
ghdl -a etages.vhd


echo "[3/5] Compilation du banc de test ($FICHIER_TEST)..."
ghdl -a "$FICHIER_TEST"

echo "[4/5] Élaboration de l'entité ($ENTITE)..."
ghdl -e "$ENTITE"

echo "[5/5] Exécution de la simulation (200ns)..."
ghdl -r "$ENTITE" --vcd=resultats.vcd --stop-time=200ns

echo "Ouverture de GTKWave..."
gtkwave resultats.vcd &

echo "========================================="
echo "   Terminé avec succès !                 "
echo "========================================="
