# ReSpace AI Design Handoff Notes

Source reference: `design-handoff/AI Design/`

## Visual Direction

- Mobile-only premium AI utility with a calm, trustworthy feel.
- Light neutral background `#EEF3F4`, white cards, teal primary accent `#0E9E8C`, and warm amber reserved for future redesign/shopping flows.
- Typography reference: Space Grotesk for display headings, Inter for body text.
- UI primitives: soft 16-26px radius cards, pill chips, segmented controls, rounded icon buttons, bottom tabs, clear step progress indicators.
- Each AI layout pairs a generated-style room image with a top-down plan so users can understand actual furniture placement.

## MVP Product Rules Reflected In Flutter

- Reshuffle Existing Room is the fully implemented Phase 1 workflow.
- Redesign My Room is visible but marked Coming Soon.
- AI detection output is editable and never treated as guaranteed truth.
- Fixed items are explicit and carried into preferences/results/final plan.
- Generated layouts include reasoning, pros/cons, difficulty, moved items, unchanged items, and step-by-step move instructions.
- Measurements/product recommendations/marketplace/AR/3D editor are deferred.

## Implemented Flutter Flow

1. Welcome
2. Home
3. Mode selection
4. Capture instructions
5. Upload/record video mock
6. Processing pipeline mock
7. Detected item review
8. Reshuffle preferences
9. Generated layout results
10. Layout detail
11. Final move plan
12. Saved projects
13. Profile/settings placeholder
