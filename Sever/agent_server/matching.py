from __future__ import annotations

from random import random
from typing import Dict, List, Optional

from .schemas import Recommendation

# 데모용 고정 데이터
CANDIDATES: Dict[str, List[dict]] = {
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


def _score(message: str, tags: List[str]) -> float:
    text = message.lower()
    hits = sum(1 for t in tags if t.lower() in text)
    base = 0.55 + (0.1 * hits)
    noise = random() * 0.2
    return min(0.98, round(base + noise, 2))


def recommend(category_id: Optional[str], message: str) -> List[Recommendation]:
    cid = category_id or "friend"
    items = CANDIDATES.get(cid, CANDIDATES["friend"])
    out: List[Recommendation] = []
    for idx, item in enumerate(items, start=1):
        out.append(
            Recommendation(
                id=f"{cid}-{idx}",
                title=item["title"],
                subtitle=item["subtitle"],
                tags=item["tags"],
                score=_score(message, item["tags"]),
            )
        )
    out.sort(key=lambda x: x.score, reverse=True)
    return out
