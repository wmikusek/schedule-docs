# RCB Schedule Tile — Developer Requirements

**Scope:** Rowing Coastal Beach Sprints (`RCB`) only.  
**Shared rules:** [schedule-tile-common.md](../common/schedule-tile-common.md)  
**Editions:** OSRP LA28 R4 V0 (`OG2028_RCB_Live_Screens_R4_V0_20251111`) · ORIS LA28 R9 V1.1 (`OG2028_RCB_ORIS_R9_V1.1_20260217`) · ODF `OG2028-RCB-0.3` (+ GEN schedule `OG2028-GEN-5.2`) · SC/CC `OG2028` v1.6.0  
**RawData:** none under `rawData/RCB` yet.  
**Freeze:** none under `ownScenarios/RCB` yet.

Flavour: **Event row + medallists after** (no live score / race times on the schedule tile). Same family as CRD / CLB / TRI — not H2H. Knockout visibility follows a **phase `Y` + race unit `S`** pattern (closest cousin: CLB Speed).

---

## 1. RCB vs common

| Topic | RCB behaviour |
|-------|----------------|
| Events | Three medal events (ORIS §2.1): Women’s Solo `RCBWSCULL1`, Men’s Solo `RCBMSCULL1`, Mixed Double Sculls `RCBXSCULL2` |
| Format | Time Trial 1 + Time Trial 2 (in-line), then Last 16 → Quarterfinals → (Repechages in CC) → Semifinals → Finals (Gold + Bronze medal races) |
| Tile type | **Event / phase / unit row** — date, time, discipline + event (+ phase; unit details for SFNL/FNL per OSRP), status, medal marker |
| Results on tile | **N/A** (OSRP §1.2) — no race times, ranks, WLT, or H2H scores |
| Live | Status + live highlight when `RUNNING`. No `liveCurrentProgress` (`SC@Period` empty) |
| After | Show **medallists** when known: solo → NOC + athlete; mixed → NOC + **team name**. Ties → all rows ([common §3.3.2](../common/schedule-tile-common.md)) |
| `competitors[]` | Full unit start list for NOC filter on **unit** tiles ([common §3.3.1](../common/schedule-tile-common.md)); phase tiles have no unit `DT_RESULT` of their own |
| Placeholders | Rich `SC@CompetitorPlace` (`TBD`, `nTT1`/`nTT2`, `NOCOMP`, `NOAWARD`) for bracket / start-list surfaces — **not** rendered as H2H rows on the schedule card |
| `resultDecision` | **N/A** on schedule tile |
| Grouping | OSRP: default **event + phase**, expandable to units for **Semifinals and Finals**. No `RCB` row in `olympic-grouping-rules.csv` yet → **no `groupId` until product adds a CSV rule** (see open questions) |
| Schedule flags | **CC verified:** only **8** unit `Y` (6× Time Trial + 2× Solo VICT). **115** unit `S` (all knockout races, TT re-rows, Mixed VICT). Knockout **phases** `8FNL`/`QFNL`/`REP-`/`SFNL`/`FNL-` = phase `Y`; `PREL`/`VICT` phases = `N` |
| Medal marker | OSRP “Medal events”. CC `@Unit` has `Medal=0` even on Gold/Bronze Medal Race names — prefer ODF GEN `Unit/@Medal` when OVR sends it (see gaps) |

---

## 2. Situations (OSRP §1 + ORIS §3.1.6)

### 2.1 Before

- Date, start time, discipline + **event** (+ **phase** name).
- Status indicators for any RCB schedule status. **Do not** show “Scheduled”.
- Medal-event marker when applicable.
- **No** result / score / start-list / opponent block on the card UI.
- Time Trials appear as **unit** tiles (`Schedule=Y`). Knockout stages appear primarily as **phase** rows (`CC@Phase` `Schedule=Y`); race units are `Schedule=S` (see §5).

### 2.2 During / after

While a race / phase is in progress:

- Highlight / `liveFlag` when `scheduleStatus = RUNNING`.
- Still **no** results, times, or WLT on the schedule tile (detail lives on Start List / Results / bracket screens).

After the medal event is completed and medallists are known (OSRP §1.2):

| Event | Medallist rows |
|-------|----------------|
| Women’s / Men’s Solo | NOC (code and/or flag) + **athlete’s name** (+ medal icon) |
| Mixed Double Sculls | NOC (code and/or flag) + **team name** (+ medal icon) |

Prefer `DT_MEDALLISTS` for who gets G/S/B. Do not invent medallists from a partial ranking. On shared medal places, FE shows **every** medallist row ([common §3.3.2](../common/schedule-tile-common.md)).

**OSRP grouping (SFNL / FNL):** default view = event + phase name; user can **expand** to event units in that phase. Unit details are called out for Semifinals and Finals only — not for Last 16 / QF / Repechage in the OSRP text.

### 2.3 Exceptional (ORIS §3.1.6)

Schedule-status matrix (shared chrome; ORIS wording = race / event / phase / session; OC terminology for statuses):

| Status | Meaning (RCB) |
|--------|----------------|
| Delayed | Does not start as scheduled but still within current ticketing session |
| Rescheduled | New date/time known within session (or later when known) |
| Postponed | Later session; new date/time unknown |
| Interrupted | Unplanned stop after start; may return to Running or escalate. Uncompleted race restarts from the beginning |
| Cancelled | Cannot be rescheduled before Closing Ceremony |

Competition-related (results / ORIS — **not** separate schedule-tile chrome unless status changes):

- False start / Yellow→Red Card → **EXC**; TT false start may add a 10s penalty note on C73A.
- **Re-row** units in CC (`…RR--`, `…R2--`) after dead heat or Jury decision — `Schedule=S`, nested under parent TT / race (not separate default cards).
- Crew withdrawal / replacement rules for QF; DNF exceptionally allowed to continue; shortened competition / fewer than 17 entries.
- Provisional results; DSQ / EXC / REL / DNS / DNF impacts on rankings and medal outputs.

IRM catalogue (`SC@IRM`, OG2028): `REL`, `DNF`, `DNS`, `EXC`, `DSQ`.  
Result types (`SC@ResultType`): `TIME`, `IRM`, `IRM_RANK`.  
WLT (`SC@WLT`): `W`, `L` — used on knockout **results** surfaces, not on the schedule tile score block.

---

## 3. Backend — RCB

### 3.1 ODF sources

| Message | Role on schedule tile |
|---------|------------------------|
| `DT_SCHEDULE` / `DT_SCHEDULE_UPDATE` | Unit/phase meta, times, venue, `ScheduleStatus`, optional `@Medal` / `HideStartDate` — **GEN** (not extended in RCB DD; inherit GEN) |
| `DT_RESULT` `START_LIST` | Full **unit** start list → `competitors[]` for NOC filter (athletes `A` or teams `T`) — **not** rendered as scores on the card |
| `DT_RESULT` LIVE / UNOFFICIAL / OFFICIAL | Keep competitor set; times / WLT / IRM feed results surfaces, not schedule scores |
| `DT_CURRENT` | Present in RCB DD — optional live merge; **do not** map to tile score |
| `DT_MEDALLISTS` | Enrich after finish: set `result.medal` on G/S/B (athletes or teams) |
| `DT_PARTIC` / `DT_PARTIC_TEAMS` | Names when schedule / result descriptions are thin |

### 3.2 Inclusion (Y + S rules)

**Default competition list** (CC `OG2028` v1.6.0):

| Kind | RSC / pattern | CC Schedule | Surfaces |
|------|---------------|-------------|----------|
| Time Trial 1 / 2 | `RCB{M\|W}SCULL1------------PREL000{1\|2}00--`, `RCBXSCULL2------------PREL000{1\|2}00--` | Unit **Y** | CIS + WMR |
| Knockout **phases** | `RCB*------------{8FNL\|QFNL\|REP-\|SFNL\|FNL-}--------` | Phase **Y** | CIS + WMR (phase row) |
| Victory ceremony (Solo) | `RCB{M\|W}SCULL1------------VICTMEDAL---` | Unit **Y** | **CIS only** |
| Victory ceremony (Mixed) | `RCBXSCULL2------------VICTMEDAL---` | Unit **S** | **Open** — see §6 / open questions |
| Knockout races / TT re-rows | e.g. `…8FNL000100--`, `…FNL-000100--`, `…PREL0001RR--` | Unit **S** | Not separate default cards; SFNL/FNL units reachable via expand (OSRP) |
| Venue / OTHR | `RCBGGEN---------------OTHRBMS-----` | **N** | Omit |

Omit meetings / non-competition even if ever marked `Y` ([common §3.1](../common/schedule-tile-common.md)). WMR drop of ceremonies is the shared BE filter.

`Schedule=S` is **visibility / nesting**, not a redirect change: if a race unit is shown (expanded SFNL/FNL), click still opens **that unit’s** results RSC unless product documents an `overrideRsc` for phase tiles (CLB Speed pattern).

### 3.3 `competitors[]` + medallists

**Unit tiles** (Time Trials, and expanded SFNL/FNL races when listed): load full start list from `DT_RESULT` (`START_LIST` and later). Keep the **full** list for NOC filter. Card UI does not show the field.

| Competition | Competitor `@Type` |
|-------------|--------------------|
| Solo TT / races | `A` |
| Mixed Double Sculls | `T` (`Description/@TeamName`) |

**After:** do **not** shrink to medallists-only. Overlay medals from `DT_MEDALLISTS`:

```
DT_MEDALLISTS  (event DocumentCode)  +  Medal/@Unit = unit RSC
        │
        ▼
same competitors[ ]  (full start list retained)
  every medallist gets result.medal = GOLD | SILVER | BRONZE
```

Which schedule **row** shows the medallist block (Finals phase tile vs Gold Medal Race unit vs event-level) needs product confirmation — OSRP only says “after the related event is completed”.

### 3.4 Progress / decision / placeholders

| Field | RCB schedule tile |
|-------|-------------------|
| `liveCurrentProgress` | **Omit** — OSRP Results N/A; `SC@Period` empty |
| `resultDecision` | Omit |
| `placeholderOpponents` | Omit on schedule card (place codes for unit results / brackets only) |
| `startText` | Common rules when `HideStartDate=Y` (GEN; no `SC@StartText` for RCB) |

### 3.5 Backend checklist

- [ ] Emit TT unit `Y` + knockout phase `Y` rows; nest / omit race unit `S` and TT re-row `S`  
- [ ] Solo VICT on CIS; Mixed VICT pending product (CC `S`)  
- [ ] No false H2H scores or race times as “tile score”  
- [ ] `liveFlag` from `RUNNING`  
- [ ] Full `competitors[]` on unit tiles; overlay `DT_MEDALLISTS` after  
- [ ] Mixed medallists expose **team** name + NOC; ties → all rows  
- [ ] No `groupId` until CSV rule exists  

---

## 4. Frontend — RCB

| Phase | FE |
|-------|-----|
| Before | Event (+ phase) title, time, venue, status / medal flag — **no** competitor / score / placeholder rows |
| During | Live highlight only; **no** result values |
| After | Medallists: **athletes** (solo) / **teams** (mixed); ties → all rows |
| SFNL / FNL | Default phase row; expand to unit rows when API / grouping exposes them (OSRP) |
| Country filter | Match athletes or teams in `competitors[]` on unit payloads |

### 4.1 Grouping / visibility

- OSRP expects phase expand for Semifinals / Finals. Runtime CSV has **no RCB row** today → no `groupId` until product adds one (ROW uses `{Session}_{PhaseRSC}` as a possible model — not assumed).
- Render what the API returns; do not client-hide victory ceremonies on WMR (BE already filters).

### 4.2 Card click redirects

Same as [common §4.3](../common/schedule-tile-common.md) — **one results URL for before / during / after**. `Schedule=S` does not change the href of a listed unit.

**Unit example** — Men’s Solo Time Trial 1 `RCBMSCULL1------------PREL000100--`:

| Surface | On card click → |
|---------|-----------------|
| **CIS** | `/en/OG2028/RCB/M/SCULL1------------/PREL/000100--/results` |
| **WMR** | `/en/la28/results/unit/rcbmscull1------------prel000100--` |

**Unit example** — Mixed Double Sculls Gold Medal Race `RCBXSCULL2------------FNL-000100--` (when shown via expand):

| Surface | On card click → |
|---------|-----------------|
| **CIS** | `/en/OG2028/RCB/X/SCULL2------------/FNL-/000100--/results` |
| **WMR** | `/en/la28/results/unit/rcbxscull2------------fnl-000100--` |

**Phase tiles:** if the schedule RSC is a phase code (`…FNL---------`), product may need an `overrideRsc` to a concrete unit (same idea as CLB Speed on Schedule RSC overrides) — not confirmed for RCB.

### 4.3 Frontend checklist

- [ ] Event-row layout; no H2H score rows  
- [ ] Live highlight only while in progress  
- [ ] After: all medallist rows (athlete vs team name)  
- [ ] No “Scheduled” badge  
- [ ] SFNL/FNL expand only when BE/grouping provides child units  
- [ ] Card click → unit (or documented override) results URL  

---

## 5. Schedule=S analysis

**Count: 115** of **124** CC `@Unit` rows (`OG2028` v1.6.0). Plus **8** unit `Y`, **1** unit `N` (venue OTHR).

`Schedule=S` is a **visibility / grouping** concern, **not** a redirect change. Click still opens that unit’s results RSC (unless a pack documents an RSC override for phase tiles).

| RSC / pattern | CC Schedule | Default list | By Event | Expected grouping |
|---------------|-------------|--------------|----------|-------------------|
| `…PREL000100--` / `…PREL000200--` (TT1 / TT2, all 3 events) | Unit **Y** | List | List | Standalone unit tiles |
| `…PREL0001RR--` / `…R2--` (TT re-rows) | Unit **S** | Nest / hide under parent TT | Nest / hide | Not separate cards |
| `RCB*------------{8FNL\|QFNL\|REP-\|SFNL\|FNL-}--------` | Phase **Y** | List as **phase** row | List | OSRP expand for **SFNL/FNL** to child units |
| Knockout races (`…8FNL000n00--`, `…QFNL…`, `…REP-…`, `…SFNL…`, `…FNL-000{1\|2}00--`, incl. RR variants) | Unit **S** | Not separate default cards | Expand (SFNL/FNL) / nest | Under phase `Y` |
| `RCB{M\|W}SCULL1------------VICTMEDAL---` | Unit **Y** | CIS only | CIS only | BE omits from WMR |
| `RCBXSCULL2------------VICTMEDAL---` | Unit **S** | **Open** | **Open** | Mixed VICT flagged `S` in CC |
| `RCBGGEN---------------OTHRBMS-----` | **N** | Omit | Omit | — |
| `…PREL--------` / `…VICT--------` phase RSC | Phase **N** | Omit as tile | Omit | TT units and VICT units carry visibility |

S breakdown by phase (units): `8FNL` 48 · `REP-` 30 · `PREL` re-rows 12 · `QFNL` 12 · `FNL-` 6 · `SFNL` 6 · `VICT` 1 (Mixed).

---

## 6. API gaps (RCB view)

| Gap | Why it is open |
|-----|----------------|
| `startText` | Same platform gap as common when `HideStartDate=Y` |
| Medallists host RSC | OSRP does not say whether medallists attach to Finals phase tile, Gold Medal Race unit, or event-level row |
| Phase tile click / `overrideRsc` | Phase `Y` rows have no unit results DocumentCode; CLB Speed uses Schedule RSC overrides — RCB not listed |
| `medalFlag` vs CC `Medal=0` | Gold/Bronze Medal Race units are `Medal=0` in CC; rely on ODF GEN `Unit/@Medal` if OVR populates it |
| Mixed VICT `Schedule=S` | Solo ceremonies are `Y`; Mixed is `S` — CIS inclusion unclear |
| Grouping CSV | OSRP expand UX needs a product rule; no `RCB` row in `olympic-grouping-rules.csv` (ROW has phase grouping — not copied here) |

Decided (platform): full `competitors[]` for NOC filter; non-H2H tied medallists → show all rows — [common §3.3.1–3.3.2](../common/schedule-tile-common.md).

---

## 7. RCB cheat sheet

```
BEFORE:  DT_SCHEDULE (GEN) + DT_RESULT START_LIST (unit Y / expanded units)
         →  meta/status/medalFlag + full competitors[] on units
         list: TT unit Y + knockout phase Y
         nest/hide: race unit S + TT re-row S
DURING:  + DT_CURRENT / DT_RESULT LIVE
         →  liveFlag only; no tile scores / no liveCurrentProgress
AFTER:   + DT_MEDALLISTS
         →  medal icons on all medallists (ties → >3)
            solo: athlete + NOC | mixed: team name + NOC
         full competitors[] retained on unit payloads
SFNL/FNL: phase Y default; expand to unit S (OSRP)
```
