from __future__ import annotations

from datetime import datetime, timezone
import re
from collections import defaultdict
from random import random
from typing import DefaultDict, Dict, List, Optional, Tuple
from uuid import uuid4

from .prompt_packs import CATEGORIES, CATEGORY_DOMAIN_BY_ID, CATEGORY_NAME_BY_ID
from .schemas import Recommendation

# 주요 카테고리는 조금 더 자연스러운 샘플을 유지한다.
CURATED_CANDIDATES: Dict[str, List[dict]] = {
    "dating": [
        {"title": "활동적인 대화형", "subtitle": "주말 데이트/카페 선호", "tags": ["외향", "대화많음", "서울"]},
        {"title": "차분한 취향형", "subtitle": "전시/영화/산책 선호", "tags": ["내향", "감성", "경기"]},
        {"title": "취미공유형", "subtitle": "운동/맛집/여행 중심", "tags": ["취미", "주도적", "서울"]},
    ],
    "friend": [
        {"title": "러닝 메이트", "subtitle": "아침 러닝/헬스 루틴", "tags": ["운동", "꾸준함", "강남"]},
        {"title": "콘텐츠 메이트", "subtitle": "넷플릭스/게임/잡담", "tags": ["집순", "게임", "홍대"]},
        {"title": "스터디 메이트", "subtitle": "커리어/독서/생산성", "tags": ["성장", "독서", "판교"]},
    ],
    "trade": [
        {"title": "거래 후보 A", "subtitle": "가격 협상 가능 / 상태 A", "tags": ["직거래", "안전결제", "급매"]},
        {"title": "거래 후보 B", "subtitle": "박스 포함 / 상태 S", "tags": ["풀박", "당일거래", "정품"]},
        {"title": "거래 후보 C", "subtitle": "예산 친화 / 상태 B+", "tags": ["가성비", "협상", "리뷰좋음"]},
    ],
    "luxury": [
        {"title": "명품 후보 A", "subtitle": "인보이스/더스트백 보유", "tags": ["정품", "보증", "상태A"]},
        {"title": "명품 후보 B", "subtitle": "최근 관리 완료", "tags": ["컨디션좋음", "실사용적음", "서울"]},
        {"title": "명품 후보 C", "subtitle": "예산 내 추천", "tags": ["합리적", "빠른응답", "안전결제"]},
    ],
    "soccer": [
        {"title": "상대팀 후보 A", "subtitle": "토 오전 / 실력 중", "tags": ["11:11", "서울", "응답빠름"]},
        {"title": "상대팀 후보 B", "subtitle": "일 오전 / 실력 중상", "tags": ["8:8", "경기", "매너좋음"]},
        {"title": "상대팀 후보 C", "subtitle": "야간 가능 / 실력 중", "tags": ["야간", "직관적", "고정팀"]},
    ],
    "futsal": [
        {"title": "풋살팀 후보 A", "subtitle": "평일 저녁 / 중", "tags": ["5:5", "강남", "빠른매칭"]},
        {"title": "풋살팀 후보 B", "subtitle": "주말 오후 / 중하", "tags": ["입문환영", "홍대", "친목"]},
        {"title": "풋살팀 후보 C", "subtitle": "주말 오전 / 중상", "tags": ["실전", "송파", "정시"]},
    ],
}

DOMAIN_DEFAULT_TEMPLATES: Dict[str, List[Tuple[str, str, List[str]]]] = {
    "people": [
        ("{name} 후보 A", "지역/시간/성향이 잘 맞는 후보", ["취향매칭", "근거리", "응답빠름"]),
        ("{name} 후보 B", "대화/활동 패턴이 비슷한 후보", ["성향유사", "활동적", "검증완료"]),
        ("{name} 후보 C", "목표와 스타일이 맞는 후보", ["목표일치", "친절", "추천많음"]),
    ],
    "sport": [
        ("{name} 상대/파트너 A", "시간대와 실력대가 유사", ["시간일치", "실력유사", "매너"]),
        ("{name} 상대/파트너 B", "주요 지역이 겹치는 팀/파트너", ["근거리", "정시", "재매칭"]),
        ("{name} 상대/파트너 C", "참여 인원/포지션이 맞는 후보", ["인원적합", "빠른확정", "활동중"]),
    ],
    "market": [
        ("{name} 매물 A", "예산 범위와 상태 조건이 맞는 매물", ["예산적합", "상태좋음", "안전거래"]),
        ("{name} 매물 B", "구성품/거래방식이 유리한 매물", ["풀구성", "직거래", "응답빠름"]),
        ("{name} 매물 C", "가격 협의가 가능한 매물", ["협의가능", "가성비", "당일거래"]),
    ],
    "service": [
        ("{name} 전문가 A", "요청 범위와 일정이 맞는 전문가", ["포트폴리오", "납기준수", "후기좋음"]),
        ("{name} 전문가 B", "예산에 맞춘 견적이 가능한 전문가", ["합리견적", "빠른응답", "실무경험"]),
        ("{name} 전문가 C", "유사 프로젝트 경험이 풍부한 전문가", ["레퍼런스", "전문성", "온라인가능"]),
    ],
    "learning": [
        ("{name} 모임 A", "목표/레벨이 유사한 모임", ["목표일치", "주기적", "피드백"]),
        ("{name} 모임 B", "시간대가 맞는 학습 그룹", ["시간일치", "온라인", "꾸준함"]),
        ("{name} 모임 C", "같은 주제로 진행 중인 그룹", ["주제일치", "실전형", "신규환영"]),
    ],
    "job": [
        ("{name} 기회 A", "경력/조건이 맞는 포지션", ["조건매칭", "성장기회", "즉시지원"]),
        ("{name} 기회 B", "근무 형태가 맞는 포지션", ["근무유연", "직무적합", "우대조건"]),
        ("{name} 기회 C", "관심 스택/산업과 맞는 포지션", ["스택일치", "산업적합", "추천"]),
    ],
}

PROFILE_SUFFIX_BY_DOMAIN = {
    "people": "프로필",
    "sport": "모집글",
    "market": "매물",
    "service": "서비스",
    "learning": "모집글",
    "job": "등록",
}

CURATED_PROFILE_TITLES = {
    "friend": "친구 프로필",
    "dating": "소개팅 프로필",
    "trade": "판매글",
    "luxury": "명품 매물",
    "soccer": "축구팀 등록",
    "futsal": "풋살팀 등록",
}

MOCK_OWNER_POOL = [
    {"name": "민지", "email": "minji.seller@agenta.local", "phone": "010-2101-4132"},
    {"name": "준호", "email": "junho.trade@agenta.local", "phone": "010-5228-1944"},
    {"name": "서윤", "email": "seoyun.market@agenta.local", "phone": "010-7351-0082"},
    {"name": "도윤", "email": "doyoon.match@agenta.local", "phone": "010-6642-3009"},
    {"name": "지아", "email": "jia.connect@agenta.local", "phone": "010-4872-7714"},
]

# 카테고리별 실제 서버 보드(로컬 메모리)
BOARD: DefaultDict[str, List[dict]] = defaultdict(list)

# 요청/수락/거절/확정 상태머신 (로컬 메모리)
ACTIONS: Dict[str, dict] = {}
ACTION_INDEX_BY_CATEGORY: DefaultDict[str, List[str]] = defaultdict(list)
ACTION_INDEX_BY_RECOMMENDATION: DefaultDict[str, List[str]] = defaultdict(list)

ACTION_TRANSITIONS: Dict[str, Dict[str, str]] = {
    "requested": {
        "accept": "accepted",
        "reject": "rejected",
        "cancel": "canceled",
    },
    "accepted": {
        "confirm": "confirmed",
        "reject": "rejected",
        "cancel": "canceled",
    },
    "rejected": {},
    "confirmed": {},
    "canceled": {},
}

CURATED_SEED_BOARD_DATA: Dict[str, List[dict]] = {
    "friend": [
        {"title": "친구 프로필: 주말 러너", "subtitle": "강남, 토 오전 러닝 + 브런치", "tags": ["러닝", "강남", "주말오전"]},
        {"title": "친구 프로필: 보드게임 메이트", "subtitle": "홍대, 보드게임/카페", "tags": ["보드게임", "홍대", "대화"]},
        {"title": "친구 프로필: 스터디 메이트", "subtitle": "판교, 커리어 독서/스터디", "tags": ["독서", "판교", "성장"]},
    ],
    "dating": [
        {"title": "소개팅 프로필: 전시 좋아함", "subtitle": "분위기 좋은 카페/전시 데이트 선호", "tags": ["전시", "카페", "차분"]},
        {"title": "소개팅 프로필: 운동 좋아함", "subtitle": "러닝/등산 같이 할 상대 원함", "tags": ["운동", "러닝", "활동적"]},
        {"title": "소개팅 프로필: 영화 마니아", "subtitle": "주말 영화+산책 선호", "tags": ["영화", "산책", "감성"]},
    ],
    "trade": [
        {"title": "판매글: 아이패드 에어 5", "subtitle": "상태 A, 펜슬 포함, 55만원", "tags": ["아이패드", "상태A", "직거래"]},
        {"title": "판매글: 소니 WH-1000XM5", "subtitle": "실사용 적음, 28만원", "tags": ["헤드폰", "소니", "가성비"]},
        {"title": "판매글: 닌텐도 스위치 OLED", "subtitle": "풀박스, 32만원", "tags": ["닌텐도", "풀박", "급매"]},
    ],
    "luxury": [
        {"title": "명품 매물: Chanel 클래식 WOC", "subtitle": "인보이스/더스트백 포함, 365만원", "tags": ["샤넬", "정품", "인보이스"]},
        {"title": "명품 매물: Louis Vuitton 네오노에", "subtitle": "상태 A-, 178만원", "tags": ["루이비통", "상태A", "서울"]},
        {"title": "명품 매물: Cartier 탱크 머스트", "subtitle": "2024 구매, 보증서 포함", "tags": ["까르띠에", "보증서", "시계"]},
        {"title": "명품 매물: Coach 태비 숄더 가방", "subtitle": "상태 A, 39만원", "tags": ["코치", "가방", "정품"]},
        {"title": "명품 매물: Coach 로그 토트 가방", "subtitle": "사용감 있음, 22만원", "tags": ["코치", "토트", "가방"]},
    ],
    "soccer": [
        {"title": "팀 등록: FC 강남토요", "subtitle": "토 10시, 11:11, 중상", "tags": ["11:11", "강남", "토요일"]},
        {"title": "팀 등록: 송파 선데이", "subtitle": "일 08시, 11:11, 중", "tags": ["송파", "일요일", "중"]},
        {"title": "팀 등록: 한강 나이트", "subtitle": "수 21시, 8:8, 중", "tags": ["야간", "8:8", "한강"]},
    ],
    "futsal": [
        {"title": "팀 등록: 홍대 풋살 크루", "subtitle": "평일 20시, 5:5, 중", "tags": ["홍대", "평일저녁", "5:5"]},
        {"title": "팀 등록: 송파 실전팀", "subtitle": "토 09시, 5:5, 중상", "tags": ["송파", "실전", "주말오전"]},
        {"title": "팀 등록: 판교 입문팀", "subtitle": "일 16시, 입문 환영", "tags": ["입문", "판교", "친목"]},
    ],
}


STOP_WORDS = {
    "나는",
    "원해",
    "찾고",
    "싶어",
    "해요",
    "하고",
    "싶은",
    "에서",
    "으로",
    "그리고",
    "입니다",
    "주세요",
    "찾아줘",
    "찾아주세요",
    "사고",
    "팔고",
    "싶습니다",
}

COMPOUND_SUFFIX_HINTS = [
    "가방",
    "지갑",
    "시계",
    "신발",
    "벨트",
    "자켓",
    "코트",
    "반지",
    "목걸이",
    "팔찌",
    "향수",
    "스위치",
    "아이패드",
    "아이폰",
]


def _tokenize(text: str) -> List[str]:
    tokens = re.findall(r"[0-9A-Za-z가-힣]+", text.lower())
    out: List[str] = []
    for token in tokens:
        if len(token) < 2 or token in STOP_WORDS:
            continue
        if token not in out:
            out.append(token)
    return out


def _expand_compound_tokens(tokens: List[str]) -> List[str]:
    out: List[str] = []
    for token in tokens:
        if token not in out:
            out.append(token)
        for suffix in COMPOUND_SUFFIX_HINTS:
            if token.endswith(suffix) and len(token) > len(suffix) + 1:
                prefix = token[: -len(suffix)]
                for extra in (prefix, suffix):
                    if len(extra) >= 2 and extra not in STOP_WORDS and extra not in out:
                        out.append(extra)
    return out


def _extract_query_tokens(message: str) -> List[str]:
    base = _tokenize(message)
    expanded = _expand_compound_tokens(base)
    return expanded[:8]


def _extract_tags(message: str) -> List[str]:
    out = _tokenize(message)[:4]
    if not out:
        return ["매칭", "조건"]
    return out


def _mask_email(email: str) -> str:
    if "@" not in email:
        return email
    local, domain = email.split("@", 1)
    if len(local) <= 2:
        masked_local = local[0] + "*"
    else:
        masked_local = local[:2] + ("*" * max(1, len(local) - 2))
    return f"{masked_local}@{domain}"


def _mask_phone(phone: str) -> str:
    digits = re.sub(r"[^0-9]", "", phone)
    if len(digits) < 8:
        return phone
    return f"{digits[:3]}-****-{digits[-4:]}"


def _owner_profile_for(category_id: str, stable_index: int = 0) -> dict:
    idx = (sum(ord(ch) for ch in category_id) + stable_index) % len(MOCK_OWNER_POOL)
    return MOCK_OWNER_POOL[idx]


def _image_seed_urls(seed: str, count: int = 3) -> List[str]:
    safe_seed = re.sub(r"[^0-9A-Za-z_-]", "", seed) or "item"
    return [f"https://picsum.photos/seed/{safe_seed}-{idx}/800/600" for idx in range(1, count + 1)]


def _score_item(query_tokens: List[str], item: dict, from_board: bool = False) -> Tuple[float, int]:
    title = item.get("title", "").lower()
    subtitle = item.get("subtitle", "").lower()
    tags = [str(t).lower() for t in item.get("tags", [])]

    hits = 0
    weighted = 0.0
    for token in query_tokens:
        token_hit = False
        if token in title:
            weighted += 0.22
            token_hit = True
        if token in subtitle:
            weighted += 0.14
            token_hit = True
        if any(token in tag for tag in tags):
            weighted += 0.18
            token_hit = True
        if token_hit:
            hits += 1

    # 검색어가 있을 때 미일치 항목은 점수를 낮추고, 일치 항목은 강하게 올린다.
    if query_tokens:
        base = 0.34 + (0.08 if from_board else 0.0)
    else:
        base = 0.56 + (0.1 if from_board else 0.0)

    if hits > 0 and len(query_tokens) > 0:
        coverage_bonus = 0.12 * (hits / len(query_tokens))
    else:
        coverage_bonus = 0.0

    # 동점 정렬 시만 약간의 노이즈를 준다.
    noise = random() * 0.03
    score = min(0.99, round(base + weighted + coverage_bonus + noise, 2))
    return score, hits


def _insert_board_item(
    category_id: str,
    title: str,
    subtitle: str,
    tags: List[str],
    item_id: Optional[str] = None,
    detail: Optional[str] = None,
    image_urls: Optional[List[str]] = None,
    owner_name: Optional[str] = None,
    owner_email: Optional[str] = None,
    owner_phone: Optional[str] = None,
) -> dict:
    stable_index = len(BOARD.get(category_id, []))
    owner = _owner_profile_for(category_id, stable_index)
    resolved_owner_name = owner_name or owner["name"]
    resolved_owner_email = owner_email or owner["email"]
    resolved_owner_phone = owner_phone or owner["phone"]
    item_key = item_id or f"{category_id}-user-{uuid4().hex[:8]}"
    resolved_detail = detail or f"{title} · {subtitle}. 태그: {', '.join(tags[:4])}"
    resolved_images = image_urls if image_urls is not None else _image_seed_urls(item_key, count=3)
    item = {
        "id": item_key,
        "title": title,
        "subtitle": subtitle,
        "tags": tags[:4] if tags else ["매칭", "조건"],
        "detail": resolved_detail,
        "image_urls": resolved_images[:5],
        "owner_name": resolved_owner_name,
        "owner_email": resolved_owner_email,
        "owner_phone": resolved_owner_phone,
        "created_at": _now_iso(),
    }
    BOARD[category_id].insert(0, item)
    BOARD[category_id] = BOARD[category_id][:120]
    return item


def _recommendation_from_item(item: dict, score: float) -> Recommendation:
    return Recommendation(
        id=item["id"],
        title=item["title"],
        subtitle=item["subtitle"],
        tags=item.get("tags", []),
        score=score,
        detail=item.get("detail", ""),
        image_urls=item.get("image_urls", []),
        owner_name=item.get("owner_name", ""),
        owner_email_masked=_mask_email(item.get("owner_email", "")),
        owner_phone_masked=_mask_phone(item.get("owner_phone", "")),
    )


def _find_board_item(category_id: str, recommendation_id: str) -> Optional[dict]:
    for item in BOARD.get(category_id, []):
        if item.get("id") == recommendation_id:
            return item
    return None


def _default_candidates_for_category(category_id: str) -> List[dict]:
    curated = CURATED_CANDIDATES.get(category_id)
    if curated:
        return curated

    name = CATEGORY_NAME_BY_ID.get(category_id, "매칭")
    domain = CATEGORY_DOMAIN_BY_ID.get(category_id, "people")
    templates = DOMAIN_DEFAULT_TEMPLATES.get(domain, DOMAIN_DEFAULT_TEMPLATES["people"])
    out: List[dict] = []
    for title_tpl, subtitle_tpl, tags in templates:
        out.append(
            {
                "title": title_tpl.format(name=name),
                "subtitle": subtitle_tpl.format(name=name),
                "tags": tags,
            }
        )
    return out


def _profile_title(category_id: str) -> str:
    if category_id in CURATED_PROFILE_TITLES:
        return CURATED_PROFILE_TITLES[category_id]
    name = CATEGORY_NAME_BY_ID.get(category_id, "등록")
    domain = CATEGORY_DOMAIN_BY_ID.get(category_id, "people")
    suffix = PROFILE_SUFFIX_BY_DOMAIN.get(domain, "등록")
    return f"{name} {suffix}"


def _seed_items_for_category(category_id: str) -> List[dict]:
    curated = CURATED_SEED_BOARD_DATA.get(category_id)
    if curated:
        return curated

    name = CATEGORY_NAME_BY_ID.get(category_id, "매칭")
    domain = CATEGORY_DOMAIN_BY_ID.get(category_id, "people")

    if domain == "people":
        return [
            {
                "title": f"{name} 프로필: 활동형",
                "subtitle": "주 2~3회 활동 가능, 근거리 선호",
                "tags": ["활동형", "근거리", "응답빠름"],
            },
            {
                "title": f"{name} 프로필: 대화형",
                "subtitle": "평일 저녁 중심, 온라인/오프라인 가능",
                "tags": ["대화형", "평일저녁", "온라인가능"],
            },
            {
                "title": f"{name} 프로필: 목표형",
                "subtitle": "명확한 조건 기반으로 매칭 희망",
                "tags": ["목표형", "조건명확", "매칭중"],
            },
        ]

    if domain == "sport":
        return [
            {
                "title": f"{name} 모집: 주말 오전",
                "subtitle": "지역/실력 맞춰 상대 또는 파트너 모집",
                "tags": ["주말오전", "실력중", "근거리"],
            },
            {
                "title": f"{name} 모집: 평일 야간",
                "subtitle": "퇴근 후 참여 가능한 팀/파트너 선호",
                "tags": ["평일야간", "정시", "응답빠름"],
            },
            {
                "title": f"{name} 모집: 정기 고정",
                "subtitle": "정기적으로 고정 매칭 희망",
                "tags": ["정기", "고정팀", "매너중시"],
            },
        ]

    if domain == "market":
        return [
            {
                "title": f"{name} 매물: 상태 A",
                "subtitle": "구성품 포함, 직거래 우선",
                "tags": ["상태A", "직거래", "구성품포함"],
            },
            {
                "title": f"{name} 매물: 가성비형",
                "subtitle": "합리적 가격, 빠른 거래 가능",
                "tags": ["가성비", "빠른거래", "협의가능"],
            },
            {
                "title": f"{name} 매물: 안전거래",
                "subtitle": "안전결제/인증 가능",
                "tags": ["안전결제", "인증가능", "응답빠름"],
            },
        ]

    if domain == "service":
        return [
            {
                "title": f"{name} 서비스: 기본형",
                "subtitle": "요청 범위 기반 견적/일정 제안 가능",
                "tags": ["견적가능", "일정협의", "실무경험"],
            },
            {
                "title": f"{name} 서비스: 빠른납기",
                "subtitle": "단기 납기 중심으로 대응 가능",
                "tags": ["빠른납기", "응답빠름", "온라인"],
            },
            {
                "title": f"{name} 서비스: 맞춤형",
                "subtitle": "요건 맞춤형으로 진행 가능",
                "tags": ["맞춤형", "협의가능", "후기좋음"],
            },
        ]

    if domain == "learning":
        return [
            {
                "title": f"{name} 모집: 주 2회",
                "subtitle": "목표 중심 학습, 피드백 포함",
                "tags": ["주2회", "목표형", "피드백"],
            },
            {
                "title": f"{name} 모집: 주말반",
                "subtitle": "주말 오전 중심 오프라인/온라인 병행",
                "tags": ["주말", "온라인병행", "신규환영"],
            },
            {
                "title": f"{name} 모집: 집중반",
                "subtitle": "단기 집중 학습/프로젝트형",
                "tags": ["집중반", "단기", "실전형"],
            },
        ]

    # domain == "job"
    return [
        {
            "title": f"{name} 등록: 기본형",
            "subtitle": "조건 협의 가능한 포지션/프로필",
            "tags": ["조건협의", "즉시시작", "경력무관"],
        },
        {
            "title": f"{name} 등록: 경력형",
            "subtitle": "경력 기반 우대 조건 포함",
            "tags": ["경력우대", "직무적합", "성장기회"],
        },
        {
            "title": f"{name} 등록: 유연근무",
            "subtitle": "근무 형태 유연, 협업 도구 활용",
            "tags": ["유연근무", "리모트", "협업"],
        },
    ]


def seed_mock_board(reset: bool = False) -> Dict[str, int]:
    if reset:
        BOARD.clear()
        ACTIONS.clear()
        ACTION_INDEX_BY_CATEGORY.clear()
        ACTION_INDEX_BY_RECOMMENDATION.clear()

    counts: Dict[str, int] = {}
    for category in CATEGORIES:
        cid = category["id"]
        existing_ids = {item["id"] for item in BOARD.get(cid, [])}
        inserted = 0

        for idx, item in enumerate(_seed_items_for_category(cid), start=1):
            seed_id = f"{cid}-seed-{idx}"
            if seed_id in existing_ids:
                continue
            _insert_board_item(
                category_id=cid,
                title=item["title"],
                subtitle=item["subtitle"],
                tags=item["tags"],
                item_id=seed_id,
            )
            inserted += 1

        counts[cid] = inserted

    return counts


def board_count() -> Dict[str, int]:
    return {cid: len(items) for cid, items in BOARD.items() if items}


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def _viewer_role(action: dict, viewer_email: Optional[str]) -> str:
    email = (viewer_email or "").strip().lower()
    if not email:
        return "viewer"
    if email == (action.get("owner_email") or "").lower():
        return "owner"
    if email == (action.get("requester_email") or "").lower():
        return "requester"
    return "viewer"


def _can_run_command(status: str, command: str, role: str) -> bool:
    if role not in {"owner", "requester"}:
        return False
    if command not in ACTION_TRANSITIONS.get(status, {}):
        return False
    if command in {"accept", "reject"}:
        return role == "owner"
    if command == "confirm":
        return role == "requester"
    if command == "cancel":
        return role in {"owner", "requester"}
    return False


def _allowed_actions_for(status: str, role: str) -> List[str]:
    possible = list(ACTION_TRANSITIONS.get(status, {}).keys())
    return [command for command in possible if _can_run_command(status, command, role)]


def _serialize_action(action: dict, viewer_email: Optional[str] = None) -> dict:
    role = _viewer_role(action, viewer_email)
    status = action["status"]
    contact_unlocked = status in {"accepted", "confirmed"} and role in {"owner", "requester"}
    counterpart_name: Optional[str] = None
    counterpart_email: Optional[str] = None
    counterpart_phone: Optional[str] = None

    if contact_unlocked:
        if role == "requester":
            counterpart_name = action.get("owner_name") or "상대"
            counterpart_email = action.get("owner_email")
            counterpart_phone = action.get("owner_phone")
        elif role == "owner":
            counterpart_name = action.get("requester_name") or "요청자"
            counterpart_email = action.get("requester_email")

    return {
        "id": action["id"],
        "category_id": action["category_id"],
        "recommendation_id": action["recommendation_id"],
        "recommendation_title": action["recommendation_title"],
        "recommendation_subtitle": action.get("recommendation_subtitle", ""),
        "status": status,
        "actor_role": role,
        "requester_email": action.get("requester_email", ""),
        "requester_name": action.get("requester_name", ""),
        "owner_email_masked": _mask_email(action.get("owner_email", "")),
        "allowed_actions": _allowed_actions_for(status, role),
        "contact_unlocked": contact_unlocked,
        "counterpart_name": counterpart_name,
        "counterpart_email": counterpart_email,
        "counterpart_phone": counterpart_phone,
        "note": action.get("note"),
        "created_at": action["created_at"],
        "updated_at": action["updated_at"],
        "history": list(action.get("history", [])),
    }


def list_actions(category_id: Optional[str] = None, viewer_email: Optional[str] = None) -> List[dict]:
    if category_id:
        ids = ACTION_INDEX_BY_CATEGORY.get(category_id, [])
    else:
        ids = list(ACTIONS.keys())

    actions = [ACTIONS[action_id] for action_id in ids if action_id in ACTIONS]
    actions.sort(key=lambda item: item.get("updated_at", ""), reverse=True)
    return [_serialize_action(item, viewer_email=viewer_email) for item in actions]


def find_action_by_recommendation(
    category_id: str,
    recommendation_id: str,
    requester_email: Optional[str] = None,
) -> Optional[dict]:
    candidate_ids = ACTION_INDEX_BY_RECOMMENDATION.get(recommendation_id, [])
    req_email = (requester_email or "").strip().lower()
    for action_id in candidate_ids:
        action = ACTIONS.get(action_id)
        if not action:
            continue
        if action["category_id"] != category_id:
            continue
        if req_email and (action.get("requester_email") or "").lower() != req_email:
            continue
        if action["status"] in {"requested", "accepted"}:
            return action
    return None


def request_action(
    category_id: Optional[str],
    recommendation_id: str,
    recommendation_title: str,
    recommendation_subtitle: str = "",
    requester_email: str = "",
    requester_name: Optional[str] = None,
    note: Optional[str] = None,
) -> dict:
    cid = category_id or "friend"
    req_email = requester_email.strip().lower()
    if not req_email:
        raise ValueError("requester_email is required")

    existing = find_action_by_recommendation(cid, recommendation_id, requester_email=req_email)
    if existing:
        return _serialize_action(existing, viewer_email=req_email)

    board_item = _find_board_item(cid, recommendation_id)
    owner_profile = _owner_profile_for(cid, stable_index=0)
    owner_email = (board_item or {}).get("owner_email", owner_profile["email"]).lower()
    owner_name = (board_item or {}).get("owner_name", owner_profile["name"])
    owner_phone = (board_item or {}).get("owner_phone", owner_profile["phone"])

    if owner_email == req_email:
        raise ValueError("cannot request your own listing")

    now = _now_iso()
    action_id = f"act-{uuid4().hex[:10]}"
    action = {
        "id": action_id,
        "category_id": cid,
        "recommendation_id": recommendation_id,
        "recommendation_title": recommendation_title,
        "recommendation_subtitle": recommendation_subtitle,
        "status": "requested",
        "requester_email": req_email,
        "requester_name": (requester_name or req_email.split("@")[0]).strip() or "요청자",
        "owner_email": owner_email,
        "owner_name": owner_name,
        "owner_phone": owner_phone,
        "note": note,
        "created_at": now,
        "updated_at": now,
        "history": [
            {
                "status": "requested",
                "note": note,
                "at": now,
            }
        ],
    }
    ACTIONS[action_id] = action
    ACTION_INDEX_BY_CATEGORY[cid].append(action_id)
    ACTION_INDEX_BY_RECOMMENDATION[recommendation_id].append(action_id)
    return _serialize_action(action, viewer_email=req_email)


def transition_action(action_id: str, command: str, actor_email: str, note: Optional[str] = None) -> dict:
    action = ACTIONS.get(action_id)
    if not action:
        raise KeyError(action_id)

    current = action["status"]
    possible = ACTION_TRANSITIONS.get(current, {})
    if command not in possible:
        allowed = ", ".join(possible.keys()) if possible else "없음"
        raise ValueError(f"invalid transition: {current} -> {command} (allowed: {allowed})")

    role = _viewer_role(action, actor_email)
    if not _can_run_command(current, command, role):
        raise PermissionError(f"forbidden transition: role={role}, status={current}, command={command}")

    next_status = possible[command]
    now = _now_iso()
    action["status"] = next_status
    action["updated_at"] = now
    if note is not None:
        action["note"] = note
    action.setdefault("history", []).append(
        {
            "status": next_status,
            "note": note,
                "at": now,
            }
    )
    return _serialize_action(action, viewer_email=actor_email)


def publish_listing(
    category_id: Optional[str],
    message: str,
    owner_name: Optional[str] = None,
    owner_email: Optional[str] = None,
) -> Tuple[Recommendation, bool]:
    cid = category_id or "friend"
    tags = _extract_tags(message)
    title = _profile_title(cid)
    summary = message.strip()
    if not summary:
        summary = "조건 미입력"
    if len(summary) > 42:
        summary = summary[:42] + "..."
    normalized_owner_email = (owner_email or "").strip().lower()

    # AI 업서트: 같은 카테고리에서 내가 올린 최신 글을 음성/텍스트로 다시 말하면 수정으로 처리.
    if normalized_owner_email:
        for idx, existing in enumerate(BOARD.get(cid, [])):
            if (existing.get("owner_email") or "").lower() != normalized_owner_email:
                continue
            existing["title"] = f"{title} 수정됨"
            existing["subtitle"] = summary
            existing["tags"] = tags[:4] if tags else ["매칭", "조건"]
            existing["detail"] = f"{summary}\n등록자: {owner_name or existing.get('owner_name', '익명')}\n태그: {', '.join(tags)}"
            if owner_name:
                existing["owner_name"] = owner_name
            existing["updated_at"] = _now_iso()
            # 수정된 항목을 보드 최상단으로 이동
            BOARD[cid].pop(idx)
            BOARD[cid].insert(0, existing)
            return _recommendation_from_item(existing, score=0.99), True

    item = _insert_board_item(
        category_id=cid,
        title=f"{title} 등록됨",
        subtitle=summary,
        tags=tags,
        detail=f"{summary}\n등록자: {owner_name or '익명'}\n태그: {', '.join(tags)}",
        owner_name=owner_name,
        owner_email=normalized_owner_email or None,
    )
    return _recommendation_from_item(item, score=0.99), False


def recommend(category_id: Optional[str], message: str, mode: Optional[str] = "find") -> List[Recommendation]:
    cid = category_id or "friend"
    default_items = _default_candidates_for_category(cid)
    board_items = BOARD.get(cid, [])
    query_tokens = _extract_query_tokens(message)
    scored: List[Tuple[Recommendation, int]] = []

    for item in board_items:
        score, hits = _score_item(query_tokens, item, from_board=True)
        scored.append((_recommendation_from_item(item, score=score), hits))

    if not board_items:
        for idx, item in enumerate(default_items, start=1):
            item_for_score = {
                "title": item["title"],
                "subtitle": item["subtitle"],
                "tags": item["tags"],
            }
            score, hits = _score_item(query_tokens, item_for_score, from_board=False)
            scored.append(
                (
                    Recommendation(
                        id=f"{cid}-default-{idx}",
                        title=item["title"],
                        subtitle=item["subtitle"],
                        tags=item["tags"],
                        score=score,
                        detail=f"{item['title']} · {item['subtitle']}",
                        image_urls=_image_seed_urls(f"{cid}-default-{idx}", count=3),
                        owner_name=_owner_profile_for(cid, idx)["name"],
                        owner_email_masked=_mask_email(_owner_profile_for(cid, idx)["email"]),
                        owner_phone_masked=_mask_phone(_owner_profile_for(cid, idx)["phone"]),
                    ),
                    hits,
                )
            )

    if query_tokens:
        matched_only = [row for row in scored if row[1] > 0]
        if matched_only:
            scored = matched_only
        else:
            # 거래/쇼핑 도메인은 미일치 fallback 추천을 노출하지 않는다.
            # (예: "코치가방" 검색 시 무관한 명품 후보 노출 방지)
            domain = CATEGORY_DOMAIN_BY_ID.get(cid, "people")
            if domain == "market" and mode != "publish":
                return []

    scored.sort(key=lambda row: (row[1], row[0].score), reverse=True)
    out = [row[0] for row in scored]
    if mode == "publish":
        return out[:5]
    return out[:8]


def find_action_for_viewer(
    category_id: str,
    recommendation_id: str,
    viewer_email: Optional[str],
) -> Optional[dict]:
    candidate_ids = ACTION_INDEX_BY_RECOMMENDATION.get(recommendation_id, [])
    if not candidate_ids:
        return None

    email = (viewer_email or "").strip().lower()
    candidates: List[dict] = []
    for action_id in candidate_ids:
        action = ACTIONS.get(action_id)
        if not action:
            continue
        if action.get("category_id") != category_id:
            continue
        candidates.append(action)

    if not candidates:
        return None

    candidates.sort(key=lambda item: item.get("updated_at", ""), reverse=True)
    if not email:
        return candidates[0]

    for action in candidates:
        if email in {
            (action.get("owner_email") or "").lower(),
            (action.get("requester_email") or "").lower(),
        }:
            return action
    return candidates[0]


def recommendation_detail(category_id: str, recommendation_id: str, viewer_email: Optional[str] = None) -> dict:
    item = _find_board_item(category_id, recommendation_id)
    if not item:
        # 기본 추천에서 생성된 id(default-*)를 상세 조회할 때의 fallback
        defaults = _default_candidates_for_category(category_id)
        matched = None
        for idx, row in enumerate(defaults, start=1):
            if recommendation_id == f"{category_id}-default-{idx}":
                matched = row
                break
        if not matched:
            raise KeyError(recommendation_id)
        owner = _owner_profile_for(category_id, 1)
        item = {
            "id": recommendation_id,
            "title": matched["title"],
            "subtitle": matched["subtitle"],
            "tags": matched["tags"],
            "detail": f"{matched['title']} · {matched['subtitle']}",
            "image_urls": _image_seed_urls(recommendation_id, count=3),
            "owner_name": owner["name"],
            "owner_email": owner["email"],
            "owner_phone": owner["phone"],
        }

    recommendation = _recommendation_from_item(item, score=0.99).dict()
    action = find_action_for_viewer(category_id, recommendation_id, viewer_email)
    return {
        "recommendation": recommendation,
        "action": _serialize_action(action, viewer_email=viewer_email) if action else None,
    }
