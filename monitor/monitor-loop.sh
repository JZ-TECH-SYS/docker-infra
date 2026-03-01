#!/usr/bin/env bash

set -euo pipefail

LOG_DIR="${LOG_DIR:-/logs}"
INTERVAL="${MONITOR_INTERVAL_SECONDS:-30}"
RETENTION_DAYS="${LOG_RETENTION_DAYS:-14}"

mkdir -p "$LOG_DIR"

echo "[$(date '+%Y-%m-%dT%H:%M:%S%z')] monitor started (interval=${INTERVAL}s, retention=${RETENTION_DAYS}d)"

while true; do
  day="$(date +%F)"
  run_ts="$(date '+%Y-%m-%dT%H:%M:%S%z')"
  run_log="${LOG_DIR}/doctor-monitor-${day}.log"
  incident_log="${LOG_DIR}/doctor-incidents-${day}.log"
  tmp_out="$(mktemp)"
  exit_code=0

  if NO_COLOR=1 /opt/monitor/doctor.sh >"$tmp_out" 2>&1; then
    exit_code=0
  else
    exit_code=$?
  fi

  {
    echo "[${run_ts}] run_start"
    cat "$tmp_out"
    echo "[$(date '+%Y-%m-%dT%H:%M:%S%z')] run_end exit_code=${exit_code}"
    echo
  } >> "$run_log"

  if [ "$exit_code" -ne 0 ]; then
    {
      echo "[${run_ts}] incident exit_code=${exit_code}"
      cat "$tmp_out"
      echo
    } >> "$incident_log"
    echo "[${run_ts}] run_complete exit_code=${exit_code} incident_log=$(basename "$incident_log")"
  else
    echo "[${run_ts}] run_complete exit_code=0 log=$(basename "$run_log")"
  fi

  rm -f "$tmp_out"

  find "$LOG_DIR" -type f -name 'doctor-*.log' -mtime +"$RETENTION_DAYS" -delete 2>/dev/null || true

  sleep "$INTERVAL"
done
