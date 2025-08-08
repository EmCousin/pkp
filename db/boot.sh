#!/bin/bash

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

  # Start PostgreSQL as the postgres user with SSL enabled
  su - postgres -c "postgres -D $PGDATA -c ssl=on -c ssl_cert_file=/var/lib/postgresql/server.crt -c ssl_key_file=/var/lib/postgresql/server.key"
else
  echo "No SSL certificates provided, starting PostgreSQL without SSL..."
  # Start PostgreSQL as the postgres user without SSL
  su - postgres -c "postgres -D $PGDATA"
fi
