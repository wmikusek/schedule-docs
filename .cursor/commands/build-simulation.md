---
name: build-simulation
description: >-
  Build an ODF schedule-tile freeze under ownScenarios/{DISC} from
  docs/{DISC}/schedule-tile-requirements.md and rawData/{DISC}. Copy ODFs
  first, remap dates, bootstrap PARTIC/TEAMS/ENTRIES, cover before/during/after
  through medals, include Schedule=S units. Use when creating schedule tile
  simulations, freezes, or ownScenarios playback.
---

# Schedule tile simulation

Argument: discipline code (e.g. `ARC`). Optional notes after the code.

```
$ARGUMENTS
```

If `$ARGUMENTS` is empty, ask for the 3-letter discipline code and stop until provided.

Default pack path: `docs/{DISC}/schedule-tile-requirements.md`.  
If that file is missing → stop and tell the user to run `/define-requirements {DISC}` first.

---

## Hard stops

1. **`rawData/{DISC}/` must exist and contain ODF XML.** If not → **HARD STOP**. Do not invent a full freeze from scratch.
2. Do **not** modify files under `rawData/`.
3. Do **not** reverse medal order: always `DT_MEDALLISTS` then `DT_MEDALS`.
4. Do not generate application code — only `ownScenarios/` XML + README + `AC.feature`.

---

## Read these templates first

| Artefact | Template |
|----------|----------|
| Requirements pack | `docs/{DISC}/schedule-tile-requirements.md` |
| Freeze README (team / multi-day) | [`ownScenarios/CKT/README.md`](../../ownScenarios/CKT/README.md) |
| Freeze README (single day H2H) | [`ownScenarios/SQU/README.md`](../../ownScenarios/SQU/README.md) |
| Freeze README (Schedule=S + overrides) | [`ownScenarios/ARC/README.md`](../../ownScenarios/ARC/README.md) |
| AC.feature style | [`ownScenarios/CRD/AC.feature`](../../ownScenarios/CRD/AC.feature) |
| Grouping | [`docs/grouping/olympic-grouping-rules.csv`](../../docs/grouping/olympic-grouping-rules.csv) |

---

## MCP / tools

- **Common Codes**: confirm `CC@Unit` Schedule **Y / N / S** counts and which RSC patterns are `S`.
- **ODF verifier**: after fabricating any XML, try `validate_attached_file` (or equivalent) on fabricated messages; report pass/fail.
- Optional: OSRP/ORIS only to clarify cases already listed in the pack — prefer the pack as source of truth for this command.

---

## Pipeline (fixed order)

```
Progress:
- [ ] Gate 0: rawData/{DISC} has ODF XML
- [ ] Read requirements pack + choose cases to cover
- [ ] Create ownScenarios/{DISC}/01_Schedule_Tile_Mixed_Day/ (or _Mixed_Days)
- [ ] COPY selected ODF from rawData → scenario folder (never edit rawData)
- [ ] Remap dates / document times to LogicalDate(s)
- [ ] Bootstrap: DT_PARTIC; if teams → DT_PARTIC_TEAMS + DT_ENTRIES
- [ ] Timeline: schedule before → during → after → medallists → medals
- [ ] Include all Schedule=S units from CC that appear in feed/pack
- [ ] Pack edge cases into other events in the same simulation
- [ ] Consistency gate: DT_SCHEDULE shape (no `<Units>`); medals ↔ RESULT winners ↔ PARTIC/ENTRIES; DT_MEDALS scope = medallists in freeze
- [ ] After-state win / situation payload present when pack requires it (not accidental NO RESULT)
- [ ] Remap check: HideEndDate still Y/N; unique filename timestamps
- [ ] DT_SCHEDULE structure gate: no invented `<Units>`; Unit/Session direct under Competition
- [ ] Fabricate ONLY missing messages; list them
- [ ] Validate fabricated with ODF verifier when possible
- [ ] Write README.md + AC.feature
- [ ] Final reply: Fabricated: … (even if empty)
```

### Gate 0 — rawData

```
rawData/{DISC}/ must exist and contain .xml ODF messages
If NOT → HARD STOP (do not fabricate an entire discipline dump)
```

### 1. Copy first

- Select messages needed for the pack cases from `rawData/{DISC}/`.
- Copy into:

  - Default: `ownScenarios/{DISC}/01_Schedule_Tile_Mixed_Day/`
  - Use `01_Schedule_Tile_Mixed_Days/` only when the sport truly needs multiple logical days (CKT-style).

- Prefer **one** simulation. Second folder only if the user asks or one day cannot hold conflicting states.

### 2. Remap dates

- Shared default **LogicalDate**: `2026-09-09` (align with other freezes).
- Extra days only when required (`2026-09-06` … etc.).
- Filename timestamps encode ingest order:

  `YYYY-MM-DD-HHMMSSmmm-DT_{TYPE}--{documentKey}.xml`

  Example: `2026-09-09-080000000-DT_PARTIC_UPDATE--ARC--------------------------------.xml`

**Remap safety (CKT lesson):**

- Never blindly replace date substrings across the whole XML — it corrupts flags such as `HideEndDate="Y"` into datetimes.
- Remap only known time fields (`StartDate`, `EndDate`, `UnitDateTime/@StartDate`, `LogicalDate`, `TimeStamp`, medal `@Date`, …).
- After remap, assert `HideEndDate` (and similar Y/N flags) are still `Y` or `N`.
- Filename prefixes must be **unique** per file (no two messages sharing the same `HHMMSSmmm` — sort order then depends on type name and breaks playback).

**DT_SCHEDULE structure (FEN lesson — mandatory):**

- ODF has **no** `<Units>` wrapper. `Unit` (and optional `Session`) sit **directly under** `Competition`.
- Never emit `<Competition><Units><Unit/>…</Units></Competition>` when fabricating / curating a schedule.
- Copy Unit element shape from `rawData/{DISC}` schedule messages.
- Before shipping: every freeze `DT_SCHEDULE[_UPDATE]` must have **zero** `<Units>` tags; first child of `Competition` is `Session` or `Unit`.

### 3. Bootstrap (required)

| Condition | Messages (order) |
|-----------|------------------|
| Always | `DT_PARTIC` / `DT_PARTIC_UPDATE` |
| Teams present (`Type=T`) | then `DT_PARTIC_TEAMS[_UPDATE]` **and** `DT_ENTRIES` |
| Then | schedule / results / current / medallists / medals |

### 4. Timeline coverage (default: one simulation through medals)

| Phase | What must appear |
|-------|------------------|
| **Before** | `DT_SCHEDULE[_UPDATE]` — units SCHEDULED / pre-draw as per pack |
| **During** | Schedule → `RUNNING` (+ `INTERRUPTED` / break if in pack) + `DT_RESULT` and/or `DT_CURRENT` per pack |
| **After / target** | `FINISHED` + results; then **`DT_MEDALLISTS` → `DT_MEDALS`** (never reverse) |

Stop-points in README so playback can pause at “before only” or “mid-live”.

### 4b. Consistency gate (mandatory before README)

Raw dumps often disagree across message types (later medallists flip, full-tournament `DT_MEDALS`, abandoned finals). **Do not ship a freeze with known mismatches.** Run this checklist and fix (prefer aligning to the RESULT of the unit in the freeze, or fabricate deliberately and list it).

#### DT_SCHEDULE XML shape

| Check | Rule |
|-------|------|
| No `<Units>` | Invented wrapper breaks BE parsers — **hard fail** if present |
| Nesting | `Competition` → (`Session`)* → `Unit`+ (or `Unit` only). Match `rawData` for the discipline |
| Curated FULL | When merging unit fragments into one message, keep the same child element names as raw ODF — do not add schema-like containers |

#### Medals ↔ results ↔ teams

| Check | Rule |
|-------|------|
| Order | `DT_MEDALLISTS` **before** `DT_MEDALS` in filename timestamps |
| `DT_MEDALS` scope | Standings must reflect **only events that have `DT_MEDALLISTS` in this freeze**. Do **not** copy a full-tournament `DT_MEDALS` that still counts women/other events you did not include — that causes “NOC has gold+bronze in table but details show only gold”. |
| Gold / silver / bronze | Each `ME_*` competitor code + org + name must exist in `DT_PARTIC_TEAMS` / `DT_PARTIC` and in `DT_ENTRIES` (teams) |
| Winner = result | For each medal unit: medallist must match `DT_RESULT` winner (`WLT=W` / `Rank=1`, and sport-specific win payload e.g. CKT `FINAL_RESULT` + `PH_TEAM` Pos=1). If raw medallists disagree with RESULT → **change medallists (and `DT_MEDALS`) to match RESULT**, unless the pack explicitly tests DQ/protest. |
| `DT_MEDALS` lines | NOC totals must equal the medallists you shipped (same G/S/B owners) |
| Schedule `Medal=` | Gold/bronze units keep `Medal="1"` / `Medal="3"` (or pack equivalent) when testing medal markers |

#### After-state “who won” text (H2H / CKT-like)

| Check | Rule |
|-------|------|
| Situation string | If the pack expects `finalResultDescription` / match-situation copy, OFFICIAL `DT_RESULT` must carry a real win (or documented exceptional) code — e.g. CKT `WON_RUN` / `WON_WKT` / `WON_SO*` **with** `PH_TEAM` + `SCORE` when the template needs them. |
| Accidental No Result | Do **not** leave `NO RESULT` / empty win payload on a medal final unless the freeze **intentionally** tests abandoned/No Result. |
| WLT / Rank | After fabricating a win string, set `WLT` / `Rank` consistently (winner W/1, loser L/2). |

#### Cross-links (teams)

| Check | Rule |
|-------|------|
| Same team id | `SCHEDULE` StartList ↔ `DT_RESULT` Home/Away/Competitors ↔ `DT_MEDALLISTS` Competitor ↔ `DT_ENTRIES` Entry ↔ `DT_PARTIC_TEAMS` |
| Composition | Podium athlete codes ⊆ entry/particip codes for that team (minor XI subset OK; unknown codes = fail) |

Document any intentional exception in README (**Fabricated** + why).

### 5. Schedule=S

If Common Codes (or the pack) lists units with `Schedule=S`, they **must** appear in schedule versions in the freeze so BE/FE can test:

- default list vs By Event visibility
- grouping / roll-up to phase (when grouping CSV or pack says so)

`S` is visibility/grouping — not a redirect change (unless the pack documents an RSC override).

### 6. Edge cases

Pack into **other events of the same discipline** in the same simulation (IRM, TBD/PreviousUnit, NOCOMP, W/O, live progress, medals on one event + live on another, …).  
Avoid a second scenario folder unless necessary.

### 7. Fabricate only when missing

After copy + remap:

- Fabricate only messages the playback still needs (e.g. RESULT / MEDALLISTS when raw dump is schedule-only).
- Keep competitor codes / team ids consistent with copied PARTIC.
- **Announce every fabricated file** to the user.
- Run ODF verifier on fabricated XML when practical; note results in README or the final reply.

### 8. Artefacts

#### `ownScenarios/{DISC}/README.md`

Must include:

- LogicalDate(s), Now after full ingest, folder name, ingest = filename order
- CC `@Unit` counts: **Y / N / S**
- Playback table (step, file prefix, message, now, what to check)
- Day / walkthrough map (RSC, status, expect)
- Redirects (CIS / WMR) per pack
- Sources in rawData (mapping table)
- **Fabricated files** section (list paths or `None`)
- Link to `AC.feature`

#### `ownScenarios/{DISC}/AC.feature`

Gherkin scenarios for key stop-points (before / mid / full ingest), referencing the scenario folder and LogicalDate — follow CRD/SQU style.

---

## Final reply (mandatory)

Always end with:

```
Fabricated:
- <path> — reason
- … or (none)
```

Also summarize: scenario path, LogicalDate, Schedule S units included, playback step count, verifier results on fabricated files.

---

## Definition of done

- [ ] Gate 0 passed (rawData used)
- [ ] ODFs copied then remapped (rawData untouched); HideEndDate/Y-N flags intact; unique timestamps
- [ ] Every `DT_SCHEDULE[_UPDATE]` has no `<Units>`; Unit/Session direct under Competition
- [ ] PARTIC (+ TEAMS + ENTRIES if teams)
- [ ] Before / during / after through MEDALLISTS → MEDALS
- [ ] **Consistency gate 4b passed** (schedule shape + medals ↔ results ↔ teams; win-situation payload if required)
- [ ] Schedule=S units included when CC has them (0×S is OK — say so in README)
- [ ] README + AC.feature written
- [ ] Fabricated list printed (even if empty)
