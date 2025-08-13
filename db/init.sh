#!/bin/bash

# Check if the necessary environment variables are set
if [ -z "$POSTGRES_PASSWORD" ] || [ -z "$GRAFANA_POSTGRES_PASSWORD" ]; then
  echo "Required environment variables are not set. Exiting."
  exit 1
fi

# Create a read-only user for Grafana
PGPASSWORD="$POSTGRES_PASSWORD" psql -U rails -d pkp_production <<EOF
CREATE ROLE grafana WITH LOGIN PASSWORD '$GRAFANA_POSTGRES_PASSWORD';
GRANT CONNECT ON DATABASE pkp_production TO grafana;
GRANT USAGE ON SCHEMA public TO grafana;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO grafana;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO grafana;
EOF
