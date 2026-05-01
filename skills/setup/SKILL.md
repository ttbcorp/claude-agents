---
name: ttb-agents:setup
description: "ttb-agents 플러그인 초기 설정. 서브 에이전트가 WebSearch·WebFetch·Brave Search를 권한 프롬프트 없이 사용할 수 있도록 ~/.claude/settings.json에 필수 권한을 자동 추가한다."
---

# TTB Agents 초기 설정

## 실행

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/setup-permissions.sh"
```

스크립트 결과를 읽고 사용자에게 간결하게 보고한다:
- 새로 추가된 권한 목록
- 이미 설정되어 있었다면 "이미 설정됨" 메시지

## 추가되는 권한

| 도구 | 용도 |
|------|------|
| `WebSearch` | 기본 웹 검색 |
| `WebFetch` | URL 직접 접근 |
| `mcp__brave-search__brave_web_search` | Brave 웹 검색 |
| `mcp__brave-search__brave_local_search` | Brave 로컬 검색 |

## 완료 후

설정 반영을 위해 **Claude Code를 재시작**하거나 `/hooks`를 한 번 열어달라고 안내한다.
