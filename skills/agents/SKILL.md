---
name: agents
description: "TTB(ttb·티티비) 전용 프로젝트 팀·워크플로우 자동화 팩토리.
  TTB·ttb·티티비 프로젝트에서 팀·에이전트·자동화 요청 시 반드시 이 스킬을 사용할 것.
  트리거 조건:
  [하네스 생성] '티티비 프로젝트팀 구성해줘', '티티비팀 만들어줘',
    '티티비 워크플로우 자동화해줘', '이 프로젝트 티티비팀으로 자동화해줘'
  [코드 작업] '파일 검색해줘', '로그 분석해줘', '테스트 실패 원인 찾아줘', '간단히 수정해줘'
  [문서 생성] '릴리스 노트 만들어줘', '코드 리뷰 요약해줘', '변경점 정리해줘', '기술 블로그 초안 써줘'
  이전 결과 수정, 팀원 추가, 재설계, 개선 요청 시에도 사용."
---

> ⚠ **DEPRECATED (v1.18.1)**: 본 스킬은 sprote v2.0의 통합 `sprote` 라우터로 이전됩니다. 자세한 사항은 README 상단 참조.

# TTB Skill Factory

세 가지 실행 모드로 동작한다. 요청 유형에 따라 자동으로 모드를 선택한다.

| 모드 | 트리거 | 주 엔진 |
|------|--------|--------|
| **A. 하네스 생성** | 팀 구성, 워크플로우 자동화 | Codex + Claude |
| **B. 코드 작업** | 파일 검색, 수정, 로그 분석, 테스트 실패 | Claude |
| **C. 문서 생성** | 릴리스 노트, 리뷰 요약, 블로그 초안 | Claude |

## 엔진 역할 분담

### engine_mode: codex_analysis (기본값)

| 엔진 | 담당 |
|------|------|
| **Codex** | 도메인 분석, 청사진 설계, 교차 검증 (설치 시) |
| **Claude Opus** | Codex 미설치 시 도메인 분석·청사진 대체 실행 |
| **Claude Sonnet** | 하네스 파일 구현 (builder), 리더 관리 |
| **Claude Haiku** | 경량 작업: 리서치, 문서화, 검증 |

> Codex 미설치 시: 도메인 분석·청사진은 Opus가 대체 실행하고, 교차 검증(synthesis-reviewer)은 생략한다.

### engine_mode: opus_analysis

| 엔진 | 담당 |
|------|------|
| **Claude Opus** | 도메인 분석, 청사진 설계, 교차 검증 (Codex 없이 전담) |
| **Codex** | 하네스 파일 구현 (builder 역할) |
| **Claude Sonnet** | 리더 관리 |
| **Claude Haiku** | 경량 작업: 리서치, 문서화, 검증 |

**설정 변경 방법:**
```bash
# 프로젝트별 설정 (우선 적용)
{project_root}/.claude/ttb-agents/engine.json

# 전역 기본값 (프로젝트 파일 없을 때 폴백)
${CLAUDE_PLUGIN_ROOT}/skills/agents/engine.json

# 예시: opus_analysis 모드로 전환
# engine_mode 값을 "opus_analysis" 로 변경

# 오케스트레이터 모델 변경 시 세션 모델도 맞춰야 함
# orchestrator_model 변경 후 → /model <값> 실행
```

## 에이전트 구성

### 모드 A — 하네스 생성

| 에이전트 | 관리 주체 | 엔진 | 역할 | 출력 |
|---------|---------|------|------|------|
| search-analyst | 오케스트레이터 | **Claude Haiku** | Brave Search 외부 리서치 | `_workspace/00_research.md` |
| **analysis-leader** | 오케스트레이터 | Claude Sonnet | 분석 파이프라인 자율 관리 | SendMessage (완료 보고) |
| domain-analyst | analysis-leader | **Codex** | 도메인·요구사항 분석 | `_workspace/01_domain_analysis.md` |
| pattern-analyst | analysis-leader | **Codex** | 아키텍처 청사진 설계 | `_workspace/02_blueprint.md` |
| synthesis-reviewer | analysis-leader | **Codex** | 교차 검증 + 보완 권고 | `_workspace/02b_synthesis.md` |
| **build-leader** | 오케스트레이터 | Claude Sonnet | 빌드 파이프라인 자율 관리 | SendMessage (완료 보고) |
| builder | build-leader | Claude Sonnet | 하네스 파일 생성 | `.claude/` + `_workspace/03_build_report.md` |
| docs-keeper | build-leader (병렬) | **Claude Haiku** | 파일 문서화 | `docs/FILES.md` |
| validator | build-leader (병렬) | **Claude Haiku** | TTB 형식·표준 검증 | `_workspace/04_validation_report.md` |
| harness-cross-validator | build-leader (병렬) | **Codex** | 청사진 의도·의미 교차 검증 | `_workspace/05_cross_validation_report.md` |

### 모드 B — 코드 작업

| 에이전트 | 관리 주체 | 엔진 | 역할 | 출력 |
|---------|---------|------|------|------|
| **code-worker** | 오케스트레이터 | **Claude** | 파일 검색·수정·로그 분석·테스트 실패 요약 | 수정 파일 또는 분석 결과 |

에스컬레이션 감지 시 → Claude가 직접 처리

### 모드 C — 문서 생성

| 에이전트 | 관리 주체 | 엔진 | 역할 | 출력 |
|---------|---------|------|------|------|
| **doc-generator** | 오케스트레이터 | **Claude Sonnet** | 릴리스 노트·리뷰 요약·변경점·블로그 초안 | 문서 파일 |

## 워크플로우

### Phase -1: 권한 사전 체크 (최초 1회)

스킬 실행 전 필수 권한이 설정되어 있는지 확인한다.

**`{CLAUDE_PLUGIN_ROOT}` 경로 결정 방법:**
이 SKILL.md 파일의 경로에서 2단계 상위 디렉토리가 플러그인 루트다.
- SKILL.md 위치: `...ttb-agents/{버전}/skills/agents/SKILL.md`
- 플러그인 루트: `...ttb-agents/{버전}/` (즉, `skills/agents` 상위 2단계)
- 예시: `/Users/xxx/.claude/plugins/cache/ttb-marketplace/ttb-agents/1.14.0/`

아래 **Python 실행 패턴**으로 권한 설정 스크립트를 실행한다:

1. `python3 "{CLAUDE_PLUGIN_ROOT}/scripts/setup-permissions.py"` 시도
2. 실패 시 `python "{CLAUDE_PLUGIN_ROOT}/scripts/setup-permissions.py"` 시도
3. 둘 다 실패 시 → **네이티브 폴백**: Read 도구로 `~/.claude/settings.json`을 읽고, 누락된 권한(`WebSearch`, `WebFetch`, `mcp__brave-search__brave_web_search`, `mcp__brave-search__brave_local_search`)을 Write 도구로 직접 추가

- `[ttb-agents/setup] 필수 권한이 이미 모두 설정되어 있습니다.` → 즉시 Phase -0.5로 진행
- 권한이 추가된 경우 → 추가된 항목을 한 줄로 보고 후 Phase -0.5로 진행

### Phase -0.5: 엔진 설정 초기화 및 로드

로컬 `engine.json`이 없으면 플러그인 기본값으로 자동 생성한 뒤 읽어들인다.

**Step 1: 로컬 engine.json 보장 (Python 실행 패턴)**

1. `python3 "{CLAUDE_PLUGIN_ROOT}/scripts/ensure-engine-json.py" "{project_root}" "{CLAUDE_PLUGIN_ROOT}"` 시도
2. 실패 시 `python "{CLAUDE_PLUGIN_ROOT}/scripts/ensure-engine-json.py" "{project_root}" "{CLAUDE_PLUGIN_ROOT}"` 시도
3. 둘 다 실패 시 → **네이티브 폴백**: [아래 네이티브 폴백 절차](#네이티브-폴백-ensure-engine-json) 실행

출력 확인:
- `이미 존재` → 기존 파일 사용
- `생성했습니다` → 사용자에게 "engine.json을 기본값으로 초기화했습니다 — 필요 시 수정하세요: {project_root}/.claude/ttb-agents/engine.json" 한 줄 보고

**Step 2: 로컬 engine.json 읽기**

Read 도구로 `{project_root}/.claude/ttb-agents/engine.json`을 읽는다.

읽은 값에서 두 가지를 추출한다:
- `orchestrator_model`: 오케스트레이터 권장 모델 (`opus` / `sonnet` / `haiku`)
- `engine_mode`: 분석·구현 엔진 조합 (`codex_analysis` / `opus_analysis`)

**오케스트레이터 모델 체크:**
현재 세션 모델과 `orchestrator_model` 값을 비교한다.

- 일치하면 → 아래 설정 요약을 출력하고 Phase 0으로 진행
- 불일치하면 → 다음 메시지를 출력하고 **중단**한다:

```
⚠️  오케스트레이터 모델 불일치
  설정값: {orchestrator_model}  /  현재 세션: {현재 모델}

  실행하려면:
  1. /model {orchestrator_model}  ← 세션 모델 변경 후 재실행
  2. 또는 engine.json의 orchestrator_model을 현재 모델로 변경:
     {project_root}/.claude/ttb-agents/engine.json

  engine_mode: {engine_mode}
```

**정상 진행 시 출력 요약:**
```
⚙️  TTB 엔진 설정  [local]
  오케스트레이터: {orchestrator_model}
  engine_mode  : {engine_mode}
    codex_analysis → 분석=Codex  / 구현=Sonnet
    opus_analysis  → 분석=Opus   / 구현=Codex
```

이후 모든 Phase에서 `engine_mode` 값을 유지하여 서브에이전트에 전달한다.

### Phase 0: 실행 모드 결정

요청 내용을 분석하여 세 모드 중 하나를 선택한다.

**모드 B (코드 작업)** 로 분기:
- "파일 검색", "수정해줘", "로그 분석", "테스트 실패", "에러 원인" 등의 키워드
- → Phase B로 이동 (하네스 생성 파이프라인 실행 안 함)

**모드 C (문서 생성)** 로 분기:
- "릴리스 노트", "코드 리뷰 요약", "변경점 정리", "블로그 초안" 등의 키워드
- → Phase C로 이동 (하네스 생성 파이프라인 실행 안 함)

**모드 A (하네스 생성)** 로 분기 (기본):
- "팀 구성", "하네스", "자동화", "에이전트 만들어줘" 등의 키워드
- `_workspace/` 디렉토리 존재 여부 확인:
  - **미존재** → 초기 실행. Phase 1로 진행
  - **존재 + 부분 수정 요청** → 부분 재실행:
    - 프로젝트 경로를 `_workspace/00_input/request.md`에서 읽는다.
    - **코딩 행동 지침 보완**을 아래 Python 실행 패턴으로 실행한다:
      1. `python3 "{CLAUDE_PLUGIN_ROOT}/scripts/ensure-coding-guidelines.py" "{프로젝트 경로}"` 시도
      2. 실패 시 `python "{CLAUDE_PLUGIN_ROOT}/scripts/ensure-coding-guidelines.py" "{프로젝트 경로}"` 시도
      3. 둘 다 실패 시 → **네이티브 폴백**: [아래 네이티브 폴백 절차](#네이티브-폴백-ensure-coding-guidelines) 실행
    - 지침이 추가된 경우 사용자에게 한 줄로 보고한다.
    - 이후 요청 유형에 따라 해당 Phase로 이동:
      - 도메인 분석 재요청 → Phase 2a부터 재실행
      - 청사진만 수정 → Phase 2b부터 재실행
      - 종합 검토 재요청 → Phase 2c만 재실행
      - 파일 재생성 → Phase 3부터 재실행
      - 문서만 갱신 → Phase 3b만 재실행
      - 검증 재실행 → Phase 4만 재실행
  - **존재 + 새 도메인 입력** → `_workspace_{YYYYMMDD_HHMMSS}/`로 이동 후 초기 실행

### Phase 0.5: ttb-design 연계 확인

`_workspace/design/01_brief.md` 존재 여부 확인:
- 존재하면 → ttb-design이 이미 실행된 상태. 디자인 브리프를 analysis-leader에 전달
- 미존재 → 독립 실행 모드 (연계 없음)

### Phase 1: 입력 수집

1. 사용자로부터 확인:
   - **도메인 설명**: 어떤 작업을 자동화할 것인가?
   - **대상 프로젝트 경로**: 하네스 파일을 어디에 생성할 것인가? (미제공 시 현재 디렉토리)
   - **코드베이스 경로**: 분석할 기존 코드베이스가 있는가?

2. `_workspace/00_input/request.md`에 입력 저장

3. 대상 프로젝트의 CLAUDE.md 코딩 행동 지침 보완 (Python 실행 패턴):
   1. `python3 "{CLAUDE_PLUGIN_ROOT}/scripts/ensure-coding-guidelines.py" "{대상 프로젝트 경로}"` 시도
   2. 실패 시 `python "{CLAUDE_PLUGIN_ROOT}/scripts/ensure-coding-guidelines.py" "{대상 프로젝트 경로}"` 시도
   3. 둘 다 실패 시 → **네이티브 폴백**: [아래 네이티브 폴백 절차](#네이티브-폴백-ensure-coding-guidelines) 실행
   - 지침이 추가된 경우 사용자에게 한 줄로 보고한다.

### Phase 1.5: 외부 리서치 (Brave Search)

**실행 모드:** 서브 에이전트 (Claude Haiku)

`_workspace/00_research.md`가 이미 있으면 스킵한다.

```
Agent(
  description: "도메인 기술 트렌드 외부 리서치",
  subagent_type: "general-purpose",
  model: "haiku",
  prompt: "당신은 search-analyst입니다. agents/search-analyst.md의 지침을 따르세요.
           도메인 설명을 참고하여 아래 4개 쿼리를 실행하세요:
           1. '{도메인 설명} automation best practices {현재 연도}'
           2. '{도메인 설명} AI agent workflow patterns'
           3. '{도메인 설명} open source automation tools {현재 연도}'
           4. '{도메인 설명} industry standards regulations'

           Brave Search MCP 우선. 미설정 시 WebSearch로 폴백.
           결과를 _workspace/00_research.md에 저장하세요."
)
```

### Phase 2: 분석 리더 실행

**오케스트레이터 역할:** 실행 → 완료 보고 수신. 내부 파이프라인에 개입하지 않는다.

```
Agent(
  description: "분석 파이프라인 자율 실행",
  subagent_type: "general-purpose",
  model: "sonnet",
  prompt: "당신은 analysis-leader입니다. agents/analysis-leader.md의 지침을 따르세요.
           도메인 설명: {도메인 설명}
           코드베이스 경로: {코드베이스 경로 또는 '없음'}
           engine_mode: {engine_mode}   ← codex_analysis | opus_analysis
           [연계] 디자인 브리프: _workspace/design/01_brief.md (존재하면 읽어서 컨텍스트 활용)
           내부 파이프라인(search-analyst → domain-analyst → pattern-analyst → synthesis-reviewer)을
           자율적으로 실행하고 완료 후 SendMessage로 보고하세요."
)
```

analysis-leader의 SendMessage 수신 후 Phase 3으로 진행.

### Phase 3: 빌드 리더 실행

**오케스트레이터 역할:** 실행 → 완료 보고 수신. 내부 파이프라인에 개입하지 않는다.

```
Agent(
  description: "빌드 파이프라인 자율 실행",
  subagent_type: "general-purpose",
  model: "sonnet",
  prompt: "당신은 build-leader입니다. agents/build-leader.md의 지침을 따르세요.
           대상 프로젝트 경로: {대상 프로젝트 경로}
           engine_mode: {engine_mode}   ← codex_analysis | opus_analysis
           내부 파이프라인(builder → [docs-keeper ∥ validator ∥ harness-cross-validator])을
           자율적으로 실행하고 완료 후 SendMessage로 보고하세요."
)
```

build-leader의 SendMessage 수신 후 Phase 4으로 진행.

### Phase 4: 결과 보고

build-leader의 SendMessage에서 수신한 상태 + 검증 보고서를 읽어 사용자에게 최종 보고:

- 생성된 파일 목록 (`_workspace/03_build_report.md` 참조)
- Codex 분석 단계 교차 검증 반영 사항 (`_workspace/02b_synthesis.md` 요약)
- 형식 검증 결과 (`_workspace/04_validation_report.md` — APPROVED / APPROVED_WITH_WARNINGS / NEEDS_REVISION)
- **의미 교차 검증 결과** (`_workspace/05_cross_validation_report.md` — Codex 관점 청사진 정합성)
- 양쪽 검증이 동의한 FAIL/P0/P1 항목은 반드시 수정 방법 안내

**에이전트 트리 출력 (필수):**

`{project_root}/.claude/agents/` 디렉토리의 에이전트 파일을 읽어 아래 형식으로 출력한다.
각 에이전트 파일의 `description` 필드 첫 문장을 역할 설명으로 사용한다.

```
## 생성된 하네스팀 구조

오케스트레이터 (Claude {orchestrator_model})
├─ {리더1 에이전트명} ({모델})  ← {역할 한 줄}
│   ├─ {서브에이전트명} ({모델})  ← {역할 한 줄}
│   └─ {서브에이전트명} ({모델})  ← {역할 한 줄}
└─ {리더2 에이전트명} ({모델})  ← {역할 한 줄}
    ├─ {서브에이전트명} ({모델})  ← {역할 한 줄}
    ├─ {서브에이전트명} ({모델})  ← {역할 한 줄}  ┐ 병렬
    └─ {서브에이전트명} ({모델})  ← {역할 한 줄}  ┘
```

트리 구성 규칙:
- 에이전트 파일의 `subagent_type` 또는 `model` 필드로 모델명 표시 (없으면 생략)
- `description`에서 "관리 주체" 또는 "오케스트레이터" 언급이 있으면 리더로 분류
- 병렬 실행 에이전트는 `┐ 병렬` / `┘` 마커로 표시
- 에이전트 파일이 없거나 읽기 실패 시 트리 출력 생략

`_workspace/` 보존 (삭제하지 않음)

---

## 모드 B 워크플로우 — 코드 작업

### Phase B1: 작업 유형 확인

사용자 요청에서 `task_type`과 `project_root`를 파악한다.

| 요청 패턴 | task_type |
|---------|---------|
| 파일 찾아줘, 어디 있어, 검색해줘 | `file_search` |
| 수정해줘, 바꿔줘, 리팩토링 | `simple_modify` |
| 로그 분석, 에러 패턴, 오류 빈도 | `log_analysis` |
| 테스트 실패, 실패 원인, 왜 떨어져 | `test_failure` |

### Phase B2: code-worker 실행

```
Agent(
  description: "로컬 코드 작업",
  subagent_type: "general-purpose",
  model: "haiku",
  prompt: "당신은 code-worker입니다. agents/code-worker.md의 지침을 따르세요.
           project_root: {프로젝트 경로}
           task_type: {file_search | simple_modify | log_analysis | test_failure}
           target: {대상 파일·디렉토리·로그}
           request: {사용자 요청 원문}

           에스컬레이션 조건이 감지되면 즉시 작업을 중단하고 이유를 반환하세요."
)
```

### Phase B3: 파일 수정 후 docs-keeper 실행

`task_type`이 `simple_modify`이고 code-worker가 실제로 파일을 수정한 경우에만 실행한다.
`file_search`, `log_analysis`, `test_failure`는 파일을 변경하지 않으므로 스킵한다.

```
Agent(
  description: "수정 파일 docs/FILES.md 갱신",
  subagent_type: "general-purpose",
  model: "haiku",
  prompt: "당신은 docs-keeper입니다. agents/docs-keeper.md의 지침을 따르세요.
           project_root: {프로젝트 경로}
           changed_files:
             - action: modified
               path: {code-worker가 수정한 파일 경로}
               summary: {code-worker 반환값에서 추출한 변경 요약}
               change_reason: {사용자 요청 원문}
           완료 후 갱신된 docs/FILES.md 경로를 반환하세요."
)
```

### Phase B4: 에스컬레이션 처리

code-worker가 에스컬레이션을 반환하면 오케스트레이터(Claude)가 직접 처리한다.

---

## 모드 C 워크플로우 — 문서 생성

### Phase C1: 문서 유형 확인

사용자 요청에서 `doc_type`과 필요한 소스 데이터를 파악한다.

| 요청 패턴 | doc_type | 필요 데이터 |
|---------|---------|----------|
| 릴리스 노트, 배포 문서 | `release_notes` | git log 범위 또는 PR 목록 |
| 코드 리뷰 요약, PR 리뷰 | `code_review` | PR URL 또는 diff |
| 변경점 정리, CHANGELOG | `changelog` | 커밋 범위 |
| 기술 블로그, 포스트 초안 | `blog_draft` | 구현 설명 또는 코드 |

소스 데이터가 부족하면 사용자에게 먼저 요청한다.

### Phase C2: doc-generator 실행

```
Agent(
  description: "문서 초안 생성",
  subagent_type: "general-purpose",
  model: "haiku",
  prompt: "당신은 doc-generator입니다. agents/doc-generator.md의 지침을 따르세요.
           project_root: {프로젝트 경로}
           doc_type: {release_notes | code_review | changelog | blog_draft}
           source_data: {원본 데이터}
           output_path: {출력 파일 경로}

           artisan 품질 기준으로 문서를 직접 작성하고 output_path에 저장하세요."
)
```

### Phase C3: 결과 보고

생성된 문서 경로와 주요 작성 내용을 사용자에게 보고한다.

---

## 데이터 흐름

### 모드 A — 하네스 생성

```
[사용자 입력]
     ↓
_workspace/00_input/request.md
     ↓
[Phase 2: analysis-leader]
  ├─ domain-analyst (Codex)   → _workspace/01_domain_analysis.md
  ├─ pattern-analyst (Codex)  → _workspace/02_blueprint.md
  └─ synthesis-reviewer (Codex) → _workspace/02b_synthesis.md
  └─ SendMessage → 오케스트레이터
     ↓
[Phase 3: build-leader]
  ├─ builder (Claude) → .claude/agents/, SKILL.md, CLAUDE.md
  ├─ docs-keeper (Haiku) ──────────────┐
  ├─ validator (Haiku, 형식) ──────────┤ 병렬
  └─ harness-cross-validator (Codex, 의미) ┘
  └─ SendMessage → 오케스트레이터
     ↓
[Phase 4: 결과 보고]
```

### 모드 B — 코드 작업

```
[사용자 요청]
     ↓
[Phase B2: code-worker (Claude)]
  ├─ file_search   → 파일 목록 + 코드 스니펫
  ├─ simple_modify → 수정된 파일
  ├─ log_analysis  → 오류 패턴 분류표
  └─ test_failure  → 실패 원인 요약 + 수정 힌트
     ↓ 에스컬레이션 감지 시
[Claude 직접 처리]
```

### 모드 C — 문서 생성

```
[사용자 요청 + 소스 데이터]
     ↓
[Phase C2: doc-generator]
  └─ Claude 직접 작성
     ↓
최종 문서 파일 (Write 저장)
```

**오케스트레이터 개입 횟수:** 6회 → **2회** (각 리더 실행 시만)

## 네이티브 폴백 절차

Python 미가용 시 Claude가 Read/Write 도구로 직접 수행한다.
상세 절차: `skills/agents/references/native-fallback.md`

---

## 에러 핸들링

에러 복구는 각 리더 에이전트가 자체적으로 처리한다. 오케스트레이터는 리더의 최종 보고에서 상태를 확인한다.

| 실패 주체 | 복구 주체 | 전략 |
|---------|---------|------|
| domain-analyst (Codex) | analysis-leader | general-purpose로 즉시 대체, 파일에 표시 |
| pattern-analyst | analysis-leader | 도메인 분석만으로 간소화 청사진 직접 작성 |
| synthesis-reviewer (Codex) | analysis-leader | 빈 synthesis 파일 생성 후 계속 |
| builder | build-leader | 부분 build_report 작성 후 docs/validator 진행 |
| docs-keeper | build-leader | 경고 기록, 검증 결과(둘)만으로 보고 |
| validator | build-leader | 경고 기록, cross-validator 결과로 대체 |
| harness-cross-validator (Codex) | build-leader | Opus 폴백 자동 실행, 그래도 실패 시 validator만으로 보고 |
| analysis-leader 전체 실패 | 오케스트레이터 | SendMessage 수신 → 사용자에게 실패 보고 |
| build-leader 전체 실패 | 오케스트레이터 | SendMessage 수신 → 사용자에게 실패 보고 |

## 테스트 시나리오

정상 흐름·에러 흐름 예시: `skills/agents/references/test-scenarios.md`

## TTB 표준 참조

`skills/agents/references/ttb-standards.md` — Codex 연계 지침 포함.
