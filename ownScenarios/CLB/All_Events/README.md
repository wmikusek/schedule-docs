# CLB — All_Events freeze (M Speed → medals · W Speed QFNL live · M Lead SFNL live · M Boulder → gold)

**Folder:** [`All_Events`](.)  
**Events:** `CLBMSPEED` · `CLBWSPEED` (stop mid-QFNL) · `CLBMLEAD` (stop mid-SFNL) · `CLBMBOULDER`  
**Ingest:** filename order `2026-09-09-HHMMSSmmm-…` (playback order only). ODF bodies keep ITL competition dates (July 2028) — same pattern as ARC `All_Events`.  
**Pack:** [`docs/CLB/schedule-tile-requirements.md`](../../../docs/CLB/schedule-tile-requirements.md)  
**CC:** OG2028 v1.6.0 · ODF dump `OG2028-CLB-0.2`

**188 XML** — schedule-tile inputs (no PDF / RECORD / COMMUNICATION; LIVE only for W Speed QF1 + M Lead SFNL).

## Selection rules

| Keep | Skip |
|------|------|
| Init `PARTIC` + `ENTRIES` for MSPEED / WSPEED / MLEAD / MBOULDER + init `SCHEDULE` shell + scoped `CONFIG` | Other events’ result streams (W Boulder, W Lead, M Lead FNL, …) |
| All `DT_SCHEDULE_UPDATE` that touch scope RSC (incl. Speed **phase** rows) | Schedule-only noise for out-of-scope events after init |
| `DT_RESULT` START_LIST / INTERMEDIATE / UNOFFICIAL / OFFICIAL / PARTIAL (last per status per unit) | LIVE except W Speed `QFNL000100` and M Lead `SFNL000100` |
| M Speed + M Boulder `DT_MEDALLISTS` **PARTIAL / UNOFFICIAL only** | **`DT_MEDALLISTS` OFFICIAL** · `DT_MEDALLISTS_DISCIPLINE` · all `DT_MEDALS` |
| Last M Speed `DT_BRACKETS` OFFICIAL | Intermediate brackets flood |

### Women’s Speed stop (QFNL live)

Include `folder_08_…/01_…Quarterfinals` through seq **`00481`**.  
Exclude `00482+`. Phase `CLBWSPEED-------------QFNL--------` stays **`RUNNING`**.

### Men’s Lead stop (SFNL live)

Include `folder_06_06_ Men's Lead_Semifinal` through seq **`00406`** (last `DT_RESULT` LIVE).  
Exclude `00407+` (schedule FINISHED / UNOFFICIAL / OFFICIAL).  
Unit `CLBMLEAD--------------SFNL000100--` stays **`RUNNING`**.

## Totals

| Type | Count |
|------|------:|
| `DT_PARTIC_UPDATE` | 3 |
| `DT_ENTRIES` | 7 |
| `DT_CONFIG` | 7 |
| `DT_SCHEDULE_UPDATE` | 79 |
| `DT_RESULT` | 85 |
| `DT_BRACKETS` | 4 |
| `DT_MEDALLISTS` | 3 (PARTIAL×1 + UNOFFICIAL×2) |
| `DT_MEDALS` | 0 (intentionally omitted — medals still unofficial) |

## Timeline (high level)

| Phase | Approx. prefix | Content |
|-------|----------------|---------|
| Bootstrap | `080000`–`08001x` | PARTIC, ENTRIES (M/W Speed, M Lead, M Boulder), CONFIG, init schedule |
| M Speed QUAL / W Speed QUAL | … | Heat parents → OFFICIAL |
| M Boulder SFNL | … | → OFFICIAL · FINISHED |
| **M Lead SFNL live** | `080105` / `080141` | Schedule **RUNNING** · RESULT **LIVE** — **stop** (no FINISHED) |
| M Speed QFNL → FNL | … | Phases FINISHED · **MEDALLISTS UNOFFICIAL** (stop — no OFFICIAL / no `DT_MEDALS`) |
| W Speed QFNL live | … | Phase **RUNNING** · QF1 **LIVE** — **stop** |
| M Boulder FNL | … | RESULT OFFICIAL · **MEDALLISTS UNOFFICIAL** (stop) |

Full ingest ends after last Boulder UNOFFICIAL medallists (no `DT_MEDALS`).

## End-state (`schedulesPerDay` by competition date)

Bodies use **2028-07-2x** `StartDate` (not remapped). After full ingest:

| Day | Tile (CC `Schedule=Y`) | Status |
|-----|------------------------|--------|
| `2028-07-24` | M/W Speed QUAL heat parents | FINISHED |
| `2028-07-25` | M Boulder SFNL | FINISHED |
| `2028-07-25` | **M Lead SFNL** `…SFNL000100--` | **RUNNING** |
| `2028-07-26` | M Speed QFNL / SFNL / FNL phases | FINISHED |
| `2028-07-26` | **W Speed QFNL phase** | **RUNNING** |
| `2028-07-27` | M Boulder FNL | FINISHED (+ **unofficial** medallists) |

## Medals (UNOFFICIAL only — no OFFICIAL / no `DT_MEDALS`)

| Event | Last `DT_MEDALLISTS` | Gold | Silver | Bronze |
|-------|----------------------|------|--------|--------|
| Men’s Speed | UNOFFICIAL (`00581`) | IRI `9106207` | ITA `9102693` | INA `9100329` |
| Men’s Boulder | UNOFFICIAL (`00942`) | ESP `9103915` | USA `9100303` | CHN `9103696` |

No Lead medals (SFNL still live). OFFICIAL medallists deliberately excluded so the tile stays in **unofficial** medal state.

## Schedule tile notes

- Speed QF/SF/FNL: list **phase** RSC; pairs are `S`.
- Speed QUAL: heat parents `Y`; race subunits `S`.
- Boulder / Lead SFNL·FNL: unit `Y`.
- RSC overrides: Speed phase tiles → `…FNL-000100--`.
- Grouping CSV: no CLB row → typically no `groupId`.

## Sources (rawData)

| Slice | Path |
|-------|------|
| Bootstrap | `folder_01_00_01` |
| M Speed QUAL | `folder_02_03_Men's Speed_Qualifications` |
| W Speed QUAL | `folder_03_04_Women's Speed_Qualifications` |
| M Boulder SFNL | `folder_05_02_Men's Boulder_Semifinal` |
| M Lead SFNL live | `folder_06_06_ Men's Lead_Semifinal` (≤ `00406`) |
| M Speed QFNL | `folder_07_07_Men's_Speed Finals/01_…Quarterfinals` |
| W Speed QFNL live | `folder_08_08_Women's_ Speed Finals/01_…Quarterfinals` (≤ `00481`) |
| M Speed SFNL | `folder_09_07_Men's_Speed Finals/02_…Semifinals` |
| M Speed FNL + medallists | `folder_11_07_Men's_Speed Finals/03_…Finals` |
| M Boulder FNL + medallists | `folder_14_10_Men's Boulder_Final` |

## Fabricated

None.

## Related

- Curated mixed “now” day: [`../01_Schedule_Tile_Mixed_Day`](../01_Schedule_Tile_Mixed_Day)  
- Acceptance: [`../AC.feature`](../AC.feature)
