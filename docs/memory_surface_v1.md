# Memory Call Surface v1 (Stage8.3)

Цель: зафиксировать, какие модули backend имеют право напрямую вызывать публичные методы памяти
(memory_manager), чтобы контролировать поверхность и упрощать аудит.

## Публичные методы памяти

Под «памятью» здесь понимается `backend/memory/memory_manager.js` и его публичный API:

- `saveFacts(...)`
- `forgetEntity(...)`
- `getRelevantFacts(...)` (включая обёртки вида `getRelevantFacts(params)`)

## Разрешённая поверхность вызовов (v1)

На текущий момент прямые вызовы публичных методов памяти допускаются только из следующих файлов:

1. `backend/server.js`
   - REST-эндпоинты:
     - `memoryManager.saveFacts(facts)`
     - `memoryManager.forgetEntity(entity)`

2. `backend/core/engine_core.js`
   - внутренняя логика движка:
     - `memoryManager.saveFacts([...])` — сохранение ключевых фактов (например, возраст владельца и др.).

3. `backend/core/files/file_facts_apply.js`
   - применение фактов из файлов (knowledge ingest):
     - `memoryManager.saveFacts(facts)`

Файл `backend/memory/memory_manager.js` сам по себе не считается участком поверхности:
он реализует API и может вызывать свои же функции внутри.

## Правило Surface v1

Любые новые прямые вызовы методов памяти (`saveFacts`, `forgetEntity`, `getRelevantFacts`)
допустимы только в перечисленных выше файлах.

Если требуется работа с памятью из других модулей, нужно:

- либо пробрасывать данные через `engine_core`,
- либо добавлять/расширять соответствующий REST-эндпоинт в `backend/server.js`,
- либо расширять pipeline `file_facts_apply` (для ingest-сценариев).

## Аудит

Для контроля поверхности используется вспомогательный скрипт:

- `scripts/audit_memory_calls.sh`
- npm-скрипт: `npm run audit:memory:calls`

Он выводит все вхождения вызовов:

- `saveFacts(`
- `forgetEntity(`
- `addFact(`
- `addFacts(`
- `upsertFact(`
- `getRelevantFacts(`

внутри каталога `backend`, исключая резервные файлы (`*BROKEN*`, `*broken*`, `*.bak_*`).

При добавлении нового места вызова памяти инженер обязан:

1. Обновить этот документ (`memory_surface_v1.md`), зафиксировав новый участок поверхности.
2. Убедиться, что он попадает под описанные выше правила архитектуры (через server / engine_core / file_facts_apply).
