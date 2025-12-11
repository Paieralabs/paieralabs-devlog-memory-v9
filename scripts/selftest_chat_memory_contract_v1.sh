#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASE="${BASE:-http://localhost:7700}"

echo "== selftest: chat + memory contract v1 (Stage9.2) =="

echo
echo "== case: owner age (Stage5.28) =="
msg="Stage9.2 smoke: what is the name of my AI?"
echo "message: ${msg}"

resp=$(curl -sS -X POST "${BASE}/api/chat" \
  -H "Content-Type: application/json" \
  -d '{"message":"Stage9.2 smoke: what is the name of my AI?","sessionId":"stage9_2_contract"}')

echo "response: ${resp}"
echo
echo "SELFTEST_CHAT_MEMORY_CONTRACT_V1_OK"

