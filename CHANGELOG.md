# Changelog

## 1.3.8 (2026-11-16)

First release.

- FitTrackee 1.3.8: `fittrackee/fittrackee:v1.3.8@sha256:b17f9d4c01d0987ed2080ee48be4f7fff57a812fbc8d490a99cb44df82cc20a3`.
- PostGIS 3.7.0 on PostgreSQL 18: `postgis/postgis:18-3.7@sha256:fe440a27c6567aefa932e988962e5827bb2c29e4b97dac2ca5268f5eafe10262`, wrapper from `aalfath/postgis-railway-template` (TLS, fast shutdown) with smaller memory defaults (`shared_buffers=128MB`).
- Web app and Dramatiq worker in one container sharing the `/data` volume; the worker starts when `REDIS_URL` is set.
- First boot creates the owner account from `FITTRACKEE_ADMIN_*` variables; no default password.
- Logs go to stdout (`GUNICORN_LOG=-`, no `APP_LOG`).
