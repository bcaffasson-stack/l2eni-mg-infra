#!/bin/bash
# ============================================================
# ETAPE 6 : Apache2 + PHP + Application Web avec Auth LDAP
# ============================================================
set -e

echo "============================================="
echo "  ETAPE 6 : Apache2 + App Web (Auth LDAP)"
echo "============================================="

read -p "Mot de passe admin LDAP : " LDAP_ADMIN_PASS
SSL_DIR="/etc/ssl/l2eni"

# [1/5] Installer Apache2 + PHP
echo "[1/5] Installation de Apache2 + PHP..."
apt install -y apache2 libapache2-mod-php php php-ldap php-mysql php-gd php-xml php-mbstring php-curl php-intl php-zip

# [2/5] Activer les modules Apache
echo "[2/5] Activation des modules Apache..."
a2enmod authnz_ldap ldap rewrite ssl headers
a2dissite 000-default.conf 2>/dev/null || true

# [3/5] Creer le VirtualHost pour appli.l2eni.mg
echo "[3/5] Creation du VirtualHost appli.l2eni.mg..."

# Creer le dossier de l'application
mkdir -p /var/www/appli
chown -R www-data:www-data /var/www/appli

cat > /etc/apache2/sites-available/appli-l2eni-mg.conf <<EOF
<VirtualHost *:80>
    ServerName appli.l2eni.mg
    Redirect permanent / https://appli.l2eni.mg/
</VirtualHost>

<VirtualHost *:443>
    ServerName appli.l2eni.mg
    DocumentRoot /var/www/appli

    SSLEngine on
    SSLCertificateFile    ${SSL_DIR}/appli.l2eni.mg.crt
    SSLCertificateKeyFile ${SSL_DIR}/appli.l2eni.mg.key
    SSLCertificateChainFile ${SSL_DIR}/ca.crt

    <Directory /var/www/appli>
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/appli-error.log
    CustomLog \${APACHE_LOG_DIR}/appli-access.log combined
</VirtualHost>
EOF

a2ensite appli-l2eni-mg.conf

# [4/5] Creer l'application web (login + dashboard)
echo "[4/5] Creation de l'application web..."

# --- index.php (page de login) ---
cat > /var/www/appli/index.php <<'PHPEOF'
<?php
session_start();

// Si deja connecte, rediriger vers dashboard
if (isset($_SESSION['user'])) {
    header('Location: dashboard.php');
    exit;
}

$error = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $uid = trim($_POST['uid'] ?? '');
    $pass = $_POST['pass'] ?? '';

    // Connexion LDAP
    $ldap = ldap_connect("ldap://localhost");
    ldap_set_option($ldap, LDAP_OPT_PROTOCOL_VERSION, 3);

    $bind_dn = "uid={$uid},ou=people,dc=l2eni,dc=mg";
    
    if (@ldap_bind($ldap, $bind_dn, $pass)) {
        // Recuperer les infos de l'utilisateur
        $search = ldap_search($ldap, "ou=people,dc=l2eni,dc=mg", "(uid={$uid})", ["cn", "sn", "mail", "uid"]);
        $entries = ldap_get_entries($ldap, $search);
        
        if ($entries['count'] > 0) {
            $_SESSION['user'] = $uid;
            $_SESSION['cn'] = $entries[0]['cn'][0] ?? $uid;
            $_SESSION['mail'] = $entries[0]['mail'][0] ?? '';
            $_SESSION['sn'] = $entries[0]['sn'][0] ?? '';
            header('Location: dashboard.php');
            exit;
        }
    }
    $error = "Identifiants incorrects !";
    ldap_close($ldap);
}
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>L2ENI - Connexion</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, sans-serif;
            background: linear-gradient(135deg, #0f2027, #203a43, #2c5364);
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
        }
        .login-box {
            background: white;
            padding: 40px;
            border-radius: 12px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            width: 400px;
        }
        .login-box h1 {
            text-align: center;
            color: #2c5364;
            margin-bottom: 10px;
            font-size: 24px;
        }
        .login-box .subtitle {
            text-align: center;
            color: #666;
            margin-bottom: 30px;
            font-size: 14px;
        }
        .form-group { margin-bottom: 20px; }
        .form-group label {
            display: block;
            margin-bottom: 6px;
            color: #333;
            font-weight: 600;
        }
        .form-group input {
            width: 100%;
            padding: 12px;
            border: 2px solid #ddd;
            border-radius: 8px;
            font-size: 15px;
            transition: border-color 0.3s;
        }
        .form-group input:focus {
            outline: none;
            border-color: #2c5364;
        }
        .btn {
            width: 100%;
            padding: 14px;
            background: #2c5364;
            color: white;
            border: none;
            border-radius: 8px;
            font-size: 16px;
            cursor: pointer;
            font-weight: 600;
        }
        .btn:hover { background: #1a3a4a; }
        .error {
            background: #fee;
            color: #c00;
            padding: 10px;
            border-radius: 6px;
            margin-bottom: 15px;
            text-align: center;
        }
        .footer {
            text-align: center;
            margin-top: 20px;
            color: #999;
            font-size: 12px;
        }
    </style>
</head>
<body>
    <div class="login-box">
        <h1>L2ENI</h1>
        <p class="subtitle">Application de Gestion - Authentification LDAP</p>
        <?php if ($error): ?>
            <div class="error"><?php echo htmlspecialchars($error); ?></div>
        <?php endif; ?>
        <form method="POST">
            <div class="form-group">
                <label>Identifiant</label>
                <input type="text" name="uid" required placeholder="Votre identifiant" autofocus>
            </div>
            <div class="form-group">
                <label>Mot de passe</label>
                <input type="password" name="pass" required placeholder="Votre mot de passe">
            </div>
            <button type="submit" class="btn">Se connecter</button>
        </form>
        <p class="footer">Authentification via annuaire LDAP - l2eni.mg</p>
    </div>
</body>
</html>
PHPEOF

# --- dashboard.php (page protegee) ---
cat > /var/www/appli/dashboard.php <<'PHPEOF'
<?php
session_start();
if (!isset($_SESSION['user'])) {
    header('Location: index.php');
    exit;
}
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>L2ENI - Tableau de bord</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, sans-serif;
            background: #f0f2f5;
        }
        .navbar {
            background: #2c5364;
            color: white;
            padding: 15px 30px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .navbar h1 { font-size: 20px; }
        .navbar a {
            color: white;
            text-decoration: none;
            background: rgba(255,255,255,0.15);
            padding: 8px 16px;
            border-radius: 6px;
        }
        .container { max-width: 900px; margin: 40px auto; padding: 0 20px; }
        .card {
            background: white;
            border-radius: 12px;
            padding: 30px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.08);
            margin-bottom: 20px;
        }
        .card h2 { color: #2c5364; margin-bottom: 15px; }
        .info-row {
            display: flex;
            padding: 10px 0;
            border-bottom: 1px solid #eee;
        }
        .info-row .label { font-weight: 600; width: 150px; color: #666; }
        .info-row .value { color: #333; }
        .welcome {
            font-size: 22px;
            color: #2c5364;
            margin-bottom: 5px;
        }
        .links { display: flex; gap: 15px; margin-top: 20px; }
        .links a {
            display: inline-block;
            padding: 12px 24px;
            background: #2c5364;
            color: white;
            text-decoration: none;
            border-radius: 8px;
            font-weight: 600;
        }
        .links a:hover { background: #1a3a4a; }
        .links a.red { background: #c0392b; }
    </style>
</head>
<body>
    <div class="navbar">
        <h1>L2ENI - Application Web</h1>
        <a href="logout.php">Deconnexion</a>
    </div>
    <div class="container">
        <div class="card">
            <p class="welcome">Bienvenue, <?php echo htmlspecialchars($_SESSION['cn']); ?> !</p>
            <p style="color:#666;">Vous etes connecte via l'annuaire LDAP.</p>
        </div>
        <div class="card">
            <h2>Vos informations (LDAP)</h2>
            <div class="info-row">
                <span class="label">Identifiant :</span>
                <span class="value"><?php echo htmlspecialchars($_SESSION['user']); ?></span>
            </div>
            <div class="info-row">
                <span class="label">Nom complet :</span>
                <span class="value"><?php echo htmlspecialchars($_SESSION['cn']); ?></span>
            </div>
            <div class="info-row">
                <span class="label">Email :</span>
                <span class="value"><?php echo htmlspecialchars($_SESSION['mail']); ?></span>
            </div>
        </div>
        <div class="links">
            <a href="https://webmail.l2eni.mg/">Webmail L2ENI</a>
            <a href="logout.php" class="red">Deconnexion</a>
        </div>
    </div>
</body>
</html>
PHPEOF

# --- logout.php ---
cat > /var/www/appli/logout.php <<'PHPEOF'
<?php
session_start();
session_destroy();
header('Location: index.php');
exit;
?>
PHPEOF

chown -R www-data:www-data /var/www/appli

# [5/5] Redemarrer Apache et tester
echo "[5/5] Redemarrage d'Apache..."
apachectl -t
systemctl restart apache2
systemctl enable apache2

echo ""
echo "============================================="
echo "  ETAPE 6 TERMINEE !"
echo "  URL : https://appli.l2eni.mg"
echo "  Auth : LDAP (utilisateurs l2eni.mg)"
echo "  Login    : admin / admin123"
echo "  Login    : prof1 / prof123"
echo "  Login    : etudiant1 / etudiant123"
echo "============================================="
