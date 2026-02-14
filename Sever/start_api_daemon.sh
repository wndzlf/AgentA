#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
API_PID_FILE="/tmp/agenta-api.pid"
API_LOG_FILE="/tmp/agenta-api.log"
OLLAMA_LOG_FILE="/tmp/agenta-ollama.log"

HOST="127.0.0.1"
PORT="8000"
MODEL="${OLLAMA_MODEL:-llama3.2:1b}"

healthcheck() {
  curl -fsS "http://${HOST}:${PORT}/health" >/dev/null 2>&1
}

if healthcheck; then
  echo "[INFO] API already running at http://${HOST}:${PORT}"
  exit 0
fi

if ! command -v ollama >/dev/null 2>&1; then
  echo "[ERROR] ollama가 없습니다. 먼저 설치하세요: brew install ollama"
  exit 1
fi

cd "$ROOT_DIR"

if [ ! -d ".venv" ]; then
  python3 -m venv .venv
fi

source .venv/bin/activate
python -m pip install --upgrade pip >/dev/null
pip install -r requirements.txt >/dev/null

if ! curl -fsS http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
  echo "[INFO] Starting Ollama..."
  nohup ollama serve >"$OLLAMA_LOG_FILE" 2>&1 &
  sleep 2
fi

if ! ollama list | awk '{print $1}' | grep -qx "$MODEL"; then
  echo "[INFO] Pulling model: $MODEL"
  ollama pull "$MODEL" >/dev/null
fi

echo "[INFO] Starting API daemon..."
nohup env OLLAMA_MODEL="$MODEL" .venv/bin/uvicorn \
  agent_server.main:app \
  --host "$HOST" \
  --port "$PORT" >"$API_LOG_FILE" 2>&1 &

echo $! >"$API_PID_FILE"

for _ in $(seq 1 30); do
  if healthcheck; then
    echo "[OK] API is up at http://${HOST}:${PORT}"
    exit 0
  fi
  sleep 1
done

echo "[ERROR] API start failed. Log: $API_LOG_FILE"
tail -n 80 "$API_LOG_FILE" || true
exit 1

