# AgentMatchPrototype (iOS)

## 실행

1. 서버 먼저 실행 (무료 AI 포함)

```bash
cd /Users/user/AgentA/Sever
./run_local_ai.sh
```

2. iOS 프로젝트 열기

- Xcode에서 `/Users/user/AgentA/iOS/AgentMatchPrototype/AgentMatchPrototype.xcodeproj` 열기
- `AgentMatchPrototype` 스킴으로 실행

## 화면 구성

- 홈: 상단 `에이전트에게 바로 물어보기` 버튼
- 홈: 카테고리 테이블뷰 + 검색
- 카테고리 상세: AI 대화 + 추천 리스트 카드

## 참고

- 현재 API 주소는 `http://127.0.0.1:8000` (시뮬레이터 기준)
- 실기기 테스트 시 서버 주소를 Mac IP로 변경 필요
- Ollama 첫 응답은 모델 로딩 때문에 10초 이상 걸릴 수 있음

## 빌드 에러 체크

### `Cannot code sign ... Info.plist ...`

이 프로젝트는 명시적 Info.plist를 사용하도록 설정되어 있습니다.

- 파일: `/Users/user/AgentA/iOS/AgentMatchPrototype/AgentMatchPrototype/Resources/Info.plist`
- 설정: `INFOPLIST_FILE = AgentMatchPrototype/Resources/Info.plist`

에러가 계속 보이면:

1. Xcode 완전 종료 후 다시 열기
2. `Product > Clean Build Folder`
3. `~/Library/Developer/Xcode/DerivedData`의 `AgentMatchPrototype*` 삭제 후 재빌드

### 실기기 빌드 시 서명 에러

`Signing for "AgentMatchPrototype" requires a development team`

- Xcode `Signing & Capabilities`에서 팀(Apple ID) 선택 필요
