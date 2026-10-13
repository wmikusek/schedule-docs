# CKT — Schedule tile freeze (mixed multi-day)

**LogicalDays:** `2026-09-06` … `2026-09-09` (4 days)  
**Now (after full ingest):** `2026-09-09T15:15:00+02:00`  
**Folder:** [`01_Schedule_Tile_Mixed_Days`](01_Schedule_Tile_Mixed_Days)  
**Ingest:** filename order (timestamp prefix).

Bodies from `rawData/CKT` (OG2028-ITL), dates remapped. Team identities and scores unchanged (except documented remaps below).

**API contract under test:** [DRES-33389](https://dgplatform.atlassian.net/jira/browse/DRES-33389) — CKT `result.result` overs, `soResult` (latest SO only), `toss` only pre-start.

## CC `@Unit` (OG2028 v1.6.0)

| Schedule | Count (CKT units) |
|----------|-------------------|
| **Y** | All competition matches + MEET + VICT |
| **N** | Phases + venue `OTHRFRG` |
| **S** | **0** |

`TMRY*` is `Y` in CC but **not present** in `DT_SCHEDULE` feeds. Listing = `Schedule=Y` units from the feed.  
OLY grouping: CKT has **no** row in `olympic-grouping-rules.csv` → **no `groupId`**.

## Team bootstrap (required)

1. `DT_PARTIC_UPDATE` — athletes  
2. `DT_PARTIC_TEAMS_UPDATE` — 12 team codes (`Type=T`)  
3. `DT_ENTRIES` `CKTMT20` + `CKTWT20` — who is in which team (GROUP / Composition)  
4. Then schedule / results  
5. End of day: **`DT_MEDALLISTS` → `DT_MEDALS`** (never reverse)

---

## Playback

| Step | File prefix | Message | Now | What to check |
|------|-------------|---------|-----|---------------|
| 1–3 | `080000`–`080003` | PARTIC + TEAMS + ENTRIES ×2 | 08:00 | teams / members loaded |
| 4 | `080004` | `DT_SCHEDULE_UPDATE` **v1** | 08:00 | 4-day shell, all competition units **SCHEDULED** |
| 5 | `080009` | `DT_SCHEDULE_UPDATE` **v2** | 08:00 | Same as v1 except M `GP2-000600` **RUNNING** (SO mid-case) |
| 6 | `080010*` (000–014) | `DT_RESULT` finished (W + M GP2 except 000600) | 08:00 | scores + overs ready for earlier days |
| 7 | `080010015` | `DT_RESULT` M12 LIVE **SO2IN1** | 08:00 | after SO1 tie (`13/0`–`13/0` still in ODF) → **`soResult` = SO2 only** (`8/1` / `YTB`) |
| 8 | `080010020` | `DT_RESULT` M12 OFFICIAL **TIED** (5× SO) | 08:00 | `soResult` = **latest** `SO5IN2` (`6/0` / `6/0`), not SO1 |
| 9 | `090000` | `DT_SCHEDULE_UPDATE` **v3** | 09:00 | W `GP1A000200` **RUNNING**; M12 FINISHED |
| 10 | `090001` | `DT_RESULT` W LIVE **SO1IN1** | 09:00 | single SO live: BAR `4/0`, IND **YTB** → `soResult.periodCode=SO1IN1` |
| 11 | `091500` | `DT_RESULT` W OFFICIAL **WON_SO** | 09:15 | 1 SO finished; `soResult` = `SO1IN2` (`12/0` / `11/2`); `FINAL_RESULT=WON_SO` |
| 12 | `091600` | `DT_SCHEDULE_UPDATE` **v4** | 09:16 | W `GP1A000200` **FINISHED** |
| 13 | `100000` | `DT_RESULT` Bronze OFFICIAL | 10:00 | `WON_WKT` |
| 14 | `142900` | `DT_RESULT` Gold **START_LIST** + toss | 14:29 | RSA `toss=FIELD`; both sides no innings score; schedule still **SCHEDULED** |
| 15 | `143000` | `DT_SCHEDULE_UPDATE` **v5** | 14:30 | Gold **RUNNING** |
| 16 | `143000500` | `DT_RESULT` Gold LIVE **IN1** | 14:30 | `PERIOD=IN1`, NZL `72/2`, RSA **YTB**; **`toss` omitted** (match started) |
| 17 | `143001` | `DT_RESULT` Gold LIVE **IN2** | 14:30 | `PERIOD=IN2`, scores `164/9` vs `19/0` |
| 18 | `151000` | `DT_RESULT` Gold OFFICIAL | 15:10 | `FINAL_RESULT=WON_RUN` → *New Zealand beat South Africa by 145 runs* |
| 19 | `151001` | `DT_SCHEDULE_UPDATE` **v6** | 15:10 | Gold **FINISHED** |
| 20 | `151010` | `DT_MEDALLISTS` | 15:10 | Men G/S/B (NZL / RSA / PAK) |
| 21 | `151011` | `DT_MEDALS` | 15:10 | standings **after** medallists — **men-only**, aligned with medallists |

Stop after step 4 for a pure “before” day. Full ingest ends at step 21 (`now = 15:15`).

---

## Day map (`schedulesPerDay`)

### 2026-09-06 — Women’s group (finished)

| RSC | Status | Expect |
|-----|--------|--------|
| `CKTWT20---------------GP1A000100--` | FINISHED | AUS vs IND · `WON_WKT` · scores ~87/2 vs 89/1 · overs in `result.result` · `finalResultDescription` |
| `CKTWT20---------------GP1B000100--` | FINISHED | NZL vs RSA · `WON_RUN` |

### 2026-09-07 — Men’s Second Round (finished)

| RSC | Status | Expect |
|-----|--------|--------|
| `CKTMT20---------------GP2-000100--` | FINISHED | NZL vs PAK · `WON_WKT` |
| `CKTMT20---------------GP2-000200--` | FINISHED | RSA vs GBR · `WON_WKT` |
| `CKTMT20---------------GP2-000300--` | FINISHED | NZL vs AUS · `WON_WKT` |

### 2026-09-08 — Men’s Second Round (finished, multi Super Over)

| RSC | Status | Expect |
|-----|--------|--------|
| `CKTMT20---------------GP2-000400--` | FINISHED | RSA vs IND · `WON_RUN` |
| `CKTMT20---------------GP2-000500--` | FINISHED | GBR vs AUS · `WON_WKT` |
| `CKTMT20---------------GP2-000600--` | FINISHED | PAK vs IND · **`TIED`** · five Super Overs · **`soResult` = latest SO5 only** |

### 2026-09-09 — NOW (after full ingest)

| RSC | Status | Expect |
|-----|--------|--------|
| `CKTWT20---------------GP1A000200--` | FINISHED | IND vs BAR · **`WON_SO`** (single Super Over) · `soResult` from `SO1IN2` |
| `CKTMT20---------------FNL-000200--` | FINISHED | Bronze **PAK** vs AUS · `WON_WKT` · `medalFlag=3` |
| `CKTMT20---------------FNL-000100--` | FINISHED | Gold NZL vs RSA · **`WON_RUN`** · `finalResultDescription` · `medalFlag=1` · medallists NZL / RSA / **PAK** |
| `CKTMT20---------------VICTMEDAL---` | SCHEDULED | Victory — **WMR hide** / CIS may keep |

Filter rows in every schedule version: `CKTGGEN…MEET000100` SCHEDULED; gender `MEET` **UNSCHEDULED** (never listed).

### Mid-playback (DRES-33389)

| Stop after | Now | Expect |
|------------|-----|--------|
| `080010015` | 08:00:10.015 | M12 **RUNNING** · `liveCurrentProgress=SO2IN1` · ODF still has SO1 `13/0`–`13/0` · **`soResult.periodCode=SO2IN1`**, PAK `8/1`, IND `YTB` — **not** SO1 scores |
| `080010020` | 08:00:10.020 | M12 OFFICIAL · `FINAL_RESULT=TIED` · **`soResult` = `SO5IN2`** (`6/0` / `6/0`) |
| `090001` | 09:00:01 | W **RUNNING** · `PERIOD=SO1IN1` · BAR `4/0`, IND `YTB` · `soResult` single SO |
| `091500` | 09:15 | W OFFICIAL · `WON_SO` · `soResult` = `SO1IN2` (`12/0` / `11/2`) |
| `142900` | 14:29 | Gold **SCHEDULED** · `ResultStatus=START_LIST` · RSA **`toss=FIELD`** · no innings scores yet |
| `143000500` | 14:30:00.5 | Gold **RUNNING** · `PERIOD=IN1` · NZL `72/2` · RSA **YTB** · **`toss` absent** |
| `143001` | 14:30:01 | Gold **RUNNING** · `PERIOD=IN2` · `164/9` vs `19/0` · **`toss` absent** |

---

## Redirects

| Surface | Example |
|---------|---------|
| CIS | `/en/OG2028/CKT/M/T20---------------/FNL-/000100--/results` |
| WMR | `/en/los-angeles-2028/results/ckt/mck/final/000100--` |

Href does not change by before / during / after.

**Acceptance criteria:** [AC.feature](AC.feature)

---

## Medals consistency

| Source | Content |
|--------|---------|
| `DT_MEDALLISTS` `CKTMT20` | NZL gold, RSA silver, **PAK** bronze |
| `DT_MEDALS` | **Same only** — `LastEvent=CKTMT20`, `FinishedEvents=1` / `TotalEvents=2`, no W medals |

**Fabricated:** `DT_MEDALS` (aligned to men’s medallists). Bronze medallist set to **PAK** to match bronze `DT_RESULT` (`WON_WKT`, PH_TEAM Pos1=PAK) — raw dump had a later AUS medallists flip that disagreed with the result.

**Fabricated on gold OFFICIAL `DT_RESULT`:** raw dump ended as `NO RESULT` (rain) with both `WLT=T` and RSA `19/0` (innings not closed). Replaced with `WON_RUN` + `PH_TEAM` NZL/RSA + `SCORE=145`, `WLT` W/L, `Rank` 1/2, and RSA score **`19/10`** (all out) so BE does not treat the match as a draw/incomplete.

---

## Not covered / raw limits

| Case | Why |
|------|-----|
| Men’s Group Stage / Women’s GP2–FNL | Not packed into this freeze (available under `rawData/CKT` if needed later) |
| Women’s `DT_MEDALLISTS` | Out of scope for this freeze |
| OFFICIAL with **exactly** two Super Overs | Raw only has 1-SO (`WON_SO`) or 5-SO (`TIED`); **2-SO latest-only** covered via LIVE `SO2IN1` on M12 |
| `Schedule=S` | None in CC for CKT |

**Remap only (not fabricated bodies):** all `ER/TOSS Value="BOWL"` → **`FIELD`** (SC@Toss). Schedule mid-states are **copies** of freeze schedules with `ScheduleStatus` edited for the unit under test.

---

## Sources in rawData

| Freeze piece | rawData |
|--------------|---------|
| PARTIC / TEAMS / ENTRIES / schedule shell | `01_Pre-Competition` (+ M07 rich schedule for StartLists) |
| W finished GP1 | `02_Group Stage Women` W01 / W02 |
| W LIVE SO1IN1 + OFFICIAL WON_SO | `02_…/W03` `…133853552…` / `…134717790…` |
| M GP2-000100…000500 | `06_Second Round Men` M07–M11 |
| M12 LIVE SO2IN1 (after SO1 tie) | `06_…/M12` `…141215250…` |
| M12 OFFICIAL TIED (5× SO) | `06_…/M12` (previous freeze OFFICIAL body) |
| Gold START_LIST + toss | `07_Medal Matches Men` M14 `…131236811…` |
| Gold LIVE IN1 / IN2 | M14 `…133955599…` / `…143254082…` |
| Bronze / Gold OFFICIAL / MEDALLISTS | `07_Medal Matches Men` M13 / M14 |
| MEDALS | **Fabricated** (aligned to men’s medallists) |
