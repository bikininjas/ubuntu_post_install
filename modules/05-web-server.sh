#!/bin/bash

################################################################################
# Module 05 - Serveur Web
# Description: Nginx + configuration pour WordPress et Node.js
################################################################################

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

if [[ "${EUID}" -ne 0 ]]; then 
    log_error "Ce script doit être exécuté en tant que root"
    exit 1
fi

log_info "=== Installation du Serveur Web ==="

# Charger la configuration du domaine si disponible
DOMAIN_CONFIG_FILE="/etc/server-domain.conf"
if [[ -f "${DOMAIN_CONFIG_FILE}" ]]; then
    # shellcheck disable=SC1090
    source "${DOMAIN_CONFIG_FILE}"
    log_info "Configuration du domaine chargée : ${SERVER_DOMAIN}"
    DOMAIN_CONFIGURED=true
else
    log_warning "Aucun domaine configuré, utilisation de la configuration par défaut"
    SERVER_DOMAIN="localhost"
    WWW_DOMAIN="www.localhost"
    DOMAIN_CONFIGURED=false
fi

# 1. Installation de Nginx
log_info "Installation de Nginx..."
apt update
DEBIAN_FRONTEND=noninteractive apt install -y nginx

# Démarrer et activer Nginx
systemctl start nginx
systemctl enable nginx

log_info "✓ Nginx installé"
nginx -v

# 2. Installation de PHP (pour WordPress)
log_info "Installation de PHP-FPM pour WordPress..."
DEBIAN_FRONTEND=noninteractive apt install -y php-fpm php-mysql php-curl php-gd php-mbstring php-xml php-xmlrpc php-soap php-intl php-zip

log_info "✓ PHP-FPM installé"
php -v

# 3. Créer une structure de dossiers pour les sites
log_info "Création de la structure pour les sites web..."
mkdir -p /var/www/html
mkdir -p /var/www/sites-available
mkdir -p /var/www/logs

# 4. Configuration Nginx de base
log_info "Configuration de Nginx..."

# Sauvegarde de la config par défaut
cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup

# Configuration optimisée
cat > /etc/nginx/nginx.conf << 'EOF'
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
    worker_connections 768;
    multi_accept on;
}

http {
    ##
    # Basic Settings
    ##
    sendfile on;
    tcp_nopush on;
    types_hash_max_size 2048;
    server_tokens off;
    
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    ##
    # SSL Settings
    ##
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;

    ##
    # Logging Settings
    ##
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    ##
    # Gzip Settings
    ##
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript application/json application/javascript application/xml+rss application/rss+xml font/truetype font/opentype application/vnd.ms-fontobject image/svg+xml;

    ##
    # Virtual Host Configs
    ##
    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
EOF

# 5. Créer une configuration par défaut avec le domaine configuré
if [[ "${DOMAIN_CONFIGURED}" == true ]]; then
    log_info "Création de la configuration Nginx pour ${SERVER_DOMAIN}..."
    
    cat > /etc/nginx/sites-available/default << EOF
# Configuration par défaut pour ${SERVER_DOMAIN}
# Généré automatiquement

server {
    listen 80 default_server;
    listen [::]:80 default_server;
    
    server_name ${SERVER_DOMAIN} ${WWW_DOMAIN};
    root /var/www/html;
    
    index index.html index.htm index.nginx-debian.html index.php;
    
    # Logs
    access_log /var/www/logs/access.log;
    error_log /var/www/logs/error.log;
    
    location / {
        try_files \$uri \$uri/ =404;
    }
    
    # PHP support (si activé)
    location ~ \\.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php-fpm.sock;
    }
    
    # Deny access to .htaccess
    location ~ /\\.ht {
        deny all;
    }
}
EOF

    # Activer le site
    ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default
    log_info "✓ Configuration par défaut créée pour ${SERVER_DOMAIN}"
fi

# 6. Créer un exemple de configuration pour WordPress
log_info "Création d'un template pour WordPress..."
cat > /etc/nginx/sites-available/wordpress-template << EOF
# Configuration WordPress Template
# Copiez ce fichier et modifiez selon vos besoins

server {
    listen 80;
    listen [::]:80;
    
    server_name ${SERVER_DOMAIN:-example.com} ${WWW_DOMAIN:-www.example.com};
    root /var/www/html/wordpress;
    
    index index.php index.html index.htm;
    
    # Logs
    access_log /var/www/logs/wordpress-access.log;
    error_log /var/www/logs/wordpress-error.log;
    
    # WordPress permalinks
    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }
    
    # PHP-FPM
    location ~ \\.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
EOF

# Continuer le template WordPress
cat >> /etc/nginx/sites-available/wordpress-template << 'EOF'
    
    # Deny access to .htaccess files
    location ~ /\.ht {
        deny all;
    }
    
    # Cache static files
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
}
EOF

# 6. Créer un exemple de configuration pour Node.js (reverse proxy)
log_info "Création d'un template pour Node.js..."
cat > /etc/nginx/sites-available/nodejs-template << 'EOF'
# Configuration Node.js Template (Reverse Proxy)
# Copiez ce fichier et modifiez server_name et le port

server {
    listen 80;
    listen [::]:80;
    
    server_name node-app.example.com;
    
    # Logs
    access_log /var/www/logs/nodejs-access.log;
    error_log /var/www/logs/nodejs-error.log;
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# 7. Page d'accueil par défaut
log_info "Création d'une page d'accueil..."
cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Serveur Ubuntu Configuré</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 50px auto;
            padding: 20px;
            background: #f4f4f4;
        }
        .container {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 0 10px rgba(0,0,0,0.1);
        }
        h1 { color: #333; }
        .success { color: #28a745; }
        ul { line-height: 1.8; }
    </style>
</head>
<body>
    <div class="container">
        <h1>✓ Serveur Web Nginx Configuré</h1>
        <p class="success">Le serveur fonctionne correctement!</p>
        
        <h2>Services installés:</h2>
        <ul>
            <li>Nginx</li>
            <li>PHP-FPM (pour WordPress)</li>
            <li>Templates de configuration disponibles</li>
        </ul>
        
        <h2>Prochaines étapes:</h2>
        <ul>
            <li>Configurer vos sites dans /etc/nginx/sites-available/</li>
            <li>Activer les sites avec: <code>ln -s /etc/nginx/sites-available/mon-site /etc/nginx/sites-enabled/</code></li>
            <li>Tester la configuration: <code>nginx -t</code></li>
            <li>Recharger Nginx: <code>systemctl reload nginx</code></li>
        </ul>
    </div>
</body>
</html>
EOF

# 8. Tester et recharger Nginx
log_info "Test de la configuration Nginx..."
nginx -t

systemctl reload nginx

log_info "=== Module Serveur Web Terminé ==="
echo ""
echo -e "${GREEN}Nginx:${NC} $(nginx -v 2>&1)"
echo -e "${GREEN}PHP:${NC} $(php -v | head -n1)"
echo ""
echo -e "${YELLOW}Templates disponibles:${NC}"
echo "  - /etc/nginx/sites-available/wordpress-template"
echo "  - /etc/nginx/sites-available/nodejs-template"
echo ""
echo -e "${YELLOW}Commandes utiles:${NC}"
echo "  - Tester la config: nginx -t"
echo "  - Recharger Nginx: systemctl reload nginx"
echo "  - Logs: /var/log/nginx/"
echo ""

exit 0
