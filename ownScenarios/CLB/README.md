# CLB — Schedule tile freezes

| Folder | Role |
|--------|------|
| [`01_Schedule_Tile_Mixed_Day`](01_Schedule_Tile_Mixed_Day) | Curated mixed “now” (M Speed SF live, Lead medals, Boulder before) |
| [`All_Events`](All_Events) | Mega freeze: **M Speed / M Boulder → unofficial medals**, **W Speed QFNL live**, **M Lead SFNL live** — see [All_Events/README.md](All_Events/README.md) |

---

# CLB — Schedule tile freeze (mixed day)

**LogicalDate:** `2026-09-09` (same day as FBL `01_Schedule_Tile_Mid_Group`)  
**Now:** `2026-09-09T09:33:00+02:00` (Men’s Speed SF2 live)  
**Ingest:** filename order (timestamp prefix). Same layout as `own_scenarios/FBL/01_Schedule_Tile_Mid_Group`.

Bodies come from `rawData/CLB` (test event). Calendar dates match FBL so both disciplines land on `schedulesPerDay/2026-09-09`.

## What the list should show (`schedule=Y` only)

| Tile | RSC | Status | Expect |
|------|-----|--------|--------|
| Women's Lead Final | `CLBWLEAD--------------FNL-000100--` | FINISHED | Three medallists (JPN Nakagawa, FRA Bertone, GBR Thompson-Smith). No climbing score. |
| Men's Speed Quarterfinals | `CLBMSPEED-------------QFNL--------` | FINISHED | Phase row. No IRM/times on tile. |
| Men's Speed Semifinals | `CLBMSPEED-------------SFNL--------` | RUNNING | Live highlight. |
| Men's Speed Finals | `CLBMSPEED-------------FNL---------` | SCHEDULED (no badge) | Medal marker. Placeholders on S units underneath. |
| Women's Boulder Final | `CLBWBOULDER-----------FNL-000100--` | GETTING_READY | Before / medal marker. No medallists yet. |

Pairs with `ScheduleFlag=S` are in the same `DT_SCHEDULE_UPDATE` so BE can decide to hide them. They must not flood the list if the phase `Y` row is already shown.

QF / SF / FNL tiles all open the **same** OSRP §8 Speed Final bracket (Heats).

## IRM / placeholders (results, not tile)

| Where | What |
|-------|------|
| Speed QF1 | `DNS` (Maimuratov KAZ) vs `DQB` (David NZL) |
| Speed SF1 | Winner Alipour (IRI) vs `NOCOMP` (walkover after QF1 IRMs) |
| Speed SF2 | LIVE Leonardo (INA) vs Zurloni (ITA) |
| Speed Big Final | Alipour + `TBD` (`WSF2`) |
| Speed Small Final | `NOCOMP` + `TBD` (`LSF2`) |
| QF2 | `UI/RERUN=Y` (re-run) — still no score on the tile |

## Playback

1. `DT_PARTIC_UPDATE` v1 → v2 → v3  
   - v1 and v2 are the full 76-athlete set (v2 is a resend).  
   - v3 patches `9100307` (Raboutou).
2. `DT_ENTRIES` for the three freeze events (latest from folder_01): Lead W, Speed M, Boulder W.
3. One `DT_SCHEDULE_UPDATE` with mixed statuses.
4. `DT_RESULT` / `DT_BRACKETS` / `DT_MEDALLISTS` as of 09:33.

Do not ingest `folder_11` (Men’s Speed Big/Small Final already finished) or Lead/Boulder LIVE from later folders.

**Acceptance criteria:** [AC.feature](AC.feature)

## Sources in rawData

| Freeze piece | rawData |
|--------------|---------|
| PARTIC / ENTRIES | `folder_01_00_01` |
| Speed QF IRM + unofficial | `folder_07_07_…/01_Quarterfinals` |
| Speed SF live freeze + brackets | `folder_09_07_…/02_Semifinals` (stop at SF2 `RUNNING`, brackets `UnitsComplete=5`) |
| Lead W official + medallists | `folder_17_13_Women's Lead_Final` |
| Boulder W start list | `folder_15_11_Women's Boulder_Final` (`DT_RESULT START_LIST`, not FINISHED) |
