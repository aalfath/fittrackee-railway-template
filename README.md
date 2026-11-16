[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/fittrackee-1?utm_medium=integration&utm_source=button&utm_campaign=fittrackee)

# FitTrackee on Railway

A Railway template for [FitTrackee](https://codeberg.org/FitTrackee/FitTrackee), a self-hosted outdoor activity tracker: upload GPX, FIT, KML or TCX files, see your routes on a map and keep your own statistics.

This repository is what the template builds. Every service except Redis builds from a folder here, so a change merged to `main` reaches everyone who deployed the template as an "update available" notice in their Railway project. Nothing changes until they apply it.

## What it deploys

| Service | Built from | What it does |
|---|---|---|
| **FitTrackee** | [`fittrackee/`](fittrackee/) | `fittrackee/fittrackee:v1.3.8` pinned by digest. Runs the web app (gunicorn) and a Dramatiq worker in one container, because both need the uploads volume. Volume at `/data` (uploaded workouts, pictures, exports, static map cache). Health check `/api/ping`. |
| **PostGIS** | [`postgis/`](postgis/) | `postgis/postgis:18-3.7` pinned by digest (PostgreSQL 18, PostGIS 3.7). FitTrackee needs PostGIS. Volume at `/var/lib/postgresql`, TLS on the private network, no public port. |
| **Redis** | Railway's Redis | Queue for the worker (data exports, workout archive uploads, emails) and API rate limits. |

On first boot the start script waits for the database, runs `ftcli db upgrade`, and creates one **owner** account from `FITTRACKEE_ADMIN_EMAIL`, `FITTRACKEE_ADMIN_USERNAME` and the generated `FITTRACKEE_ADMIN_PASSWORD`. There is no default password. On later boots it only applies migrations.

## Variables (FitTrackee service)

| Variable | Default | Notes |
|---|---|---|
| `FITTRACKEE_ADMIN_EMAIL` | *(you enter it)* | Email of the owner account, used to log in |
| `FITTRACKEE_ADMIN_USERNAME` | `admin` | 3–30 letters, digits or `_` |
| `FITTRACKEE_ADMIN_PASSWORD` | generated | Read it in the service's Variables tab. Only used to create the account; change it in the app afterwards |
| `APP_SECRET_KEY` | generated | Signs login tokens |
| `UI_URL` | `https://${{RAILWAY_PUBLIC_DOMAIN}}` | Change it if you add a custom domain |
| `DATABASE_URL` | `${{PostGIS.DATABASE_URL}}` | |
| `REDIS_URL` | `${{Redis.REDIS_URL}}` | |
| `API_RATE_LIMITS` | `300 per 5 minutes` | Empty value turns rate limits off |
| `PORT` | `5000` | |

Optional, add them yourself when you need them ([FitTrackee docs](https://docs.fittrackee.org/en/installation/environments_variables.html)):

- **Email** (account confirmation, password reset): `EMAIL_URL` (for example `smtp://user:password@smtp.example.com:587?tls=True`) and `SENDER_EMAIL`.
- **Weather**: `WEATHER_API_PROVIDER=visualcrossing` and `WEATHER_API_KEY`.
- **Maps and elevation**: `TILE_SERVER_URL`, `MAP_ATTRIBUTION`, `STATICMAP_SUBDOMAINS`, `OPEN_ELEVATION_API_URL`, `VALHALLA_API_URL`.
- Tuning: `APP_WORKERS` (gunicorn workers, default 2), `APP_TIMEOUT` (default 120 s), `WORKERS_PROCESSES` / `WORKERS_THREADS` (Dramatiq, default 1 / 2).

## Registration

Registration is open by default, as upstream ships it. Without email settings, new accounts stay inactive until an admin activates them (Admin > Users, or `ftcli users update USERNAME --activate` in the service shell). To close registration, go to Admin > Application and turn it off.

## Updates

The FitTrackee and PostGIS images are pinned by version and digest in each folder's `Dockerfile`. Version bumps land here through a pull request with a [`CHANGELOG.md`](CHANGELOG.md) entry, after a test deploy. Read the changelog before you apply an update in Railway. FitTrackee applies its own database migrations on start; back up the database before a FitTrackee update that includes migrations. PostgreSQL major upgrades (for example 18 to 19) need a dump and restore and will be called out first in the changelog.

## Local run

```sh
docker build -t fittrackee-railway fittrackee
docker build -t fittrackee-postgis postgis
```

Then run them with the variables above (see `fittrackee/railway-start.sh` for every setting the start script fills in).

## License

The wrapper files in this repository are MIT licensed. FitTrackee is AGPL-3.0, PostGIS is GPL-2.0, PostgreSQL uses the PostgreSQL License.
