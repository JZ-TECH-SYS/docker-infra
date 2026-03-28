#!/bin/sh
set -eu

if [ -f /pgadmin4/pgpass ]; then
  cp /pgadmin4/pgpass /var/lib/pgadmin/.pgpass
  chmod 600 /var/lib/pgadmin/.pgpass
fi

/entrypoint.sh "$@" &
child_pid=$!

sleep 20

/venv/bin/python3 /pgadmin4/bootstrap_pgadmin.py || true

trap 'kill -TERM "$child_pid" 2>/dev/null || true' INT TERM
wait "$child_pid"
