#!/usr/bin/env bash
set -euo pipefail

# Selftest: MEMORY public API invariant
# Цель: гарантировать, что __PAIERA_PUBLIC_API_STAGE5_18__
#       существует и даёт объект с методами saveFacts и forgetEntity.
# Проверка тегов вынесена в отдельные tagger-guards.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

NODE_SCRIPT=$(cat <<'JS'
const mm = require('./backend/memory/memory_manager.js');

const KEY = '__PAIERA_PUBLIC_API_STAGE5_18__';
const v = mm[KEY];

if (!v) {
  console.error('FAIL: public API key missing:', KEY);
  process.exit(1);
}

const api = (typeof v === 'function') ? v() : v;

const hasSaveFacts = !!(api && typeof api.saveFacts === 'function');
const hasForget    = !!(api && typeof api.forgetEntity === 'function');

if (!hasSaveFacts || !hasForget) {
  console.error('FAIL: public API methods missing:', { hasSaveFacts, hasForget });
  process.exit(1);
}

console.log('MEMORY_PUBLIC_API_INVARIANT_OK', { hasSaveFacts, hasForget });
JS
)

node -e "$NODE_SCRIPT"
