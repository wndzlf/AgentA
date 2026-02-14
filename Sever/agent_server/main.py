from __future__ import annotations

import re
from typing import Dict, List, Optional

from fastapi import FastAPI, HTTPException

from .ai_engine import AIEngine
from .matching import (
    board_count,
    list_actions,
    publish_listing,
    recommend,
    request_action,
    seed_mock_board,
    transition_action,
)
from .prompt_packs import (
    CATEGORY_DEFS,
    CATEGORY_DOMAIN_BY_ID,
    PROMPT_PACKS,
    category_mode_schema,
    mode_options,
    resolve_mode,
    route_categories,
)
from .schemas import (
    AskRequest,
    AskResponse,
    ActionCreateRequest,
    ActionListResponse,
    ActionTransitionRequest,
    BootstrapResponse,
    Category,
    CategorySchemaResponse,
    MatchAction,
    RouteCandidate,
    RouteRequest,
    RouteResponse,
)

app = FastAPI(title="Agent Match Prototype API", version="0.1.0")
ai_engine = AIEngine()


def _parse_price_won(text: str) -> Optional[int]:
    text = text or ""
    match_manwon = re.search(r"(\d{1,4})\s*만원", text)
    if match_manwon:
        return int(match_manwon.group(1)) * 10000
    match_won = re.search(r"(\d{2,9})\s*원", text)
    if match_won:
        return int(match_won.group(1))
    return None


def _format_price_range(prices: List[int]) -> Optional[str]:
    if not prices:
        return None
    low = min(prices)
    high = max(prices)
    if low >= 10000 and high >= 10000:
        low_m = low // 10000
        high_m = high // 10000
        return f"{low_m}만~{high_m}만원"
    return f"{low:,}~{high:,}원"


def _market_find_summary(user_message: str, recs: List) -> str:
    if not recs:
        return (
            f"'{user_message}' 관련 매물이 현재 0건이에요. "
            "브랜드/모델/예산 조건을 조금 넓혀서 다시 검색해보세요."
        )

    prices: List[int] = []
    for rec in recs:
        parsed = _parse_price_won(f"{rec.title} {rec.subtitle}")
        if parsed is not None:
            prices.append(parsed)

    price_range = _format_price_range(prices)
    top_titles = [rec.title.replace("명품 매물: ", "") for rec in recs[:2]]
    title_part = ", ".join(top_titles) if top_titles else "후보"
    if price_range:
        return f"'{user_message}' 관련 {len(recs)}건, 가격대 {price_range}. 상위: {title_part}."
    return f"'{user_message}' 관련 {len(recs)}건을 찾았어요. 상위: {title_part}."


@app.on_event("startup")
def seed_on_startup() -> None:
    # 로컬 테스트 편의를 위해 목데이터를 기본 시드한다.
    seed_mock_board(reset=False)


@app.get("/health")
def health() -> Dict[str, str]:
    return {"status": "ok"}


@app.get("/categories", response_model=List[Category])
def categories() -> List[Category]:
    return [Category(**item) for item in CATEGORY_DEFS]


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


@app.get("/categories/{category_id}/schema", response_model=CategorySchemaResponse)
def category_schema(category_id: str, mode: Optional[str] = None) -> CategorySchemaResponse:
    pack = PROMPT_PACKS.get(category_id)
    if not pack:
        raise HTTPException(status_code=404, detail="category not found")
    schema = category_mode_schema(category_id=category_id, mode=mode)
    return CategorySchemaResponse(**schema)


@app.post("/agent/route", response_model=RouteResponse)
def route_agent(req: RouteRequest) -> RouteResponse:
    candidates_raw = route_categories(req.message, limit=max(1, min(req.limit, 10)))
    candidates = [RouteCandidate(**item) for item in candidates_raw]
    selected = candidates[0] if candidates else None
    return RouteResponse(selected=selected, candidates=candidates)


@app.post("/agent/ask", response_model=AskResponse)
def ask_agent(req: AskRequest) -> AskResponse:
    mode_id, _ = resolve_mode(req.category_id, req.mode)
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

    recs = recommend(category_id=req.category_id, message=req.message, mode=mode_id)
    recommendation_context: Optional[str] = None
    if recs:
        top = recs[:3]
        lines = [f"추천 결과 총 {len(recs)}건"]
        for idx, rec in enumerate(top, start=1):
            lines.append(
                f"{idx}. {rec.title} | {rec.subtitle} | 태그: {', '.join(rec.tags)} | 점수: {int(rec.score * 100)}"
            )
        recommendation_context = "\n".join(lines)

    category_domain = CATEGORY_DOMAIN_BY_ID.get(req.category_id or "friend", "people")
    if mode_id == "find" and category_domain == "market":
        assistant = _market_find_summary(req.message, recs)
    else:
        assistant = ai_engine.reply(
            category_id=req.category_id,
            message=req.message,
            mode=mode_id,
            action_context=action_context,
            recommendation_context=recommendation_context,
        )
    if action_result and "등록" not in assistant:
        assistant = f"{action_result}\n{assistant}"
    return AskResponse(
        assistant_message=assistant,
        active_mode=mode_id,
        action_result=action_result,
        recommendations=recs,
    )


@app.get("/actions", response_model=ActionListResponse)
def actions(category_id: Optional[str] = None) -> ActionListResponse:
    return ActionListResponse(actions=[MatchAction(**item) for item in list_actions(category_id=category_id)])


@app.post("/actions/request", response_model=MatchAction)
def create_action(req: ActionCreateRequest) -> MatchAction:
    action = request_action(
        category_id=req.category_id,
        recommendation_id=req.recommendation_id,
        recommendation_title=req.recommendation_title,
        recommendation_subtitle=req.recommendation_subtitle,
        note=req.note,
    )
    return MatchAction(**action)


@app.post("/actions/{action_id}/transition", response_model=MatchAction)
def update_action(action_id: str, req: ActionTransitionRequest) -> MatchAction:
    try:
        action = transition_action(action_id=action_id, command=req.action, note=req.note)
        return MatchAction(**action)
    except KeyError:
        raise HTTPException(status_code=404, detail="action not found")
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))


@app.post("/dev/seed")
def dev_seed(reset: bool = False) -> Dict[str, Dict[str, int]]:
    inserted = seed_mock_board(reset=reset)
    return {"inserted": inserted, "totals": board_count()}
