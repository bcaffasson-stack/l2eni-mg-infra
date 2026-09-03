# 🏗️ Infrastructure Réseau Complète — l2eni.mg

> **Mini-datacenter** sur une seule machine virtuelle Debian 13 : site web avec authentification LDAP, serveur de messagerie complet, serveur DNS, et supervision avec alertes automatiques.

![Linux](https://img.shields.io/badge/Debian-13-A81D33?logo=debian&logoColor=white)
![Apache](https://img.shields.io/badge/Apache-2.4-D22128?logo=apache)
![LDAP](https://img.shields.io/badge/OpenLDAP-2.5-blue)
![Postfix](https://img.shields.io/badge/Postfix-3.7-6B8E23)
![Dovecot](https://img.shields.io/badge/Dovecot-2.3-8B0000)
![BIND](https://img.shields.io/badge/BIND9-9.18-critical)
![Grafana](https://img.shields.io/badge/Grafana-11.6-F46800?logo=grafana)
![Prometheus](https://img.shields.io/badge/Prometheus-2.53-E6522C?logo=prometheus)

---

## 🚀 En une phrase

Un projet qui installe **un serveur d'entreprise complet** sur une seule VM : un site web protégé par mot de passe, un serveur de mails (comme un Gmail privé), un DNS pour le domaine `l2eni.mg`, et un tableau de bord qui surveille tout et alerte par mail en cas de panne.

---

## 📦 Les 4 piliers du projet

### 1. 🌐 Site Web avec authentification LDAP — `appli.l2eni.mg`
- Apache2 + PHP avec connexion sécurisée
- **OpenLDAP** : annuaire centralisé des utilisateurs (admin, prof, etudiants)
- Un seul mot de passe pour accéder à tout le système

### 2. 📧 Serveur de messagerie — `webmail.l2eni.mg`
- **Postfix** (SMTP) : envoi/réception des mails
- **Dovecot** (IMAP) : boîtes mail des utilisateurs
- **Roundcube** : interface webmail moderne (thème dark L2ENI)
- **MariaDB** : base de données du webmail

### 3. 🌍 Serveur DNS — `l2eni.mg`
- **BIND9** : résout `appli`, `webmail`, `monitoring`, `mail`, `serveur`, `ns1`
- Gestion de la zone directe + enregistrements MX (mail)

### 4. 📊 Supervision & Alertes — `monitoring.l2eni.mg`
- **Prometheus** : collecte les métriques (CPU, RAM, disque, état des services)
- **Grafana** : tableaux de bord visuels en temps réel
- **Alertmanager** : envoie un mail à `admin@l2eni.mg` si un service tombe (CPU > 80%, RAM > 95%, disque > 90%...)
- **Node Exporter** : capteur système

---

## 🛡️ Sécurité

| Mesure | Rôle |
|---|---|
| **SSL/TLS (mkcert)** | Chiffre toutes les connexions HTTPS |
| **fail2ban** (6 jails) | Bloque les IPs après tentatives échouées |
| **OpenLDAP** | Gestion centralisée des comptes |
| **Security Headers** | Anti-XSS, anti-clickjacking, anti-sniffing |

---

## 📁 Architecture

```
                    ┌──────────────────────────────┐
                    │      VM Debian 13             │
                    │       10.0.2.15               │
                    │                               │
                    │  ┌──────┐  ┌──────┐           │
                    │  │ LDAP │  │ DNS  │           │
                    │  │ :389 │  │ :53  │           │
                    │  └──┬───┘  └──┬───┘           │
                    │     │         │               │
                    │  ┌──┴───┐  ┌──┴────┐           │
                    │  │Postfix│  │Apache │           │
                    │  │ :25   │  │ :443  │           │
                    │  └──┬───┘  └──┬────┘           │
                    │  ┌──┴───┐     │                │
                    │  │Dovecot│    │  ┌──────────┐  │
                    │  │ :143  │    └──┤ Prometheus │ │
                    │  └──────┘        │ :9090    │  │
                    │         ┌─────────┤ ┌────────┐ │
                    │         │ Roundcube│ │ Grafana ││
                    │         │ webmail  │ │ :3000  ││
                    │         └─────────┘ └────┬───┘ │
                    │                  Alertmanager :9093
                    └──────────────────────────────┘
```

---

## 🔑 Identifiants de démonstration

| Service | URL | Login | Mot de passe |
|---|---|---|---|
| Site web | `https://appli.l2eni.mg/` | admin | admin123 |
| Webmail | `https://webmail.l2eni.mg/` | admin | admin123 |
| Supervision | `https://monitoring.l2eni.mg/` | admin | admin123 |

> ⚠️ Le certificat est **auto-signé** (mkcert). Le navigateur affichera un avertissement la première fois — cliquez pour continuer.

---

## 📥 Installation sur votre propre VM

### Prérequis
- [VirtualBox](https://www.virtualbox.org/) + [Debian 13 netinst](https://www.debian.org/)
- 4 GB RAM, 2 CPU, 20 GB disque

### Étape 1 — Préparation Windows
```powershell
# Ajouter les domaines au fichier hosts (en ADMINISTRATEUR)
# C:\Windows\System32\drivers\etc\hosts
10.0.2.15  l2eni.mg appli.l2eni.mg webmail.l2eni.mg mail.l2eni.mg ns1.l2eni.mg
```

### Étape 2 — Copier le projet dans la VM
```
SCP :   scp -r scripts/ beli@IP_VM:/home/beli/
Boîte partagée VirtualBox, ou copier-coller manuel
```

### Étape 3 — Installer (dans la VM)
```bash
# Phase 1 : réseau + hostname
sudo bash scripts/00-setup-reseau.sh
sudo reboot

# Phase 2 : installer tous les services
sudo bash scripts/install-phase2.sh

# OU, étape par étape :
sudo bash scripts/01-securite.sh
sudo bash scripts/02-dns-bind9.sh
sudo bash scripts/03-ssl-auto-signes.sh
sudo bash scripts/04-ldap.sh
sudo bash scripts/05-mail-postfix-dovecot.sh
sudo bash scripts/06-apache-app-web.sh
sudo bash scripts/07-roundcube-webmail.sh
sudo bash scripts/08-tests.sh
```

---

## ✅ Vérification rapide

```bash
# Depuis la VM
systemctl is-active apache2 named postfix dovecot slapd mariadb prometheus grafana-server alertmanager

# DNS
dig @localhost appli.l2eni.mg

# LDAP
ldapsearch -x -b dc=l2eni,dc=mg '(objectClass=person)'

# Depuis Windows (navigateur ou curl)
curl -k https://appli.l2eni.mg/
curl -k https://webmail.l2eni.mg/
curl -k https://monitoring.l2eni.mg/
```

---

## 📁 Structure du dépôt

```
l2eni-mg-infra/
├── scripts/           ← Scripts d'installation (bash)
│   ├── 00-setup-reseau.sh
│   ├── 01-securite.sh
│   ├── 02-dns-bind9.sh
│   ├── 03-ssl-auto-signes.sh
│   ├── 04-ldap.sh
│   ├── 05-mail-postfix-dovecot.sh
│   ├── 06-apache-app-web.sh
│   ├── 07-roundcube-webmail.sh
│   ├── 08-tests.sh
│   └── install-phase*.sh
├── config/            ← Fichiers de configuration réels
│   ├── apache/        ← Vhosts appli, webmail, monitoring
│   ├── dns/           ← Zone l2eni.mg
│   ├── ldap/          ← Schémas LDAP
│   ├── mail/          ← Postfix + Dovecot
│   ├── monitoring/    ← Prometheus + Grafana + Alertmanager
│   └── roundcube/     ← Config webmail
├── templates/         ← Thème dark webmail (login personnalisé)
├── docs/              ← Documentation complète
└── README.md          ← Ce fichier
```

---

## 🛠️ Technologies

| Domaine | Outils |
|---|---|
| **Système** | Debian 13, VirtualBox |
| **Web** | Apache2, PHP, HTML/CSS/JS |
| **Annuaire** | OpenLDAP |
| **Mail** | Postfix, Dovecot, Roundcube, MariaDB |
| **DNS** | BIND9 |
| **Supervision** | Prometheus, Grafana, Alertmanager, Node Exporter |
| **Sécurité** | SSL/TLS (mkcert), fail2ban |

---

## 📜 Licence

Ce projet est sous licence **MIT** — libre d'utilisation et de modification.

---

*Projet pédagogique réalisé par Belco Caffasson RAHARIVONJY — Infrastructure réseau d'entreprise sur un seul serveur.*
