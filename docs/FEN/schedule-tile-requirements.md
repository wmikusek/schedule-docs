# FEN Schedule Tile — Developer Requirements

**Scope:** Fencing (FEN) only.  
**Shared rules:** [schedule-tile-common.md](../common/schedule-tile-common.md)  
**Editions:** OSRP LA28 R4 V1.0 (`OG2028_FEN_Live_Screens_R4_V1.0_20260130`) · ORIS LA28 R9 V1.1 (`OG2028_FEN_ORIS_R9_V1.1_20260206`) · ODF `OG2028-FEN-0.2` (DD; rawData feed attr also shows `OG2028-FEN-0.3`) · SC/CC `OG2028` v1.6.0  
**RawData:** [`rawData/FEN`](../../rawData/FEN) (ITL OG2028-style days 01–09 + pre-competition).  
**Freeze:** [`ownScenarios/FEN`](../../ownScenarios/FEN) (`01_Schedule_Tile_Mixed_Day`).

---

## 1. FEN vs common

| Topic | FEN behaviour |
|-------|----------------|
| Tile type | **H2H bout/match** — individuals `Type=A` and teams `Type=T` |
| Results on tile | **Hit score** (`POINTS`) during and after; updated after each hit (OSRP §1.4) |
| Winner | `@WLT` — pass through `SC@WLT` including **`V(T)`** (Victory by toss) |
| `resultDecision` | **Not used** — V(T) is a **per-competitor WLT code**, not FBL-style unit `UI/RES_CODE` |
| `liveCurrentProgress` | **Out of scope for schedule tile** — OSRP §1.4 has no period chrome (period belongs on Start List / Results). Do not map `UI/PERIOD` here |
| Opponents on tile | Only what OSRP §1 requires: **names when known** (first phase after draw; later phases when resolved). No invented schedule placeholders (`Winner n`, dual `TBD`, etc.) |
| Grouping | Out of discipline-pack scope — runtime CSV only ([`olympic-grouping-rules.csv`](../grouping/olympic-grouping-rules.csv): `FEN` → `{Session}_{PhaseRSC}`) |
| Schedule flag `S` | **None** in CC@Unit (0 units) |
| Inclusion | `Schedule=Y` units per common (incl. DRAW / meetings / trainings rules in common). **VICTMEDAL** CIS only / WMR omit remains common. `Schedule=N` session/OTHR containers are not competition tiles |

---

## 2. Situations (OSRP §1 + ORIS §3.1.6)

### 2.1 Before the Draw

- Date, start time, discipline, **event + phase**.
- Status / medal indicators (not “Scheduled”).
- No opponents.

### 2.2 After the Draw

- Start time of each phase in the main component; start time of each unit upon expansion.
- After the draw, **only the opponents of the first phase are known** and should be displayed on those schedule items.
- Later phases: as soon as opponents are known, add **names** (OSRP: “names or bracket position” — do **not** invent CIS placeholder copy beyond what the feed/product already expose as real competitor data).

### 2.3 During / after

- Live highlight when `RUNNING`.
- Score on both sides; update after each hit.
- After bout/match: indicate winner via `WLT`.
- **Regular:**

```
Print Name/Team Name                  n
Print Name/Team Name                  n
```

- **Victory by Toss:**

```
Print Name/Team Name        V(T)  n
Print Name/Team Name                  n
```

- **IRM:**

```
Print Name/Team Name                  n
Print Name/Team Name     IRM     n
```

- Medal bouts/matches: medal symbol on the winner (`medalFlag` / result medal).

### 2.4 Exceptional (ORIS §3.1.6)

Schedule statuses: Delayed / Rescheduled / Postponed / Interrupted / Cancelled (bout or match / session / phase). Interrupted bout/match that cannot finish in-session → postpone / reschedule / cancel; incomplete bout/match **restarts from the beginning** when resumed (ORIS).

IRMs on tile (`SC@IRM`): `DNS`, `DNF`, `EXC`, `DQB`, `MED`. Tile shows competitor `@IRM` when present on `DT_RESULT`.

Provisional results (`PROVISIONAL`) possible — after `FINISHED`, badge follows `resultStatus`.

---

## 3. Backend — FEN

Implements [common §3](../common/schedule-tile-common.md) plus the following.

### 3.1 ODF sources

| Message | FEN use on tile |
|---------|-----------------|
| `DT_SCHEDULE[_UPDATE]` | Meta, status, medal, start list when opponents known, `HideStartDate` / `StartText` |
| `DT_RESULT` | LIVE → UNOFFICIAL → OFFICIAL: `POINTS` score, `@WLT` (incl. `V(T)`), `@IRM`, `ResultStatus` |
| `DT_CURRENT` | If sent — merge live score / WLT / IRM only for the tile |
| `DT_PARTIC` / `DT_PARTIC_TEAMS` | Athlete print names / team names |

Do **not** require `DT_MEDALLISTS` for H2H medal icons on the bout/match tile — use unit `Medal` + winner (`WLT`) per common H2H pattern.

### 3.2 Inclusion (Y + S)

| Rule | Behaviour |
|------|-----------|
| `Schedule=Y` | Emit per [common §3.1](../common/schedule-tile-common.md) — **no FEN-specific omit** of DRAW or other Y units beyond that shared filter |
| `Schedule=S` | **None** in OG2028 CC@Unit for FEN |
| `Schedule=N` | Session / OTHR containers (19 codes) — not competition tiles |
| `VICTMEDAL---` | Common: **CIS only**; BE omits from WMR |

### 3.3 Scores / WLT / IRM

| API | ODF |
|-----|-----|
| `competitors[].result.result` | `Result/@Result` (hit total; `ResultType=POINTS`) |
| `resultType` | `POINTS` (typical) |
| `winLoseTie` | `Result/@WLT` → **pass through `SC@WLT`**: `W`, `L`, `T`, **`V(T)`** |
| `invalidResultMark` | `Result/@IRM` → `DNS` / `DNF` / `EXC` / `DQB` / `MED` |

`SC@WLT` (FEN):

| Code | Description |
|------|-------------|
| `W` | Victory |
| `L` | Defeat |
| `T` | Tie |
| `V(T)` | Victory by toss |

**DD prose vs codes:** Data Dictionary text for `@WLT` often says only W/L; **authoritative values are `SC@WLT`**, which includes `V(T)`. RawData confirms `WLT="V(T)"` on the winner when the bout/match is decided by toss.

### 3.4 `V(T)` — Victory by Toss (schedule tile)

OSRP §1.4 requires the **`V(T)`** marker on the winner’s row (not a separate unit-level decision strip).

```
DT_RESULT  Competition/Result/@WLT = "V(T)"   (winner)
           Competition/Result/@WLT = "L"      (loser)
           both sides typically same @Result (e.g. 14-14)
        │
        ▼
API  competitors[winner].result.winLoseTie = "V(T)"
     competitors[loser].result.winLoseTie  = "L"
        │
        ▼
FE   show "V(T)" beside winner name + score (OSRP Victory by Toss layout)
```

#### RawData evidence

| Unit | File (under `rawData/FEN/…`) | Notes |
|------|------------------------------|--------|
| `FENMSABRE-------------R32-000500--` | `02_DAY01_…/…122613957-DT_RESULT-…` | Individual; `WLT="V(T)"` / `L`; scores `14`/`14`; `UI/OVERTIME=Y`; `UI/PERIOD=E-FS` |
| `FENWTEAMEPEE----------QFNL000200--` | `05_DAY04_…/…145527632-DT_RESULT-…` | Team; `WLT="V(T)"` on Pos 2; scores `36`/`36` |

Only **5** `DT_RESULT` messages in this dump carry `WLT="V(T)"` (same two units across versions).

#### Do **not** map these as the schedule `V(T)` label

| ODF | Meaning | Tile use |
|-----|---------|----------|
| `ExtendedInfo[@Type='UI'][@Code='TOSS']/@Value` = `A` \| `B` | Priority / toss side **before overtime** | **Not** the OSRP `V(T)` string |
| `UI/OVERTIME` = `Y` | Encounter went to OT | Context only |
| `UI/PERIOD` = `E-FS` | Game state **Final Score** (`SC@GameState`) | Not schedule `V(T)` |

Bracket feeds may show `V(T) 14 - 14` on `DT_BRACKETS` — schedule tile still takes **`DT_RESULT/@WLT`**.

### 3.5 `liveCurrentProgress` — out of scope for schedule tile

ODF `UI/PERIOD` + `SC@Period` / `SC@GameState` feed **Start List / Results** (OSRP §2–§3), not Competition Schedule §1.4.

Tile live = `liveFlag` + hit score. Do not populate `liveCurrentProgress` for FEN schedule.

### 3.6 `resultDecision` — out of scope

Victory by toss is **`winLoseTie = "V(T)"`**. Do not invent `resultDecision.code = "V(T)"`.

### 3.7 Opponents (no invented placeholders)

OSRP schedule content for FEN does **not** specify CIS/WMR placeholder rows (`Winner n`, `TBD` labels, `NOCOMP` copy, etc.).

| When | Tile |
|------|------|
| Before draw | No opponents |
| After draw — first phase | Known opponents’ **names** |
| Later phases | Add **names** when known; until then do **not** invent placeholder UI for the schedule tile |

BE still carries the full start list in `competitors[]` when the feed has real competitors (common §3.3.1 NOC filter). Do **not** invent `placeholderOpponents[].name` composition for FEN schedule chrome.

### 3.8 `startText`

Common §3.4 when `HideStartDate=Y`.

### 3.9 Backend checklist

- [ ] H2H scores from `DT_RESULT` `POINTS`  
- [ ] Pass through `winLoseTie` including **`V(T)`** (not normalised to `W`)  
- [ ] IRMs from `@IRM`  
- [ ] No schedule-tile `liveCurrentProgress` / `resultDecision`  
- [ ] Do not treat `UI/TOSS` A/B as the `V(T)` label  
- [ ] Full `competitors[]` when known (NOC filter) — no invented placeholder names  
- [ ] Inclusion per common (no FEN-only DRAW omit)  
- [ ] Individuals `A` + teams `T` name blocks  

---

## 4. Frontend — FEN

| Phase | FE |
|-------|-----|
| Before draw | Event/phase, time, venue, medal flag — no opponents |
| After draw | Known first-phase names; later units without names until opponents known — **no invented placeholders** |
| During | Live highlight + score; **no** period strip |
| After | Score; winner; **`V(T)`** when `winLoseTie === "V(T)"`; IRM layout; medal icon on medal bout/match winner |

### 4.1 `V(T)` behaviour

| `winLoseTie` | FE |
|--------------|-----|
| `W` | Winner marker (no `V(T)` text) |
| `V(T)` | Winner **and** display **`V(T)`** between name and score (OSRP) |
| `L` | Loser row |
| `T` | Tie (rare on finished Olympic bout/match) |

Treat `V(T)` as a winning code for “is winner” logic (highlight, medal icon) — no separate `resultDecision`.

### 4.2 Grouping

Discipline packs do **not** redefine grouping. Use [`olympic-grouping-rules.csv`](../grouping/olympic-grouping-rules.csv) / grouping OpenSpec. FEN row: `{Session}_{PhaseRSC}`, `GroupType=phase`.

### 4.3 Card click redirects

Same as [common §4.3](../common/schedule-tile-common.md) — **one unit-results URL for before / during / after**.

Example individual gold: `FENMEPEE--------------FNL-000100--`

| Surface | On card click → |
|---------|-----------------|
| **CIS** | `/en/OG2028/FEN/M/EPEE--------------/FNL-/000100--/results` |
| **WMR** | `/en/la28/results/unit/fenmepee--------------fnl-000100--` |

Example team gold: `FENWTEAMSABR----------FNL-000100--` → CIS event slot `TEAMSABR----------`, phase `FNL-`, unit `000100--`.

### 4.4 Frontend checklist

- [ ] Before/after draw layouts (names only when known)  
- [ ] Live score without period chrome  
- [ ] Render `V(T)` from `winLoseTie`  
- [ ] IRM + medal-match icon  
- [ ] Grouping from CSV only  
- [ ] Card click → unit results (common §4.3)  

---

## 5. Schedule=S analysis

| RSC / pattern | CC Schedule | Default list | By Event | Expected grouping |
|---------------|-------------|--------------|----------|-------------------|
| *(none)* | — | — | — | **0** `Schedule=S` units in OG2028 CC@Unit for FEN |

`Schedule=S` does not change card redirect RSC. Grouping itself is CSV-owned, not this pack.

---

## 6. API gaps (FEN view)

| Field | FEN need |
|-------|----------|
| `startText` | Yes if any visible `HideStartDate=Y` units |
| `resultDecision` | **No** — use `winLoseTie` `V(T)` |
| `liveCurrentProgress` | **No** on schedule tile |
| Pass-through `winLoseTie` values beyond W/L | **Yes** — must accept `V(T)` (and `T`) from `SC@WLT` |

---

## 7. FEN cheat sheet

```
BEFORE DRAW:  DT_SCHEDULE              →  meta / phase only (no opponents)
AFTER DRAW:   DT_SCHEDULE              →  known A|T names (first phase; later when known)
DURING:       + DT_RESULT LIVE         →  liveFlag + POINTS score
AFTER:        + DT_RESULT              →  score, WLT (W|L|V(T)), IRM, medal
              UI/TOSS A|B              →  NOT schedule V(T) label
```
