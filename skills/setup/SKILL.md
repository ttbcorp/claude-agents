---
name: setup
description: "ttb-agents 플러그인 초기 설정.
  서브 에이전트가 WebSearch·WebFetch·Brave Search를 권한 프롬프트 없이 사용할 수 있도록 ~/.claude/settings.json에 필수 권한을 자동 추가한다.
  '/ttb-agents:setup', 'ttb 권한 설정해줘', '플러그인 초기 설정해줘', 'ttb-agents 설치 후 설정해줘' 요청 시 반드시 이 스킬을 사용할 것.
  권한 누락 확인, 설정 재실행, 추가 권한 재적용 요청 시에도 사용."
---

# TTB Agents 초기 설정

## 실행

### Step 1: Python 가용성 확인

아래 명령으로 Python 설치 여부를 확인한다:

```
python3 --version
```

실패 시:

```
python --version
```

결과에 따라 `PYTHON_CMD`를 결정한다:
- `python3` 성공 → `PYTHON_CMD=python3`
- `python` 성공 → `PYTHON_CMD=python`
- 둘 다 실패 → `PYTHON_CMD=none`

사용자에게 Python 상태를 한 줄로 보고한다:
- 발견: `Python {버전} 확인 — 스크립트 모드`
- 미발견: `Python 미설치 — 네이티브 모드 (모든 기능 정상 동작)`
  - 선택 사항으로 설치 안내: Python 3이 있으면 스크립트 모드로 더 빠르게 동작합니다. 설치: https://python.org

### Step 2: 권한 설정

**PYTHON_CMD가 있는 경우:**

```
{PYTHON_CMD} "{CLAUDE_PLUGIN_ROOT}/scripts/setup-permissions.py"
```

**PYTHON_CMD=none인 경우 (네이티브 폴백):**

Read 도구로 `~/.claude/settings.json`을 읽고, 아래 권한 목록에서 누락된 항목을 직접 추가한다:

```json
["WebSearch", "WebFetch", "mcp__brave-search__brave_web_search", "mcp__brave-search__brave_local_search"]
```

- `permissions.allow` 배열에 누락 항목만 추가 (중복 금지)
- Write 도구로 저장

결과를 사용자에게 보고한다:
- 새로 추가된 권한 목록
- 이미 설정되어 있었다면 "이미 설정됨" 메시지

## 추가되는 권한

| 도구 | 용도 |
|------|------|
| `WebSearch` | 기본 웹 검색 |
| `WebFetch` | URL 직접 접근 |
| `mcp__brave-search__brave_web_search` | Brave 웹 검색 |
| `mcp__brave-search__brave_local_search` | Brave 로컬 검색 |

### Step 3: gstack UI 검증 Hook 설정

프로젝트 `.claude/settings.json`에 UI 파일 변경 시 gstack 스크린샷 검증 hook을 추가한다.

**대상 파일:** `{PROJECT_ROOT}/.claude/settings.json`

파일을 Read 도구로 읽어 기존 `hooks.PostToolUse` 배열에 아래 항목이 이미 있으면 스킵하고, 없으면 추가한다 (중복 금지):

```json
{
  "matcher": "Write|Edit",
  "hooks": [
    {
      "type": "command",
      "command": "FILE=$(jq -r '.tool_input.file_path // .tool_response.filePath' 2>/dev/null); if ! echo \"$FILE\" | grep -qE '\\.(html|htm|jsx|tsx|vue|svelte|css|scss|less)$'; then exit 0; fi; if ! command -v gstack &>/dev/null; then echo '{\"systemMessage\":\"gstack이 설치되지 않아 UI 검증을 건너뜁니다. gstack 설치 후 /gstack-upgrade로 최신 버전을 유지하세요.\"}'; exit 0; fi; gstack screenshot \"$FILE\" 2>/dev/null || true",
      "statusMessage": "UI 화면 변경 감지 — gstack으로 검증 중...",
      "timeout": 60
    }
  ]
}
```

- 파일이 없으면 `{"hooks":{"PostToolUse":[...]}}` 형태로 새로 생성한다.
- 이미 동일한 `matcher`가 존재하면 `.hooks` 배열에 command만 추가한다.

결과를 보고한다:
- 추가됨: "gstack UI 검증 hook을 `.claude/settings.json`에 추가했습니다."
- 이미 있음: "gstack UI 검증 hook 이미 설정됨 — 스킵."

## 완료 후

설정 반영을 위해 **Claude Code를 재시작**하거나 `/hooks`를 한 번 열어달라고 안내한다.
