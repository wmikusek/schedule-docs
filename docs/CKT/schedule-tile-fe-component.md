# CKT Schedule Tile — FE Component Extension

**Audience:** Frontend (WMR / CIS schedule card)  
**Baseline Figma:** [Cross-sport pages 2.0 — Header / schedule card](https://www.figma.com/design/7R46sxsgqvLb3kbA1BW6cF/Cross-sport-pages-2.0?node-id=27483-256042&m=dev) (`7R46sxsgqvLb3kbA1BW6cF` · `27483:256042`)  
**Product rules:** [schedule-tile-requirements.md](./schedule-tile-requirements.md) · [common](../common/schedule-tile-common.md)  
**API:** [Schedule](https://dgplatform.atlassian.net/wiki/spaces/SCDLA/pages/3120988164/Schedule)

This doc maps the **existing baseline card** to what CKT needs. Do not fork a separate cricket-only card unless design ships one — extend the same component with sport variants / slots.

---

## 1. Baseline anatomy (what we already have)

From the selected Figma instance (`Header` → `Card content`):

| Slot (Figma name) | Role today | CKT reuse |
|-------------------|------------|-----------|
| **WMR Schedule cards time & status** | Time pill + status icon + optional medal | Keep. During live, status/progress may show innings (see §3). |
| **Text box → Headline** | Discipline name (e.g. Basketball) | Keep → Cricket / CKT display name. |
| **Text box → Subtext** | Event / phase (e.g. Men’s Semifinal) | Keep → event + phase; group stage may include “Group A” (OSRP). |
| **Right aligned** | Full Results · bookmark · overflow | Unchanged (product chrome). |
| **Results box → WMR Schedule results** | 2 stacked rows: flag · name · **numeric score**; winner chevron | Keep layout; change **score cell** content and row states (§4). |
| **Match info** (in Figma: **hidden**) | Reserved strip under header / around results | **Enable for CKT** — match-situation / first-innings line (§5). |
| **WMR Schedule buttons bar** (hidden) | Extra actions | Out of scope unless product asks. |

Figma annotation on winner chevron: *“Winner indicator doesn't show up on medal events”* — still apply for CKT H2H; hide on pure medal-event layouts if that rule is global.

```
┌─────────────────────────────────────────────────────────────┐
│ [time]  Headline (discipline)              Full Results  … │
│ [status] Subtext (event / phase)                           │
│ [medal?]                                                   │
├─────────────────────────────────────────────────────────────┤
│  Results box                                               │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 🏳️ Team A                              score cell A │◀──│ winner
│  │ 🏳️ Team B                              score cell B │   │
│  └─────────────────────────────────────────────────────┘   │
│  Match info  ← enable for CKT (situation / elected)        │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Variant strategy

| Approach | Recommendation |
|----------|----------------|
| New `ScheduleCardCkt` | Avoid unless design diverges heavily |
| Same card + `disciplineCode === 'CKT'` / flavour `h2h-score` | **Preferred** — extend score renderer + Match info |
| Score cell as pluggable `ScoreRenderer` | Strongly preferred — baseline uses simple number; CKT needs string / dual line |

**FE responsibility split**

| Layer | Owns |
|-------|------|
| BE / API | `result.result` (+ overs); IN1 `YTB` + `toss`; `soResult` (`SO`/`SO2`…); `liveCurrentProgress`; `finalResultDescription`; placeholders; WLT |
| FE | Map API → baseline slots; **do not** compose ResultDesc / `#ORG*` templates client-side |

---

## 3. Header extensions (time & status)

### 3.1 Unchanged

- Time from `startDate` **or** `startText` when `hideStartDate` ([common §3.4](../common/schedule-tile-common.md)).
- No “Scheduled” badge.
- Medal icon when `medalFlag` ≠ none.
- Status icon from `scheduleStatus` / after finish `resultStatus` (common).

### 3.2 Live progress (CKT-specific)

When `scheduleStatus` is live-ish (`RUNNING`, break, interrupted) and API provides `liveCurrentProgress`:

| Field | UI |
|-------|-----|
| `liveCurrentProgress.name` | Show as progress label (e.g. **2nd Innings**, optionally with over if BE folded it into `name`) |
| Placement | Prefer under / beside status icon in **time & status**, **or** as secondary line in Match info — pick one per design; do not duplicate. |

Before start / after finish: treat progress as absent (`null`) — do not leave stale innings text.

---

## 4. Results box — competitor rows

Baseline: two rows, each `NOC/flag + name + score`.

### 4.1 Competitors / placeholders

| API | FE |
|-----|-----|
| Confirmed team | Flag + team name (`competitors[]`) |
| Placeholder | No flag (or placeholder glyph per DS); `placeholderOpponents[].name` as-is (`To be determined`, `Second Round Rank n`, …) |
| `NOCOMP` | Follow DS empty/no-competitor pattern if present |

Do not invent TBD copy on FE.

### 4.2 Score cell — replace simple integer

Baseline shows `18` / `16`. For CKT the **same cell** must support:

| State | Display | Source |
|-------|---------|--------|
| Before | Empty / hidden scores | No `result` / no `YTB` (even post-toss) |
| During IN1 — batting | `nnn/n (n.n)` | `competitors[].result.result` |
| During IN1 — not yet batted | **Yet to bat** | `result.result === "YTB"` → OSRP phrase |
| During IN2 | Both scores | No YTB / no toss |
| During / after — Super Over | Primary score + second line `SO` / `SO2`… + score | `soResult` **only when `score` is not `YTB`** (e.g. `SO 7/0 (1)`). If `soResult.score === "YTB"` → **omit** the SO line for that row. Latest SO only (`SO2` replaces `SO`). |
| IRM / abandoned path | Follow IRM / empty + Match info sentence | Prefer situation line for Abandoned / No Result |

**Typography**

- Winner row: keep baseline **bold name** + winner chevron (`WLT=W`).
- Losing / other: medium weight as today.
- “Yet to bat”: treat as score-slot text (medium), not a fake `0/0`.

**Layout risk:** cricket strings are wider than `18`. Score column must allow shrink/wrap or min-width growth without colliding with names. If Figma has no CKT score variant yet, implement with design tokens and flag for UX review of long strings (`245/8 (50.0)` + `SO 12/1 (1.2)`).

### 4.3 Winner indicator

- Show when `WLT` indicates winner and unit is not under the global “hide on medal events” rule.
- CKT after: always prefer chevron + bold on winner when there is a decisive result; for `TIED` / No Result / Abandoned — **no** winner chevron.

---

## 5. Match info slot (enable for CKT)

Baseline has **Match info** hidden. For CKT, show it when there is copy:

| Phase | Content | API |
|-------|---------|-----|
| During — 1st innings | Elected line (2 i18n strings) | FE from `competitors[].toss` (`BAT`\|`FIELD`) + that competitor’s team name (requirements §3.4). Hide when `toss` absent (IN2 / before / after). |
| After | Match situation sentence | **`extendedResultInfo.finalResultDescription` only** |
| After examples | `India beat Pakistan by 9 wickets` · `… by 44 runs` · Super Over · `Match Abandoned` · `No Result` | BE-interpolated `SC@ResultDesc` |

**IN1 elected translations (FE owns copy + name substitution)**

| `toss` | Match info |
|--------|------------|
| `BAT` | `First innings: {Team name} elected to bat` |
| `FIELD` | `First innings: {Team name} elected to field` |

`{Team name}` = display name of the competitor that carries `toss` (same name as on that H2H row).

**Rules**

1. Never build `#ORG1 beat #ORG2 by #SCR …` on the client (after sentence).
2. If `finalResultDescription` is null/empty after finish, hide Match info (do not fall back to guessing from scores).
3. One line; truncate/ellipsis per DS if overflow.
4. Do not put situation text inside the score column.
5. Super Over: render `soResult.periodCode` as-is (`SO`, `SO2`, …) **only with a real score**. Do **not** show an SO line when `soResult.score` is `YTB`. BE sends latest SO only — when `periodCode` is `SO2`, do not keep a previous `SO` line. If BE still sends `SO1`, FE may strip the `1` until scoreboard/BE align (requirements §3.4b).

---

## 6. Phase → slot matrix

| Slot | Before | During | After |
|------|--------|--------|-------|
| Time / startText | ✓ | ✓ | ✓ (or finished status focus) |
| Status / medal | status as common; medal if any | live + optional `liveCurrentProgress` | result status + medal |
| Headline / Subtext | discipline + event/phase/group | same | same |
| Results rows | teams or placeholders; **no scores / no YTB** | flags + names + score **or** YTB (IN1 only); SO second line only when `soResult.score` ≠ `YTB` | scores (+ SO if scored); winner styling |
| Match info | hidden | elected line from `toss` (IN1 only; 2 i18n strings) | **`finalResultDescription`** |
| Full Results etc. | as product | as product | as product |

---

## 7. Suggested FE props / mapping (illustrative)

Not a mandated TypeScript contract — align with existing Schedule API types.

```ts
// Baseline row
type ScheduleCompetitorRow = {
  flag?: string;
  name: string;
  isWinner?: boolean;
  /** Baseline: number | string. CKT innings: "128/5 (20.3)" | "Yet to bat" */
  scoreDisplay?: string | null;
  /** CKT Super Over line when scored: "SO 7/0 (1)" | "SO2 12/0 (1.4)". Omit / null when soResult.score is YTB. */
  soScoreDisplay?: string | null;
  toss?: "BAT" | "FIELD";
};

type ScheduleCardViewModel = {
  timeLabel: string;           // clock or startText
  status: { icon: string; label?: string };
  medalVisible: boolean;
  headline: string;            // discipline
  subtext: string;             // event / phase / group
  rows: [ScheduleCompetitorRow, ScheduleCompetitorRow] | ScheduleCompetitorRow[];
  liveProgressLabel?: string | null;  // from liveCurrentProgress.name
  matchInfo?: string | null;          // finalResultDescription | elected line from toss
  showMatchInfo: boolean;
};
```

| API | → VM |
|-----|------|
| `competitors[].result.result` (+ YTB in IN1) | `scoreDisplay` |
| `competitors[].soResult` | `soScoreDisplay` (`periodCode` + score) |
| `competitors[].toss` | `toss` / elected `matchInfo` (IN1) |
| `competitors[].result.wlt` | `isWinner` |
| `placeholderOpponents[]` | rows without scores |
| `liveCurrentProgress.name` | `liveProgressLabel` |
| `extendedResultInfo.finalResultDescription` | `matchInfo` (after) |

---

## 8. FE checklist (CKT vs baseline)

- [ ] Reuse baseline card; no parallel cricket-only layout without design
- [ ] Score cell accepts **string** (runs/wickets/overs), not only integer
- [ ] Before: empty scores (never double YTB)
- [ ] Map IN1 `YTB` → **Yet to bat** in score slot
- [ ] Super Over: second line only when `soResult.score` is not `YTB` (e.g. `SO 7/0 (1)`); latest SO only (`SO2` replaces `SO`); optional strip `1` if BE sends `SO1`
- [ ] Enable **Match info** for `finalResultDescription` after finish
- [ ] Never compose **after** situation sentence on FE
- [ ] IN1: two i18n strings — `First innings: {Team} elected to bat/field` from `toss` + team name; hide in IN2
- [ ] Placeholders: render BE `name`; no client TBD dictionary
- [ ] Optional: `liveCurrentProgress` in status area during live
- [ ] Winner chevron + bold; suppress for tie / abandoned / no result
- [ ] Long score strings: layout QA (desktop + mobile widths)

---

## 9. Design follow-ups

Ask design if missing from the baseline node:

1. Explicit CKT states: Yet to bat, long score, Super Over, Match info with situation text, live innings chip.
2. Placeholder row (no flag).
3. Whether live progress sits in **time & status** or **Match info**.

Until those frames exist, implement against this doc + OSRP copy; visual polish when CKT variants land in the same Figma file.
