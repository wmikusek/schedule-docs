# ARC — Schedule tile freezes

| Folder | Role |
|--------|------|
| [`01_Schedule_Tile_Mixed_Day`](01_Schedule_Tile_Mixed_Day) | Curated mixed day (live gold, medals, Schedule=S) — walkthrough below |
| [`All_Events`](All_Events) | Mega freeze: **Compound Mixed + Men’s Individual** through finals (no LIVE/PDF) — see [All_Events/README.md](All_Events/README.md) |

---

# ARC — Schedule tile freeze (mixed day)

**LogicalDate:** `2026-09-09` (same day as FBL `01_Schedule_Tile_Mid_Group` and CLB `01_Schedule_Tile_Mixed_Day`)  
**Now:** `2026-09-09T14:51:00+02:00` (Women’s Individual Gold live, set 3)  
**Ingest:** filename order (timestamp prefix). Same layout as `own_scenarios/FBL/01_Schedule_Tile_Mid_Group`.

Bodies: Recurve names/teams from `rawData/ARC` (Paris 2024). Dates remapped to `2026-09-09`. Compound Mixed QUAL subunits are LA28-only (not in the Paris dump) and are fabricated from CC `OG2028` v1.5.0. `DT_RESULT` / `DT_MEDALLISTS` are fabricated (the Paris dump has schedule/brackets only).

All ARC phases are `Schedule=N` — **no phase cards**. Daily API takes only event units with CC `Schedule=Y` that are not `UNSCHEDULED`.

## Walkthrough (now = 14:51)

Default list, in start-time order. Click goes to **that tile’s unit-results RSC** unless noted.

### 1. Recurve Ranking Round

**Women’s Individual QUAL** `ARCWINDIVID-----------QUAL000100--` — FINISHED, 08:00. Only ranking unit on the default list. No H2H.

Team/Mixed QUAL are **not** next to it. Those three units are CC `Schedule=S` (same session as Individual QUAL):

| RSC | CC | Default | By Event |
|-----|----|---------|----------|
| `ARCWTEAM3-------------QUAL000100--` | S | hidden | listed |
| `ARCMTEAM3-------------QUAL000100--` | S | hidden | listed |
| `ARCXTEAM2-------------QUAL000100--` | S | hidden | listed |

`S` is visibility only, not a redirect. From By Event, click still opens that QUAL unit RSC.

### 2. Compound Mixed QUAL (nested)

Parent `ARCXTEAMC-------------QUAL00010000` — `Group=Unit`, CC `N` — **never listed**.

Listed subunits (`Group=SubUnit`, CC `Y`):

1. **Women’s Compound QUAL** `…QUAL00010001` — FINISHED  
2. **Men’s Compound QUAL** `…QUAL00010002` — GETTING_READY, 15:00, no live score  

**Only ARC redirect.** Both tiles open the parent:

`QUAL00010001` / `QUAL00010002` → `ARCXTEAMC-------------QUAL00010000`

One Compound Mixed QUAL page (OSRP C73C), not Compound Individual events. See [Schedule RSC overrides](https://dgplatform.atlassian.net/wiki/spaces/SCDLA/pages/3229941783/Schedule+RSC+overrides).

### 3. Women’s Team — event already has medals

3. **Bronze** `ARCWTEAM3-------------FNL-000200--` — FINISHED, NED 6–2 MEX, `medalFlag=3`  
4. **Gold** `ARCWTEAM3-------------FNL-000100--` — FINISHED, KOR 5–1 CHN, `medalFlag=1`  

Event medallists: KOR / CHN / NED. Click → that match’s unit results. No override. Bronze and gold are **not grouped**.

### 4. Women’s Individual — eliminations + finals

Hidden even though CC `Y`:

- `R64-000100--` — `UNSCHEDULED` + `BYE`  
- `TMRY000500--` — session row, OVR `UNSCHEDULED` (CC still `Y`)

On the list:

5. **1/8** `8FNL000600--` — FINISHED, Kaur 6 vs Choirunisa **DNS**, no medal  
6. **Bronze** `FNL-000200--` — FINISHED, Jeon 6–2 Barbelin, `medalFlag=3`  
7. **Gold** `FNL-000100--` — **RUNNING**, Lim 4 – Nam 2, Set 3, live highlight, `medalFlag=1`  

Bronze and gold stay **separate**. Click → unit RSC. No override.

### 5. Recurve Mixed — rest of the day (SCHEDULED, no badge)

8. **1/8** `8FNL000100--` — KOR vs TPE, **15:30** (clock shown)  
9. **1/8** `8FNL000200--` — ITA vs FRA, **15:30**, `UnitNum=129`  
10. **QF** `QFNL000100--` — KOR vs **Winner 129**, `HideStartDate=Y` (no clock)  
11. **SF** `SFNL000100--` / `SFNL000200--` — empty, `UnitNum` 142 / 143, no clock  
12. **Gold** `FNL-000100--` — **Winner 142** vs **Winner 143**, medal, `HideStartDate=Y` + `HideUnitNum=Y`, **not** grouped with 1/8  

Click → unit RSC. No override.

### Redirects

| Tile | href |
|------|------|
| Compound QUAL W `…QUAL00010001` | **override** → `ARCXTEAMC-------------QUAL00010000` |
| Compound QUAL M `…QUAL00010002` | **override** → `ARCXTEAMC-------------QUAL00010000` |
| every other listed tile | unit-results of **that** RSC, same before / during / after |

Other rows on the Confluence override list are **CLB Speed** (QF/SF/FNL phases → `FNL-000100`), not ARC.

## Tile cheat sheet (`schedule=Y` only)

| Tile | RSC | Status | Expect |
|------|-----|--------|--------|
| Women's Individual Ranking Round | `ARCWINDIVID-----------QUAL000100--` | FINISHED | Qual unit. No H2H. Team/Mixed QUAL **not** listed next to it. |
| Women's Compound Qualification | `ARCXTEAMC-------------QUAL00010001` | FINISHED | SubUnit of Compound Mixed. Parent `…QUAL00010000` hidden. |
| Men's Compound Qualification | `ARCXTEAMC-------------QUAL00010002` | GETTING_READY | SubUnit. Getting Ready badge. No live score. |
| Women's Team Bronze | `ARCWTEAM3-------------FNL-000200--` | FINISHED | NED 6 – 2 MEX. `medalFlag=3`. |
| Women's Team Gold | `ARCWTEAM3-------------FNL-000100--` | FINISHED | KOR 5 – 1 CHN. `medalFlag=1`. Event medallists: KOR / CHN / NED. |
| Women's Individual 1/8 | `ARCWINDIVID-----------8FNL000600--` | FINISHED | Kaur (IND) 6 vs Choirunisa (INA) `DNS`. IRM layout, no medal. |
| Women's Individual Bronze | `ARCWINDIVID-----------FNL-000200--` | FINISHED | Jeon (KOR) 6 – 2 Barbelin (FRA). `medalFlag=3`. **Do not group** with gold. |
| Women's Individual Gold | `ARCWINDIVID-----------FNL-000100--` | RUNNING | Lim 4 – Nam 2 (KOR). Live highlight. `liveCurrentProgress` = Set 3. `medalFlag=1`. |
| Mixed Team 1/8 | `ARCXTEAM2-------------8FNL000100--` | SCHEDULED (no badge) | KOR vs TPE. Show start time (first Mixed phase of the remaining day). |
| Mixed Team 1/8 | `ARCXTEAM2-------------8FNL000200--` | SCHEDULED (no badge) | ITA vs FRA. `UnitNum=129` (source for Winner 129). |
| Mixed Team Quarterfinal | `ARCXTEAM2-------------QFNL000100--` | SCHEDULED (no badge) | KOR vs **Winner 129**. `HideStartDate=Y` — no clock. |
| Mixed Team Semifinal | `ARCXTEAM2-------------SFNL000100--` | SCHEDULED (no badge) | No opponents yet. `HideStartDate=Y`. `UnitNum=142`. |
| Mixed Team Semifinal | `ARCXTEAM2-------------SFNL000200--` | SCHEDULED (no badge) | No opponents yet. `HideStartDate=Y`. `UnitNum=143`. |
| Mixed Team Gold | `ARCXTEAM2-------------FNL-000100--` | SCHEDULED (no badge) | **Winner 142** vs **Winner 143**. Medal marker. `HideStartDate=Y`, `HideUnitNum=Y`. **Not grouped**. |

In the same `DT_SCHEDULE_UPDATE` but **not** on the default list:

| RSC | Flag / status | Why hidden |
|-----|----------------|------------|
| `ARCWTEAM3-------------QUAL000100--` | `S` FINISHED | Recurve Team QUAL concurrent with Individual QUAL |
| `ARCMTEAM3-------------QUAL000100--` | `S` FINISHED | same |
| `ARCXTEAM2-------------QUAL000100--` | `S` FINISHED | Recurve Mixed QUAL concurrent with Individual QUAL |
| `ARCXTEAMC-------------QUAL00010000` | `N` FINISHED | Compound QUAL parent (`Group=Unit`) |
| `ARCWINDIVID-----------R64-000100--` | `Y` UNSCHEDULED + `BYE` | OSRP: bye units omitted |
| `ARCWINDIVID-----------TMRY000500--` | `Y` UNSCHEDULED | Session TMRY sent by OVR as unscheduled |

By Event filter: the three Recurve Team/Mixed QUAL `S` units **must** appear.

## IRM / placeholders (results, not always on the tile)

| Where | What |
|-------|------|
| Women's 1/8 `8FNL000600` | Kaur `SETS 6 W` vs Choirunisa `IRM_SETS DNS L` |
| Mixed QF | Known KOR + `TBD` / `PreviousWLT=W` / `PreviousUnit=…8FNL000200--` → **Winner 129** |
| Mixed Gold | both sides `TBD` → **Winner 142** / **Winner 143** |
| Women's R64 `000100` | Kaur vs `BYE` — unit not listed |

No `resultDecision` on any ARC tile.

## Playback

1. `DT_PARTIC_UPDATE` — 22 athletes used on the freeze tiles.  
2. `DT_PARTIC_TEAMS_UPDATE` — 8 team identities (code/name/org). No athlete composition here.  
3. `DT_ENTRIES` for `ARCWTEAM3` and `ARCXTEAM2` — team structure (`Entry/Composition`).  
4. One `DT_SCHEDULE_UPDATE` with mixed Y/S/N flags and statuses.  
5. `DT_RESULT` + `DT_MEDALLISTS` as of 14:51.

Do not expect Paris `DT_RESULT` from `rawData/ARC` — it is not in that dump.

**Acceptance criteria:** [AC.feature](AC.feature)

## Sources in rawData

| Freeze piece | rawData / notes |
|--------------|-----------------|
| PARTIC / TEAMS | `DT_PARTIC`, `DT_PARTIC_TEAMS` (subset of codes on the tiles; no Composition) |
| Team composition | `DT_ENTRIES` per event RSC (`ARCWTEAM3`, `ARCXTEAM2`) |
| W Team gold/bronze start lists | `DT_SCHEDULE_UPDATE` ~306 (2024-07-30) |
| W Individual gold/bronze start lists | `DT_SCHEDULE_UPDATE` ~702 / ~704 (2024-08-03) |
| Mixed 8FNL KOR–TPE / ITA–FRA | `DT_SCHEDULE_UPDATE` ~306 |
| Compound QUAL subunits | CC `@Unit` LA28 (`Group=SubUnit`, Schedule Y/N) — not in Paris |
| Scores / medallists | Fabricated from ODF ARC `SETS` / `IRM_SETS` / `DT_MEDALLISTS` |
