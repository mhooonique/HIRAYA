# Digital Platform Agent Collaboration Protocol

## Shared Mission
- Build a cohesive, high-quality UI for Digital Platform using the Hiraya brand theme.
- Prioritize user engagement, smooth transitions, and production-safe implementations.
- Minimize regressions with focused verification per changed section.

## Team Workflow
1. `ui-orchestrator` breaks work into tasks and assigns specialists.
2. Specialists must read and follow shared design tokens and section constraints before editing.
3. Every specialist reports:
   - files changed
   - decisions made
   - unresolved risks
4. `qa-consistency` performs cross-section theme and interaction checks before handoff.

## Shared Context Sync (Required)
- Before coding, each agent posts a short **Task Intent** note with affected files and UX goals.
- After coding, each agent posts a **Delta Summary** with exact interaction and visual changes.
- `ui-orchestrator` maintains a running **Theme Contract**: colors, radii, typography scale, and motion durations.
- If one agent changes a motion/spacing pattern, all active agents must align to the updated pattern in the same sprint.
- Any unresolved uncertainty is escalated back to `ui-orchestrator` before more edits are made.

## Task Assignment Matrix
- `landing-marketplace-ui-specialist`: hero, search, category rhythm, marketplace visual storytelling.
- `auth-ui-specialist`: auth-entry interactions used inside shared headers or cross-route nav elements.
- `qa-consistency`: final visual consistency, route safety, responsive behavior, and interaction parity.
- `ui-orchestrator`: workload balancing, final integration review, and conflict resolution.

## Delivery Standard
- Every task owner must run targeted checks for edited files and verify no route/provider contract regressions.
- All UI edits must preserve accessibility and text readability against dark backgrounds.
- Motion must stay smooth and intentional: no decorative animation without UX purpose.

## Uniformity Rules
- Keep typography, spacing rhythm, and motion timing consistent across auth, landing, marketplace, and footer.
- Reuse existing core widgets and color constants whenever possible.
- Keep brand language as **Digital Platform** for all visible labels.

## Error Avoidance
- Run targeted static checks on edited files.
- Prefer incremental patches over broad rewrites.
- Preserve existing route contracts unless explicitly migrated.
