# CLB Schedule Tile — Developer Requirements

**Scope:** Sport Climbing (CLB) only.  
**Shared rules:** [schedule-tile-common.md](../common/schedule-tile-common.md)  
**Editions:** OSRP LA28 R4 V1.0 · ORIS LA28 R9 · ODF CLB LA28 · SC/CC `OG2028` v1.5.0  
**RawData:** Paris-style dump under `rawData/CLB`.  
**Test freezes:** [ownScenarios/CLB](../../ownScenarios/CLB/README.md) — `01_Schedule_Tile_Mixed_Day` (LogicalDate `2026-09-09`); mega [`All_Events`](../../ownScenarios/CLB/All_Events/README.md) (M Speed→medals, W Speed QFNL live, M Lead SFNL live, M Boulder→gold)

---

## 1. CLB vs common

| Topic | CLB behaviour |
|-------|----------------|
| Tile type | **Phase/unit session** (Boulder/Lead) or Speed **phase** row — not H2H score card |
| Results on tile | **N/A** (OSRP schedule) |
| After | Show **medallists** (NOC + athlete) when known; ties → all rows ([common §3.3.2](../common/schedule-tile-common.md)) |
| `competitors[]` | **Full** start list for NOC filter ([common §3.3.1](../common/schedule-tile-common.md)) |
| Placeholders | Rich `SC@CompetitorPlace` exists in ODF — **not shown on schedule tile** (Speed `S` pairs merge into Finals phase tile) |
| `liveCurrentProgress` | **N/A** for schedule tile (`SC@Period` empty); live = status highlight |
| `resultDecision` | **N/A** on schedule tile |
| Schedule flags | **CC verified (OG2028):** Speed **phase** `QFNL`/`SFNL`/`FNL-` = `Schedule=Y`; each race **unit** (pairs) = `Schedule=S`. Qual heat parents = unit `Y`; race subunits = `S`. Boulder/Lead final units = `Y`. List **Y** rows; do not list each `S` pair as its own schedule card |

---

## 2. Situations (OSRP §1)

### 2.1 Before / during

- Date, start time, discipline, event, phase.
- Status / medal indicators (not “Scheduled”); live highlight when `RUNNING`.
- **No result scores** on the schedule tile.
- Do **not** show Speed pair (H2H / placeholder) rows on the schedule card — `Schedule = S` races are merged under the Finals / phase `Y` tile.

### 2.2 After event completed

- Show **medallists**: NOC (code/flag) + athlete name (+ medal icon). Usual case three (G/S/B); on ties show **every** medallist ([common §3.3.2](../common/schedule-tile-common.md)).

### 2.3 Speed schedule granularity (`CC@Unit` / `CC@Phase`, OG2028)

| Stage | CC Schedule | What appears on schedule UI |
|-------|-------------|------------------------------|
| Boulder / Lead SFNL & FNL | **Unit `Y`** | That unit tile |
| Speed Qualification Seeding / Elimination (heat parent) | **Unit `Y`** | Heat parent tile |
| Speed Qual Elimination races (`…EL01`…`EL07`) | **Unit `S`** (SubUnit) | **Not** separate cards — under parent `Y` |
| Speed Quarterfinals / Semifinals / Finals | **Phase `Y`** (`…QFNL--------`, `…SFNL--------`, `…FNL---------`) | **One phase tile** (e.g. “Men's Speed Finals”) |
| Speed QF/SF/FNL pair units (Big Final, Small Final, QF 1–4, …) | **Unit `S`** | **Not** separate cards — covered by phase `Y` |

So: `Schedule=S` does not invent a merge rule by itself — CC already puts **visibility on the phase (`Y`)** and marks pair races **`S`**. FE/BE list `Y` (units + Speed phases); omit or nest `S` pairs.

---

## 3. Backend — CLB

### 3.1 ODF sources

| Message | Role |
|---------|------|
| `DT_SCHEDULE[_UPDATE]` | Meta, status, medal flag, start list / place codes |
| `DT_RESULT` | Unit results (not shown as schedule score per OSRP) |
| `DT_BRACKETS` | Finals bracket context |
| `DT_MEDALLISTS` | **Enrich finished event** with G/S/B |
| `DT_PARTIC` | Names |

### 3.2 Medallists on tile (after)

Same pattern as CRD:

```
DT_MEDALLISTS → schedules[] competitors[]
  type=A, athleteNames, organisation, result.medal = GOLD|SILVER|BRONZE
```

### 3.3 Placeholder opponents

`SC@CompetitorPlace` codes (`TBD`, `WQF*`, `WSF*`, `LSF*`, `BYE`, `NOCOMP`) apply to Speed **pair** units in ODF. For the **schedule tile**, those `S` units are not listed as separate cards (merged into Finals / phase `Y`) — FE schedule results box does **not** need H2H placeholder rendering. Place-code resolution remains relevant for unit results / brackets surfaces, not Daily Schedule.

### 3.4 Progress / decision

| Field | CLB schedule tile |
|-------|-------------------|
| `liveCurrentProgress` | Omit (or only if product invents non-PERIOD progress — not in OSRP schedule) |
| `resultDecision` | Omit |
| `startText` | Common rules if HideStartDate used (StartText not in CLB batch hit — confirm per DD version) |

### 3.5 Inclusion

- Default list: `Schedule=Y` from CC — Speed **phases** (QFNL/SFNL/FNL) and Boulder/Lead/Qual **units**; plus agreed medal ceremony units.
- Speed pair **units** with `Schedule=S` are not separate Daily Schedule cards (see §2.3).

### 3.6 CLB checklist

- [ ] Y (and agreed S) units in payload  
- [ ] No climbing scores on schedule tile  
- [ ] Place codes on Speed pairs: not required for schedule tile UI (S → Finals phase)  
- [ ] After: all medallist rows from `DT_MEDALLISTS` (incl. ties); full `competitors[]` retained  
- [ ] Live = `scheduleStatus` / `liveFlag` only  

---

## 4. Frontend — CLB

**Results box (FE summary):** [schedule-tile-fe-score.md](./schedule-tile-fe-score.md)

| Phase | FE |
|-------|-----|
| Before | Event/phase, time; **no** H2H / placeholder opponent rows |
| During | Live highlight; no result block |
| After | All medallist rows (`result.medal`; >3 if ties) |

### 4.1 Card click redirects

Same as [common §4.3](../common/schedule-tile-common.md) — **one results URL for before / during / after**.

**CLB Speed is on [Schedule RSC overrides](https://dgplatform.atlassian.net/wiki/spaces/SCDLA/pages/3229941783/Schedule+RSC+overrides):** phase tiles (shared finals/brackets screen) must navigate via `overrideRsc` when set — e.g. schedule RSC `CLBMSPEED-------------FNL---------` → override `CLBMSPEED-------------FNL-000100--` (same idea for W / QFNL / SFNL on that page).

Example after override (Big Final unit):

| Surface | On card click → |
|---------|-----------------|
| **CIS** | `/en/OG2028/CLB/M/SPEED-------------/FNL-/000100--/results` |
| **WMR** | `/en/la28/results/unit/clbmspeed-------------fnl-000100--` |

Boulder / Lead / Qual heat parents use their own unit RSC (no override unless listed). In-app tabs after Results are not part of the schedule card href.

---

## 5. Cheat sheet

```
BEFORE/DURING: DT_SCHEDULE  →  meta/status for Schedule=Y rows; no scores; no H2H placeholders
AFTER:         DT_MEDALLISTS →  all medallists on tile (ties → >3); full competitors[] kept
SPEED (CC):    Phase QFNL/SFNL/FNL = Y → one tile; pair units = S → not listed separately
SPEED click:   use overrideRsc (shared brackets/finals page) per Schedule RSC overrides
```
