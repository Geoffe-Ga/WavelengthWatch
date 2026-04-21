# Remaining GitHub Issues — Concurrency Plan

**Date:** 2026-04-21
**Author:** Claude (session `gqeTE`)
**Branch:** `claude/github-issues-workflow-plan-gqeTE`
**Scope:** All 34 currently-open issues in `geoffe-ga/wavelengthwatch`

## Executive Summary

This plan maximizes parallel execution while respecting merge-conflict risk. The longest serial chain is the Liquid Glass rebuild (phases 2a → 7, since 1a/1b have already shipped via PRs #306 and #310 even though issues #293 and #294 remain OPEN and should be closed). Everything else can run in 2–4 parallel tracks across Waves 1–2, then serializes for flow-surface work.

## Issue Inventory

| Group | Issues |
|---|---|
| Liquid Glass rebuild (epic #292) | #293, #294, #295, #296, #297, #298, #299, #300, #301, #302, #303 |
| Analytics simplifications | #280, #281, #282, #285 |
| Journal-flow reframes | #283, #284, #286, #287, #288, #289 |
| Analytics epic #187 | #258 (profile), #259 (optimize), #260 (drill-down) |
| Offline queue epic #186 | #215, #216, #218 |
| Tooling / release | #232, #271, #272 |
| Meta (needs decomposition) | #244 |

**Note:** Issues #293 and #294 are still OPEN despite phases 1a/1b having landed via PRs #306 and #310. Before starting Wave 4, close these as done or verify any remaining acceptance criteria.

## Dependency Rules

1. Liquid Glass phases are strictly sequential: **1a → 1b → 2a → 2b → 3a → 3b → 4 → 5 → 6a → 6b → 7**.
2. Offline queue is sequential: **#215 → #216 → #218**.
3. Analytics epic: **#258 first**, then **#259 + #260 in parallel**.
4. Journal-flow reframes conflict with Liquid Glass Phase 4 (#299). Land them **before** Phase 4 *or* fold into Phase 4.
5. Analytics reframes all touch the same views — batch into one PR rather than running parallel.
6. #272 (TestFlight) gates on app being release-ready.
7. #244 needs decomposition before engineering begins — side track only.

## Batches

### Wave 1 — four parallel tracks

| Track | Issue(s) | Why safe to parallelize |
|---|---|---|
| A | #232 | New shell script, new file only |
| B | #258 | Profiling / measurement only, no production edits |
| C | #271 | Docs + metadata, zero code |
| D | #280 + #281 + #282 + #285 (one PR) | All analytics copy/logic tweaks; serialize edits within the PR to avoid self-conflict |

### Wave 2 — two parallel tracks after Wave 1 lands

| Track | Chain | Notes |
|---|---|---|
| E | #259 → #260 | Needs #258 findings; drill-down can start once optimize design is settled |
| F | #215 → #216 → #218 | Offline queue wired, then surfaced, then tested |

### Wave 3 — single serial track (journal-flow reframes)
#283 → #284 → #286 → #287 → #288 → #289. All mutate journal flow or curriculum detail — serialize to avoid rebase churn.

### Wave 4 — Liquid Glass rebuild (single serial track)
#295 → #296 → #297 → #298 → #299 → #300 → #301 → #302 → #303.
(Issues #293 and #294 should be closed as already-shipped before starting.)

### Wave 5 — release gate
#272 after all of Wave 4 merges.

### Side track (any time)
Decompose #244 into 4–8 sub-issues; do not commit engineering cycles yet.

## Prompts

Each prompt is designed to be terse but explicit about which skills/scripts to use. Every agent should work on a feature branch off `main` and open one PR per issue (except Wave 1 Track D, which ships as a single batched PR).

### Wave 1 — Track A (#232)
```
Implement issue #232 in geoffe-ga/wavelengthwatch. Use the stay-green skill
(TDD + Gate 2). Put the script under scripts/. No UI or backend changes.
Run scripts/check-backend.sh before pushing. Open a PR when green.
```

### Wave 1 — Track B (#258)
```
Work issue #258 using the stay-green skill. Produce a profiling report in
prompts/claude-comm/ (use the file-naming-conventions skill for the filename)
with hotspots identified via Instruments or a test-harness timing pass. No
production code changes required; if you add a benchmark harness, gate it
behind a test target. Run frontend/WavelengthWatch/run-tests-individually.sh
before push.
```

### Wave 1 — Track C (#271)
```
Complete issue #271. Docs-only. Place artifacts under docs/ or a
store-assets/ folder. Use the file-naming-conventions skill for any dated
planning notes. Open PR.
```

### Wave 1 — Track D (#280 #281 #282 #285 as one PR)
```
Deliver issues #280, #281, #282, #285 as a single PR titled
"Analytics reframes batch 1". Use stay-green (write/adjust tests first).
Use the vibe skill for copy changes. Run
frontend/WavelengthWatch/run-tests-individually.sh. Reference all four issue
numbers in the PR body.
```

### Wave 2 — Track E (#259 then #260)
```
Execute issues #259 then #260 sequentially on the same branch, one commit per
issue. Use stay-green end-to-end. For #259, consult the #258 profiling report
before changing queries. For #260, use the tracer-code skill to wire
navigation before filling detail. Run
frontend/WavelengthWatch/run-tests-individually.sh between issues. Open one
PR per issue.
```

### Wave 2 — Track F (#215 → #216 → #218)
```
Execute issues #215, #216, #218 serially, one PR each. Use stay-green. #218
is test-heavy — use the testing skill. After each merge, run
frontend/WavelengthWatch/run-tests-individually.sh and
scripts/check-backend.sh if backend touched.
```

### Wave 3 (#283 → #284 → #286 → #287 → #288 → #289)
```
Work issues #283, #284, #286, #287, #288, #289 one at a time on separate
branches off main, PR each before starting the next. Use stay-green for all;
use tracer-code for #284 and #288 (new surfaces). Run
frontend/WavelengthWatch/run-tests-individually.sh before every push. Ask
before changing any shared ViewModel signature.
```

### Wave 4 — Liquid Glass phases (one run per phase)
Substitute `<NUM>` with 295, 296, … 303, one at a time:
```
Execute issue #<NUM> from epic #292. Use stay-green for the whole issue. For
architectural choices inside the phase, use architectural-decisions. Use
max-quality-no-shortcuts — no SwiftLint/mypy bypasses. For Phase 6a (#301)
use the testing skill. For Phase 6b (#302) use comprehensive-pr-review
against the accumulated diff. For Phase 7 (#303) use backlog-grooming. Run
frontend/WavelengthWatch/run-tests-individually.sh before push. Open one PR;
link it to #292.
```

### Wave 5 (#272)
```
Coordinate issue #272. No code; produce a TestFlight checklist and
tester-comms plan in prompts/claude-comm/ using the file-naming-conventions
skill. Verify prerequisites (App Store metadata #271 merged, all Liquid
Glass phases closed).
```

### Side track (#244)
```
Use the backlog-grooming skill on epic #244. Produce a decomposition
proposal with 4–8 sub-issues, each with acceptance criteria. Do not open
the sub-issues yet — post the proposal as a comment on #244 for human
review.
```

## Throughput Summary

- **Wave 1:** up to 4 agents in parallel
- **Wave 2:** 2 agents in parallel
- **Wave 3:** 1 agent (serial, 6 issues)
- **Wave 4:** 1 agent (serial, 9 remaining phases)
- **Wave 5:** 1 agent (final gate)

If you accept rebase risk on the journal flow, Wave 3 can run concurrently with Waves 1–2, pushing peak parallelism to 5 tracks. Running Wave 4 alongside Wave 3 is NOT recommended — Phase 4 (#299) is the merge-conflict hotspot.
