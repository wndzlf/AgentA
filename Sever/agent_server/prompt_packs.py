from __future__ import annotations

from typing import Dict, List, Optional, Tuple

# domain:
# - people: 사람/관계 매칭
# - sport: 스포츠 매칭
# - market: 사고팔기/양도 매칭
# - service: 전문가/서비스 매칭
# - learning: 스터디/클래스 매칭
# - job: 채용/구직 매칭

# tuple shape:
# (id, name, summary, icon, focus)
PEOPLE_CATEGORIES: List[Tuple[str, str, str, str, str]] = [
    ("dating", "소개팅", "성향 기반 이성 추천", "heart.circle", "관계 목표, 가치관, 라이프스타일"),
    ("friend", "친구 만들기", "관심사/성격 기반 매칭", "person.2.circle", "관심사, 활동 시간, 대화 성향"),
    ("networking", "비즈니스 네트워킹", "업계/직무 기반 연결", "person.3", "직무, 업계, 협업 목적"),
    ("meetup", "모임/번개", "지역 기반 소셜 모임", "person.3", "지역, 모임 목적, 인원"),
    ("roommate", "룸메이트", "주거/생활 패턴 매칭", "house.and.person", "예산, 생활패턴, 반려/흡연 여부"),
    ("travelmate", "여행 메이트", "일정/취향 기반 동행", "airplane.circle", "여행지, 일정, 예산"),
    ("language", "언어교환", "언어/시간대 기반 파트너", "globe", "학습 언어, 회화 레벨, 시간대"),
    ("mentor", "멘토링", "멘토/멘티 매칭", "graduationcap.circle", "경력 단계, 멘토링 목표"),
    ("volunteer", "봉사/기부", "봉사활동/후원 연결", "hand.raised.circle", "봉사 분야, 가능 시간"),
    ("parenting", "육아 돌봄", "돌봄 요청/도우미 매칭", "figure.and.child.holdinghands", "아동 연령, 돌봄 시간, 지역"),
    ("pet", "반려동물 입양", "입양/임시보호/분양 매칭", "pawprint.circle", "반려경험, 거주환경, 케어 가능시간"),
    ("gaming", "게임 파티", "게임/티어 기반 파티", "gamecontroller.circle", "게임명, 티어, 플레이 시간"),
    ("foodmate", "맛집 메이트", "식사/카페 동행", "fork.knife.circle", "지역, 음식 취향, 시간"),
    ("moviebuddy", "영화 메이트", "영화 취향 기반 동행", "film.circle", "장르, 관람 시간, 지역"),
    ("musicbuddy", "공연 메이트", "공연/페스티벌 동행", "music.note", "장르, 일정, 지역"),
    ("startup", "창업 팀빌딩", "공동창업/핵심멤버 매칭", "briefcase.circle", "아이템 단계, 필요 역할"),
    ("petcaremate", "펫시터 메이트", "반려동물 돌봄 매칭", "pawprint.circle", "견종/묘종, 돌봄 방식, 시간"),
    ("carpool", "카풀", "출퇴근/통학 카풀 매칭", "car.circle", "출발지/도착지, 시간"),
    ("neighborhelp", "동네 도움", "생활 도움 교환", "house.circle", "요청 종류, 지역, 가능 시간"),
    ("hobbyclub", "취미 동호회", "취미 기반 커뮤니티 매칭", "sparkles", "취미 주제, 활동 빈도"),
]

SPORT_CATEGORIES: List[Tuple[str, str, str, str, str]] = [
    ("soccer", "축구 매칭", "상대팀/용병 매칭", "sportscourt.circle", "지역, 시간, 경기형식, 실력대"),
    ("futsal", "풋살 매칭", "근거리 풋살 팀 매칭", "sportscourt.circle", "지역, 시간, 5:5 인원, 실력대"),
    ("tennis", "테니스 매칭", "복식/랠리 파트너 매칭", "sportscourt.circle", "코트 위치, 단/복식, 레벨"),
    ("badminton", "배드민턴 매칭", "실력/지역 기반 파트너", "sportscourt.circle", "체육관, 게임수, 레벨"),
    ("basketball", "농구 매칭", "팀원/상대팀 매칭", "sportscourt.circle", "풀코트/하프, 인원, 레벨"),
    ("baseball", "야구 매칭", "용병/친선 경기 매칭", "sportscourt.circle", "포지션, 경기일, 리그 레벨"),
    ("volleyball", "배구 매칭", "팀/포지션 기반 매칭", "sportscourt.circle", "실내/비치, 포지션, 레벨"),
    ("golf", "골프 라운딩", "동반자/티타임 매칭", "flag.circle", "골프장, 티타임, 평균타수"),
    ("running", "러닝 크루", "페이스/코스 기반 매칭", "figure.run.circle", "페이스, 거리, 코스"),
    ("cycling", "사이클 동행", "거리/코스 기반 동행", "bicycle.circle", "코스, 평균속도, 거리"),
    ("hiking", "등산 동행", "난이도/코스 기반 매칭", "mountain.2", "산행 코스, 난이도, 시간"),
    ("climbing", "클라이밍 파트너", "짐/난이도 기반 매칭", "figure.climbing", "짐 위치, 난이도, 등반 스타일"),
    ("swimming", "수영 파트너", "영법/레벨 기반 매칭", "figure.pool.swim", "영법, 페이스, 레인 시간"),
    ("pingpong", "탁구 매칭", "레벨/장소 기반 매칭", "sportscourt.circle", "구장, 단/복식, 레벨"),
    ("bowling", "볼링 매칭", "평균점수 기반 매칭", "sportscourt.circle", "볼링장, 평균점수, 시간"),
    ("yoga", "요가 메이트", "레벨/시간 기반 동행", "figure.cooldown", "요가 스타일, 수업 시간"),
    ("pilates", "필라테스 메이트", "수업/레벨 기반 동행", "figure.core.training", "기구/매트, 수업 시간"),
    ("martialarts", "무술 파트너", "종목/체급 기반 매칭", "figure.martial.arts", "종목, 체급, 스파링 강도"),
    ("surf", "서핑 동행", "포인트/파도 기반 동행", "water.waves", "포인트, 레벨, 이동수단"),
    ("snowboard", "스노보드 동행", "슬로프/레벨 기반 동행", "snow", "리조트, 슬로프, 레벨"),
    ("ski", "스키 동행", "코스/레벨 기반 동행", "snowflake.circle", "리조트, 코스, 레벨"),
    ("fishing", "낚시 동행", "포인트/어종 기반 동행", "drop.circle", "어종, 포인트, 출조시간"),
    ("padel", "파델 매칭", "코트/레벨 기반 파트너", "sportscourt.circle", "코트 위치, 레벨, 복식"),
    ("squash", "스쿼시 매칭", "코트/레벨 기반 파트너", "sportscourt.circle", "코트 위치, 경기 템포"),
    ("crossfit", "크로스핏 메이트", "WOD/시간 기반 동행", "figure.strengthtraining.traditional", "박스 위치, WOD 난이도"),
    ("boxing", "복싱 파트너", "스파링/미트 파트너", "sportscourt.circle", "체급, 강도, 시간"),
    ("dance", "댄스 메이트", "장르/레벨 기반 동행", "music.note", "장르, 연습시간, 레벨"),
    ("skate", "스케이트 메이트", "장소/레벨 기반 동행", "sportscourt.circle", "장소, 레벨, 시간"),
    ("triathlon", "트라이애슬론 크루", "훈련 파트너 매칭", "figure.run.circle", "훈련 종목, 주당 훈련량"),
    ("diving", "다이빙 버디", "해역/라이선스 기반 매칭", "water.waves", "라이선스, 해역, 일정"),
]

MARKET_CATEGORIES: List[Tuple[str, str, str, str, str]] = [
    ("trade", "일반 거래", "사고팔기/가격 제안", "cart.circle", "상품명, 가격, 상태, 거래지역"),
    ("luxury", "명품 거래", "브랜드/상태 기반 거래", "sparkles", "브랜드, 모델, 정품증빙, 상태"),
    ("ticket", "티켓 양도", "공연/스포츠 티켓 거래", "ticket", "공연명, 일정, 좌석, 매수"),
    ("usedcar", "중고차 거래", "차량 조건 기반 거래", "car.circle", "차종, 연식, 주행거리, 사고이력"),
    ("realestate", "부동산", "매물/조건 기반 매칭", "building.columns.circle", "위치, 예산, 평형, 계약형태"),
    ("electronics", "전자기기 거래", "가전/디지털 기기 거래", "laptopcomputer", "모델명, 상태, 구성품"),
    ("mobile", "휴대폰 거래", "스마트폰/태블릿 거래", "iphone", "기기명, 용량, 배터리 상태"),
    ("computer", "컴퓨터 거래", "데스크탑/노트북 거래", "desktopcomputer", "CPU/GPU, 사용기간, 상태"),
    ("tablet", "태블릿 거래", "태블릿/펜슬 거래", "ipad", "모델, 용량, 배터리 상태"),
    ("console", "게임기 거래", "콘솔/패키지 거래", "gamecontroller.circle", "기종, 컨트롤러, 타이틀"),
    ("gaminggear", "게이밍 장비 거래", "키보드/마우스/헤드셋", "gamecontroller", "모델, 스위치, 사용감"),
    ("fashion", "패션 거래", "의류/신발/가방 거래", "tshirt", "브랜드, 사이즈, 착용횟수"),
    ("beauty", "뷰티 거래", "화장품/향수 거래", "sparkles", "브랜드, 개봉여부, 유통기한"),
    ("watches", "시계 거래", "시계/스트랩 거래", "clock", "브랜드, 보증서, 오버홀"),
    ("jewelry", "주얼리 거래", "반지/목걸이 거래", "sparkles", "소재, 보증서, 상태"),
    ("bags", "가방 거래", "백팩/토트/크로스백 거래", "bag", "브랜드, 사이즈, 상태"),
    ("shoes", "신발 거래", "운동화/구두 거래", "shoeprints.fill", "브랜드, 사이즈, 실착횟수"),
    ("books", "도서 거래", "책/교재 거래", "book.circle", "도서명, 필기여부, 상태"),
    ("furniture", "가구 거래", "책상/의자/침대 거래", "square.grid.2x2", "사이즈, 사용기간, 운반방식"),
    ("appliance", "가전 거래", "TV/냉장고/세탁기 거래", "tv", "모델명, 연식, 설치조건"),
    ("homegoods", "생활용품 거래", "생활/정리용품 거래", "shippingbox.circle", "품목, 상태, 수량"),
    ("kitchen", "주방용품 거래", "식기/조리도구 거래", "fork.knife.circle", "브랜드, 구성품, 상태"),
    ("kids", "유아용품 거래", "유모차/장난감 거래", "figure.2.and.child.holdinghands", "연령대, 상태, 구성품"),
    ("baby", "출산/육아 물품", "육아 소모품/장비 거래", "figure.and.child.holdinghands", "품목, 개봉여부, 수량"),
    ("petgoods", "반려용품 거래", "사료/장난감/케이지 거래", "pawprint.circle", "반려종, 유통기한, 상태"),
    ("camera", "카메라 거래", "바디/렌즈/악세사리", "camera.circle", "모델, 컷수, 보증여부"),
    ("musicgear", "악기 거래", "기타/피아노/음향장비", "music.note", "모델, 사용기간, 상태"),
    ("collectibles", "수집품 거래", "피규어/카드/굿즈 거래", "gift.circle", "희소성, 상태, 구성품"),
    ("art", "아트 거래", "그림/디자인/작품 거래", "paintpalette", "작품 정보, 크기, 보증"),
    ("handmade", "핸드메이드 거래", "수공예/제작품 거래", "scissors", "재료, 제작방식, 커스텀 여부"),
    ("food", "식품 거래", "공동구매/지역 식품 거래", "fork.knife.circle", "품목, 수량, 수령방식"),
    ("coupon", "쿠폰/기프티콘", "쿠폰/상품권 거래", "tag.circle", "유효기간, 금액, 사용처"),
    ("bicycletrade", "자전거 거래", "자전거/부품 거래", "bicycle.circle", "차종, 사이즈, 상태"),
    ("motorcycle", "오토바이 거래", "바이크/장비 거래", "car.circle", "차종, 배기량, 주행거리"),
    ("carparts", "자동차 부품 거래", "타이어/휠/부품 거래", "car", "차종호환, 상태, 장착이력"),
    ("sportsgear", "스포츠용품 거래", "운동장비/유니폼 거래", "sportscourt.circle", "종목, 사이즈, 상태"),
    ("camping", "캠핑용품 거래", "텐트/버너/캠핑장비", "tent.circle", "구성품, 사용횟수, 하자"),
    ("office", "사무용품 거래", "의자/모니터/문구 거래", "briefcase.circle", "품목, 수량, 상태"),
    ("industrial", "산업장비 거래", "공구/산업기기 거래", "wrench.and.screwdriver", "사양, 사용시간, 점검이력"),
    ("plants", "식물 거래", "식물/화분 거래", "leaf.circle", "종류, 크기, 관리난이도"),
    ("craftmaterial", "재료 거래", "DIY/공예 재료 거래", "shippingbox", "재료명, 수량, 상태"),
    ("rentals", "대여 거래", "물품 단기 대여", "clock.arrow.circlepath", "대여기간, 보증금, 상태"),
    ("subscription", "구독권 거래", "구독권/이용권 양도", "creditcard", "잔여기간, 이전 가능여부"),
]

SERVICE_CATEGORIES: List[Tuple[str, str, str, str, str]] = [
    ("freelance", "프리랜서", "프로젝트/전문가 매칭", "briefcase.circle", "업무범위, 예산, 일정"),
    ("design", "디자인 의뢰", "로고/UI/브랜딩 의뢰", "paintbrush.pointed", "스타일, 산출물, 납기"),
    ("developer", "개발 의뢰", "웹/앱/백엔드 개발", "chevron.left.forwardslash.chevron.right", "기능범위, 스택, 일정"),
    ("marketing", "마케팅 의뢰", "광고/콘텐츠/운영", "megaphone", "채널, KPI, 예산"),
    ("translation", "번역/통역", "문서 번역/현장 통역", "character.book.closed", "언어쌍, 분량, 마감"),
    ("photo", "사진 촬영", "스냅/프로필/제품 촬영", "camera.circle", "촬영목적, 컷수, 보정범위"),
    ("video", "영상 제작", "촬영/편집/숏폼 제작", "video.circle", "분량, 스타일, 납기"),
    ("event", "행사 대행", "행사/공연/프로모션 대행", "party.popper", "행사규모, 일정, 예산"),
    ("wedding", "웨딩 서비스", "스튜디오/메이크업/플래너", "heart.circle", "예식일, 스타일, 예산"),
    ("moving", "이사/운반", "이사/소형 운송 매칭", "truck.box", "출발/도착, 짐량, 날짜"),
    ("cleaning", "청소 서비스", "입주/거주 청소", "sparkles", "공간크기, 오염도, 일정"),
    ("repair", "수리 서비스", "가전/집수리/장비수리", "wrench.and.screwdriver", "고장증상, 모델, 방문시간"),
    ("legal", "법률 상담", "계약/분쟁/노무 상담", "building.columns", "사안 유형, 긴급도, 예산"),
    ("tax", "세무/회계", "세무 신고/회계 상담", "doc.text", "사업유형, 기간, 신고범위"),
    ("consulting", "비즈니스 컨설팅", "전략/운영/PM 컨설팅", "chart.line.uptrend.xyaxis", "목표, 기간, 예산"),
    ("coaching", "코칭", "커리어/라이프 코칭", "person.crop.circle.badge.checkmark", "목표, 주기, 진행방식"),
    ("health", "건강/피트니스", "식단/운동 코칭", "heart.text.square", "목표, 제약사항, 주당빈도"),
    ("pt", "퍼스널 트레이닝", "PT 트레이너 매칭", "figure.strengthtraining.functional", "목표부위, 주당횟수, 예산"),
    ("petcare", "펫케어 서비스", "산책/돌봄/미용 매칭", "pawprint.circle", "반려종, 시간, 장소"),
    ("housekeeping", "가사 도우미", "정리/청소/가사 도움", "house.circle", "업무범위, 주기, 시간"),
    ("interior", "인테리어 상담", "리모델링/공간 컨설팅", "square.grid.2x2", "공간유형, 예산, 일정"),
    ("delivery", "심부름/배달 대행", "생활 심부름 매칭", "shippingbox.circle", "요청내용, 거리, 시간"),
    ("driver", "운전 대행", "픽업/장거리 운전", "car.circle", "경로, 시간, 보험조건"),
    ("va", "비서/운영 지원", "리서치/운영/CS 지원", "doc.text", "업무범위, 근무시간, 기간"),
    ("data", "데이터 분석", "대시보드/리포트 구축", "chart.bar.xaxis", "데이터소스, 목표지표, 납기"),
    ("copywriting", "카피라이팅", "브랜드/광고 문구 작성", "text.quote", "톤앤매너, 매체, 분량"),
    ("voiceover", "보이스오버", "나레이션/성우 녹음", "mic.circle", "톤, 길이, 납기"),
    ("musicprod", "음원 제작", "작곡/편곡/믹싱 매칭", "music.note", "장르, 레퍼런스, 납기"),
    ("itsupport", "IT 지원", "설치/장애 대응 서비스", "desktopcomputer", "환경, 장애증상, 일정"),
    ("hrservice", "HR 서비스", "채용/평가/조직 운영 지원", "person.3", "조직규모, 과제, 기간"),
]

LEARNING_CATEGORIES: List[Tuple[str, str, str, str, str]] = [
    ("study", "스터디", "학습 목표 기반 스터디 매칭", "book.circle", "주제, 목표, 주당 학습시간"),
    ("class", "원데이 클래스", "클래스 등록/수강 매칭", "paintpalette", "주제, 정원, 일정"),
    ("tutoring", "과외", "학생/튜터 매칭", "graduationcap.circle", "과목, 학년, 목표"),
    ("codingstudy", "코딩 스터디", "개발 스터디 파트너", "chevron.left.forwardslash.chevron.right", "언어/프레임워크, 목표"),
    ("languageclass", "어학 스터디", "회화/시험 기반 스터디", "globe", "언어, 레벨, 목표점수"),
    ("examprep", "시험 준비", "공무원/자격시험 스터디", "doc.text", "시험종류, 일정, 강도"),
    ("certification", "자격증 스터디", "자격증 취득 스터디", "checkmark.seal", "자격증명, 준비기간"),
    ("bookclub", "북클럽", "독서/토론 모임", "book.circle", "도서장르, 모임주기"),
    ("research", "연구 협업", "논문/리서치 협업 매칭", "magnifyingglass", "주제, 방법론, 역할"),
    ("publicspeaking", "발표/스피치", "발표 연습 파트너", "mic.circle", "주제, 발표시간, 피드백 방식"),
    ("financeclass", "금융 스터디", "재테크/회계 학습 모임", "chart.line.uptrend.xyaxis", "학습주제, 난이도"),
    ("designclass", "디자인 스터디", "UI/그래픽 학습 모임", "paintbrush.pointed", "툴, 목표 포트폴리오"),
    ("musicclass", "음악 레슨", "악기/보컬 학습 매칭", "music.note", "악기, 레벨, 레슨주기"),
    ("fitnessclass", "운동 클래스", "운동 클래스/챌린지", "figure.run.circle", "종목, 빈도, 목표"),
    ("kidsclass", "아동 클래스", "아동 학습/체험 클래스", "figure.and.child.holdinghands", "연령, 수업형태, 시간"),
]

JOB_CATEGORIES: List[Tuple[str, str, str, str, str]] = [
    ("job", "구인구직", "채용/지원 매칭", "building.2.crop.circle", "직무, 경력, 근무형태"),
    ("parttime", "알바 매칭", "단기/파트타임 매칭", "briefcase.circle", "근무시간, 시급, 지역"),
    ("intern", "인턴십", "인턴 공고/지원 매칭", "graduationcap.circle", "직무, 기간, 우대역량"),
    ("remotejob", "원격근무", "리모트 포지션 매칭", "desktopcomputer", "타임존, 협업도구, 고용형태"),
    ("gig", "긱 워크", "단건 업무 매칭", "bolt.circle", "업무단위, 단가, 마감"),
    ("sideproject", "사이드프로젝트", "사이드프로젝트 팀 빌딩", "sparkles", "프로젝트 주제, 필요역할"),
    ("recruiting", "리크루팅", "채용 담당자/후보 연결", "person.3", "채용직무, 채용단계"),
    ("startuphire", "스타트업 채용", "초기팀 채용/합류", "briefcase.circle", "미션, 역할, 보상구조"),
    ("contract", "계약직 매칭", "기간제 채용 매칭", "doc.text", "계약기간, 업무범위, 단가"),
    ("globaljob", "해외취업", "해외 포지션 매칭", "globe", "국가, 비자, 언어"),
    ("careerchange", "커리어 전환", "직무 전환 매칭", "arrow.triangle.2.circlepath", "현재경력, 전환희망직무"),
    ("portfolio", "포트폴리오 피드백", "실무자 포트폴리오 리뷰", "folder.circle", "직군, 작품수, 목표회사"),
]


def _build_defs(domain: str, rows: List[Tuple[str, str, str, str, str]]) -> List[Dict[str, str]]:
    out: List[Dict[str, str]] = []
    for cid, name, summary, icon, focus in rows:
        out.append(
            {
                "id": cid,
                "name": name,
                "summary": summary,
                "icon": icon,
                "domain": domain,
                "focus": focus,
            }
        )
    return out


CATEGORY_DEFS: List[Dict[str, str]] = [
    *_build_defs("people", PEOPLE_CATEGORIES),
    *_build_defs("sport", SPORT_CATEGORIES),
    *_build_defs("market", MARKET_CATEGORIES),
    *_build_defs("service", SERVICE_CATEGORIES),
    *_build_defs("learning", LEARNING_CATEGORIES),
    *_build_defs("job", JOB_CATEGORIES),
]

CATEGORIES: List[Dict[str, str]] = [
    {"id": item["id"], "name": item["name"], "summary": item["summary"], "icon": item["icon"]}
    for item in CATEGORY_DEFS
]

CATEGORY_NAME_BY_ID = {item["id"]: item["name"] for item in CATEGORIES}
CATEGORY_DOMAIN_BY_ID = {item["id"]: item["domain"] for item in CATEGORY_DEFS}
CATEGORY_FOCUS_BY_ID = {item["id"]: item["focus"] for item in CATEGORY_DEFS}
DEFAULT_MODE = "find"


def _make_modes(name: str, domain: str, focus: str) -> Dict[str, Dict[str, str]]:
    focus_hint = f"핵심 포인트: {focus}."

    if domain == "people":
        return {
            "find": {
                "title": "찾기",
                "description": f"{name} 대상 매칭",
                "prompt_hint": f"{focus_hint} 지역/시간/원하는 관계 조건을 입력해주세요.",
                "welcome": f"{name} 찾기 모드입니다. 원하는 조건을 말해주세요.",
                "system_prompt": (
                    f"{name} 매칭 코치처럼 응답하세요. {focus_hint} "
                    "입력에서 핵심 조건을 구조화하고 누락된 필수 조건 1개만 질문하세요."
                ),
            },
            "publish": {
                "title": "나를 올리기",
                "description": f"{name}용 내 프로필 등록",
                "prompt_hint": f"{focus_hint} 내 성향/가능 시간/활동 지역을 입력해주세요.",
                "welcome": f"{name} 프로필 등록 모드입니다. 나를 소개해주세요.",
                "system_prompt": (
                    f"{name} 등록 도우미처럼 응답하세요. {focus_hint} "
                    "입력을 프로필 문장 2개로 요약하고 안전/신뢰 확인 질문 1개를 하세요."
                ),
            },
        }

    if domain == "sport":
        return {
            "find": {
                "title": "매칭 찾기",
                "description": f"{name} 상대/파트너 탐색",
                "prompt_hint": f"{focus_hint} 지역/시간/실력/인원(또는 경기형식)을 입력해주세요.",
                "welcome": f"{name} 매칭 찾기 모드입니다. 원하는 경기 조건을 알려주세요.",
                "system_prompt": (
                    f"{name} 경기 코디네이터처럼 응답하세요. {focus_hint} "
                    "매칭 성사율을 높이기 위해 누락된 경기 정보 1개를 질문하세요."
                ),
            },
            "publish": {
                "title": "팀/내 정보 올리기",
                "description": f"{name} 모집/요청 등록",
                "prompt_hint": f"{focus_hint} 팀 정보, 가능한 시간, 요청사항을 입력해주세요.",
                "welcome": f"{name} 등록 모드입니다. 팀/파트너 정보를 입력해주세요.",
                "system_prompt": (
                    f"{name} 등록 도우미처럼 응답하세요. {focus_hint} "
                    "등록글을 한 번에 이해되게 요약하고 누락된 필수정보 1개를 질문하세요."
                ),
            },
        }

    if domain == "market":
        return {
            "find": {
                "title": "매물 찾기",
                "description": f"{name} 조건 기반 탐색",
                "prompt_hint": f"{focus_hint} 상품명/예산/상태/거래조건을 입력해주세요.",
                "welcome": f"{name} 매물 찾기 모드입니다. 원하는 조건을 알려주세요.",
                "system_prompt": (
                    f"{name} 거래 에이전트처럼 응답하세요. {focus_hint} "
                    "거래 확정을 위해 필요한 추가 질문 1개를 하세요."
                ),
            },
            "publish": {
                "title": "매물 올리기",
                "description": f"{name} 판매/양도 등록",
                "prompt_hint": f"{focus_hint} 상품 정보, 상태, 가격, 거래방식을 입력해주세요.",
                "welcome": f"{name} 매물 등록 모드입니다. 판매/양도 정보를 입력해주세요.",
                "system_prompt": (
                    f"{name} 등록 도우미처럼 응답하세요. {focus_hint} "
                    "매물 핵심을 요약하고 신뢰도에 중요한 질문 1개를 하세요."
                ),
            },
        }

    if domain == "service":
        return {
            "find": {
                "title": "전문가 찾기",
                "description": f"{name} 제공자 탐색",
                "prompt_hint": f"{focus_hint} 요청 내용, 예산, 일정, 지역/온라인 여부를 입력해주세요.",
                "welcome": f"{name} 전문가 찾기 모드입니다. 필요한 조건을 알려주세요.",
                "system_prompt": (
                    f"{name} PM처럼 응답하세요. {focus_hint} "
                    "범위/예산/일정을 정리하고 산출물 관련 질문 1개를 하세요."
                ),
            },
            "publish": {
                "title": "서비스 올리기",
                "description": f"{name} 서비스 등록",
                "prompt_hint": f"{focus_hint} 제공 가능 업무, 단가, 일정, 경험을 입력해주세요.",
                "welcome": f"{name} 서비스 등록 모드입니다. 제공 가능한 내용을 입력해주세요.",
                "system_prompt": (
                    f"{name} 등록 도우미처럼 응답하세요. {focus_hint} "
                    "서비스 소개를 2문장으로 요약하고 견적에 필요한 질문 1개를 하세요."
                ),
            },
        }

    if domain == "learning":
        return {
            "find": {
                "title": "모임 찾기",
                "description": f"{name} 참여처 탐색",
                "prompt_hint": f"{focus_hint} 주제, 목표, 시간대, 지역/온라인 여부를 입력해주세요.",
                "welcome": f"{name} 찾기 모드입니다. 원하는 학습 조건을 말해주세요.",
                "system_prompt": (
                    f"{name} 코디네이터처럼 응답하세요. {focus_hint} "
                    "목표/일정/레벨을 정리하고 학습 강도 질문 1개를 하세요."
                ),
            },
            "publish": {
                "title": "모집 올리기",
                "description": f"{name} 모집/개설 등록",
                "prompt_hint": f"{focus_hint} 주제, 일정, 정원, 진행방식, 비용을 입력해주세요.",
                "welcome": f"{name} 등록 모드입니다. 모집 정보를 입력해주세요.",
                "system_prompt": (
                    f"{name} 등록 도우미처럼 응답하세요. {focus_hint} "
                    "모집글을 구조화해 요약하고 누락된 일정 정보 1개를 질문하세요."
                ),
            },
        }

    # domain == "job"
    return {
        "find": {
            "title": "조건 찾기",
            "description": f"{name} 조건 기반 탐색",
            "prompt_hint": f"{focus_hint} 희망 직무, 경력, 조건, 지역/근무형태를 입력해주세요.",
            "welcome": f"{name} 찾기 모드입니다. 원하는 조건을 알려주세요.",
            "system_prompt": (
                f"{name} 커리어 코치처럼 응답하세요. {focus_hint} "
                "우선순위를 정리하고 추가 질문 1개를 하세요."
            ),
        },
        "publish": {
            "title": "공고/프로필 올리기",
            "description": f"{name} 등록",
            "prompt_hint": f"{focus_hint} 역할, 조건, 기간, 위치(또는 리모트)를 입력해주세요.",
            "welcome": f"{name} 등록 모드입니다. 필요한 정보를 입력해주세요.",
            "system_prompt": (
                f"{name} 등록 도우미처럼 응답하세요. {focus_hint} "
                "등록 정보 핵심을 요약하고 선발/지원 기준 질문 1개를 하세요."
            ),
        },
    }


PROMPT_PACKS: Dict[str, Dict[str, Dict[str, str]]] = {
    item["id"]: {"modes": _make_modes(item["name"], item["domain"], item["focus"])}
    for item in CATEGORY_DEFS
}


def resolve_mode(category_id: Optional[str], mode: Optional[str]) -> Tuple[str, Dict[str, str]]:
    cid = category_id or "friend"
    pack = PROMPT_PACKS.get(cid, PROMPT_PACKS["friend"])
    mode_map = pack["modes"]
    mode_id = mode if mode in mode_map else DEFAULT_MODE
    if mode_id not in mode_map:
        mode_id = next(iter(mode_map.keys()))
    return mode_id, mode_map[mode_id]


def mode_options(category_id: Optional[str]) -> List[Dict[str, str]]:
    cid = category_id or "friend"
    pack = PROMPT_PACKS.get(cid, PROMPT_PACKS["friend"])
    out: List[Dict[str, str]] = []
    for mode_id, meta in pack["modes"].items():
        out.append(
            {
                "id": mode_id,
                "title": meta["title"],
                "description": meta["description"],
            }
        )
    return out
