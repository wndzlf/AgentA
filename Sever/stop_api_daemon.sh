#!/usr/bin/env bash
set -euo pipefail

API_PID_FILE="/tmp/agenta-api.pid"
HOST="127.0.0.1"
PORT="8000"

if [ -f "$API_PID_FILE" ]; then
  PID="$(cat "$API_PID_FILE" || true)"
  if [ -n "${PID}" ] && kill -0 "$PID" >/dev/null 2>&1; then
    kill "$PID" >/dev/null 2>&1 || true
    echo "[INFO] Stopped API process: $PID"
  fi
  rm -f "$API_PID_FILE"
fi

# PID 파일 없이 올라간 uvicorn도 정리
pkill -f "uvicorn agent_server.main:app --host ${HOST} --port ${PORT}" >/dev/null 2>&1 || true

if curl -fsS "http://${HOST}:${PORT}/health" >/dev/null 2>&1; then
  echo "[WARN] API still responding on ${HOST}:${PORT}"
  exit 1
fi

echo "[OK] API daemon stopped"

