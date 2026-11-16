#!/bin/sh
# Railway start script for FitTrackee.
# - keeps uploads and the static map cache on one volume (DATA_DIR, default /data)
# - waits for the database, applies migrations (ftcli db upgrade)
# - creates the first owner account once, from FITTRACKEE_ADMIN_* variables
# - runs gunicorn (web) and, when REDIS_URL is set, a Dramatiq worker in the
#   same container, because both need the same uploads volume
set -eu

export FLASK_APP=fittrackee FLASK_SKIP_DOTENV=1
export PORT="${PORT:-5000}"
DATA_DIR="${DATA_DIR:-/data}"
# FitTrackee stores files in "$UPLOAD_FOLDER/uploads".
export UPLOAD_FOLDER="${UPLOAD_FOLDER:-$DATA_DIR}"
export STATICMAP_CACHE_DIR="${STATICMAP_CACHE_DIR:-$DATA_DIR/staticmap_cache}"
export GUNICORN_LOG="${GUNICORN_LOG:--}"

: "${DATABASE_URL:?DATABASE_URL must be set (reference the PostGIS service)}"
: "${APP_SECRET_KEY:?APP_SECRET_KEY must be set}"
: "${UI_URL:?UI_URL must be set, for example https://YOUR-DOMAIN}"
[ -n "${REDIS_URL:-}" ] || unset REDIS_URL

mkdir -p "$UPLOAD_FOLDER" "$STATICMAP_CACHE_DIR"
if [ "$(id -u)" = "0" ]; then
  # Railway volumes are created root-owned; fix ownership once.
  if [ "$(stat -c %u "$DATA_DIR")" != "1000" ] || [ "$(stat -c %u "$STATICMAP_CACHE_DIR")" != "1000" ]; then
    chown -R fittrackee:fittrackee "$DATA_DIR" "$UPLOAD_FOLDER" "$STATICMAP_CACHE_DIR"
  fi
  as_app() { python /usr/local/bin/run-as-app.py "$@"; }
else
  as_app() { "$@"; }
fi

echo "railway-start: waiting for the database"
as_app python - <<'PY'
import os, sys, time
import sqlalchemy as sa
engine = sa.create_engine(os.environ["DATABASE_URL"], pool_pre_ping=True)
for attempt in range(90):
    try:
        with engine.connect() as conn:
            conn.execute(sa.text("SELECT 1"))
        sys.exit(0)
    except Exception as exc:
        print("railway-start: database not ready:", str(exc).strip().splitlines()[0], flush=True)
        time.sleep(2)
sys.exit("railway-start: database still unreachable after 180 s")
PY

echo "railway-start: applying database migrations"
as_app ftcli db upgrade

owners() {
  as_app python - <<'PY'
import os
import sqlalchemy as sa
with sa.create_engine(os.environ["DATABASE_URL"]).connect() as conn:
    print(conn.execute(sa.text("SELECT count(*) FROM users WHERE role = 100")).scalar())
PY
}

if [ "$(owners)" = "0" ]; then
  if [ -n "${FITTRACKEE_ADMIN_EMAIL:-}" ] && [ -n "${FITTRACKEE_ADMIN_PASSWORD:-}" ]; then
    user="${FITTRACKEE_ADMIN_USERNAME:-admin}"
    echo "railway-start: creating the owner account '$user'"
    as_app ftcli users create "$user" --email "$FITTRACKEE_ADMIN_EMAIL" \
      --password "$FITTRACKEE_ADMIN_PASSWORD" --role owner \
      ${FITTRACKEE_ADMIN_LANG:+--lang "$FITTRACKEE_ADMIN_LANG"} \
      ${FITTRACKEE_ADMIN_TZ:+--tz "$FITTRACKEE_ADMIN_TZ"} || true
    if [ "$(owners)" = "0" ]; then
      echo "railway-start: ERROR: the owner account was not created; check FITTRACKEE_ADMIN_USERNAME (3-30 letters, digits or _) and FITTRACKEE_ADMIN_EMAIL, then redeploy" >&2
    fi
  else
    echo "railway-start: no owner account yet; set FITTRACKEE_ADMIN_EMAIL and FITTRACKEE_ADMIN_PASSWORD and redeploy" >&2
  fi
fi

stopping=0
wpid=""
if [ -n "${REDIS_URL:-}" ]; then
  echo "railway-start: starting the Dramatiq worker"
  as_app dramatiq fittrackee.tasks:broker \
    --processes "${WORKERS_PROCESSES:-1}" --threads "${WORKERS_THREADS:-2}" &
  wpid=$!
fi

echo "railway-start: starting gunicorn on port $PORT"
as_app gunicorn -b "[::]:$PORT" "fittrackee:create_app()" \
  --log-level "${LOG_LEVEL:-info}" --error-logfile "$GUNICORN_LOG" \
  --workers "${APP_WORKERS:-2}" --timeout "${APP_TIMEOUT:-120}" --no-control-socket &
gpid=$!

trap 'stopping=1; kill -TERM $gpid $wpid 2>/dev/null || true' TERM INT
while kill -0 "$gpid" 2>/dev/null && { [ -z "$wpid" ] || kill -0 "$wpid" 2>/dev/null; }; do
  sleep 2
done
[ "$stopping" = "1" ] || echo "railway-start: a process exited, stopping the container" >&2
kill -TERM $gpid $wpid 2>/dev/null || true
wait || true
[ "$stopping" = "1" ] && exit 0
exit 1
