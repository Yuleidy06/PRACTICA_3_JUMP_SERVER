#!/bin/bash
# =====================================================
# Practica 4 - WEB-SERVER-CAJA (Sistema de Caja)
# Ubuntu 22.04 - IP 10.9.50.2/29 - Gateway 10.9.50.1
# Autora: Yuleidy Barrientos - 20220949
# =====================================================

# --- Red (archivo /etc/network/interfaces del contenedor en GNS3) ---
# auto eth0
# iface eth0 inet static
#     address 10.9.50.2
#     netmask 255.255.255.248
#     gateway 10.9.50.1

# --- HTTPS: certificado autofirmado y sitio en el puerto 443 ---
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/caja.key -out /etc/ssl/caja.crt -subj "/CN=10.9.50.2"

echo 'server { listen 443 ssl; ssl_certificate /etc/ssl/caja.crt; ssl_certificate_key /etc/ssl/caja.key; root /var/www/html; index index.html index.nginx-debian.html; }' \
  > /etc/nginx/conf.d/https.conf

nginx -t

# --- SSH: permitir acceso por contrasena ---
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config

# --- Iniciar servicios (en el contenedor no arrancan solos) ---
mkdir -p /run/sshd
/usr/sbin/sshd
nginx 2>/dev/null || nginx -s reload

# --- Verificacion ---
ps aux | grep -E "sshd|nginx" | grep -v grep
