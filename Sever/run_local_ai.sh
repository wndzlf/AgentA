#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT_DIR"

if ! command -v ollama >/dev/null 2>&1; then
  echo "[ERROR] ollama가 설치되어 있지 않습니다. 먼저 설치하세요."
  echo "        brew install ollama"
  exit 1
fi

if [ ! -d ".venv" ]; then
  python3 -m venv .venv
fi

source .venv/bin/activate
python -m pip install --upgrade pip >/dev/null
pip install -r requirements.txt >/dev/null

if ! curl -fsS http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
  echo "[INFO] Ollama 서버를 시작합니다..."
  nohup ollama serve >/tmp/agenta-ollama.log 2>&1 &
  sleep 2
fi

MODEL="${OLLAMA_MODEL:-llama3.2:1b}"

if ! ollama list | awk '{print $1}' | grep -qx "$MODEL"; then
  echo "[INFO] Ollama 모델을 다운로드합니다: $MODEL"
  ollama pull "$MODEL"
fi

echo "[INFO] API 서버 시작: http://127.0.0.1:8000"
echo "[INFO] 사용 모델: $MODEL"
OLLAMA_MODEL="$MODEL" uvicorn agent_server.main:app --host 127.0.0.1 --port 8000 --reload
