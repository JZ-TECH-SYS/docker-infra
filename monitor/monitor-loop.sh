#!/usr/bin/env bash

set -euo pipefail

LOG_DIR="${LOG_DIR:-/logs}"
INTERVAL="${MONITOR_INTERVAL_SECONDS:-30}"
RETENTION_DAYS="${LOG_RETENTION_DAYS:-14}"
AUTO_HEAL_ENABLED="${AUTO_HEAL_ENABLED:-1}"
AUTO_HEAL_COOLDOWN_SECONDS="${AUTO_HEAL_COOLDOWN_SECONDS:-120}"
STATE_DIR="${STATE_DIR:-/logs/.state}"
LAST_AUTOHEAL_FILE="${STATE_DIR}/last-autoheal-epoch"

mkdir -p "$LOG_DIR"
mkdir -p "$STATE_DIR"

echo "[$(date '+%Y-%m-%dT%H:%M:%S%z')] monitor started (interval=${INTERVAL}s, retention=${RETENTION_DAYS}d, auto_heal=${AUTO_HEAL_ENABLED}, cooldown=${AUTO_HEAL_COOLDOWN_SECONDS}s)"

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
    autoheal_note="autoheal=disabled"
    now_epoch="$(date +%s)"
    last_autoheal_epoch=0
    if [ -f "$LAST_AUTOHEAL_FILE" ]; then
      last_autoheal_epoch="$(cat "$LAST_AUTOHEAL_FILE" 2>/dev/null || echo 0)"
    fi

    if [ "$AUTO_HEAL_ENABLED" = "1" ] || [ "$AUTO_HEAL_ENABLED" = "true" ] || [ "$AUTO_HEAL_ENABLED" = "TRUE" ]; then
      elapsed=$((now_epoch - last_autoheal_epoch))
      if [ "$elapsed" -ge "$AUTO_HEAL_COOLDOWN_SECONDS" ]; then
        fix_ts="$(date '+%Y-%m-%dT%H:%M:%S%z')"
        fix_log="${LOG_DIR}/doctor-autoheal-${day}.log"
        tmp_fix="$(mktemp)"
        fix_exit_code=0

        if NO_COLOR=1 /opt/monitor/doctor.sh --fix >"$tmp_fix" 2>&1; then
          fix_exit_code=0
        else
          fix_exit_code=$?
        fi

        {
          echo "[${fix_ts}] autoheal_start"
          cat "$tmp_fix"
          echo "[$(date '+%Y-%m-%dT%H:%M:%S%z')] autoheal_end exit_code=${fix_exit_code}"
          echo
        } >> "$fix_log"

        {
          echo "[${fix_ts}] incident_autoheal exit_code=${fix_exit_code}"
          cat "$tmp_fix"
          echo
        } >> "$incident_log"

        rm -f "$tmp_fix"
        echo "$now_epoch" > "$LAST_AUTOHEAL_FILE"
        autoheal_note="autoheal=run autoheal_exit_code=${fix_exit_code} autoheal_log=$(basename "$fix_log")"
      else
        autoheal_note="autoheal=skipped cooldown_remaining=$((AUTO_HEAL_COOLDOWN_SECONDS - elapsed))s"
      fi
    fi

    echo "[${run_ts}] run_complete exit_code=${exit_code} incident_log=$(basename "$incident_log") ${autoheal_note}"
  else
    echo "[${run_ts}] run_complete exit_code=0 log=$(basename "$run_log")"
  fi

  rm -f "$tmp_out"

  find "$LOG_DIR" -type f -name 'doctor-*.log' -mtime +"$RETENTION_DAYS" -delete 2>/dev/null || true

  sleep "$INTERVAL"
done
