# Sever API Prototype

`Sever` 폴더명은 기존 프로젝트 구조를 그대로 사용했습니다.

## 1) 빠른 실행 (권장)

```bash
cd /Users/user/AgentA/Sever
./run_local_ai.sh
```

이 스크립트는 아래를 자동으로 처리합니다.

- `.venv` 생성 및 의존성 설치
- Ollama 서버 기동 확인
- 무료 모델(`llama3.2:1b`) 자동 다운로드
- FastAPI 서버 실행 (`127.0.0.1:8000`)

## 2) 백그라운드 실행 (앱 테스트용)

앱에서 "서버 연결 실패"가 자주 뜨면, 아래처럼 데몬으로 올려두고 Xcode를 실행하세요.

```bash
cd /Users/user/AgentA/Sever
./start_api_daemon.sh
```

중지:

```bash
cd /Users/user/AgentA/Sever
./stop_api_daemon.sh
```

QA 스모크(라우팅/ask 포함):

```bash
cd /Users/user/AgentA/Sever
./qa_smoke.sh
```

## 3) 수동 실행

```bash
cd /Users/user/AgentA/Sever
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
OLLAMA_MODEL=llama3.2:1b uvicorn agent_server.main:app --reload --host 127.0.0.1 --port 8000
```

헬스체크:

```bash
curl http://127.0.0.1:8000/health
```

## 4) 무료 AI 연결

로컬에서 Ollama를 실행하면 무료 모델로 응답합니다.
Ollama가 없거나 실패하면 서버는 자동으로 fallback 응답을 사용합니다.

환경변수:

- `OLLAMA_BASE_URL` (기본값: `http://127.0.0.1:11434`)
- `OLLAMA_MODEL` (기본값: `llama3.2:1b`)
- `OLLAMA_TIMEOUT` (기본값: `30`)

## 5) 목데이터 시드

서버 시작 시 카테고리별 목데이터가 자동으로 로드됩니다.

필요하면 수동으로 다시 시드:

```bash
curl -X POST "http://127.0.0.1:8000/dev/seed?reset=true"
```

- `reset=true`: 기존 등록 데이터 초기화 후 목데이터 재적재
- `reset=false`: 없는 시드만 추가

## 6) 주요 API

- `GET /categories`
- `GET /categories/{category_id}/bootstrap?mode=find|publish`
- `GET /categories/{category_id}/schema?mode=find|publish`
- `POST /agent/route` (자유문장 → 카테고리/모드 추론)
- `POST /agent/ask` (`mode=find|publish`)
- `GET /actions?category_id=...` (요청/수락/거절/확정 상태 조회)
- `POST /actions/request` (요청 생성)
- `POST /actions/{action_id}/transition` (`accept|reject|confirm|cancel`)
- `POST /dev/seed?reset=true|false`

샘플 요청:

```bash
curl -X POST http://127.0.0.1:8000/agent/ask \
  -H "Content-Type: application/json" \
  -d '{"category_id":"dating","message":"나는 차분한 성향이고 대화 잘 통하는 사람을 원해"}'
```
