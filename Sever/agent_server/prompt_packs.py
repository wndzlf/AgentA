from __future__ import annotations

CATEGORIES = [
    {"id": "dating", "name": "소개팅", "summary": "성향 기반 이성 추천", "icon": "heart.circle"},
    {"id": "friend", "name": "친구 만들기", "summary": "관심사/성격 기반 매칭", "icon": "person.2.circle"},
    {"id": "trade", "name": "일반 거래", "summary": "사고팔기/가격 제안", "icon": "cart.circle"},
    {"id": "luxury", "name": "명품 거래", "summary": "브랜드/상태 기반 매칭", "icon": "sparkles"},
    {"id": "soccer", "name": "축구 매칭", "summary": "상대팀/용병 매칭", "icon": "sportscourt.circle"},
    {"id": "futsal", "name": "풋살 매칭", "summary": "근거리 풋살 팀 매칭", "icon": "figure.indoor.soccer"},
]

PROMPT_PACKS = {
    "dating": {
        "prompt_hint": "성향, 나이대, 선호 스타일, 거리, 대화 성향을 말해주세요.",
        "welcome": "소개팅 에이전트입니다. 원하는 상대 조건을 말해주시면 바로 추천을 보여드릴게요.",
    },
    "friend": {
        "prompt_hint": "취미, 성격, 선호 활동, 지역을 말해주세요.",
        "welcome": "친구 만들기 에이전트입니다. 어떤 친구를 찾는지 알려주세요.",
    },
    "trade": {
        "prompt_hint": "사려는/팔려는 물건, 예산/희망가격, 상태 조건을 말해주세요.",
        "welcome": "거래 에이전트입니다. 상품 조건을 말해주시면 맞춤 리스트를 보여드릴게요.",
    },
    "luxury": {
        "prompt_hint": "브랜드, 모델, 상태, 예산/희망가격을 말해주세요.",
        "welcome": "명품 거래 에이전트입니다. 원하는 브랜드/조건을 알려주세요.",
    },
    "soccer": {
        "prompt_hint": "지역, 시간대, 실력대, 매칭 형식(8:8/11:11)을 말해주세요.",
        "welcome": "축구 매칭 에이전트입니다. 조건에 맞는 팀을 추천해드릴게요.",
    },
    "futsal": {
        "prompt_hint": "지역, 인원, 시간, 실력대를 말해주세요.",
        "welcome": "풋살 매칭 에이전트입니다. 빠르게 잡을 수 있는 경기 리스트를 찾아드릴게요.",
    },
}
