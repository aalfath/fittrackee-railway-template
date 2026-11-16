# PostGIS 3.7.0 on PostgreSQL 18 (Debian trixie), official image pinned by digest.
# Same wrapper as aalfath/postgis-railway-template. FitTrackee needs PostGIS.
FROM postgis/postgis:18-3.7@sha256:fe440a27c6567aefa932e988962e5827bb2c29e4b97dac2ca5268f5eafe10262

# PostgreSQL 18 data layout. Mount the Railway volume at /var/lib/postgresql.
ENV PGDATA=/var/lib/postgresql/18/docker

# The image's own 10_postgis.sh creates the postgis extension in POSTGRES_DB on
# first start (it is sourced, so it stays non-executable); 20-railway.sh sets
# memory defaults sized for a small FitTrackee database.
COPY initdb/ /docker-entrypoint-initdb.d/
COPY railway-entrypoint.sh /usr/local/bin/railway-entrypoint.sh
RUN chmod 0755 /usr/local/bin/railway-entrypoint.sh /docker-entrypoint-initdb.d/20-railway.sh

EXPOSE 5432
ENTRYPOINT ["/usr/local/bin/railway-entrypoint.sh"]
CMD []
