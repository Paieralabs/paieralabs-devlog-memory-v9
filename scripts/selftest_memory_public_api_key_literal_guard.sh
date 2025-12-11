#!/usr/bin/env bash
set -euo pipefail
node - <<'NODE'
const fs=require('fs');
const f='backend/memory/memory_manager.js';
const s=fs.readFileSync(f,'utf8');
const count=(re)=> (s.match(re)||[]).length;
const n=count(/__PAIERA_PUBLIC_API_STAGE5_18__/g);
console.log('KEY_literal(__PAIERA_PUBLIC_API_STAGE5_18__):', n);
const EXPECT=1;
if (n !== EXPECT) {
  console.error(`FAIL: expected KEY_literal count == ${EXPECT} (baseline). If intentional, bump EXPECT in guard script.`);
  process.exit(2);
}
console.log('KEY_LITERAL_GUARD_OK');
NODE
