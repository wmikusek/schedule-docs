# CKT Schedule Tile — Developer Requirements

**Scope:** Cricket (CKT) only.  
**Shared rules:** [schedule-tile-common.md](../common/schedule-tile-common.md)  
**FE component extension (baseline Figma → CKT slots):** [schedule-tile-fe-component.md](./schedule-tile-fe-component.md)  
**Editions:** OSRP LA28 R4 V1.0 · ORIS LA28 R9 V1.1 · ODF `OG2028-CKT-0.3` · SC/CC `OG2028` v1.5.0  
**RawData:** `rawData/CKT` (sim / SignalR captures with `DT_SCHEDULE_UPDATE`, `DT_RESULT`, …)  
**API:** [Schedule](https://dgplatform.atlassian.net/wiki/spaces/SCDLA/pages/3120988164/Schedule) — includes CKT-specific `extendedResultInfo.finalResultDescription`.

---

## 1. CKT vs common

| Topic | CKT behaviour |
|-------|----------------|
| Competitors | Teams (`Type=T`) |
| Live progress | Current **innings** (+ over) → `liveCurrentProgress` (§3.2) |
| Score | Runs/wickets `nnn/n` (+ overs); **`YTB` only in IN1** for the side yet to bat — **never** before start / never both sides |
| Toss | Raw `competitors[].toss` = `BAT` \| `FIELD` **only during IN1** on the toss winner (§3.4) |
| Super Over | Separate `soResult` on each competitor; first SO → `periodCode: "SO"`, later → `"SO2"`… (§3.4b) |
| After text | Interpolated sentence from `UI/FINAL_RESULT` → `extendedResultInfo.finalResultDescription` (§3.3) |
| `resultDecision` | **Not primary** — use FINAL_RESULT / ResultDesc instead of FBL-style RES_CODE |
| Placeholders | `TBD`, `ROUND2_R1`…`R4`, `NOCOMP` (`SC@CompetitorPlace`) |
| Group label | Group stage: event name like “Women's Group A” |
| Grouping | N/A (OSRP) |
| Interrupt outcomes | May finish as **No Result** / **Abandoned** (ORIS) |
| Ticket | [DRES-33389](https://dgplatform.atlassian.net/jira/browse/DRES-33389) (schedules enrichment; contract below supersedes earlier “toss only pre-start” draft) |

---

## 2. Situations (OSRP §1.2 + ORIS §3.1.6)

### 2.1 Before

- Date, start time, discipline / event / phase, match number.
- Group stage: show “Event name Group x”.
- Opponents confirmed: NOC + team name.
- Not confirmed: **`TBD`** or **Stage 2 Rank n** (codes → SC Description, §3.5).
- No “Scheduled” badge; medal marker when applicable.
- **No scores, no `YTB`, no `toss`, no `soResult`** — even after the coin toss in ODF (`START_LIST`). Do not render two empty / YTB score cells.

### 2.2 During

- Live highlight.
- **1st innings (`PERIOD=IN1`):**
  - One side: live score `nnn/n (overs)`.
  - Other side: **`YTB`** (Yet to bat).
  - Toss winner exposes raw `toss: "BAT" | "FIELD"` (§3.4). FE may compose Match info *“First innings: {Team} elected to bat/field”* from that competitor’s `toss` + team name.
  - Consistency: `BAT` → toss winner is batting (has the score); `FIELD` → toss winner has `YTB` (other side batting).
- **2nd innings (`PERIOD=IN2`):** both sides show innings scores; **no `toss`**, **no `YTB`**.
- **Super Over:** keep main innings in `result.result`; SO line via `soResult` (§3.4b). First SO label = `SO` (not `SO1`); second+ = `SO2`, `SO3`, …
- Optional progress: current innings (and over) via `liveCurrentProgress`.

### 2.3 After

- Winner indicated (`WLT`).
- Scores for both sides (incl. Super Over line when played — same `soResult` rules, latest SO only).
- **Match situation** sentence, e.g.  
  `India beat Pakistan by 9 wickets` / `… by 44 runs` / `… in Super Over` / `Match Abandoned` / `No Result`.
- Medal symbol on medal matches.
- No `toss`.

### 2.4 Score formats (OSRP / schedules API)

Regular (IN2 / after without SO):

```
Team Name        nnn/n (n.n or nn)
Team Name        nnn/n (n.n or nn)
Match situation text
```

First Super Over (`soResult.periodCode = "SO"`) — FE sketch (omit SO line when `score` is `YTB`):

```
Team Name        nnn/n (…)
                  SO 7/0 (1)
Team Name        nnn/n (…)
```

Second+ Super Over (`periodCode = "SO2"` …) — same rule; BE exposes **latest SO only**:

```
Team Name        nnn/n (…)
                  SO2 7/0 (1)
Team Name        nnn/n (…)
```

BE may still send `soResult.score = "YTB"` for the side yet to face that SO — **FE does not render** an SO line for that row. FE may strip a trailing `1` if BE still sends `SO1` — confirm against scoreboard whether BE normalises first SO to `"SO"` (§3.4b open point).

### 2.5 Exceptional (ORIS)

Same schedule statuses as common (Cricket IF may use different words; **OC codes** apply). Extra:

| Situation | Tile / data impact |
|-----------|-------------------|
| Interrupted → cannot complete | Often **No Result** (not only postpone) |
| Abandoned (no play) | Result **Match Abandoned**; group points rules per ORIS |
| DLS revised target / win | Situation text may include DLS (OSRP); feed via ResultDesc / extensions when provided |
| Refuse to play | Default win sentence (`BYDEFAULT`) |
| DQB | Team/player IRM path |

---

## 3. Backend — CKT

Implements [common §3](../common/schedule-tile-common.md) plus below.

### 3.1 ODF messages

| Message | CKT tile role |
|---------|----------------|
| `DT_SCHEDULE[_UPDATE]` | Meta, status, teams / place codes |
| `DT_RESULT` | LIVE scores, `YTB`, `UI/PERIOD` (+ OVER), `ER/TOSS`, `UI/BATTING`, `UI/FINAL_RESULT`, WLT |
| `DT_CURRENT` | If present — live merge (prefer with RESULT) |
| `DT_PARTIC_TEAMS` | Team names for `#ORG*` interpolation |

### 3.2 `liveCurrentProgress` (innings / over)

```
DT_RESULT  ExtendedInfo[@Type='UI'][@Code='PERIOD']/@Value     e.g. IN1, IN2, SO1IN1
           Extension[@Code='OVER']/@Value                      e.g. O11  (optional)
        │
        ▼
SC@Period Description   "1st Innings" / "2nd Innings" / "Over 11" / "Super Over" …
        │
        ▼
liveCurrentProgress.code = PERIOD value (e.g. "IN2")
liveCurrentProgress.name = SC Description (e.g. "2nd Innings")
# optional: expose over as name suffix or separate field if product needs "(O11)"
```

| When | API |
|------|-----|
| Match live / intermediate | Set from latest PERIOD (keep previous innings code during scheduled break — ODF) |
| Finished / before start | `null` |

RawData example: `PERIOD Value="IN2"` + `Extension Code="OVER" Value="O11"`.

### 3.3 `extendedResultInfo.finalResultDescription` (Confluence — CKT)

Confluence: shared ExtendedInfo `Code=FINAL_RESULT`; **replace variables** in the CC/SC string with team names and score.

```
DT_RESULT  ExtendedInfo[@Type='UI'][@Code='FINAL_RESULT']/@Value     e.g. WON_WKT
           Extension PH_TEAM Pos=1 → winner team id
           Extension PH_TEAM Pos=2 → loser team id
           Extension SCORE → margin (runs/wickets) when applicable
        │
        ▼
SC@ResultDesc Description template
  e.g. "#ORG1 beat #ORG2 by #SCR wickets"
        │
        ▼
Replace:
  #ORG1 ← team name (or NOC) for PH_TEAM Pos=1
  #ORG2 ← team name for Pos=2
  #SCR  ← Extension SCORE
        │
        ▼
API  extendedResultInfo.finalResultDescription
     = "India beat Pakistan by 9 wickets"
```

#### `SC@ResultDesc` (CKT) — templates

| Code | Template (Description) |
|------|------------------------|
| `WON_WKT` | `#ORG1 beat #ORG2 by #SCR wickets` |
| `WON_RUN` | `#ORG1 beat #ORG2 by #SCR runs` |
| `WON_SO` | `Match tied, #ORG1 beat #ORG2 in Super Over` |
| `WON_SO2`…`WON_SO5` | `… in second/third/… Super Over` |
| `TIED` | `Match tied` |
| `ABANDONED` | `#ORG1 vs #ORG2 - Match Abandoned` |
| `NO_RESULT` | `#ORG1 vs #ORG2 - No Result` |
| `BYDEFAULT` | `#ORG1 beat #ORG2 (by default)` |

#### Worked example (rawData)

`FINAL_RESULT Value="WON_WKT"`  
`PH_TEAM Pos=1` = India team, `Pos=2` = Pakistan, `SCORE=9`  
→ **`India beat Pakistan by 9 wickets`**.

`WON_RUN` + `SCORE=44` → **`Australia beat New Zealand by 44 runs`**.  
`WON_SO2` (no SCORE in sample) → use template without `#SCR`.

Populate from **UNOFFICIAL** onward (ODF); clear or omit before match end.

### 3.4 Schedules competitor enrichment — score / YTB / toss

CKT-only fields on schedules / schedulesPerDay competitors (see also [DRES-33389](https://dgplatform.atlassian.net/jira/browse/DRES-33389)).

#### `result.result` (overs)

1. Base = `unit_competitor_results.result` / ODF `@Result` (or ResultMark).
2. If value is a numeric score and batting extended stat `BATTING`/`NO` exists for a **non-SO** period → append overs: `148/9 (10.1)`.
3. Pass through all-out forms (`148/10`) — do not strip `/10`.
4. Non-CKT: unchanged.

#### `YTB` gate

| Phase | `result.result` |
|-------|-----------------|
| Before start (SCHEDULED / START_LIST / no LIVE innings) | **Omit** scores — do **not** emit `YTB` on either side |
| LIVE `PERIOD=IN1` | Batting side = score (+ overs); other side = `YTB` |
| LIVE `PERIOD=IN2` / finished (no incomplete chase edge) | Both sides = innings scores; **no `YTB`** |
| Super Over (one side yet to face SO) | Main innings scores stay in `result.result`; SO-side `YTB` goes in **`soResult.score`**, not as a fake second innings YTB |

Never show two `YTB` cells. Before the match there is simply **no** result payload.

#### `toss` gate (`BAT` \| `FIELD`)

ODF: `ER/TOSS` only on the toss-winning `Result` (`SC@Toss`).

| When | API |
|------|-----|
| Before start | **`toss` omitted** (even if ODF already has TOSS) |
| LIVE + `UI/PERIOD = IN1` | Emit `toss` on the toss-winning competitor only |
| LIVE + `PERIOD = IN2` / SO* / finished | **`toss` omitted** |

Do **not** return a BE-translated elected sentence for schedules — FE builds copy from `toss` + that competitor’s `teamNames` / organisation when needed.

**IN1 consistency with decision:**

| `toss` | Toss-winner `result.result` | Other side |
|--------|----------------------------|------------|
| `BAT` | Score (they bat first) | `YTB` |
| `FIELD` | `YTB` (they field first) | Score |

```
DT_RESULT  Result[…]/ExtendedResults/ExtendedResult[@Type='ER'][@Code='TOSS']
           @Value = BAT | FIELD   (only on toss winner)
           Gate to expose on schedules API: PERIOD == IN1
```

#### `SC@Toss` (CKT)

| Code | Description |
|------|-------------|
| `BAT` | Won the toss and elected to bat |
| `FIELD` | Won the toss and elected to field |

**Invalid:** free text (`"BOWL"`, `"bat"`, …). Only `BAT` / `FIELD`. Map invalid `BOWL` → `FIELD` if still seen in feeds.

#### Example fragments (schedules)

**Pre-start (after toss in ODF — still no scores / toss in API):**

```json
{
  "competitors": [
    { "code": "...IND01", "teamNames": { "name": "India" } },
    { "code": "...AUS01", "teamNames": { "name": "Australia" } }
  ]
}
```

**LIVE IN1 — elected to bat:**

```json
{
  "competitors": [
    { "code": "...IND01", "toss": "BAT", "result": { "result": "148/9 (10.1)" } },
    { "code": "...AUS01", "result": { "result": "YTB" } }
  ]
}
```

**LIVE IN1 — elected to field:**

```json
{
  "competitors": [
    { "code": "...IND01", "result": { "result": "148/9 (10.1)" } },
    { "code": "...AUS01", "toss": "FIELD", "result": { "result": "YTB" } }
  ]
}
```

**LIVE IN2 — no toss:**

```json
{
  "competitors": [
    { "code": "...IND01", "result": { "result": "148/9 (20.0)" } },
    { "code": "...AUS01", "result": { "result": "123/8 (18.2)" } }
  ]
}
```

### 3.4b `soResult` — Super Over (latest only)

Separate field so FE can render SO on its **own line** (not concatenated into `result.result`).

| Rule | Behaviour |
|------|-----------|
| Source | Last `Periods/Period` whose `Code` starts with `SO` (`SO1IN1`, `SO1IN2`, `SO2IN1`, …) |
| Scope | Same `periodCode` on **both** competitors when an SO is active |
| Score | That period’s Home/Away score for the competitor; may be `YTB`; append SO overs from `BATTING`/`NO` with `pos` = that period when present |
| Latest only | If SO1 tied and match is in SO2, expose **SO2** scores — do **not** surface SO1 in `soResult` even though ODF still has SO1 rows |
| Absent | No SO period → omit `soResult` |
| FE display | Show SO second line **only when `score` is not `YTB`** (e.g. `SO 7/0 (1)`). YTB in `soResult` → no SO line on that row. |

#### `periodCode` normalisation

| Super Over series | API `soResult.periodCode` |
|-------------------|---------------------------|
| First (`SO1…` in ODF) | **`SO`** (no `1`) |
| Second (`SO2…`) | **`SO2`** |
| Third+ | **`SO3`** … |

**Open product / scoreboard check:** if scheduleItems / scoreboard already emit `SO1` for the first Super Over, either BE schedules override to `"SO"` for parity with the tile, **or** FE strips the trailing `1` when rendering. Prefer BE `"SO"` once confirmed.

#### Examples

**First Super Over:**

```json
{
  "competitors": [
    {
      "result": { "result": "148/9 (20.0)" },
      "soResult": { "periodCode": "SO", "score": "12/0 (1.4)" }
    },
    {
      "result": { "result": "146/9 (20.0)" },
      "soResult": { "periodCode": "SO", "score": "YTB" }
    }
  ]
}
```

**Second (or later) Super Over:**

```json
{
  "competitors": [
    {
      "result": { "result": "148/9 (20.0)" },
      "soResult": { "periodCode": "SO2", "score": "12/0 (1.4)" }
    },
    {
      "result": { "result": "146/9 (20.0)" },
      "soResult": { "periodCode": "SO2", "score": "YTB" }
    }
  ]
}
```

### 3.5 Placeholder opponents

`SC@CompetitorPlace` (CKT):

| Code | Description → `placeholderOpponents[].name` |
|------|-----------------------------------------------|
| `TBD` | To be determined |
| `ROUND2_R1`…`ROUND2_R4` | Second Round Rank 1…4 (OSRP “Stage 2 Rank n”) |
| `NOCOMP` | No competitor |

Prefer **Description as `name`** (same pattern as FBL). RawData schedule dump in this repo had little TBD; codes are authoritative for medal / stage-2 tiles.

### 3.6 `resultDecision` / RES_CODE

Not required for CKT schedule tile UX. Match outcome sentence is **`finalResultDescription`**. Do not conflate with FBL AET/PSO.

### 3.7 `startText`

Follow [common §3.4](../common/schedule-tile-common.md) when `HideStartDate=Y`.

### 3.8 CKT backend checklist

Shared plus:

- [ ] Before start: no `result` / no `YTB` / no `toss` / no `soResult`  
- [ ] `result.result` = runs/wickets + overs (`BATTING`/`NO`); pass through `/10`  
- [ ] `YTB` only for the non-batting side in **IN1** (never both sides)  
- [ ] `toss` raw `BAT`\|`FIELD` only when `PERIOD=IN1`; omit in IN2 / SO / after / before  
- [ ] `soResult` = latest SO only; `periodCode` `SO` then `SO2`… (§3.4b)  
- [ ] `liveCurrentProgress` from `UI/PERIOD` (+ optional OVER)  
- [ ] `finalResultDescription` interpolated from `SC@ResultDesc` + PH_TEAM + SCORE  
- [ ] Placeholders `TBD` / `ROUND2_R*` via CompetitorPlace Description  
- [ ] Abandoned / No Result / default templates supported  

---

## 4. Frontend — CKT

Shared layout plus (detail: [schedule-tile-fe-component.md](./schedule-tile-fe-component.md)):

| Phase | FE |
|-------|-----|
| Before | Teams / placeholders only; **empty score column** (ignore any residual YTB) |
| During IN1 | Score + `YTB`; optional Match info from `competitors[].toss` + team name; `liveCurrentProgress` |
| During IN2 | Both scores; **hide** toss / elected line |
| During / after SO | Main score from `result.result`; second line from `soResult` **only when score ≠ `YTB`** (e.g. `SO 7/0 (1)`); latest SO only |
| After | Both scores (+ SO if scored); winner; **`finalResultDescription`** as match-situation line; medal icon |

**Design:** standard H2H schedule card — extend score cell + Match info; no cricket-only layout fork.

Do not invent the **after** situation sentence on FE — render `extendedResultInfo.finalResultDescription` from BE.  
During IN1 elected copy is composed on FE from raw `toss` + team name — **two i18n strings**: `First innings: {Team} elected to bat` / `… elected to field`.

Baseline Figma already has a hidden **Match info** strip — enable it for CKT situation / elected copy; extend the **score cell** beyond a plain integer.

### 4.1 Card click redirects

Same phase rule as [common §4.3](../common/schedule-tile-common.md) — **href does not change** for before / during / after. **WMR path shape differs** from `/results/unit/{rsc}` (compact LA28 tree).

| Surface | On card click → |
|---------|-----------------|
| **CIS** (pool example `CKTMTEAM--------------GPA-000100--`) | `/en/OG2028/CKT/M/TEAM--------------/GPA-/000100--/results` |
| **WMR** (group example `CKTMT20---------------GP1A000100--`) | `/en/los-angeles-2028/results/ckt/mck/gp1a/000100--` |
| **WMR** (women / GP1B `CKTWT20---------------GP1B000200--`) | `/en/los-angeles-2028/results/ckt/wck/gp1b/000200--` |

WMR builder: `resolveCktGroupStandingsMatchHref` — maps gender → `mck`/`wck`, phase → `gp1a`/`gp1b`/`gp2`/`semifinal`/`final`, unit tail → `000100--`. Unknown phase → no link.

---

## 5. API gaps (CKT view)

| Field | Status |
|-------|--------|
| `extendedResultInfo.finalResultDescription` | **On Confluence** — implement §3.3 |
| `liveCurrentProgress` | On Confluence — use for innings (§3.2), not only FBL |
| `competitors[].result.result` overs | CKT enrichment — §3.4 |
| `competitors[].toss` | CKT — raw `BAT`\|`FIELD`, **IN1 only** — §3.4 |
| `competitors[].soResult` | CKT — latest SO; `SO` / `SO2`… — §3.4b |
| `startText` | Still missing if HideStartDate used |
| `resultDecision` | Not needed for CKT |
| First SO label `SO` vs `SO1` | Confirm with scoreboard whether BE normalises or FE strips `1` |

### Open product questions

1. Scoreboard / scheduleItems: does first Super Over already use `SO` or `SO1`? Align schedules `soResult.periodCode` with that surface (prefer `"SO"`).

---

## 6. CKT cheat sheet

```
BEFORE:  DT_SCHEDULE  →  teams | TBD / ROUND2_Rn → placeholders
         (no result / YTB / toss / soResult)

DURING IN1:  DT_RESULT → score + YTB; toss on winner (BAT|FIELD); PERIOD → liveCurrentProgress
DURING IN2:  DT_RESULT → both scores; no toss / no YTB
DURING SO:   result.result = innings; soResult = latest SO (periodCode SO | SO2…)

AFTER:   DT_RESULT → scores (+ soResult if any), WLT, FINAL_RESULT → finalResultDescription
```