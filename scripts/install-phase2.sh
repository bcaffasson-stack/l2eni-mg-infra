#!/bin/bash
# ============================================================
#  SCRIPT PRINCIPAL - PHASE 2 (apres reboot)
#  Installe tous les services
# ============================================================
set -e

DIR="$(cd "$(dirname "$0")" && pwd)"

echo ""
echo "###################################################"
echo "#     PHASE 2 : INSTALLATION DES SERVICES         #"
echo "###################################################"
echo ""

if [ "$EUID" -ne 0 ]; then
    echo "ERREUR : Lance en root (sudo su)"
    exit 1
fi

echo "==> ETAPE 1 : Securite du serveur"
bash "${DIR}/01-securite.sh"
echo ""
read -p "Appuie sur Entree pour continuer..."

echo "==> ETAPE 2 : Serveur DNS (BIND9)"
bash "${DIR}/02-dns-bind9.sh"
echo ""
read -p "IMPORTANT : Ajoute l'IP dans le fichier hosts de ton PC Windows !"
read -p "Appuie sur Entree pour continuer..."

echo "==> ETAPE 3 : Certificats SSL auto-signes"
bash "${DIR}/03-ssl-auto-signes.sh"
echo ""
read -p "Appuie sur Entree pour continuer..."

echo "==> ETAPE 4 : Annuaire LDAP"
bash "${DIR}/04-ldap.sh"
echo ""
read -p "Appuie sur Entree pour continuer..."

echo "==> ETAPE 5 : Serveur Mail (Postfix + Dovecot)"
bash "${DIR}/05-mail-postfix-dovecot.sh"
echo ""
read -p "Appuie sur Entree pour continuer..."

echo "==> ETAPE 6 : Apache2 + App Web"
bash "${DIR}/06-apache-app-web.sh"
echo ""
read -p "Appuie sur Entree pour continuer..."

echo "==> ETAPE 7 : Roundcube Webmail"
bash "${DIR}/07-roundcube-webmail.sh"
echo ""
read -p "Appuie sur Entree pour continuer..."

echo "==> ETAPE 8 : Tests de validation"
bash "${DIR}/08-tests.sh"

echo ""
echo "###################################################"
echo "#           INSTALLATION TERMINEE !                #"
echo "###################################################"
echo ""
echo "  Application Web : https://appli.l2eni.mg"
echo "  Webmail         : https://webmail.l2eni.mg"
echo ""
echo "  Utilisateurs :"
echo "    admin@l2eni.mg      / admin123"
echo "    prof1@l2eni.mg      / prof123"
echo "    etudiant1@l2eni.mg  / etudiant123"
echo ""
