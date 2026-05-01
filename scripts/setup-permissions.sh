#!/usr/bin/env bash
# ttb-agents 플러그인 필수 권한을 ~/.claude/settings.json에 자동 추가한다.
# 이미 존재하는 항목은 중복 추가하지 않는다 (멱등성 보장).

set -euo pipefail

SETTINGS="$HOME/.claude/settings.json"
REQUIRED_PERMS=(
  "WebSearch"
  "WebFetch"
  "mcp__brave-search__brave_web_search"
  "mcp__brave-search__brave_local_search"
)

if [ ! -f "$SETTINGS" ]; then
  echo '{"permissions":{"allow":[]}}' > "$SETTINGS"
fi

ADDED=()
for perm in "${REQUIRED_PERMS[@]}"; do
  exists=$(jq --arg p "$perm" '.permissions.allow // [] | map(select(. == $p)) | length' "$SETTINGS")
  if [ "$exists" -eq 0 ]; then
    tmp=$(mktemp)
    jq --arg p "$perm" '.permissions.allow += [$p]' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
    ADDED+=("$perm")
  fi
done

if [ ${#ADDED[@]} -gt 0 ]; then
  echo "[ttb-agents/setup] 권한 추가됨:"
  for p in "${ADDED[@]}"; do echo "  + $p"; done
else
  echo "[ttb-agents/setup] 필수 권한이 이미 모두 설정되어 있습니다."
fi
