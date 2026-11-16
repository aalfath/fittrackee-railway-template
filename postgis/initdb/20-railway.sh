#!/bin/bash
# Runs once, when the database is first created (docker-entrypoint-initdb.d),
# after the image's 10_postgis.sh. Stores memory settings with ALTER SYSTEM
# (postgresql.auto.conf), so they can be changed later with ALTER SYSTEM and a restart.
set -euo pipefail

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<SQL
ALTER SYSTEM SET shared_buffers = '${PG_SHARED_BUFFERS:-128MB}';
ALTER SYSTEM SET effective_cache_size = '${PG_EFFECTIVE_CACHE_SIZE:-512MB}';
ALTER SYSTEM SET maintenance_work_mem = '${PG_MAINTENANCE_WORK_MEM:-64MB}';
ALTER SYSTEM SET work_mem = '${PG_WORK_MEM:-8MB}';
SQL
echo "postgis: postgis ready in ${POSTGRES_DB}"
