#!/bin/bash
# ============================================================
# ETAPE 4 : Annuaire LDAP (OpenLDAP / slapd)
# ============================================================
set -e

echo "============================================="
echo "  ETAPE 4 : Annuaire LDAP (OpenLDAP)"
echo "============================================="

read -p "Mot de passe admin LDAP (sera utilise partout) : " LDAP_ADMIN_PASS

# [1/4] Installer slapd
echo "[1/4] Installation de slapd..."
export DEBIAN_FRONTEND=noninteractive
apt install -y slapd ldap-utils

# [2/4] Reconfigurer slapd avec nos parametres
echo "[2/4] Reconfiguration de slapd..."
cat > /tmp/slapd-preseed.cfg <<EOF
slapd slapd/internal/generated_adminpw password ${LDAP_ADMIN_PASS}
slapd slapd/internal/adminpw password ${LDAP_ADMIN_PASS}
slapd slapd/password1 password ${LDAP_ADMIN_PASS}
slapd slapd/password2 password ${LDAP_ADMIN_PASS}
slapd slapd/domain string l2eni.mg
slapd shared/organization string L2ENI
slapd slapd/purge_database boolean true
slapd slapd/move_old_database boolean true
slapd slapd/no_configuration boolean false
slapd slapd/backend select MDB
EOF
debconf-set-selections /tmp/slapd-preseed.cfg
dpkg-reconfigure -f noninteractive slapd

# [3/4] Creer la structure LDAP (ou=people, ou=groups)
echo "[3/4] Creation de la structure LDAP..."

LDAP_BASE="dc=l2eni,dc=mg"
LDAP_CN="cn=admin,${LDAP_BASE}"

cat > /tmp/structure.ldif <<EOF
# Organizational Units
dn: ou=people,${LDAP_BASE}
objectClass: organizationalUnit
ou: people

dn: ou=groups,${LDAP_BASE}
objectClass: organizationalUnit
ou: groups
EOF

ldapadd -x -D "${LDAP_CN}" -w "${LDAP_ADMIN_PASS}" -f /tmp/structure.ldif || echo "(structure deja existante, OK)"

# [4/4] Creer les utilisateurs de test
echo "[4/4] Creation des utilisateurs de test..."

# Fonction pour creer un user LDAP
creer_user() {
    local UID_NAME=$1
    local CN=$2
    local SN=$3
    local MAIL=$4
    local PASS=$5
    local UID_NUM=$6

    HASH=$(slappasswd -s "${PASS}")

    cat > /tmp/user-${UID_NAME}.ldif <<EOF
dn: uid=${UID_NAME},ou=people,${LDAP_BASE}
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
uid: ${UID_NAME}
cn: ${CN}
sn: ${SN}
givenName: ${CN}
mail: ${MAIL}
userPassword: ${HASH}
uidNumber: ${UID_NUM}
gidNumber: 1000
homeDirectory: /home/${UID_NAME}
loginShell: /bin/bash
EOF

    ldapadd -x -D "${LDAP_CN}" -w "${LDAP_ADMIN_PASS}" -f /tmp/user-${UID_NAME}.ldif && \
        echo "  -> User ${UID_NAME} cree (${MAIL})" || echo "  -> User ${UID_NAME} deja existe"
}

creer_user "admin"     "Admin"     "L2ENI"    "admin@l2eni.mg"     "admin123"     "1001"
creer_user "prof1"     "Prof"      "Andry"    "prof1@l2eni.mg"     "prof123"      "1002"
creer_user "etudiant1" "Etudiant"  "Rakoto"   "etudiant1@l2eni.mg" "etudiant123"  "1003"

# Verification
echo ""
echo "Verification des utilisateurs LDAP :"
echo "---"
ldapsearch -x -H ldap:/// -b "ou=people,${LDAP_BASE}" "(objectClass=inetOrgPerson)" uid mail cn
echo "---"

# Creer le home directory
mkdir -p /home/admin /home/prof1 /home/etudiant1
chown -R 1000:1000 /home/admin /home/prof1 /home/etudiant1

echo ""
echo "============================================="
echo "  ETAPE 4 TERMINEE !"
echo "  Base DN     : ${LDAP_BASE}"
echo "  Admin DN    : ${LDAP_CN}"
echo "  Mot de passe : ${LDAP_ADMIN_PASS}"
echo ""
echo "  Users crees :"
echo "    admin@l2eni.mg     (MDP: admin123)"
echo "    prof1@l2eni.mg     (MDP: prof123)"
echo "    etudiant1@l2eni.mg (MDP: etudiant123)"
echo "============================================="
