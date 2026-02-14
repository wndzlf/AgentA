#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOST="127.0.0.1"
PORT="${1:-18080}"
PYTHON_BIN="$ROOT_DIR/.venv/bin/python"

if [[ ! -x "$PYTHON_BIN" ]]; then
  echo "[ERROR] .venv가 없습니다. 먼저 /Users/user/AgentA/Sever/run_local_ai.sh 를 실행하세요."
  exit 1
fi

cd "$ROOT_DIR"

$PYTHON_BIN -m uvicorn agent_server.main:app --host "$HOST" --port "$PORT" >/tmp/agenta-qa-smoke.log 2>&1 &
API_PID=$!
cleanup() {
  kill "$API_PID" >/dev/null 2>&1 || true
  wait "$API_PID" >/dev/null 2>&1 || true
}
trap cleanup EXIT

for _ in $(seq 1 20); do
  if curl -fsS "http://$HOST:$PORT/health" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

if ! curl -fsS "http://$HOST:$PORT/health" >/dev/null 2>&1; then
  echo "[ERROR] API 기동 실패. 로그: /tmp/agenta-qa-smoke.log"
  exit 1
fi

echo "[OK] health"

CATEGORIES_JSON="$(curl -fsS "http://$HOST:$PORT/categories")"
CATEGORY_COUNT="$($PYTHON_BIN -c 'import json,sys; print(len(json.loads(sys.argv[1])))' "$CATEGORIES_JSON")"
if [[ "$CATEGORY_COUNT" -lt 100 ]]; then
  echo "[ERROR] categories 부족: $CATEGORY_COUNT"
  exit 1
fi

echo "[OK] categories: $CATEGORY_COUNT"

route_test() {
  local query="$1"
  local expected_domain="$2"
  local payload
  payload=$(printf '{"message":"%s","limit":3}' "$query")
  local response
  response="$(curl -fsS -X POST "http://$HOST:$PORT/agent/route" -H 'Content-Type: application/json' -d "$payload")"

  local selected_category selected_domain selected_mode
  selected_category="$($PYTHON_BIN -c 'import json,sys; obj=json.loads(sys.argv[1]); sel=obj.get("selected") or {}; print(sel.get("category_name",""))' "$response")"
  selected_domain="$($PYTHON_BIN -c 'import json,sys; obj=json.loads(sys.argv[1]); sel=obj.get("selected") or {}; print(sel.get("domain",""))' "$response")"
  selected_mode="$($PYTHON_BIN -c 'import json,sys; obj=json.loads(sys.argv[1]); sel=obj.get("selected") or {}; print(sel.get("suggested_mode",""))' "$response")"

  if [[ -z "$selected_category" ]]; then
    echo "[ERROR] route 실패: $query"
    exit 1
  fi

  if [[ -n "$expected_domain" && "$selected_domain" != "$expected_domain" ]]; then
    echo "[WARN] route domain 예상과 다름: query='$query' got='$selected_domain' expected='$expected_domain'"
  else
    echo "[OK] route: '$query' -> $selected_category ($selected_domain/$selected_mode)"
  fi
}

route_test "송파에서 일요일 오전 축구 상대팀 구해요" "sport"
route_test "닌텐도 스위치 32만원에 팔고 싶어" "market"
route_test "소개팅 하고 싶어. 대화 잘 통하는 사람" "people"

ASK_FIND='{"category_id":"trade","mode":"find","message":"닌텐도 스위치 35만원 이하 찾고 싶어"}'
ASK_FIND_RESP="$(curl -fsS -X POST "http://$HOST:$PORT/agent/ask" -H 'Content-Type: application/json' -d "$ASK_FIND")"
ASK_FIND_RECS="$($PYTHON_BIN -c 'import json,sys; print(len(json.loads(sys.argv[1]).get("recommendations",[])))' "$ASK_FIND_RESP")"
if [[ "$ASK_FIND_RECS" -lt 1 ]]; then
  echo "[ERROR] ask(find) 추천 결과 없음"
  exit 1
fi

echo "[OK] ask(find): recs=$ASK_FIND_RECS"

ASK_LUXURY_STRICT='{"category_id":"luxury","mode":"find","message":"코치가방 찾아줘"}'
ASK_LUXURY_STRICT_RESP="$(curl -fsS -X POST "http://$HOST:$PORT/agent/ask" -H 'Content-Type: application/json' -d "$ASK_LUXURY_STRICT")"
ASK_LUXURY_STRICT_RECS="$($PYTHON_BIN -c 'import json,sys; print(len(json.loads(sys.argv[1]).get("recommendations",[])))' "$ASK_LUXURY_STRICT_RESP")"
if [[ "$ASK_LUXURY_STRICT_RECS" -lt 1 ]]; then
  echo "[ERROR] ask(find,luxury) 코치 매물 추천 없음"
  exit 1
fi

ASK_LUXURY_RELEVANCE="$($PYTHON_BIN -c 'import json,sys,re; recs=json.loads(sys.argv[1]).get("recommendations",[]); ok=all(("coach" in ((r.get("title","")+r.get("subtitle","")).lower()) or ("코치" in (r.get("title","")+r.get("subtitle","")))) for r in recs); print("ok" if ok else "bad")' "$ASK_LUXURY_STRICT_RESP")"
if [[ "$ASK_LUXURY_RELEVANCE" != "ok" ]]; then
  echo "[ERROR] ask(find,luxury) 무관 추천 포함"
  exit 1
fi

echo "[OK] ask(find,luxury): coach-only recommendations"

ASK_PUBLISH='{"category_id":"dating","mode":"publish","message":"나는 차분하고 주말 오후 만남 선호, 소개팅 등록"}'
ASK_PUBLISH_RESP="$(curl -fsS -X POST "http://$HOST:$PORT/agent/ask" -H 'Content-Type: application/json' -d "$ASK_PUBLISH")"
ASK_ACTION="$($PYTHON_BIN -c 'import json,sys; print((json.loads(sys.argv[1]).get("action_result") or ""))' "$ASK_PUBLISH_RESP")"
if [[ -z "$ASK_ACTION" ]]; then
  echo "[ERROR] ask(publish) action_result 없음"
  exit 1
fi

echo "[OK] ask(publish): $ASK_ACTION"

# 상태머신: 요청 -> 수락 -> 확정
FIRST_REC_ID="$($PYTHON_BIN -c 'import json,sys; recs=json.loads(sys.argv[1]).get("recommendations",[]); print(recs[0]["id"] if recs else "")' "$ASK_FIND_RESP")"
FIRST_REC_TITLE="$($PYTHON_BIN -c 'import json,sys; recs=json.loads(sys.argv[1]).get("recommendations",[]); print(recs[0]["title"] if recs else "")' "$ASK_FIND_RESP")"
FIRST_REC_SUBTITLE="$($PYTHON_BIN -c 'import json,sys; recs=json.loads(sys.argv[1]).get("recommendations",[]); print(recs[0]["subtitle"] if recs else "")' "$ASK_FIND_RESP")"

if [[ -z "$FIRST_REC_ID" ]]; then
  echo "[ERROR] 액션 테스트용 추천 ID 추출 실패"
  exit 1
fi

ACTION_CREATE_PAYLOAD="$(printf '{"category_id":"trade","recommendation_id":"%s","recommendation_title":"%s","recommendation_subtitle":"%s","note":"첫 요청"}' "$FIRST_REC_ID" "$FIRST_REC_TITLE" "$FIRST_REC_SUBTITLE")"
ACTION_CREATE_RESP="$(curl -fsS -X POST "http://$HOST:$PORT/actions/request" -H 'Content-Type: application/json' -d "$ACTION_CREATE_PAYLOAD")"
ACTION_ID="$($PYTHON_BIN -c 'import json,sys; print(json.loads(sys.argv[1]).get("id",""))' "$ACTION_CREATE_RESP")"
ACTION_STATUS="$($PYTHON_BIN -c 'import json,sys; print(json.loads(sys.argv[1]).get("status",""))' "$ACTION_CREATE_RESP")"
if [[ -z "$ACTION_ID" || "$ACTION_STATUS" != "requested" ]]; then
  echo "[ERROR] action request 생성 실패"
  exit 1
fi

echo "[OK] action(request): $ACTION_ID"

ACTION_ACCEPT_RESP="$(curl -fsS -X POST "http://$HOST:$PORT/actions/$ACTION_ID/transition" -H 'Content-Type: application/json' -d '{"action":"accept","note":"수락 테스트"}')"
ACTION_ACCEPT_STATUS="$($PYTHON_BIN -c 'import json,sys; print(json.loads(sys.argv[1]).get("status",""))' "$ACTION_ACCEPT_RESP")"
if [[ "$ACTION_ACCEPT_STATUS" != "accepted" ]]; then
  echo "[ERROR] action accept 실패: $ACTION_ACCEPT_STATUS"
  exit 1
fi

echo "[OK] action(accept)"

ACTION_CONFIRM_RESP="$(curl -fsS -X POST "http://$HOST:$PORT/actions/$ACTION_ID/transition" -H 'Content-Type: application/json' -d '{"action":"confirm","note":"확정 테스트"}')"
ACTION_CONFIRM_STATUS="$($PYTHON_BIN -c 'import json,sys; print(json.loads(sys.argv[1]).get("status",""))' "$ACTION_CONFIRM_RESP")"
if [[ "$ACTION_CONFIRM_STATUS" != "confirmed" ]]; then
  echo "[ERROR] action confirm 실패: $ACTION_CONFIRM_STATUS"
  exit 1
fi

echo "[OK] action(confirm)"

ACTION_LIST_RESP="$(curl -fsS "http://$HOST:$PORT/actions?category_id=trade")"
ACTION_LIST_COUNT="$($PYTHON_BIN -c 'import json,sys; print(len(json.loads(sys.argv[1]).get("actions",[])))' "$ACTION_LIST_RESP")"
if [[ "$ACTION_LIST_COUNT" -lt 1 ]]; then
  echo "[ERROR] action list 비어있음"
  exit 1
fi

echo "[OK] action(list): count=$ACTION_LIST_COUNT"
echo "[DONE] QA smoke passed"
