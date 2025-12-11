#!/usr/bin/env bash
set -euo pipefail

# Stage7.33_fix9d — простой, но устойчивый KEY scope guard.
# Логика:
#   1) читаем backend/memory/memory_manager.js целиком;
#   2) находим все позиции маркеров:
#        STAGE7.32_PUBLIC_API_KEY_SURFACE_BEGIN / _END
#      и все позиции KEY-литерала __PAIERA_PUBLIC_API_STAGE5_18__;
#   3) ищем пару (BEGIN, END), которая "обнимает" KEY (BEGIN < KEY < END);
#   4) проверяем, что в ЭТОМ surface-блоке KEY встречается ровно 1 раз.

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

ROOT="$ROOT" node <<'NODE'
const fs   = require('fs');
const path = require('path');

const root = process.env.ROOT;
if (!root) {
  console.error('FAIL: ROOT not set');
  process.exit(1);
}

const file = path.join(root, 'backend/memory/memory_manager.js');
let s;
try {
  s = fs.readFileSync(file, 'utf8');
} catch (e) {
  console.error('FAIL: cannot read memory_manager.js:', e.message || e);
  process.exit(1);
}

const BEGIN_TOKEN = 'STAGE7.32_PUBLIC_API_KEY_SURFACE_BEGIN';
const END_TOKEN   = 'STAGE7.32_PUBLIC_API_KEY_SURFACE_END';
const KEY_TOKEN   = '__PAIERA_PUBLIC_API_STAGE5_18__';

function allIndexes(haystack, needle) {
  const res = [];
  let idx = haystack.indexOf(needle);
  while (idx !== -1) {
    res.push(idx);
    idx = haystack.indexOf(needle, idx + needle.length);
  }
  return res;
}

const beginIdx = allIndexes(s, BEGIN_TOKEN);
const endIdx   = allIndexes(s, END_TOKEN);
const keyIdx   = allIndexes(s, KEY_TOKEN);

if (!beginIdx.length || !endIdx.length) {
  console.error('FAIL: KEY surface markers not found (BEGIN/END missing)');
  process.exit(1);
}
if (!keyIdx.length) {
  console.error('FAIL: KEY literal not found at all');
  process.exit(1);
}

// Ищем пару BEGIN/END, которая охватывает хотя бы один KEY
let usedBegin = null;
let usedEnd   = null;
let usedKey   = null;

for (const k of keyIdx) {
  const bCandidates = beginIdx.filter(b => b < k);
  const eCandidates = endIdx.filter(e => e > k);
  if (!bCandidates.length || !eCandidates.length) continue;

  const b = bCandidates[bCandidates.length - 1]; // ближайший BEGIN сверху
  const e = eCandidates[0];                      // ближайший END снизу

  usedBegin = b;
  usedEnd   = e;
  usedKey   = k;
  break;
}

if (usedBegin === null || usedEnd === null) {
  console.error(
    'FAIL: no BEGIN/END pair that encloses KEY (markers malformed or misplaced)'
  );
  process.exit(1);
}

// Берём surface-окно именно по найденной паре
const surface = s.slice(usedBegin, usedEnd);
const reKey = new RegExp(KEY_TOKEN.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'g');
const matches = surface.match(reKey) || [];
const count = matches.length;

if (count !== 1) {
  console.error(
    'FAIL: KEY literal count inside surface != 1 (found ' + count + ')'
  );
  process.exit(1);
}

console.log('KEY_SCOPE_GUARD_OK');
NODE

