#!/bin/bash

# PostgreSQL SSL Certificate Generation using Let's Encrypt DNS Challenge
# This script generates SSL certificates for PostgreSQL using DNS challenge

set -e

# Configuration
DOMAIN="inscriptions.parkourparis.fr"  # Replace with your actual domain
CERT_DIR="/etc/letsencrypt/live/$DOMAIN"
POSTGRES_CERT_DIR="/etc/ssl/postgresql"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Generating PostgreSQL SSL certificates using Let's Encrypt DNS challenge...${NC}"

# Check if certbot is installed
if ! command -v certbot &> /dev/null; then
    echo -e "${RED}Certbot is not installed. Installing...${NC}"
    sudo apt update
    sudo apt install -y certbot
fi

# Create PostgreSQL certificate directory
sudo mkdir -p $POSTGRES_CERT_DIR
sudo chmod 700 $POSTGRES_CERT_DIR

# Generate certificate using DNS challenge
echo -e "${YELLOW}Generating Let's Encrypt certificate for $DOMAIN using DNS challenge...${NC}"
echo -e "${YELLOW}This will require you to add a TXT record to your DNS.${NC}"
echo -e "${YELLOW}Follow the instructions when prompted.${NC}"

sudo certbot certonly --manual --preferred-challenges dns -d $DOMAIN --agree-tos --email emmanuel@hey.com

# Copy certificates to PostgreSQL directory
echo -e "${YELLOW}Copying certificates to PostgreSQL directory...${NC}"
echo -e "${YELLOW}Source directory: $CERT_DIR${NC}"
ls -la $CERT_DIR/

sudo cp $CERT_DIR/fullchain.pem $POSTGRES_CERT_DIR/server.crt
sudo cp $CERT_DIR/privkey.pem $POSTGRES_CERT_DIR/server.key

# Verify both files exist
if [ ! -f "$POSTGRES_CERT_DIR/server.crt" ]; then
    echo -e "${RED}Error: Certificate file not found!${NC}"
    exit 1
fi

if [ ! -f "$POSTGRES_CERT_DIR/server.key" ]; then
    echo -e "${RED}Error: Private key file not found!${NC}"
    exit 1
fi

echo -e "${GREEN}Both certificate and private key files created successfully!${NC}"

# Set proper permissions
# Check if postgres user exists, otherwise use root
if id "postgres" &>/dev/null; then
    sudo chown postgres:postgres $POSTGRES_CERT_DIR/server.key $POSTGRES_CERT_DIR/server.crt
else
    echo -e "${YELLOW}PostgreSQL user not found, using root ownership${NC}"
    sudo chown root:root $POSTGRES_CERT_DIR/server.key $POSTGRES_CERT_DIR/server.crt
fi
sudo chmod 600 $POSTGRES_CERT_DIR/server.key
sudo chmod 644 $POSTGRES_CERT_DIR/server.crt

echo -e "${GREEN}SSL certificates generated successfully!${NC}"
echo -e "${YELLOW}Certificate location: $POSTGRES_CERT_DIR${NC}"
echo -e "${YELLOW}Certificate file: $POSTGRES_CERT_DIR/server.crt${NC}"
echo -e "${YELLOW}Private key file: $POSTGRES_CERT_DIR/server.key${NC}"

# Display certificate info
echo -e "${GREEN}Certificate information:${NC}"
sudo openssl x509 -in $POSTGRES_CERT_DIR/server.crt -text -noout | grep -E "(Subject:|Issuer:|Not Before:|Not After:)"

# Create renewal hook to update PostgreSQL certificates
echo -e "${YELLOW}Creating certbot renewal hook...${NC}"
sudo mkdir -p /etc/letsencrypt/renewal-hooks/post
sudo tee /etc/letsencrypt/renewal-hooks/post/postgresql-renewal.sh > /dev/null << 'EOF'
#!/bin/bash
# Copy renewed certificates to PostgreSQL directory
cp /etc/letsencrypt/live/inscriptions.parkourparis.fr/fullchain.pem /etc/ssl/postgresql/server.crt
cp /etc/letsencrypt/live/inscriptions.parkourparis.fr/privkey.pem /etc/ssl/postgresql/server.key

# Check if postgres user exists, otherwise use root
if id "postgres" &>/dev/null; then
    chown postgres:postgres /etc/ssl/postgresql/server.key /etc/ssl/postgresql/server.crt
else
    chown root:root /etc/ssl/postgresql/server.key /etc/ssl/postgresql/server.crt
fi

chmod 600 /etc/ssl/postgresql/server.key
chmod 644 /etc/ssl/postgresql/server.crt

# Restart PostgreSQL to pick up new certificates (if running as systemd service)
systemctl restart postgresql 2>/dev/null || true
EOF

sudo chmod +x /etc/letsencrypt/renewal-hooks/post/postgresql-renewal.sh

echo -e "${GREEN}Next steps:${NC}"
echo "1. Update your Kamal secrets with the certificate content:"
echo "   POSTGRES_SSL_CERT: $(sudo cat $POSTGRES_CERT_DIR/server.crt | base64 -w 0)"
echo "   POSTGRES_SSL_KEY: $(sudo cat $POSTGRES_CERT_DIR/server.key | base64 -w 0)"
echo "2. Configure PostgreSQL to use SSL certificates"
echo "3. Restart PostgreSQL service"
echo "4. Test certificate renewal: sudo certbot renew --dry-run"
