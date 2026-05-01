# TTB Claude Agents

TTB 전용 Claude Code 플러그인. 여섯 개의 스킬로 구성된다.

- **`/ttb-agents:agents`** — 현재 프로젝트를 분석하여 에이전트 팀과 워크플로우를 자동 설계·생성
- **`/ttb-agents:design`** — artisan 원칙 기반 UI/UX 기획·구현·검토를 자동화
- **`/ttb-agents:review`** — 하네스 파일을 읽고 TTB 표준 준수 여부를 검증
- **`/ttb-agents:pm-workflow`** — 시장 조사·PRD 작성·로드맵 수립·검증을 자동 실행하는 PM 기획 파이프라인
- **`/ttb-agents:sllm`** — 9B·7B·3B 소형 LLM에서 작동하는 에이전트 하네스를 10대 아키텍처 최적화를 적용하여 자동 설계·생성
- **`/ttb-agents:advisor`** — /compact 선행 후 Opus 리뷰어에 에스컬레이션하는 모델 승급 스킬

## 스킬

### `/ttb-agents:agents` — 프로젝트 자동화 팩토리

세 가지 모드로 동작한다. 요청 내용에 따라 자동으로 모드를 선택한다.

| 모드 | 트리거 예시 | 주 엔진 |
|------|-----------|--------|
| **하네스 생성** | 티티비 프로젝트팀 구성해줘 | Codex + Claude |
| **코드 작업** | 파일 검색해줘, 로그 분석해줘, 테스트 실패 원인 찾아줘 | Claude |
| **문서 생성** | 릴리스 노트 만들어줘, 코드 리뷰 요약해줘, 블로그 초안 써줘 | Claude |

**하네스 생성 파이프라인:**
```
Phase -0.5 engine.json 로드 → orchestrator_model 체크 → 불일치 시 abort
Phase 1.5  search-analyst (Haiku) ── Brave Search 도메인 리서치 ──────→ 00_research.md
Phase 2    analysis-leader (Sonnet)
            ├─ [codex_analysis] domain-analyst (Codex) ─────────────→ 01_domain_analysis.md
            │  [opus_analysis]  domain-analyst (Opus)  ─────────────→ 01_domain_analysis.md
            ├─ [codex_analysis] pattern-analyst (Codex) ────────────→ 02_blueprint.md
            │  [opus_analysis]  pattern-analyst (Opus)  ────────────→ 02_blueprint.md
            └─ [codex_analysis] synthesis-reviewer (Codex) ─────────→ 02b_synthesis.md
               [opus_analysis]  synthesis-reviewer (Opus)  ─────────→ 02b_synthesis.md
Phase 3    build-leader (Sonnet)
            ├─ [codex_analysis] builder (Sonnet) ───────────────────→ .claude/agents/ + SKILL.md
            │  [opus_analysis]  builder (Codex)  ───────────────────→ .claude/agents/ + SKILL.md
            ├─ docs-keeper (Haiku) ── 파일 문서화 ──────────────────────→ docs/FILES.md
            └─ validator (Haiku) ── TTB 표준 검증 ───────────────────→ 04_validation_report.md
```

**engine_mode 설정** (`skills/agents/engine.json`):

| engine_mode | 분석 엔진 | 구현 엔진 |
|-------------|----------|----------|
| `codex_analysis` (기본) | Codex → Opus 폴백 | Claude Sonnet |
| `opus_analysis` | Claude Opus | Codex |

**코드 작업 파이프라인:**
```
code-worker (Claude)
  ├─ 파일 검색·간단한 수정·로그 분석·테스트 실패 요약
  └─ 에스컬레이션 감지 시 → 오케스트레이터(Claude) 직접 처리
```

**문서 생성 파이프라인:**
```
doc-generator (Claude)
  └─ 사실 검토·문체 보완 기준으로 직접 작성 후 저장
```

### `/ttb-agents:design` — UI/UX 디자인 팩토리

artisan 원칙 기반으로 디자인 컨텍스트 수집부터 구현·검토·Claude·Codex 교차 검증까지 자동화한다.

**트리거 예시:**
```
티티비 UI 만들어줘
티티비 디자인 검토해줘
티티비 AI 안 티나게 개선해줘
티티비 교차 검증해줘
```

**파이프라인:**
```
Phase 1    인라인 ── 디자인 컨텍스트 수집 (.artisan.md)
Phase 1.5  search-analyst (Haiku) ── Brave Search 트렌드 리서치 ─────→ design/00_research.md
Phase 2    design-planner (Codex) ── 리서치 기반 UX/UI 브리프 ─────────→ design/01_brief.md
Phase 3    design-implementer (Sonnet)
            └─ code-validator (Haiku) ── artisan 규칙 검증 (파일마다) ──→ design/02_build_report.md
Phase 4    design-reviewer (Opus) ── 시각적 품질·접근성·안티패턴 ─────→ design/03_review_report.md
Phase 5    design-cross-validator (Opus + Codex) ── Claude·Codex 교차 검증 → design/04_cross_validation_report.md
           최종 판정: HUMAN_QUALITY / BORDERLINE / AI_DETECTABLE
```

### `/ttb-agents:review` — TTB 표준 검증

현재 프로젝트의 하네스 파일을 읽고 TTB 표준 준수 여부를 점검한다.

**트리거 예시:**
```
/ttb-agents:review
하네스 검증해줘
TTB 표준 확인해줘
에이전트 파일 검토해줘
```

**파이프라인:**
```
Phase 0    .claude/ 존재 확인
Phase 1    validator (Haiku) ── 에이전트·SKILL.md 전체 검증 ──────────→ _workspace/review_report.md
Phase 2    결과 요약 보고 (PASS/WARN/FAIL + 최종 판정)
```

---

### `/ttb-agents:pm-workflow` — PM 기획 파이프라인

제품 아이디어부터 검증된 PRD와 실행 가능한 로드맵까지 4단계를 자동 실행한다.

**트리거 예시:**
```
B2B SaaS 일정 관리 도구 기획해줘
이 앱 PRD 작성해줘
시장 조사부터 로드맵까지 만들어줘
로드맵만 다시 짜줘
PRD 검증 다시 해줘
```

**파이프라인:**
```
Phase 1    research-analyst (Haiku) ── 시장·경쟁사·유저 문제 조사 ──────→ _workspace/01_research.md
Phase 2    prd-writer (Opus) ── PRD 작성 (INVEST 기준) ────────────────→ _workspace/02_prd.md
Phase 3    roadmap-planner (Opus) ── MoSCoW 로드맵 + 의존성 설계 ───────→ _workspace/03_roadmap.md
Phase 4    prd-validator (Haiku) ── PRD·로드맵 교차 검증 ──────────────→ _workspace/04_validation.md
```

**실행 모드:**

| 모드 | 조건 | 동작 |
|------|------|------|
| 전체 실행 | `_workspace/` 미존재, 새 제품 아이디어 | Phase 1~4 순차 실행 |
| 단계 재실행 | "로드맵만 다시", "PRD 수정", "검증 다시" | 해당 Phase만 재실행 |
| 새 제품 | `_workspace/` 존재 + 새 아이디어 | 기존 백업 후 전체 실행 |

**유저 인터뷰 입력:**
`_workspace/00_input/interviews/` 경로에 `.md` 또는 `.txt` 파일을 배치하면 research-analyst가 자동으로 읽어 조사에 반영한다.

**검증 판정 기준:**

| 판정 | 의미 | 다음 단계 |
|------|------|---------|
| `APPROVED` | 이슈 없음 | 개발 착수 준비 완료 |
| `APPROVED_WITH_WARNINGS` | [MEDIUM]/[LOW] 이슈만 존재 | 권고 사항 검토 후 착수 |
| `NEEDS_REVISION` | [HIGH] 이슈 존재 | 재실행 여부 확인 (최대 1회) |

---

---

### `/ttb-agents:sllm` — 소형 LLM 최적화 하네스 팩토리

9B·7B·3B 소형 LLM(Ollama, 로컬 AI)에서 작동하는 에이전트 하네스를 자동 설계·생성한다.
10대 아키텍처 최적화를 모든 생성 에이전트에 적용한다.

**트리거 예시:**
```
sLLM 에이전트 만들어줘
소형 모델로 이메일 분류 자동화해줘
Ollama 에이전트 구성해줘
로컬 LLM 하네스 만들어줘
기존 에이전트를 sLLM 호환으로 변환해줘
```

**파이프라인:**
```
Phase 2    sllm-analyzer (Haiku) ── 도메인 분석 + 원자 작업 분류 ─────→ _workspace/sllm/01_domain_analysis.md
Phase 3    sllm-optimizer (Sonnet) ── 10대 최적화 설계 명세 작성 ──────→ _workspace/sllm/02_optimization_plan.md
Phase 4    sllm-builder (Sonnet) ── 에이전트 파일 + SKILL.md 생성 ─────→ .claude/ + 03_build_report.md
```

**적용되는 10대 아키텍처 최적화:**

| OPT | 기법명 | 효과 |
|-----|-------|-----|
| OPT-01 | 구조화 프롬프트 | 출력 품질 525% 향상, 속도 36% 개선 |
| OPT-02 | MicroCompact 출력 압축 | 도구 결과 80~93% 압축 |
| OPT-03 | 생산 모드 강제 | 무한 탐색 루프 방지 |
| OPT-04 | 사고 비활성화 | 토큰 8~10배 절약 |
| OPT-05 | 지연 도구 로딩 | 프롬프트 토큰 60% 절약 |
| OPT-06 | 외부 메모리 | 세션 간 컨텍스트 유지 |
| OPT-07 | KV 캐시 포킹 | 분기 연산 가속 |
| OPT-08 | 쓰기 검증 규율 | 파일 무결성 보장 |
| OPT-09 | 병렬 부트 파이프라인 | 시작 시간 9% 단축 |
| OPT-10 | 안정 시스템 프롬프트 | 반복 호출 속도 60% 향상 |

**실행 모드:**

| 모드 | 조건 | 동작 |
|------|------|------|
| 하네스 생성 | 새 도메인, `_workspace/sllm/` 미존재 | 전체 파이프라인 실행 |
| 기존 변환 | "기존 에이전트를 sLLM 호환으로 변환" | optimizer + builder만 실행 |
| 최적화 감사 | "sLLM 호환 확인해줘" | optimizer 감사 모드만 실행 |

---

### `/ttb-agents:advisor` — Opus 에스컬레이션

Sonnet으로 진행하다 복잡한 결정이나 막힌 상황에서 Opus 리뷰어에 에스컬레이션한다.
토큰 비용 절감을 위해 `/compact` 실행을 먼저 요청하고, 확인 후 `advisor()`를 호출한다.

**트리거 예시:**
```
Opus에 물어봐
더 강한 모델로 확인해줘
막혔어 advisor 써줘
결정이 어려워 리뷰 받아줘
```

**워크플로우:**
```
Phase 0  현재 작업 상황 요약 표 출력 (목표 / 진행 상태 / 막힌 지점)
Phase 1  사용자에게 /compact 실행 요청 + 대기
Phase 2  완료 확인 (완료·ok·done·ㅇㅇ) 또는 건너뛰기(그냥 해줘·skip) 처리
Phase 3  advisor() 호출 → Opus 리뷰 수행
Phase 4  결과를 핵심 권고 / 주의 사항 / 다음 행동 표로 정리하여 보고
```

---

**스킬 연계:**
- `/ttb-agents:agents` 실행 후 `/ttb-agents:design`을 실행하면 하네스 청사진(`02_blueprint.md`)이 디자인 기획에 자동 반영된다.
- 반대로 `/ttb-agents:design` 실행 후 `/ttb-agents:agents`를 실행하면 디자인 브리프(`design/01_brief.md`)가 에이전트 분석에 전달된다.
- `/ttb-agents:sllm`으로 생성한 에이전트는 Ollama 등 로컬 sLLM 환경에서 독립적으로 실행 가능하다.
- `/ttb-agents:advisor`는 어떤 스킬 실행 중에도 호출 가능하며, 막히거나 중요한 결정 시 Opus의 독립 리뷰를 받을 수 있다.

## 설치

`~/.claude/settings.json`에 추가:

```json
{
  "extraKnownMarketplaces": {
    "ttb-marketplace": {
      "source": {
        "source": "github",
        "repo": "ttbcorp/claude-agents"
      }
    }
  },
  "enabledPlugins": {
    "ttb-agents@ttb-marketplace": true
  }
}
```

설치 후 `/ttb-agents:setup`을 실행하면 서브 에이전트가 웹 검색 도구를 사용할 수 있도록 필수 권한이 `~/.claude/settings.json`에 자동으로 추가된다. `/ttb-agents:agents` 첫 실행 시에도 자동으로 수행된다.

Claude Code를 재시작하면 자동으로 다운로드됩니다.

## 파일 구조

```
ttb-agents/
├── README.md
├── scripts/
│   ├── deploy.sh                    # GitLab·GitHub 배포 스크립트
│   └── setup-permissions.sh         # 필수 권한 자동 추가 (멱등성)
├── agents/                          # 에이전트 정의 파일
│   ├── analysis-leader.md           # 분석 파이프라인 자율 관리자
│   ├── build-leader.md              # 빌드 파이프라인 자율 관리자
│   ├── builder.md                   # 하네스 파일 생성 전문가
│   ├── code-validator.md            # 코드 artisan 규칙 검증기
│   ├── code-worker.md               # 코드 작업 에이전트
│   ├── design-cross-validator.md    # Claude·Codex 교차 검증 전문가
│   ├── design-implementer.md        # 디자인 브리프 기반 UI 구현 전문가
│   ├── design-planner.md            # UX/UI 기획 전문가
│   ├── design-reviewer.md           # 디자인 품질 검토 전문가
│   ├── doc-generator.md             # 문서 생성 에이전트
│   ├── docs-keeper.md               # 소스 파일 문서화 전문가
│   ├── domain-analyst.md            # Codex 기반 도메인·요구사항 분석 전문가
│   ├── pattern-analyst.md           # 도메인 분석 기반 아키텍처 청사진 설계
│   ├── prd-validator.md             # PRD·로드맵 교차 검증 전문가
│   ├── prd-writer.md                # PRD 작성 전문가 (INVEST 기준)
│   ├── research-analyst.md          # 시장·경쟁사·유저 문제 조사 전문가
│   ├── roadmap-planner.md           # MoSCoW 로드맵 + 의존성 설계 전문가
│   ├── search-analyst.md            # Brave Search 웹 리서치 전문가
│   ├── synthesis-reviewer.md        # Codex 기반 분석 교차 검증 전문가
│   ├── sllm-analyzer.md             # sLLM 도메인 분석 + 원자 작업 분류 전문가
│   ├── sllm-builder.md              # sLLM 최적화 하네스 파일 생성 전문가
│   ├── sllm-optimizer.md            # sLLM 10대 아키텍처 최적화 설계 전문가
│   └── validator.md                 # 하네스 산출물 TTB 표준 검증 전문가
└── skills/
    ├── agents/
    │   ├── SKILL.md                 # /ttb-agents:agents 스킬 오케스트레이터
    │   ├── engine.json              # 오케스트레이터 모델·엔진 모드 설정
    │   └── references/
    │       └── ttb-standards.md     # TTB 표준 및 Codex 연계 지침
    ├── design/
    │   ├── SKILL.md                 # /ttb-agents:design 스킬 오케스트레이터
    │   └── references/
    │       └── design-principles.md # TTB artisan 디자인 원칙 요약
    ├── pm-workflow/
    │   ├── SKILL.md                 # /ttb-agents:pm-workflow 스킬 오케스트레이터
    │   └── references/
    │       └── pm-standards.md      # PRD 템플릿·로드맵 형식·INVEST 체크리스트
    ├── advisor/
    │   └── SKILL.md                 # /ttb-agents:advisor 스킬 (/compact → advisor() 에스컬레이션)
    ├── review/
    │   └── SKILL.md                 # /ttb-agents:review 스킬 오케스트레이터
    ├── setup/
    │   └── SKILL.md                 # /ttb-agents:setup 스킬 (권한 초기 설정)
    └── sllm/
        ├── SKILL.md                 # /ttb-agents:sllm 스킬 오케스트레이터
        └── references/
            └── sllm-optimizations.md # sLLM 10대 아키텍처 최적화 상세 설명
```

## 에이전트 상세

### `/ttb-agents:agents` 에이전트

| 에이전트 | 엔진 | 관리 주체 | 역할 |
|---------|------|---------|------|
| **code-worker** | Claude | 오케스트레이터 | 파일 검색·간단한 수정·로그 분석·테스트 실패 요약. 복잡한 작업은 오케스트레이터에게 에스컬레이션 |
| **doc-generator** | Claude Sonnet | 오케스트레이터 | 릴리스 노트·코드 리뷰 요약·변경점·블로그 초안 생성 |
| **analysis-leader** | Claude Sonnet | 오케스트레이터 | domain-analyst → pattern-analyst → synthesis-reviewer 파이프라인을 자율 실행. engine_mode 수신 후 분기. 내부 에러 자체 복구 |
| **domain-analyst** | Codex / Opus | analysis-leader | 도메인 설명과 코드베이스를 분석하여 작업 유형·병렬화 가능성·에이전트 역할 초안 도출 (engine_mode에 따라 Codex 또는 Opus) |
| **pattern-analyst** | Codex / Opus | analysis-leader | 도메인 분석 결과를 기반으로 실행 모드 선택, TTB 표준 적용하여 하네스 청사진 작성 (engine_mode에 따라 Codex 또는 Opus) |
| **synthesis-reviewer** | Codex / Opus | analysis-leader | domain-analyst와 pattern-analyst 결과를 비교·교차 검증하여 보완점·누락·과설계 도출 (engine_mode에 따라 Codex 또는 Opus) |
| **build-leader** | Claude Sonnet | 오케스트레이터 | builder 완료 후 docs-keeper + validator를 병렬 실행. engine_mode 수신 후 builder 선택. 내부 에러 자체 복구 |
| **builder** | Sonnet / Codex | build-leader | 청사진 기반으로 SKILL.md·에이전트 .md·오케스트레이터·CLAUDE.md 실제 생성 (engine_mode에 따라 Sonnet 또는 Codex) |
| **docs-keeper** | Claude Haiku | build-leader | 파일 생성·변경 시마다 `docs/FILES.md`를 최신 상태로 유지 |
| **validator** | Claude Haiku | build-leader / review | 구조 무결성·description 품질·트리거 충돌·TTB 표준 준수 여부 검증. PASS/WARN/FAIL 분류 |
| **search-analyst** | Claude Haiku | 오케스트레이터 | Brave Search MCP 우선, 미설정 시 WebSearch → WebFetch 폴백으로 도메인 리서치 수행 |

### `/ttb-agents:design` 에이전트

| 에이전트 | 엔진 | 관리 주체 | 역할 |
|---------|------|---------|------|
| **design-planner** | Codex | 오케스트레이터 | `.artisan.md` 컨텍스트와 리서치 결과를 기반으로 구현 가능한 UX/UI 디자인 브리프 작성 |
| **design-implementer** | Sonnet | 오케스트레이터 | 디자인 브리프 기반 프로덕션 품질 UI 코드 생성. Haiku code-validator로 artisan 검증 루프 |
| **code-validator** | Claude Haiku | design-implementer | `generate_file` 직후 파일마다 artisan 규칙 위반을 검증하고 MODIFY_HINTS 반환. 코드는 수정하지 않음 |
| **design-reviewer** | Claude Opus | 오케스트레이터 | 시각적 품질·접근성·퍼포먼스·안티패턴을 P0-P3 심각도로 분류하여 검토 보고서 작성 |
| **design-cross-validator** | Opus + Codex | 오케스트레이터 | Claude 리뷰와 Codex 독립 리뷰를 비교하여 AI 편향 패턴 제거. 최종 판정: HUMAN_QUALITY / BORDERLINE / AI_DETECTABLE |

### `/ttb-agents:review` 에이전트

| 에이전트 | 엔진 | 관리 주체 | 역할 |
|---------|------|---------|------|
| **validator** | Claude Haiku | 오케스트레이터 | `.claude/agents/` + `.claude/skills/` 전체를 읽고 TTB 표준 체크리스트 기준으로 검증 |

### `/ttb-agents:pm-workflow` 에이전트

| 에이전트 | 엔진 | 관리 주체 | 역할 |
|---------|------|---------|------|
| **research-analyst** | Claude Haiku | 오케스트레이터 | 시장 규모·트렌드·경쟁사 최소 3개 분석·유저 페인 포인트 조사. `_workspace/00_input/interviews/` 자동 탐색 포함. 웹 검색 불가 시 도메인 지식 기반 조사 후 계속 진행 |
| **prd-writer** | Claude Opus | 오케스트레이터 | `pm-standards.md` 필수 로딩 후 PRD 작성. INVEST 기준 유저 스토리, Gherkin 형식 수용 기준, 비기능 요구사항 포함 |
| **roadmap-planner** | Claude Opus | 오케스트레이터 | PRD 기반 기능 분해, MoSCoW 우선순위 분류, 단계별 일정 산정, 기능 의존성 매핑 |
| **prd-validator** | Claude Haiku | 오케스트레이터 | PRD·로드맵 교차 검증. 빠진 요구사항·모순·테스트 불가 기준·INVEST 미충족을 [HIGH]/[MEDIUM]/[LOW]로 분류 |

### `/ttb-agents:sllm` 에이전트

| 에이전트 | 엔진 | 관리 주체 | 역할 |
|---------|------|---------|------|
| **sllm-analyzer** | 기본 LLM | 오케스트레이터 | 도메인·코드베이스를 분석하여 원자 작업 단위를 식별. 토큰 예산·출력 구조·sLLM 적합 여부를 표로 분류 |
| **sllm-optimizer** | 기본 LLM | 오케스트레이터 | 도메인 분석 기반으로 10대 최적화를 적용한 에이전트 설계 명세 작성. 구조화 프롬프트·출력 스키마·생산 모드 경계 정의 |
| **sllm-builder** | 기본 LLM | 오케스트레이터 | 설계 명세 기반으로 에이전트 .md 파일과 SKILL.md 생성. model: 파라미터 없이 Agent() 호출 — ANTHROPIC_MODEL 환경 변수로 로컬 모델 자동 라우팅. OPT-08 쓰기 검증 적용 |

## 요구사항

- Claude Code

## 라이선스

MIT
