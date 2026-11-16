# FitTrackee 1.3.8, official image pinned by digest (Docker Hub, linux/amd64 + arm64).
FROM fittrackee/fittrackee:v1.3.8@sha256:b17f9d4c01d0987ed2080ee48be4f7fff57a812fbc8d490a99cb44df82cc20a3

# The start script runs as root only long enough to make the Railway volume
# writable, then drops to the image's own "fittrackee" user (run-as-app.py).
USER root
COPY railway-start.sh run-as-app.py /usr/local/bin/
RUN chmod 0755 /usr/local/bin/railway-start.sh && chmod 0644 /usr/local/bin/run-as-app.py

ENV FLASK_APP=fittrackee \
    FLASK_SKIP_DOTENV=1 \
    PORT=5000

EXPOSE 5000
ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/railway-start.sh"]
