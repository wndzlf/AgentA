from __future__ import annotations

import re
from typing import Dict, List, Optional, Tuple

from fastapi import FastAPI, HTTPException

from .ai_engine import AIEngine
from .matching import (
    board_count,
    list_actions,
    publish_listing,
    recommendation_detail,
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
    EmailAuthRequest,
    EmailAuthResponse,
    MatchAction,
    RecommendationDetailResponse,
    RouteCandidate,
    RouteRequest,
    RouteResponse,
)

app = FastAPI(title="Agent Match Prototype API", version="0.1.0")
ai_engine = AIEngine()
USERS_BY_EMAIL: Dict[str, Dict[str, str]] = {}

SUPPORTED_LANGS = {"ko", "en"}
DOMAIN_TITLE_EN = {
    "people": "People & Relationships",
    "sport": "Sports",
    "market": "Commerce & Trading",
    "service": "Services",
    "learning": "Learning & Classes",
    "job": "Career & Hiring",
}
MODE_TITLE_EN = {"find": "Find", "publish": "Post"}
GENERIC_HINT_EN = {
    "find": "Share concrete conditions to improve matching quality.",
    "publish": "Describe your listing/profile clearly for faster matching.",
}
GENERIC_WELCOME_EN = {
    "find": "AI matching is ready. Tell me your conditions.",
    "publish": "Let's post your profile/listing. Tell me key details.",
}


def _normalized_lang(lang: Optional[str]) -> str:
    value = (lang or "").strip().lower()
    if not value:
        return "ko"
    if value in SUPPORTED_LANGS:
        return value
    if value.startswith("ko"):
        return "ko"
    return "en"


def _to_english_label(category_id: str, fallback: str) -> str:
    tokens = [token for token in category_id.replace("_", " ").split("-") if token]
    if not tokens:
        return fallback
    return " ".join(token.capitalize() for token in tokens)


def _localized_category(item: Dict[str, str], lang: str) -> Category:
    if lang == "ko":
        return Category(**item)
    english_name = _to_english_label(item["id"], item["name"])
    domain_title = DOMAIN_TITLE_EN.get(item.get("domain", ""), "General")
    summary = f"AI agent matching for {english_name.lower()}."
    focus = f"{domain_title} context optimized matching."
    return Category(
        id=item["id"],
        name=english_name,
        summary=summary,
        icon=item["icon"],
        domain=item.get("domain", ""),
        focus=focus,
    )


def _localized_mode_payload(modes: List, lang: str) -> List:
    if lang == "ko":
        return modes
    localized = []
    for mode in modes:
        payload = mode.dict() if hasattr(mode, "dict") else dict(mode)
        mode_id = payload.get("id", "")
        payload["title"] = MODE_TITLE_EN.get(mode_id, payload.get("title", mode_id.title()))
        if mode_id == "find":
            payload["description"] = "Find suitable people/listings based on your conditions."
        elif mode_id == "publish":
            payload["description"] = "Post your listing/profile to be matched."
        localized.append(payload)
    return localized


def _localized_bootstrap_text(
    category_id: Optional[str],
    mode_id: str,
    welcome: str,
    prompt_hint: str,
    lang: str,
) -> Tuple[str, str]:
    if lang == "ko":
        return welcome, prompt_hint
    category_name = _to_english_label(category_id or "match", "Match")
    welcome_en = f"{category_name}: {GENERIC_WELCOME_EN.get(mode_id, GENERIC_WELCOME_EN['find'])}"
    hint_en = GENERIC_HINT_EN.get(mode_id, GENERIC_HINT_EN["find"])
    return welcome_en, hint_en


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


def _market_find_summary_en(user_message: str, recs: List) -> str:
    if not recs:
        return (
            f"No listings found for '{user_message}'. "
            "Try widening brand/model/budget filters."
        )
    prices: List[int] = []
    for rec in recs:
        parsed = _parse_price_won(f"{rec.title} {rec.subtitle}")
        if parsed is not None:
            prices.append(parsed)

    price_range = _format_price_range(prices)
    top_titles = [rec.title.replace("명품 매물: ", "") for rec in recs[:2]]
    title_part = ", ".join(top_titles) if top_titles else "top picks"
    if price_range:
        return f"{len(recs)} listings for '{user_message}', price range {price_range}. Top: {title_part}."
    return f"{len(recs)} listings for '{user_message}'. Top: {title_part}."


@app.on_event("startup")
def seed_on_startup() -> None:
    # 로컬 테스트 편의를 위해 목데이터를 기본 시드한다.
    seed_mock_board(reset=False)


@app.get("/health")
def health() -> Dict[str, str]:
    return {"status": "ok"}


@app.get("/categories", response_model=List[Category])
def categories(lang: Optional[str] = None) -> List[Category]:
    language = _normalized_lang(lang)
    return [_localized_category(item, language) for item in CATEGORY_DEFS]


@app.get("/categories/{category_id}/bootstrap", response_model=BootstrapResponse)
def bootstrap(category_id: str, mode: Optional[str] = None, lang: Optional[str] = None) -> BootstrapResponse:
    pack = PROMPT_PACKS.get(category_id)
    if not pack:
        raise HTTPException(status_code=404, detail="category not found")
    language = _normalized_lang(lang)
    mode_id, mode_meta = resolve_mode(category_id, mode)
    recs = recommend(category_id=category_id, message="초기 추천", mode=mode_id)
    welcome, prompt_hint = _localized_bootstrap_text(
        category_id=category_id,
        mode_id=mode_id,
        welcome=mode_meta["welcome"],
        prompt_hint=mode_meta["prompt_hint"],
        lang=language,
    )
    return BootstrapResponse(
        welcome_message=welcome,
        prompt_hint=prompt_hint,
        active_mode=mode_id,
        modes=_localized_mode_payload(mode_options(category_id), language),
        recommendations=recs,
    )


@app.get("/categories/{category_id}/schema", response_model=CategorySchemaResponse)
def category_schema(category_id: str, mode: Optional[str] = None, lang: Optional[str] = None) -> CategorySchemaResponse:
    pack = PROMPT_PACKS.get(category_id)
    if not pack:
        raise HTTPException(status_code=404, detail="category not found")
    schema = category_mode_schema(category_id=category_id, mode=mode)
    if _normalized_lang(lang) == "en":
        schema["examples"] = [
            "Tell me location, budget, and preferred schedule.",
            "I want a trusted match with fast response.",
            "Please show top matches and why they fit.",
        ]
    return CategorySchemaResponse(**schema)


@app.post("/agent/route", response_model=RouteResponse)
def route_agent(req: RouteRequest, lang: Optional[str] = None) -> RouteResponse:
    candidates_raw = route_categories(req.message, limit=max(1, min(req.limit, 10)))
    if _normalized_lang(lang) == "en":
        for item in candidates_raw:
            if item.get("reason", "").startswith("매칭 키워드:"):
                reason = item["reason"].replace("매칭 키워드:", "Matched keywords:")
                item["reason"] = reason
            item["category_name"] = _to_english_label(item["category_id"], item["category_name"])
    candidates = [RouteCandidate(**item) for item in candidates_raw]
    selected = candidates[0] if candidates else None
    return RouteResponse(selected=selected, candidates=candidates)


@app.post("/agent/ask", response_model=AskResponse)
def ask_agent(req: AskRequest, lang: Optional[str] = None) -> AskResponse:
    language = _normalized_lang(lang)
    mode_id, _ = resolve_mode(req.category_id, req.mode)
    action_result: Optional[str] = None
    action_context: Optional[str] = None

    if mode_id == "publish":
        listing, updated = publish_listing(
            category_id=req.category_id,
            message=req.message,
            owner_name=req.user_name,
            owner_email=req.user_email,
        )
        if language == "ko":
            action_result = f"{'수정 완료' if updated else '등록 완료'}: {listing.title}"
        else:
            action_result = f"{'Updated' if updated else 'Posted'}: {listing.title}"
        action_context = (
            f"{'등록 항목' if language == 'ko' else 'Posted item'}: {listing.title}\n"
            f"{'요약' if language == 'ko' else 'Summary'}: {listing.subtitle}\n"
            f"{'태그' if language == 'ko' else 'Tags'}: {', '.join(listing.tags)}"
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
        assistant = _market_find_summary(req.message, recs) if language == "ko" else _market_find_summary_en(req.message, recs)
    else:
        assistant = ai_engine.reply(
            category_id=req.category_id,
            message=req.message,
            mode=mode_id,
            action_context=action_context,
            recommendation_context=recommendation_context,
        )
        if language == "en":
            # Free local model quality can vary; enforce concise predictable EN fallback.
            if mode_id == "publish":
                assistant = "Your listing was posted. I refreshed matching candidates from the server."
            else:
                assistant = f"I analyzed your request and found {len(recs)} matching candidates."
    if action_result and "등록" not in assistant:
        assistant = f"{action_result}\n{assistant}"
    return AskResponse(
        assistant_message=assistant,
        active_mode=mode_id,
        action_result=action_result,
        recommendations=recs,
    )


@app.get("/actions", response_model=ActionListResponse)
def actions(category_id: Optional[str] = None, viewer_email: Optional[str] = None) -> ActionListResponse:
    return ActionListResponse(
        actions=[
            MatchAction(**item)
            for item in list_actions(category_id=category_id, viewer_email=viewer_email)
        ]
    )


@app.post("/actions/request", response_model=MatchAction)
def create_action(req: ActionCreateRequest) -> MatchAction:
    try:
        action = request_action(
            category_id=req.category_id,
            recommendation_id=req.recommendation_id,
            recommendation_title=req.recommendation_title,
            recommendation_subtitle=req.recommendation_subtitle,
            requester_email=req.requester_email,
            requester_name=req.requester_name,
            note=req.note,
        )
        return MatchAction(**action)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))


@app.post("/actions/{action_id}/transition", response_model=MatchAction)
def update_action(action_id: str, req: ActionTransitionRequest) -> MatchAction:
    try:
        action = transition_action(
            action_id=action_id,
            command=req.action,
            actor_email=req.actor_email,
            note=req.note,
        )
        return MatchAction(**action)
    except KeyError:
        raise HTTPException(status_code=404, detail="action not found")
    except PermissionError as exc:
        raise HTTPException(status_code=403, detail=str(exc))
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))


@app.get("/categories/{category_id}/recommendations/{recommendation_id}", response_model=RecommendationDetailResponse)
def recommendation(
    category_id: str,
    recommendation_id: str,
    viewer_email: Optional[str] = None,
) -> RecommendationDetailResponse:
    try:
        payload = recommendation_detail(
            category_id=category_id,
            recommendation_id=recommendation_id,
            viewer_email=viewer_email,
        )
        return RecommendationDetailResponse(**payload)
    except KeyError:
        raise HTTPException(status_code=404, detail="recommendation not found")


@app.post("/auth/email", response_model=EmailAuthResponse)
def auth_email(req: EmailAuthRequest) -> EmailAuthResponse:
    email = req.email.strip().lower()
    if not re.match(r"^[^@\s]+@[^@\s]+\.[^@\s]+$", email):
        raise HTTPException(status_code=400, detail="invalid email")

    name = (req.name or "").strip()
    if not name:
        name = email.split("@")[0]

    created = email not in USERS_BY_EMAIL
    USERS_BY_EMAIL[email] = {"email": email, "name": name}
    return EmailAuthResponse(email=email, name=name, created=created)


@app.post("/dev/seed")
def dev_seed(reset: bool = False) -> Dict[str, Dict[str, int]]:
    inserted = seed_mock_board(reset=reset)
    return {"inserted": inserted, "totals": board_count()}
