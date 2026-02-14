from __future__ import annotations

from typing import Dict, List

from fastapi import FastAPI, HTTPException

from .ai_engine import AIEngine
from .matching import recommend
from .prompt_packs import CATEGORIES, PROMPT_PACKS
from .schemas import AskRequest, AskResponse, BootstrapResponse, Category

app = FastAPI(title="Agent Match Prototype API", version="0.1.0")
ai_engine = AIEngine()


@app.get("/health")
def health() -> Dict[str, str]:
    return {"status": "ok"}


@app.get("/categories", response_model=List[Category])
def categories() -> List[Category]:
    return [Category(**item) for item in CATEGORIES]


@app.get("/categories/{category_id}/bootstrap", response_model=BootstrapResponse)
def bootstrap(category_id: str) -> BootstrapResponse:
    pack = PROMPT_PACKS.get(category_id)
    if not pack:
        raise HTTPException(status_code=404, detail="category not found")
    recs = recommend(category_id=category_id, message="초기 추천")
    return BootstrapResponse(
        welcome_message=pack["welcome"],
        prompt_hint=pack["prompt_hint"],
        recommendations=recs,
    )


@app.post("/agent/ask", response_model=AskResponse)
def ask_agent(req: AskRequest) -> AskResponse:
    assistant = ai_engine.reply(category_id=req.category_id, message=req.message)
    recs = recommend(category_id=req.category_id, message=req.message)
    return AskResponse(assistant_message=assistant, recommendations=recs)
