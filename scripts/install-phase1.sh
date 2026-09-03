#!/bin/bash
# ============================================================
#  SCRIPT PRINCIPAL D'INSTALLATION
#  Projet L2ENI - Infrastructure complete
#  l2eni.mg
# ============================================================
set -e

DIR="$(cd "$(dirname "$0")" && pwd)"

echo ""
echo "###################################################"
echo "#                                                 #"
echo "#      INSTALLATION INFRASTRUCTURE L2ENI.MG       #"
echo "#                                                 #"
echo "#  Services :                                     #"
echo "#    - DNS (BIND9)                                #"
echo "#    - LDAP (OpenLDAP)                            #"
echo "#    - Mail (Postfix + Dovecot)                   #"
echo "#    - Web App (Apache2 + PHP + Auth LDAP)        #"
echo "#    - Webmail (Roundcube)                        #"
echo "#                                                 #"
echo "###################################################"
echo ""
echo "Appuie sur Entree pour continuer..."
read

# Verification : root
if [ "$EUID" -ne 0 ]; then
    echo "ERREUR : Ce script doit etre lance en root (sudo su)"
    exit 1
fi

# Verification : Debian
if ! grep -q "Debian" /etc/os-release 2>/dev/null; then
    echo "ATTENTION : Ce script est concu pour Debian 12."
    read -p "Continuer quand meme ? (o/n) : " CONT
    if [ "$CONT" != "o" ]; then exit 1; fi
fi

echo ""
echo "==> ETAPE 0 : Configuration reseau + hostname"
bash "${DIR}/00-setup-reseau.sh"
echo ""
echo "Redemarre la VM maintenant, puis relance ce script pour continuer."
echo "  -> sudo reboot"
echo "  Puis reconnecte-toi et relance : sudo bash ${DIR}/install.sh"
exit 0
