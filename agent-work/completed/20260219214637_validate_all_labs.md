# validate_all_labs

## Status: completed (20260219214749)

## Context
User requested a strict validation of whether all labs in this repository are correct and valid.
Validation must cover both structure and content expectations defined in `AGENTS.md`.
No file changes should be made outside this work-tracking record unless required by user.

## Value Proposition
Provides a trustworthy audit result with concrete gaps, so the user can prioritize fixes and avoid broken learning scenarios.

## Alternatives considered (with trade-offs)
- Quick spot-check of a few scenarios: fast but high risk of false confidence.
- Full structural + semantic audit of all scenario docs and lab files: slower but highest confidence and actionable findings.
- Execute all labs end-to-end: strongest runtime confidence but requires heavy dependencies/runtime and may be costly.

## Todos
- [x] Inspect repo state and enumerate all scenario/lab paths
- [x] Validate required files and naming conventions for each scenario
- [x] Validate markdown content requirements (frontmatter, sections, quick-check format)
- [x] Validate lab artifacts (`lab/README.md`, `lab/main.tf`, `lab/verify.sh`) and script executability
- [x] Summarize findings with severity and exact file references
- [x] Provide final verdict on whether labs are 100% correct and valid

## Acceptance Criteria
- Every scenario under `learning-materials/fundamentals` is checked against AGENTS requirements.
- Any missing or invalid requirement is reported with precise path references.
- Final answer states clearly whether the set is 100% correct or not.

## Notes
If runtime verification cannot be executed due environment constraints, report that explicitly as residual risk.
