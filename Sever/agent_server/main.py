from __future__ import annotations

from typing import Dict, List, Optional

from fastapi import FastAPI, HTTPException

from .ai_engine import AIEngine
from .matching import board_count, publish_listing, recommend, seed_mock_board
from .prompt_packs import CATEGORIES, PROMPT_PACKS, mode_options, resolve_mode
from .schemas import AskRequest, AskResponse, BootstrapResponse, Category

app = FastAPI(title="Agent Match Prototype API", version="0.1.0")
ai_engine = AIEngine()


@app.on_event("startup")
def seed_on_startup() -> None:
    # 로컬 테스트 편의를 위해 목데이터를 기본 시드한다.
    seed_mock_board(reset=False)


@app.get("/health")
def health() -> Dict[str, str]:
    return {"status": "ok"}


@app.get("/categories", response_model=List[Category])
def categories() -> List[Category]:
    return [Category(**item) for item in CATEGORIES]


@app.get("/categories/{category_id}/bootstrap", response_model=BootstrapResponse)
def bootstrap(category_id: str, mode: Optional[str] = None) -> BootstrapResponse:
    pack = PROMPT_PACKS.get(category_id)
    if not pack:
        raise HTTPException(status_code=404, detail="category not found")
    mode_id, mode_meta = resolve_mode(category_id, mode)
    recs = recommend(category_id=category_id, message="초기 추천", mode=mode_id)
    return BootstrapResponse(
        welcome_message=mode_meta["welcome"],
        prompt_hint=mode_meta["prompt_hint"],
        active_mode=mode_id,
        modes=mode_options(category_id),
        recommendations=recs,
    )


@app.post("/agent/ask", response_model=AskResponse)
def ask_agent(req: AskRequest) -> AskResponse:
    mode_id, mode_meta = resolve_mode(req.category_id, req.mode)
    action_result: Optional[str] = None
    action_context: Optional[str] = None

    if mode_id == "publish":
        listing = publish_listing(category_id=req.category_id, message=req.message)
        action_result = f"등록 완료: {listing.title}"
        action_context = (
            f"등록 항목: {listing.title}\n"
            f"요약: {listing.subtitle}\n"
            f"태그: {', '.join(listing.tags)}"
        )

    assistant = ai_engine.reply(
        category_id=req.category_id,
        message=req.message,
        mode=mode_id,
        action_context=action_context,
    )
    recs = recommend(category_id=req.category_id, message=req.message, mode=mode_id)
    if action_result and "등록" not in assistant:
        assistant = f"{action_result}\n{assistant}"
    return AskResponse(
        assistant_message=assistant,
        active_mode=mode_id,
        action_result=action_result,
        recommendations=recs,
    )


@app.post("/dev/seed")
def dev_seed(reset: bool = False) -> Dict[str, Dict[str, int]]:
    inserted = seed_mock_board(reset=reset)
    return {"inserted": inserted, "totals": board_count()}
