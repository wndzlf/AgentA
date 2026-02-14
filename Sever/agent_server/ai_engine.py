from __future__ import annotations

import json
import os
from typing import Any, Dict, Optional

import requests

from .prompt_packs import CATEGORY_DOMAIN_BY_ID, CATEGORY_NAME_BY_ID, resolve_mode


class AIEngine:
    def __init__(self) -> None:
        self.ollama_base = os.getenv("OLLAMA_BASE_URL", "http://127.0.0.1:11434")
        # 기본값은 로컬 무료 사용에 유리한 경량 모델로 둔다.
        self.ollama_model = os.getenv("OLLAMA_MODEL", "llama3.2:1b")
        # 첫 요청(콜드 스타트)은 시간이 걸릴 수 있어 여유 있게 설정.
        self.timeout = float(os.getenv("OLLAMA_TIMEOUT", "30"))

    def reply(
        self,
        category_id: Optional[str],
        message: str,
        mode: Optional[str] = "find",
        action_context: Optional[str] = None,
        recommendation_context: Optional[str] = None,
    ) -> str:
        # 1) 로컬 무료 AI(Ollama) 우선
        text = self._reply_with_ollama(
            category_id=category_id,
            message=message,
            mode=mode,
            action_context=action_context,
            recommendation_context=recommendation_context,
        )
        if text:
            return text
        # 2) 실패 시 안전한 fallback
        return self._fallback(category_id, mode)

    def _reply_with_ollama(
        self,
        category_id: Optional[str],
        message: str,
        mode: Optional[str],
        action_context: Optional[str],
        recommendation_context: Optional[str],
    ) -> Optional[str]:
        category_key = category_id or "friend"
        mode_id, mode_meta = resolve_mode(category_key, mode)
        category_name = CATEGORY_NAME_BY_ID.get(category_key, "친구 만들기")
        category_domain = CATEGORY_DOMAIN_BY_ID.get(category_key, "people")

        user_message = message
        if action_context:
            user_message = f"{message}\n\n[ActionResult]\n{action_context}"
        if recommendation_context:
            user_message = f"{user_message}\n\n[RecommendationContext]\n{recommendation_context}"

        mode_specific = (
            "추천 결과 컨텍스트가 주어지면 추상적인 설명 대신, "
            "실제 후보 수(몇 건)와 상위 후보의 제목/상태/가격(또는 핵심 조건)을 구체적으로 설명하라. "
            "리스트에 없는 정보를 꾸며내지 마라."
        )
        if mode_id == "find" and category_domain == "market":
            response_format = (
                "응답 형식: 1) 검색 결과 요약(몇 건, 핵심 키워드) "
                "2) 상위 매물 2~3개를 항목으로 설명 "
                "3) 바로 선택/비교할 수 있는 다음 질문 1개."
            )
        else:
            response_format = (
                "응답 형식: 1) 핵심요약 1문장 "
                "2) 다음 행동 1~2개 "
                "3) 필요한 추가질문 1개."
            )

        system_prompt = (
            "너는 카테고리 전용 AI 에이전트다. 한국어로 간결히 답해라. "
            f"카테고리: {category_name}. "
            f"현재 모드: {mode_meta['title']}({mode_id}). "
            f"모드 설명: {mode_meta['description']}. "
            f"입력 힌트: {mode_meta['prompt_hint']}. "
            f"모드 지시: {mode_meta['system_prompt']} "
            f"{mode_specific} "
            f"{response_format}"
        )
        payload: Dict[str, Any] = {
            "model": self.ollama_model,
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_message},
            ],
            "stream": False,
        }
        try:
            res = requests.post(
                f"{self.ollama_base}/api/chat",
                headers={"Content-Type": "application/json"},
                data=json.dumps(payload),
                timeout=self.timeout,
            )
            if res.status_code != 200:
                return None
            data = res.json()
            content = data.get("message", {}).get("content", "").strip()
            return content or None
        except Exception:
            return None

    def _fallback(self, category_id: Optional[str], mode: Optional[str]) -> str:
        cid = category_id or "friend"
        _, mode_meta = resolve_mode(cid, mode)
        return (
            f"{mode_meta['welcome']} 요청을 반영 중입니다. "
            "정밀 매칭을 위해 지역/시간/예산 중 한 가지를 추가로 알려주세요."
        )
