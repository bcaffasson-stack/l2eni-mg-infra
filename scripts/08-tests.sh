#!/bin/bash
# ============================================================
# ETAPE 8 : Tests de validation
# ============================================================
set -e

echo "============================================="
echo "  ETAPE 8 : Tests de validation"
echo "============================================="

read -p "IP de la VM : " VM_IP
OK=0
FAIL=0

test_ok() {
    echo "  [OK] $1"
    ((OK++))
}

test_fail() {
    echo "  [ECHEC] $1"
    ((FAIL++))
}

echo ""
echo "--- TEST 1 : Hostname ---"
HOSTNAME=$(hostname)
if [ "$HOSTNAME" = "serveur.l2eni.mg" ]; then
    test_ok "Hostname correct : $HOSTNAME"
else
    test_fail "Hostname : $HOSTNAME (attendu: serveur.l2eni.mg)"
fi

echo ""
echo "--- TEST 2 : DNS (BIND9) ---"
for DOMAIN in l2eni.mg appli.l2eni.mg webmail.l2eni.mg mail.l2eni.mg; do
    RESULT=$(dig @localhost $DOMAIN A +short 2>/dev/null)
    if [ "$RESULT" = "$VM_IP" ]; then
        test_ok "DNS $DOMAIN -> $RESULT"
    else
        test_fail "DNS $DOMAIN -> '$RESULT' (attendu: $VM_IP)"
    fi
done

MX=$(dig @localhost l2eni.mg MX +short 2>/dev/null | head -1)
if echo "$MX" | grep -q "mail.l2eni.mg"; then
    test_ok "DNS MX -> $MX"
else
    test_fail "DNS MX -> '$MX'"
fi

echo ""
echo "--- TEST 3 : LDAP (OpenLDAP) ---"
LDAP_TEST=$(ldapsearch -x -H ldap:/// -b "dc=l2eni,dc=mg" "(objectClass=inetOrgPerson)" uid 2>/dev/null | grep "uid:" | wc -l)
if [ "$LDAP_TEST" -ge 3 ]; then
    test_ok "LDAP : $LDAP_TEST utilisateurs trouves"
else
    test_fail "LDAP : seulement $LDAP_TEST utilisateurs (attendu: 3+)"
fi

for USER in admin prof1 etudiant1; do
    if ldapsearch -x -H ldap:/// -b "dc=l2eni,dc=mg" "(uid=$USER)" 2>/dev/null | grep -q "uid: $USER"; then
        test_ok "LDAP user $USER existe"
    else
        test_fail "LDAP user $USER introuvable"
    fi
done

echo ""
echo "--- TEST 4 : SSL (certificats) ---"
for DOMAIN in appli.l2eni.mg webmail.l2eni.mg mail.l2eni.mg; do
    if [ -f "/etc/ssl/l2eni/${DOMAIN}.crt" ]; then
        test_ok "Certificat $DOMAIN present"
    else
        test_fail "Certificat $DOMAIN manquant"
    fi
done

echo ""
echo "--- TEST 5 : Apache2 ---"
if systemctl is-active --quiet apache2; then
    test_ok "Apache2 est actif"
else
    test_fail "Apache2 ne tourne pas"
fi

HTTP_CODE=$(curl -sk -o /dev/null -w "%{http_code}" https://appli.l2eni.mg/ 2>/dev/null)
if [ "$HTTP_CODE" = "200" ]; then
    test_ok "https://appli.l2eni.mg -> HTTP $HTTP_CODE"
else
    test_fail "https://appli.l2eni.mg -> HTTP $HTTP_CODE"
fi

HTTP_CODE=$(curl -sk -o /dev/null -w "%{http_code}" https://webmail.l2eni.mg/ 2>/dev/null)
if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "302" ]; then
    test_ok "https://webmail.l2eni.mg -> HTTP $HTTP_CODE"
else
    test_fail "https://webmail.l2eni.mg -> HTTP $HTTP_CODE"
fi

echo ""
echo "--- TEST 6 : Postfix (SMTP) ---"
if systemctl is-active --quiet postfix; then
    test_ok "Postfix est actif"
else
    test_fail "Postfix ne tourne pas"
fi

echo ""
echo "--- TEST 7 : Dovecot (IMAP) ---"
if systemctl is-active --quiet dovecot; then
    test_ok "Dovecot est actif"
else
    test_fail "Dovecot ne tourne pas"
fi

echo ""
echo "--- TEST 8 : UFW (Pare-feu) ---"
if ufw status | grep -q "active"; then
    test_ok "UFW est actif"
else
    test_fail "UFW n'est pas actif"
fi

echo ""
echo "--- TEST 9 : Auth LDAP depuis PHP ---"
PHP_TEST=$(php -r '
$ldap = ldap_connect("ldap://localhost");
ldap_set_option($ldap, LDAP_OPT_PROTOCOL_VERSION, 3);
if (@ldap_bind($ldap, "uid=admin,ou=people,dc=l2eni,dc=mg", "admin123")) {
    echo "OK";
} else {
    echo "FAIL";
}
ldap_close($ldap);
' 2>/dev/null)
if [ "$PHP_TEST" = "OK" ]; then
    test_ok "Auth LDAP via PHP fonctionne"
else
    test_fail "Auth LDAP via PHP echoue"
fi

echo ""
echo "--- TEST 10 : Auth Dovecot (IMAP) ---"
DOVECOT_TEST=$(doveadm auth test admin admin123 2>/dev/null | tail -1)
if echo "$DOVECOT_TEST" | grep -qi "auth succeeded\|passdb.*auth ok"; then
    test_ok "Auth Dovecot (IMAP) fonctionne"
else
    test_fail "Auth Dovecot (IMAP) echoue : $DOVECOT_TEST"
fi

echo ""
echo "============================================="
echo "  RESULTATS : ${OK} reussis / ${FAIL} echecs"
echo "============================================="

if [ $FAIL -eq 0 ]; then
    echo "  TOUS LES TESTS PASSENT !"
else
    echo "  Certains tests ont echoue. Verifiez les services."
fi
echo ""
