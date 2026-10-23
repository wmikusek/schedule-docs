# CKT — Schedule tile freezes

**Editions:** ODF `OG2028-CKT-0.3` · CC/SC `OG2028` v1.6.0 · pack [`docs/CKT/schedule-tile-requirements.md`](../../docs/CKT/schedule-tile-requirements.md)  
**Raw:** `rawData/CKT` (OG2028-ITL) — never edited.

| Folder | Role |
|--------|------|
| [`02_Schedule_Tile_Full_Tournament`](02_Schedule_Tile_Full_Tournament) | **Full tournament dump** — all precomp + every `DT_SCHEDULE_UPDATE` + final results for all matches (incl. Super Overs) |
| [`01_Schedule_Tile_Mixed_Days`](01_Schedule_Tile_Mixed_Days) | Curated multi-day micro-cases for [DRES-33389](https://dgplatform.atlassian.net/jira/browse/DRES-33389) (toss / YTB / `soResult` mid-states) |

**Acceptance:** [AC.feature](AC.feature)

---

## `02_Schedule_Tile_Full_Tournament` (primary large freeze)

**LogicalDays (content):** `2026-09-06` … `2026-09-10` (mapped from raw `2026-07-20` … `2026-07-24`)  
**Filename timestamps:** sequential ingest clock starting `2026-09-06-080000000` (order = playback order, not wall-clock of the match)  
**Now (after full ingest):** `2026-09-10T16:00:00+02:00`  
**Files:** 267 XML

### What is included

| Block | Count / notes |
|-------|----------------|
| Bootstrap | `DT_PARTIC_UPDATE` → `DT_PARTIC_TEAMS_UPDATE` → `DT_ENTRIES` ×2 (M/W) |
| Pre-competition | CONFIG, POOL_STANDING, schedule shell updates from `01_Pre-Competition` |
| Mid-tournament bootstrap | PARTIC / TEAMS / ENTRIES / POOL_STANDING from `After Women's Gold Medal Match` |
| **All** `DT_SCHEDULE_UPDATE` | **190** messages from every match folder + precomp + after-women |
| `DT_RESULT` | **57** — up to 3 trailing OFFICIAL per match + Super Over LIVE/INTERMEDIATE samples |
| Medals | Women `DT_MEDALLISTS` → `DT_MEDALS` (after W gold); Men `DT_MEDALLISTS` → full `DT_MEDALS` (W+M) → `DT_MEDALLISTS_DISCIPLINE` |

**Not included:** PDF, PING, LOCAL_ON, ALERT, COMMUNICATION; full LIVE ball-by-ball RESULT dumps; M03 (`GP1A000200`) has **no** `DT_RESULT` in raw (schedule-only).

### CC `@Unit` (OG2028 v1.6.0)

| Schedule | Count |
|----------|-------|
| **Y** | All competition matches + MEET + VICT (+ TMRY in CC, usually absent from feed) |
| **N** | Phases + venue `OTHRFRG` |
| **S** | **0** |

OLY grouping: no CKT row in `olympic-grouping-rules.csv` → **no `groupId`**.

### Match RESULT coverage (27 units with results)

| Event | Units | Notable FINAL_RESULT |
|-------|-------|----------------------|
| Women GP1 | A000100…300, B000100…300 | W01 `WON_WKT`, W02 `WON_RUN`, **W03 `WON_SO`**, … |
| Women GP2 | 000100…000600 | all OFFICIAL (incl. W12) |
| Women FNL | Bronze + Gold | `WON_WKT` |
| Men GP1 | A000100, A000300, B000100…300 | M01 **DLS**, M04 `BYDEFAULT`, M05 `ABANDONED`, … (**no M03 RESULT**) |
| Men GP2 | 000100…000600 | **M12 five Super Overs → `TIED`** |
| Men FNL | Bronze + Gold | Bronze `WON_WKT` (PAK); Gold **`WON_RUN`** (see Fabricated) |

### Super Over playback (stop after prefix)

| File prefix | Unit | Expect |
|-------------|------|--------|
| `080038` / `080041` | W `GP1A000200` | LIVE/INT **SO1IN1** / **SO1IN2** |
| `080044` / `080045` | W `GP1A000200` | OFFICIAL **`WON_SO`** |
| `080335` … `080401` | M `GP2-000600` | SO1…SO5 innings samples (`soResult.periodCode` = latest only: `SO`…`SO5`) |
| `080403` | M `GP2-000600` | OFFICIAL **`TIED`** · `soResult.periodCode=SO5` |

### Medals (end of ingest)

| Message | Content |
|---------|---------|
| `DT_MEDALLISTS` W | IND gold, AUS silver, NZL bronze |
| `DT_MEDALS` (mid) | Women-only standings (`FinishedEvents=1`) |
| `DT_MEDALLISTS` M | NZL gold, RSA silver, **PAK** bronze |
| `DT_MEDALS` (final) | Full table W+M (`FinishedEvents=2`) — PAK men’s bronze (aligned to bronze RESULT) |
| `DT_MEDALLISTS_DISCIPLINE` | Discipline roll-up |

Order always **medallists → medals** within each gender block; final men medals last.

### Remap / gates

- July → September date map on `LogicalDate` / `StartDate` / `EndDate` / `TimeStamp` / compact stamps only (not blanket string replace).
- `HideEndDate` / `HideStartDate` / `HideUnitNum` remain `Y`/`N`.
- No `<Units>` wrapper in any schedule message.
- `ER/TOSS` `BOWL` → **`FIELD`** (SC@Toss).

### Fabricated

| File (prefix) | Reason |
|---------------|--------|
| `…-DT_RESULT--CKTMT20---------------GP2-000600---` (`080403`) | OFFICIAL body from `01` freeze with `FINAL_RESULT=TIED` (raw had `MATCH TIED` / later corrupt `tu ss`) |
| `…-DT_RESULT--CKTMT20---------------FNL-000100---` (`080423`) | Gold OFFICIAL **`WON_RUN`** from `01` freeze (raw ended `NO RESULT` / rain) — preceding UNOFFICIAL `NO RESULT` kept |
| `…-DT_MEDALLISTS--CKTMT20…` (`080424`) | Men podium NZL/RSA/**PAK** from `01` (raw bronze later flipped to AUS) |
| `…-DT_MEDALS--CKT…` (`080425`) | Full W+M standings from raw men-gold medals, **AUS M-bronze → PAK**, `LastEvent=CKTMT20` |

### Sources in rawData

| Freeze piece | rawData |
|--------------|---------|
| Precomp bootstrap + schedule shells | `01_Pre-Competition` |
| All schedule updates | every `**/…DT_SCHEDULE*` under `rawData/CKT` |
| Match OFFICIAL (+ SO samples) | `02_`…`07_` match folders |
| After-women PARTIC/ENTRIES/pools/schedule | `After Women's Gold Medal Match` |
| Women medallists / mid medals | `04_Medal Matches Women` |
| Curated M12 TIED / M gold / men medallists | copied from `01_Schedule_Tile_Mixed_Days` then date-aligned |

---

## `01_Schedule_Tile_Mixed_Days` (curated DRES-33389)

Smaller 4-day freeze focused on API contract: overs, `YTB` only in IN1, `toss` only in IN1, `soResult` latest SO only. See playback table in git history / AC.feature scenarios tagged with `01_Schedule_Tile_Mixed_Days`.

**LogicalDays:** `2026-09-06` … `2026-09-09` · **Now:** `2026-09-09T15:15:00+02:00`

---

## Redirects (both freezes)

| Surface | Example |
|---------|---------|
| CIS | `/en/OG2028/CKT/M/T20---------------/FNL-/000100--/results` |
| WMR | `/en/los-angeles-2028/results/ckt/mck/final/000100--` |

Href does not change by before / during / after.
