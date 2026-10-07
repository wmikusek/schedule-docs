# FEN — Schedule tile freeze 01 (mixed day)

**LogicalDate:** `2026-09-09`  
**Folder:** [`01_Schedule_Tile_Mixed_Day`](.)  
**Ingest:** filename order (timestamp prefix).  
**Now after full ingest:** `2026-09-09T17:00:00+02:00`  
**Pack:** [`docs/FEN/schedule-tile-requirements.md`](../../../docs/FEN/schedule-tile-requirements.md)

Bodies from `rawData/FEN` (OG2028-ITL). Dates remapped to `2026-09-09`. Scores / WLT / medallists unchanged except curated schedules + scoped `DT_MEDALS`.

**CC `@Unit`:** Y=585 · N=19 · **S=0** (no Schedule=S units in freeze).

**Grouping (CSV):** `FEN` → `GroupId = {Session}_{PhaseRSC}`  
This freeze uses three sessions so CSV can form groups:

| Session | Phase RSC pattern | Units (for grouping) |
|---------|-------------------|----------------------|
| `FEN01` | `…R32-` / `…FNL-` (MSABRE) | 4× R32 + gold + bronze individual |
| `FEN04` | `…QFNL` (WTEAMEPEE) | 4× Women’s Épée Team Table of 8 |
| `FEN09` | `…QFNL` / `…SFNL` / `…FNL-` (WTEAMSABR) | 4 QF + 2 SF + gold + bronze team |

---

## Playback

| Step | File prefix | Message | Now (approx) | What to check |
|------|-------------|---------|--------------|---------------|
| 1 | `080000000` | `DT_PARTIC_UPDATE` | 08:00 | athletes |
| 2 | `080000500` | `DT_PARTIC_TEAMS_UPDATE` | 08:00 | teams |
| 3 | `080001*` | `DT_ENTRIES` ×3 | 08:00 | MSABRE / WTEAMEPEE / WTEAMSABR |
| 4 | `080002000` | `DT_SCHEDULE_UPDATE` **v1** | 08:00 | **18 units SCHEDULED** — before; names where StartList present |
| 5 | `130500000` | `DT_SCHEDULE_UPDATE` **v2** | 13:05 | Mid statuses (MSABRE FNL already FINISHED; WTEAMSABR mid) |
| 6 | `130501000` | `DT_RESULT` LIVE | 13:05 | WTEAMSABR **QF4 RUNNING** + live score |
| 7 | `130502000` | `DT_RESULT` OFFICIAL | 13:05 | **V(T)** Men’s Sabre R32-000500 (14–14) |
| 8 | `130503000` | `DT_RESULT` OFFICIAL | 13:05 | **V(T)** Women’s Épée Team QFNL000200 (36–36) |
| 9 | `130504–506` | `DT_RESULT` OFFICIAL | 13:05 | WTEAMSABR QF1–3 scores |
| 10 | `170000000` | `DT_SCHEDULE_UPDATE` **v3** | 17:00 | All 18 **FINISHED** |
| 11 | `170001–005` | `DT_RESULT` | 17:00 | WTEAMSABR SF + bronze + gold + QF4 official |
| 12 | `170006–007` | `DT_RESULT` | 17:00 | **MSABRE individual** gold + bronze official |
| 13 | `170009000` | `DT_MEDALLISTS` | 17:00 | **MSABRE** G/S/B (individual) |
| 14 | `170010000` | `DT_MEDALLISTS` | 17:00 | **WTEAMSABR** G/S/B (team) |
| 15 | `170011000` | `DT_MEDALS` | 17:00 | Standings for **2 events** only |

Stop after step 4 for “before only”; after step 9 for “mid / V(T) + live QF”; full ingest for medals.

---

## After mid ingest (`now ≈ 13:05`)

### V(T) wins (pack §3.4)

| RSC | Expect |
|-----|--------|
| `FENMSABRE-------------R32-000500--` | FINISHED · KOR **V(T)** 14 vs HUN 14 |
| `FENWTEAMEPEE----------QFNL000200--` | FINISHED · winner **V(T)** 36–36 |

Do **not** treat `UI/TOSS` A/B as the schedule `V(T)` label — use `@WLT`.

### Women’s Sabre Team — mid

| RSC | Status | Expect |
|-----|--------|--------|
| QF1–QF3 | FINISHED | Scores + W/L |
| QF4 | **RUNNING** | Live score / `liveFlag` |
| SF + FNL gold/bronze | SCHEDULED | Medal flags on gold (`1`) / bronze (`3`) |
| MSABRE FNL gold/bronze | **FINISHED** | Individual medals already done by mid stop |

### Grouping

Same session + same phase RSC → one group (e.g. four `FEN09` + `…QFNL` QFs).

---

## After full ingest (`now = 17:00`)

### Men’s Sabre Individual — medals

| Tile | RSC | Status | Expect |
|------|-----|--------|--------|
| Gold | `FENMSABRE-------------FNL-000100--` | FINISHED | SAMELE (ITA) **15** – APITHY (FRA) **13** · `medalFlag=1` |
| Bronze | `FENMSABRE-------------FNL-000200--` | FINISHED | OH (KOR) **15** – EGY **7** · `medalFlag=3` |
| Medallists | `DT_MEDALLISTS` MSABRE | OFFICIAL | G Samele · S Apithy · B Oh |

### Women’s Sabre Team — medals

| Tile | RSC | Status | Expect |
|------|-----|--------|--------|
| Gold | `FENWTEAMSABR----------FNL-000100--` | FINISHED | ALG **45** – ITA **40** · `medalFlag=1` · winner ALG |
| Bronze | `FENWTEAMSABR----------FNL-000200--` | FINISHED | KOR **45** – HUN **43** · `medalFlag=3` |
| Medallists | `DT_MEDALLISTS` WTEAMSABR | OFFICIAL | ME_GOLD ALG · ME_SILVER ITA · ME_BRONZE KOR |

### `DT_MEDALS` (2 events)

| NOC | M | W | TOT |
|-----|---|---|-----|
| ITA | 1G | 1S | 2 |
| ALG | — | 1G | 1 |
| FRA | 1S | — | 1 |
| KOR | 1B | 1B | 2 |

Consistency: each medallist matches the corresponding RESULT winner.

### Redirects

Every tile → unit-results of **that** RSC ([pack §4.3](../../../docs/FEN/schedule-tile-requirements.md)).

Example gold CIS: `/en/OG2028/FEN/W/TEAMSABR----------/FNL-/000100--/results`  
WMR: `/en/la28/results/unit/fenwteamsabr----------fnl-000100--`

---

## Sources in rawData

| Piece | rawData |
|-------|---------|
| PARTIC / TEAMS / ENTRIES | `01_Pre-Competiton` |
| Unit shells (WTEAMSABR) | `10_DAY09_…` schedule UPDATEs |
| Unit shells (MSABRE R32) | `02_DAY01_…` |
| Unit shells (WTEAMEPEE QF) | `05_DAY04_…` |
| V(T) individual RESULT | `02_DAY01_…/…R32-000500…` OFFICIAL |
| V(T) team RESULT | `05_DAY04_…/…QFNL000200…` OFFICIAL |
| WTEAMSABR QF/SF/FNL RESULT + MEDALLISTS | `10_DAY09_…` |

---

## Fabricated / curated

| Piece | Note |
|-------|------|
| Schedule v1 / v2 / v3 | Curated FULL messages (**18 units**; sessions FEN01 / FEN04 / FEN09). Not a raw single-file copy. |
| `FENMSABRE…R32-000200/000300` shells | Cloned from R32-000100 **without StartList** (grouping only) |
| Other WTEAMEPEE QF siblings without StartList | Cloned from QFNL000200 when harvest empty |
| `DT_MEDALS` | **Fabricated** scoped to **MSABRE + WTEAMSABR** only. Raw full-tournament standings discarded. |

**ODF verifier:** `validate_xml_structure` on fabricated `DT_MEDALS` timed out in the build session — re-run locally if needed.

**Acceptance criteria:** [../AC.feature](../AC.feature)
