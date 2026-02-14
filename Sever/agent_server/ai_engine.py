from __future__ import annotations

import json
import os
from typing import Any, Dict, Optional

import requests

from .prompt_packs import PROMPT_PACKS


class AIEngine:
    def __init__(self) -> None:
        self.ollama_base = os.getenv("OLLAMA_BASE_URL", "http://127.0.0.1:11434")
        # 기본값은 로컬 무료 사용에 유리한 경량 모델로 둔다.
        self.ollama_model = os.getenv("OLLAMA_MODEL", "llama3.2:1b")
        # 첫 요청(콜드 스타트)은 시간이 걸릴 수 있어 여유 있게 설정.
        self.timeout = float(os.getenv("OLLAMA_TIMEOUT", "30"))

    def reply(self, category_id: Optional[str], message: str) -> str:
        # 1) 로컬 무료 AI(Ollama) 우선
        text = self._reply_with_ollama(category_id, message)
        if text:
            return text
        # 2) 실패 시 안전한 fallback
        return self._fallback(category_id, message)

    def _reply_with_ollama(self, category_id: Optional[str], message: str) -> Optional[str]:
        category_key = category_id or "friend"
        pack = PROMPT_PACKS.get(category_key, PROMPT_PACKS["friend"])
        system_prompt = (
            "You are a category agent. Keep response concise in Korean. "
            "Ask one clarifying question and summarize preference in one sentence. "
            f"Category hint: {pack['prompt_hint']}"
        )
        payload: Dict[str, Any] = {
            "model": self.ollama_model,
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": message},
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

    def _fallback(self, category_id: Optional[str], message: str) -> str:
        cid = category_id or "friend"
        pack = PROMPT_PACKS.get(cid, PROMPT_PACKS["friend"])
        return (
            f"요청을 반영해 {pack['welcome']} 우선 조건을 더 정밀하게 맞추려면 "
            "지역/시간/예산(또는 선호 스타일) 1가지를 추가로 알려주세요."
        )
