#!/bin/bash

# This script is called after PostgreSQL is initialized
# Set the PGDATA variable to the appropriate PostgreSQL data directory
export PGDATA=/var/lib/postgresql/data

# Check if SSL certificates are provided
if [ -n "$POSTGRES_SSL_CERT" ] && [ -n "$POSTGRES_SSL_KEY" ]; then
  echo "SSL certificates provided, configuring PostgreSQL with SSL..."

  # Replace literal '\n' with actual newlines in environment variables
  POSTGRES_SSL_CERT=$(echo "$POSTGRES_SSL_CERT" | sed 's/\\n/\n/g')
  POSTGRES_SSL_KEY=$(echo "$POSTGRES_SSL_KEY" | sed 's/\\n/\n/g')

  echo "$POSTGRES_SSL_CERT" > /var/lib/postgresql/server.crt
  echo "$POSTGRES_SSL_KEY" > /var/lib/postgresql/server.key

  # Set ownership and permissions for SSL files
  chown postgres:postgres /var/lib/postgresql/server.key
  chmod 600 /var/lib/postgresql/server.key
  chown postgres:postgres /var/lib/postgresql/server.crt
  chmod 644 /var/lib/postgresql/server.crt

  # Wait for PostgreSQL to be fully initialized
  echo "Waiting for PostgreSQL to be ready..."
  until pg_isready -h localhost -p 5432; do
    sleep 1
  done

  # Configure SSL in postgresql.conf
  echo "Configuring SSL in postgresql.conf..."
  echo "ssl = on" >> "$PGDATA/postgresql.conf"
  echo "ssl_cert_file = '/var/lib/postgresql/server.crt'" >> "$PGDATA/postgresql.conf"
  echo "ssl_key_file = '/var/lib/postgresql/server.key'" >> "$PGDATA/postgresql.conf"

  # Restart PostgreSQL to apply SSL configuration
  echo "Restarting PostgreSQL to apply SSL configuration..."
  su -s /bin/sh postgres -c "pg_ctl -D '$PGDATA' reload"

  echo "SSL configuration complete."
else
  echo "No SSL certificates provided, PostgreSQL will run without SSL."
fi
