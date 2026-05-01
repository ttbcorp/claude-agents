# 파일 목록

> 마지막 갱신: 2026-04-28
> 총 파일 수: 7개

---

## agents

### `agents/research-analyst.md`

| 항목 | 내용 |
|------|------|
| 역할 | 시장·경쟁사·유저 문제 조사 에이전트. pm-workflow Phase 1 담당 |
| 주요 exports | 없음 (에이전트 정의 파일) |
| 최종 변경 | 2026-04-18 — pm-workflow 파이프라인 초기 생성 |

---

### `agents/prd-writer.md`

| 항목 | 내용 |
|------|------|
| 역할 | PRD 작성 에이전트. 조사 결과 기반 기능 요구사항·유저 스토리(INVEST)·수용 기준 작성. pm-workflow Phase 2 담당 |
| 주요 exports | 없음 (에이전트 정의 파일) |
| 최종 변경 | 2026-04-18 — pm-workflow 파이프라인 초기 생성 |

---

### `agents/roadmap-planner.md`

| 항목 | 내용 |
|------|------|
| 역할 | 로드맵 설계 에이전트. MoSCoW 우선순위, 스프린트 계획, 기능 의존성 매핑. pm-workflow Phase 3 담당 |
| 주요 exports | 없음 (에이전트 정의 파일) |
| 최종 변경 | 2026-04-18 — pm-workflow 파이프라인 초기 생성 |

---

### `agents/prd-validator.md`

| 항목 | 내용 |
|------|------|
| 역할 | PRD·로드맵 교차 검증 에이전트. 빠진 요구사항, 모순 탐지, INVEST 체크, 심각도 분류. pm-workflow Phase 4 담당 |
| 주요 exports | 없음 (에이전트 정의 파일) |
| 최종 변경 | 2026-04-18 — pm-workflow 파이프라인 초기 생성 |

---

## skills

### `skills/agents/engine.json`

| 항목 | 내용 |
|------|------|
| 역할 | `/ttb-agents:agents` 엔진 설정 파일. 오케스트레이터 모델과 분석/구현 엔진 조합을 지정 |
| 주요 필드 | `orchestrator_model` (opus/sonnet/haiku), `engine_mode` (codex_analysis/opus_analysis) |
| 최종 변경 | 2026-04-28 — v1.9.2 신규 생성. 오케스트레이터 모델 고정 및 engine_mode 스위치 지원 |

---

### `skills/pm-workflow/SKILL.md`

| 항목 | 내용 |
|------|------|
| 역할 | PM 자동화 워크플로우 오케스트레이터 스킬. 시장 조사→PRD→로드맵→검증 4단계 파이프라인 자동 실행 |
| 주요 exports | pm-workflow 스킬 (트리거: 제품 기획, PRD 작성, 로드맵, 시장 조사, 경쟁사 분석, 유저 스토리) |
| 최종 변경 | 2026-04-18 — pm-workflow 파이프라인 초기 생성 |

---

### `skills/pm-workflow/references/pm-standards.md`

| 항목 | 내용 |
|------|------|
| 역할 | PM 문서 품질 기준. PRD 템플릿 구조, MoSCoW 로드맵 형식, INVEST 체크리스트 6개 기준, 모순 탐지 패턴, 심각도 분류 기준 정의 |
| 주요 exports | PRD 필수 섹션 구조, 로드맵 필수 섹션 구조, INVEST 판정 기준, 검증 패턴 |
| 최종 변경 | 2026-04-18 — pm-workflow 파이프라인 초기 생성 |
