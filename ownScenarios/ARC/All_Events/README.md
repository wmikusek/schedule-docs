# ARC — All_Events freeze (Compound Mixed + Men’s Individual → finals)

**Folder:** [`All_Events`](.)  
**Events:** `ARCXTEAMC` (Compound Mixed Team) · `ARCMINDIVID` (Recurve Men’s Individual)  
**Ingest:** filename order `2026-09-09-HHMMSSmmm-…` (playback order only). ODF bodies keep ITL competition dates (July 2028).  
**Pack:** [`docs/ARC/schedule-tile-requirements.md`](../../../docs/ARC/schedule-tile-requirements.md)  
**CC:** OG2028 v1.6.0

**527 XML** — schedule-tile inputs only (no LIVE / PDF / RECORD / LOCAL / BRACKETS / RANKING).

> If you meant **Recurve** Mixed (`ARCXTEAM2`) instead of Compound Mixed, say so and we can swap Day 2 → Day 7.

## Selection rules

| Keep | Skip |
|------|------|
| PARTIC + TEAMS + ENTRIES for the 2 events | Other events’ ENTRIES |
| Event + unit `DT_CONFIG` for the 2 events | CONFIG for other events |
| `DT_SCHEDULE_UPDATE` from Event Configuration (full shell) + later UPDATEs that mention `ARCMINDIVID*` / `ARCXTEAMC*` units | Schedule UPDATEs that only touch other events |
| `DT_RESULT` **START_LIST / INTERMEDIATE / UNOFFICIAL / OFFICIAL** (last per status per unit) | **LIVE** |
| Last `DT_MEDALLISTS` per event → matching `DT_MEDALS` | Full-tournament medals that still count women/team/recurve-mixed |

## Totals

| Type | Count |
|------|------:|
| `DT_PARTIC_UPDATE` / `DT_PARTIC_TEAMS_UPDATE` | 1 / 1 |
| `DT_ENTRIES` | 2 |
| `DT_CONFIG` | 60 |
| `DT_SCHEDULE_UPDATE` | 262 |
| `DT_RESULT` | 197 (66 units) |
| `DT_MEDALLISTS` | 2 |
| `DT_MEDALS` | 2 |

`DT_RESULT` statuses: START_LIST ×66 · UNOFFICIAL ×66 · OFFICIAL ×65  
(`ARCMINDIVID-----------R32-000500--` has no OFFICIAL in rawData — only UNOFFICIAL.)

## Timeline (high level)

| Phase | Prefix band (approx.) | Content |
|-------|----------------------|---------|
| Bootstrap | `080000`–`08000x` | PARTIC, TEAMS, ENTRIES ×2, event CONFIG, initial schedule |
| Day 1 QUAL | … | Compound Mixed + Men Ind QUAL → OFFICIAL; early elim START_LISTs |
| Day 2 Compound Mixed | … → `080219`/`080220` | 8FNL → QF → SF → Bronze/Gold OFFICIAL · **MEDALLISTS → MEDALS** (XTEAMC only) |
| Days 3–4 / 6 Men Ind elim | … | R64 / R32 / 8FNL results (no LIVE) |
| Day 8 Men Ind finals | … → `080751` | QF → SF → Bronze/Gold OFFICIAL · **MEDALLISTS** |
| Close | `080845` → `080846` | Men Ind **MEDALLISTS** then fabricated **MEDALS** (nothing after except that pair) |

Stop after initial schedule for pure **before**. Full ingest ends at `080846`.

**Playback order note:** late-timestamped Men Ind RESULT/SCHEDULE from the dump were moved **before** Men Ind `DT_MEDALLISTS`, so the stream ends `… → FNL OFFICIAL → MEDALLISTS → MEDALS`. No messages added.

## Medals (aligned with OFFICIAL FNL)

| Event | Gold | Silver | Bronze |
|-------|------|--------|--------|
| Compound Mixed | MEX `…MEX01` | IND `…IND01` | GBR `…GBR01` |
| Men’s Individual | TUR `9005002` | COL `9005644` | ITA `9005454` |

Winners match `WLT=W` on FNL OFFICIAL RESULT.

## Schedule tile notes

- `ARCXTEAMC-------------QUAL000100--` is CC **Schedule=S** — often hidden on default list; visible under By Event.
- Men Ind QUAL is **Schedule=Y**.
- Bye / `UNSCHEDULED` units: do not list (pack + common).
- Grouping: session+event for match rounds; **FNL-** not grouped.
- No LIVE → no mid-match score / `liveCurrentProgress` in this freeze (use Mixed_Day for live gold).

## Sources (rawData)

| Slice | Path |
|-------|------|
| Bootstrap | `00_Event_Configuration/` (filtered) |
| Compound QUAL START_LIST | `01_Pre-Competiton/` |
| Day 1 QUAL + schedule | `02_Day 1_Team_Qualification Round/` |
| Compound Mixed → medals | `03_Day 2_Mixed_Team_Compound/` |
| Men Ind R64/R32 | `04_Day 3_…` · `05_Day 4_…` |
| Men Ind 8FNL START_LIST | `06_Day 6_…` (shared day folders) |
| Men Ind QF→Gold + medallists | `08_Day 8_Individual_Men/` |

## Fabricated

| File | Why |
|------|-----|
| `2026-09-09-080846000-DT_MEDALS--ARC--------------------------------.xml` | Raw Day-8 `DT_MEDALS` still counts other finished ARC events (women/teams/recurve mixed). Rebuilt standings for **ARCXTEAMC + ARCMINDIVID only**, from freeze medallists. |

## Related

- Live gold + multi-event mixed day: [`../01_Schedule_Tile_Mixed_Day`](../01_Schedule_Tile_Mixed_Day)  
- Acceptance: [`../AC.feature`](../AC.feature)
