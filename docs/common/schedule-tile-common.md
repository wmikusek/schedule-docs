# Schedule Tile — Common Requirements (cross-discipline)

Shared rules for CIS / WMR schedule cards. Discipline packs add sport-specific situations, codes, and ODF mappings:

- [FBL](../FBL/schedule-tile-requirements.md) · [FBL FE map](../FBL/schedule-tile-fe.md)
- [ARC](../ARC/schedule-tile-requirements.md) · [ARC FE results](../ARC/schedule-tile-fe-score.md)
- [CKT](../CKT/schedule-tile-requirements.md)
- [CRD](../CRD/schedule-tile-requirements.md) · [CRD FE results](../CRD/schedule-tile-fe-score.md)
- [SQU](../SQU/schedule-tile-requirements.md) · [SQU FE results](../SQU/schedule-tile-fe-score.md)
- [CLB](../CLB/schedule-tile-requirements.md) · [CLB FE results](../CLB/schedule-tile-fe-score.md)
- [BSB](../BSB/schedule-tile-requirements.md)
- [TRI](../TRI/schedule-tile-requirements.md) · [TRI FE results](../TRI/schedule-tile-fe-score.md)
- [FEN](../FEN/schedule-tile-requirements.md)
- [RCB](../RCB/schedule-tile-requirements.md)

**Tile flavours:**
- **H2H + score:** FBL, ARC, CKT, SQU, BSB, FEN  
- **Event row + medallists after (no live score on tile):** CRD, CLB, TRI, RCB  

**API contract:** [SCDLA Schedule](https://dgplatform.atlassian.net/wiki/spaces/SCDLA/pages/3120988164/Schedule) — `{competitionCode}/schedule` (+ `schedulesPerDay/{YYYY-MM-DD}`), SSE + HTTP.

---

## 1. Sources of truth

| Layer | Document | Role |
|-------|----------|------|
| UX content | OSRP § Competition Schedule (per discipline) | What the tile shows before / during / after |
| Procedures | ORIS §3.1.6 (per discipline) | Delayed / postponed / interrupted / cancelled / provisional / IRMs |
| Feed | ODF Data Dictionary (per discipline) | Exact XPaths and triggers |
| Codes | `CC@ScheduleStatus`, `CC@ResultStatus`, discipline `SC@*` | Labels for codes |
| Platform API | Confluence Schedule | JSON delivered to FE |

OSRP often defers detailed cross-sport schedule chrome to a separate document; discipline packs cover sport-specific data and indicators.

---

## 2. Tile lifecycle

State comes first from **`scheduleStatus`** (`CC@ScheduleStatus`). After `FINISHED`, prefer **`resultStatus`** (`CC@ResultStatus`) for the status badge.

| Phase | Typical trigger | Tile shows |
|-------|-----------------|------------|
| **Before** | `SCHEDULED`, `GETTING_READY`, `DELAYED`, `RESCHEDULED`, `POSTPONED`, … | Time/venue/event/phase/unit, opponents or placeholders, medal marker if any. **No live score.** Do **not** show badge “Scheduled”. |
| **During** | `RUNNING` (+ in-match `INTERRUPTED` / `SCHEDULED_BREAK`) | Live highlight (`liveFlag`), live score (if applicable), optional progress (`liveCurrentProgress` — **sport-specific**). |
| **After** | `FINISHED` | Final score, winner (`WLT`), IRMs / sport decision indicators, medals. Badge from `resultStatus`. |

### Schedule status → UI (shared)

| Code | UI label | Notes |
|------|----------|-------|
| `SCHEDULED` | *(no badge)* | OSRP (FBL/ARC): “Scheduled” not needed |
| `GETTING_READY` | Getting Ready | Pre-start |
| `RUNNING` | In Progress | Highlight / `liveFlag = true` |
| `DELAYED` | Delayed | Within current ticketing session |
| `RESCHEDULED` | Rescheduled | New date/time known |
| `POSTPONED` | Postponed | New date/time unknown |
| `INTERRUPTED` | Interrupted | Started; resume or escalate |
| `SCHEDULED_BREAK` | Scheduled Break | Planned break |
| `FINISHED` | Finished → then result status | Official / Protested / Provisional when available |
| `CANCELLED` | Cancelled | Will not be played |
| `UNSCHEDULED` | — | Usually **not listed** on schedule UI (discipline may require hiding BYE units etc.) |

ORIS schedule-change matrix (delay → reschedule / postpone / cancel) is shared conceptually; wording may say “match” or “session” per sport.

---

## 3. Backend — shared

### 3.1 Inclusion

Tiles, **all disciplines**:

- Emit **competition units** and **official trainings** only. Do not emit meetings or other non-competition units, even when `Schedule=Y`.
- **Victory ceremonies:** include on **CIS**; omit from **WMR**. The **backend** applies this filter for every discipline. Frontend does not hide them.
- Medal **games** (`Unit/@Medal` 1 or 3) are competition units and stay on both surfaces.
- Discipline `Schedule=S` rules still apply (see the pack).
- HTTP snapshot + SSE patches; day filter endpoint as in Confluence.

### 3.2 ODF messages (baseline)

| Message | Role |
|---------|------|
| `DT_SCHEDULE` / `DT_SCHEDULE_UPDATE` | Identity, times, venue, status, medal, start list / placeholders, hide flags |
| `DT_RESULT` | Scores, WLT, IRM, resultStatus, sport progress / decision ExtendedInfos |
| `DT_CURRENT` | Optional high-frequency live (when discipline sends it) |
| `DT_PARTIC` / `DT_PARTIC_TEAMS` | Enrich names when schedule description thin |

### 3.3 Common API ← ODF fields

| API field | ODF source | Notes |
|-----------|------------|-------|
| `rsc` | `Unit/@Code` | |
| `discipline*` / `gender` / `event*` / `phase*` / `unitName` | RSC + CC descriptions / `ItemName` | |
| `unitNumber` / `hideUnitNum` | `@UnitNum` / `@HideUnitNum` | |
| `sessionCode` | `@SessionCode` | |
| `startDate` / `endDate` / `hideStartDate` / `hideEndDate` / `dateOrder` | Unit date attrs / `@Order` | |
| `liveFlag` | Derived: `ScheduleStatus == RUNNING` | |
| `scheduleStatus` / `*Description` | `@ScheduleStatus` + CC | |
| `resultStatus` / `*Description` | `DT_RESULT` `@ResultStatus` + CC | |
| `venue*` / `location*` | Unit venue/location + descriptions | |
| `medalFlag` | `Unit/@Medal` | `0` none; `1` gold; `3` bronze (API convention) |
| `competitors[]` | Known `Start/Competitor` + `Result` | `type` `A` or `T` per sport; see §3.3.1 |
| `competitors[].result.*` | `Result/@Result`, `@ResultType`, `@WLT`, `@IRM`, medal | |
| `placeholderOpponents[]` | Unknown competitors — **resolution is sport-specific** | See packs |
| `liveCurrentProgress` | **Sport-specific** (optional on Confluence: “e.g. FBL”) | See packs |
| `extendedResultInfo.finalResultDescription` | **CKT (and similar)** — Confluence | Interpolated match-situation text; see CKT pack |
| `resultDecision` | **Proposed / sport-specific** | See packs + §5 |
| `startText` | **Proposed** when `hideStartDate` | §3.4 |

### 3.3.1 Full `competitors[]` + NOC filter (global)

**Global:** every competition unit tile must carry the **complete** unit start list in `competitors[]` (from `DT_RESULT` START_LIST / later statuses, and/or schedule `StartList` when that is the source). Do **not** shrink the payload to medallists-only after finish.

Country / NOC filter matches a tile when any `competitors[].organisation` equals the selected NOC (athlete or team). Card UI still follows the discipline flavour — H2H shows opponents; event-row packs show medallists after and do **not** render the full start list on the card.

### 3.3.2 Event-row medallists after + ties (global for non-H2H)

For **event row + medallists** tiles (not H2H score cards):

- After finish, set `result.medal` from `DT_MEDALLISTS` on every medallist in the full `competitors[]`.
- FE renders **all** medallist rows (`result.medal` set). Usual case is three (G/S/B).
- **Ties:** when a medal place is shared, show **more than three** rows — every athlete/team that has a medal. Do not collapse shared places into a single row.

H2H medal **games** keep the shared rule of a medal icon on the game winner(s) per the H2H pack — this section does not change H2H score layout.

### 3.4 `startText` — ODF → API → display (shared)

When `Unit/@HideStartDate = Y`, FE must not show `startDate` as the clock.

```
DT_SCHEDULE  HideStartDate="Y"
             StartText[@Language='ENG']/@Value     code or free text
        │
        ▼
API  hideStartDate = true
     startText = Value  (if Value ∈ SC@StartText → Description optional; else pass-through)
        │
        ▼
FE   time slot = startText
```

| Case | API | FE |
|------|-----|-----|
| No hide | `hideStartDate: false` | Format `startDate` |
| Hide + StartText | `startText` set | Show `startText` |
| Hide, no StartText | `startText` null | Still **do not** show clock from `startDate` |

> **API gap:** Confluence has `hideStartDate` but not `startText` — add for all disciplines that use HideStartDate.

### 3.5 Placeholder opponents — shared algorithm

1. Detect **known** competitor: real participant/team id + organisation/name → `competitors[]`.
2. Else treat as **placeholder** → `placeholderOpponents[]` with `order` from `SortOrder`/`StartOrder`.
3. Resolve **display `name`** using discipline rules (codes catalogue and/or `PreviousUnit` / `PreviousWLT`). **FE must not invent** the string.
4. When schedule update replaces placeholder with a real competitor, move to `competitors[]` and clear that side from `placeholderOpponents[]`.

Discipline packs define codes (`SC@CompetitorPlace`) and worked examples.

### 3.6 Merge / update rules (shared)

1. Last message wins per (`DocumentType`, document/unit key).
2. Schedule UPDATE patches metadata/status/competitors; does not wipe scores.
3. While `RUNNING`, merge live RESULT/CURRENT per discipline pack; keep `liveCurrentProgress` in sync if used.
4. On `FINISHED`, clear live progress; keep RESULT through unofficial → official; apply sport decision fields if any.
5. `hideStartDate` / `startText` follow latest schedule message.

### 3.7 Backend checklist (shared)

- [ ] Competition units + official trainings in the payload; victory ceremonies on CIS only (BE drops them for WMR)  
- [ ] Full `competitors[]` start list on every competition unit (NOC filter) — §3.3.1  
- [ ] Status transitions reflected on SSE  
- [ ] Placeholders resolved to `placeholderOpponents[].name` (discipline rules)  
- [ ] Placeholder → real competitor on schedule update  
- [ ] `startText` when `hideStartDate` (once API field exists)  
- [ ] IRM / WLT from `DT_RESULT` when applicable  
- [ ] Event-row after: all medallist rows including ties — §3.3.2  

---

## 4. Frontend — shared

### 4.1 Layout

- **When:** `startText` if `hideStartDate`, else `startDate`
- **Where:** venue / location
- **What:** discipline, event, phase/unit, unit number unless hidden
- **Who:** `competitors` or `placeholderOpponents`
- **Status:** §2 (never “Scheduled”)
- **Medal:** when `medalFlag` ∈ {1,3}
- **Live:** emphasize `liveFlag`
- Progress / decision indicators: **discipline pack**

### 4.2 Filters (product)

- Render the list the API returns. Victory-ceremony omission for WMR is a backend filter ([§3.1](#31-inclusion)), not a client hide
- Live only / hide finished use `liveFlag` / statuses
- Do not list `UNSCHEDULED` units unless a pack explicitly requires it

### 4.3 Card click redirects (shared)

Clicking a schedule card / match tile always opens the **unit results** surface for that unit’s RSC. **The href does not change by tile phase** (before / during / after) or by exceptional schedule status — the destination page renders start-list / live / final content from unit data.

| Surface | Builder (CI) | Path pattern |
|---------|--------------|--------------|
| **CIS** schedule list | `buildCisUnitResultsHref(rsc, lng, competition)` | `/{lng}/{competition}/{DISC}/{G}/{event}/{phase}/{unit}/results` |
| **WMR** (most sports) | `buildResultsSectionHref({ sectionId: 'results', rscCode })` | `/{lng}/{competition}/results/unit/{rsc}` |

**Rules:**

1. **RSC required.** CIS: if `rsc` is missing/blank, fall back to schedule list (`/{lng}/{competition}/schedule/list`). WMR: omit the tile link when unit code is invalid/empty.
2. **Always land on `results`.** Do not deep-link to side-rail panels (`start-list`, officials, …) or alternate page tabs (`bracket`, `summary`, …) from the schedule card — those stay in-app navigation after arrival.
3. **Competition / RSC casing.** CIS competition is **uppercase** (`OG2028`). WMR competition is the route slug (e.g. `la28`); unit RSC in the path is **lowercase**.
4. **RSC → CIS segments.** 34-char Tiger unit code → `DISC` (3) + `G` (1) + `event` (18) + `phase` (4) + `unit` (8). Phase/unit keep ODF dash padding (e.g. `FNL-`, `GPA-`, `000100--`).
5. **Sport-specific WMR paths.** If a discipline still uses the compact LA28 results tree, document it in the pack (today: **CKT** → `/{lng}/los-angeles-2028/results/ckt/...`). Others use `/results/unit/{rsc}`.

Per-discipline packs list concrete example URLs.

### 4.4 Frontend checklist (shared)

- [ ] Before / during / after render from schedule API  
- [ ] Exceptional statuses visible  
- [ ] Placeholders show BE `name`, not empty rows  
- [ ] No “Scheduled” badge  
- [ ] Live units visually distinct  
- [ ] Card click → unit results href (§4.3); same URL for before / during / after  

---

## 5. Cross-discipline API gaps

| Field | Status on Confluence | Needed when |
|-------|----------------------|-------------|
| `startText` | Missing | Any unit with `HideStartDate=Y` |
| `resultDecision` | Missing | Sports with unit-level `UI/RES_CODE` (e.g. FBL AET/PSO/FORFEIT) |
| `liveCurrentProgress` | Present (noted for sports like FBL) | Sports with live period/set/innings progress |
| `extendedResultInfo.finalResultDescription` | Present (CKT note on Confluence) | Cricket match-situation sentence from `UI/FINAL_RESULT` |
| PSO / period detail scores | Missing | Sports that show paren/detail scores (e.g. FBL PSO) |

---

## 6. Minimal shared cheat sheet

```
BEFORE:  DT_SCHEDULE[_UPDATE]  →  meta, status, teams|placeholders, startText?
DURING:  + DT_RESULT / DT_CURRENT     →  live score, optional liveCurrentProgress
AFTER:   + DT_RESULT (finished)       →  score, WLT, IRM, optional resultDecision
```
