$TTL    86400
; === SOA (Start of Authority) ===
;   ns1.l2eni.mg.  = le serveur DNS primaire
;   admin.l2eni.mg = l'adresse email de l'admin (admin@l2eni.mg)
@       IN  SOA     ns1.l2eni.mg. admin.l2eni.mg. (
                    2026081801   ; Serial (AAAA-MM-JJNN)
                    3600        ; Refresh : secondaires verifient toutes les heures
                    1800        ; Retry : reessai apres echec
                    604800      ; Expire : apres 1 semaine, les donnees expirent
                    8640 )      ; Negative TTL : duree de cache des reponses "NXDOMAIN"

; === Nameserver (NS) ===
@           IN  NS      ns1.l2eni.mg.

; === Enregistrements A (adresse IPv4) ===
ns1         IN  A       10.0.2.15
@           IN  A       10.0.2.15
appli       IN  A       10.0.2.15
webmail     IN  A       10.0.2.15
mail        IN  A       10.0.2.15
serveur     IN  A       10.0.2.15

; === Enregistrement MX (mail exchange) ===
; Le MX indique quel serveur recoit le mail pour @l2eni.mg
; La priorite 10 signifie : c'est le serveur principal
@           IN  MX  10  mail.l2eni.mg.

; === CNAME (alias) ===
www         IN  CNAME   l2eni.mg.
monitoring    IN    A    10.0.2.15
