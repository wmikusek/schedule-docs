# CKT Summary

## Navigation
- Generic

## Filtering
- Generic

## Grouping
- No grouping

## Card Content
- For unknown teams display differs by round
-- Second round - TBD abbreviation
  -- Finals - string e.g 'Second Round Rank 3'
- Design: standard **H2H** card (score cell + Match info; no separate CKT layout)
- Score: innings `runs/wickets (overs)`; Super Over on a separate line via `soResult` (`SO` for first, `SO2`… later) — **only when `soResult.score` is not `YTB`** (e.g. `SO 7/0 (1)`); latest SO only
- Before match: no scores / no YTB (even after toss)
- During IN1: one score + YTB; raw `toss` BAT|FIELD on toss winner → FE elected line (2 i18n: bat / field)
- During IN2: both scores; no toss / no YTB
- Medallists follow head-to-head pattern (G & S together, B on different item)
- Head-to-head winner highlight pattern
- **Status / Match info line**
  - Before: empty
  - During IN1: `First innings: {Team name} elected to bat` / `… elected to field` (from `toss` + team name)
  - After: BE `finalResultDescription` (winner + situation string; do not compose on FE)

## Contextual Menu
- TBC
