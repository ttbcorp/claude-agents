# 스킬 라우팅

요청이 스킬과 매칭되면 **Skill 도구를 첫 번째 행동으로 실행**한다.
직접 답변하거나 다른 도구를 먼저 실행하지 않는다.

## ttb-agents 스킬

| 요청 유형 | 스킬 |
|---------|------|
| 프로젝트 팀 구성, 워크플로우 자동화, 릴리스 노트, 코드 작업 | `ttb-agents:agents` |
| UI 만들기, 디자인 검토, AI 안 티나게 개선, 교차 검증 | `ttb-agents:design` |
| 제품 기획, PRD 작성, 시장 조사, 로드맵 수립 | `ttb-agents:pm-workflow` |
| sLLM 에이전트 생성, 소형 모델 자동화, Ollama 하네스 | `ttb-agents:sllm` |
| 하네스 검증, TTB 표준 확인, 에이전트 파일 검토 | `ttb-agents:review` |
| 권한 설정 초기화 (첫 설치 후) | `ttb-agents:setup` |
| 막혔을 때, 어려운 결정, Opus에 물어봐, 어드바이저 | `ttb-agents:advisor` |

## gstack 스킬

| 요청 유형 | 스킬 |
|---------|------|
| 제품 아이디어, 빌드할 가치 있어?, 브레인스토밍 | `office-hours` |
| 버그, 오류, 왜 안 돼, 500 에러, 예상 외 동작 | `investigate` |
| 배포, push, PR 생성, ship | `ship` |
| QA, 사이트 테스트, 버그 찾기 | `qa` |
| 코드 리뷰, diff 확인, pre-landing 검토 | `review` |
| 배포 후 문서 업데이트 | `document-release` |
| 주간 회고, 이번 주 뭐 했어 | `retro` |
| 디자인 시스템 구축, 브랜드 가이드 | `design-consultation` |
| 시각 감사, 디자인 폴리시, 화면 이상해 | `design-review` |
| 아키텍처 리뷰, 설계 검토 | `plan-eng-review` |
| 진행 저장, 컨텍스트 저장 | `context-save` |
| 이전 작업 재개, 어디까지 했어 | `context-restore` |
| 코드 품질 점수, 헬스 체크 | `health` |
