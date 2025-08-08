# #!/bin/bash

# if [ -z "$POSTGRES_SSL_CERT" ] || [ -z "$POSTGRES_SSL_KEY" ]; then
#   echo "Required certificates environment variables are not set. Exiting."
#   exit 1
# fi

# # Replace literal '\n' with actual newlines in environment variables
# POSTGRES_SSL_CERT=$(echo "$POSTGRES_SSL_CERT" | sed 's/\\n/\n/g')
# POSTGRES_SSL_KEY=$(echo "$POSTGRES_SSL_KEY" | sed 's/\\n/\n/g')

# echo "$POSTGRES_SSL_CERT" > /var/lib/postgresql/server.crt
# echo "$POSTGRES_SSL_KEY" > /var/lib/postgresql/server.key

# # Set ownership and permissions for SSL files
# chown postgres:postgres /var/lib/postgresql/server.key
# chmod 600 /var/lib/postgresql/server.key
# chown postgres:postgres /var/lib/postgresql/server.crt
# chmod 644 /var/lib/postgresql/server.crt

# # Set the PGDATA variable to the appropriate PostgreSQL data directory
# export PGDATA=/var/lib/postgresql/data

# # Start PostgreSQL as the postgres user with SSL enabled
# su - postgres -c "postgres -D $PGDATA -c ssl=on -c ssl_cert_file=/var/lib/postgresql/server.crt -c ssl_key_file=/var/lib/postgresql/server.key"
