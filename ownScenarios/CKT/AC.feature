Feature: CKT schedule tiles — full tournament freeze
  Background:
    Given competition OG2028-ITL
    And the CKT messages in own_scenarios/CKT/02_Schedule_Tile_Full_Tournament have been ingested in filename order

  Scenario: Team bootstrap precedes schedule
    Given only messages up to 2026-09-06-080003000 have been ingested
    Then DT_PARTIC_UPDATE and DT_PARTIC_TEAMS_UPDATE have loaded athletes and Type=T teams
    And DT_ENTRIES for CKTMT20 and CKTWT20 define team compositions
    And schedule messages may start immediately after bootstrap

  Scenario: Full schedule feed covers all competition units
    Given now is 2026-09-10T16:00:00+02:00
    When the client requests schedulesPerDay for LogicalDates 2026-09-06 through 2026-09-10
    Then every Schedule=Y competition match from the feed appears on some day
    And Women's and Men's GP1, GP2, Bronze and Gold units are present
    And no tile has a groupId
    And CC Schedule=S count for CKT is 0

  Scenario: All matches expose finished scores after full ingest
    Given now is 2026-09-10T16:00:00+02:00
    Then OFFICIAL DT_RESULT exists for 27 match units (all except Men's GP1A000200 which has no raw RESULT)
    And Women's GP1A000200 FINAL_RESULT is WON_SO with soResult.periodCode SO
    And Men's GP2-000600 FINAL_RESULT is TIED with soResult.periodCode SO5
    And Men's Gold FINAL_RESULT is WON_RUN
    And exceptional finals include Men's GP1 DLS, BYDEFAULT and ABANDONED where present in ODF

  Scenario: Multi Super Over mid-ingest shows latest period only
    Given only messages up to 2026-09-06-080341000 have been ingested
    Then CKTMT20 GP2-000600 soResult.periodCode is SO2 (not SO1)
    When messages up to 2026-09-06-080403000 have been ingested
    Then the unit is FINISHED with FINAL_RESULT TIED and soResult.periodCode SO5

  Scenario: Medals order and full standings
    Given now is 2026-09-10T16:00:00+02:00
    Then Women DT_MEDALLISTS was ingested before the mid DT_MEDALS (FinishedEvents=1)
    And Men DT_MEDALLISTS was ingested before the final DT_MEDALS (FinishedEvents=2)
    And final DT_MEDALS includes both genders
    And men's bronze Organisation is PAK (aligned to bronze DT_RESULT)
    And women's podium is IND gold, AUS silver, NZL bronze

  Scenario: Card click always goes to unit results
    Given now is 2026-09-10T16:00:00+02:00
    When the user clicks any listed competition tile
    Then the href is the unit-results URL for that RSC
    And the href does not change between before, during and after


Feature: CKT schedule tiles — curated multi-day freeze (DRES-33389)
  Background:
    Given competition OG2028-ITL
    And the CKT messages in own_scenarios/CKT/01_Schedule_Tile_Mixed_Days have been ingested in filename order

  Scenario: Team bootstrap precedes schedule
    Given only messages up to 2026-09-09-080003000 have been ingested
    Then DT_PARTIC_TEAMS_UPDATE has loaded team Type=T identities
    And DT_ENTRIES for CKTMT20 and CKTWT20 define team compositions
    And no schedule tiles are available yet

  Scenario: Morning schedule — all competition units before
    Given only messages up to 2026-09-09-080004000 have been ingested
    And now is 2026-09-09T08:00:00+02:00
    When the client requests schedulesPerDay/2026-09-09 for CKT
    Then today's competition tiles are SCHEDULED:
      | CKTWT20---------------GP1A000200-- |
      | CKTMT20---------------FNL-000200-- |
      | CKTMT20---------------FNL-000100-- |
    And no tile shows a Scheduled badge
    And no tile has liveFlag or medallists
    And no tile has a groupId

  Scenario: Day lists span four LogicalDates
    Given now is 2026-09-09T15:15:00+02:00
    When the client requests schedulesPerDay for each day
    Then 2026-09-06 lists Women's GP1A000100 and GP1B000100 as FINISHED
    And 2026-09-07 lists Men's GP2-000100..000300 as FINISHED
    And 2026-09-08 lists Men's GP2-000400..000600 as FINISHED
    And 2026-09-09 lists Women GP1A000200, Men's Bronze, Men's Gold as FINISHED competition tiles

  Scenario: Finished women group shows cricket score with overs and finalResultDescription
    Given now is 2026-09-09T15:15:00+02:00
    When the client opens schedulesPerDay/2026-09-06
    Then CKTWT20 GP1A000100 is FINISHED Australia vs India
    And competitors[].result.result includes runs/wickets with overs from BATTING/NO (e.g. 87/2 (20))
    And FINAL_RESULT is WON_WKT with SCORE 9
    And finalResultDescription interpolates India beat Australia by 9 wickets
    And competitors are Type=T from PARTIC_TEAMS / ENTRIES
    And soResult is omitted
    And toss is omitted

  Scenario: Mid — multi Super Over LIVE shows only latest SO (SO2), not SO1
    Given only messages up to 2026-09-09-080010015 have been ingested
    And now is 2026-09-09T08:00:10.015+02:00
    Then CKTMT20 GP2-000600 is RUNNING with liveFlag true
    And liveCurrentProgress is SO2IN1
    And ODF Periods still contain SO1IN2 HomeScore=13/0 AwayScore=13/0
    And both competitors expose soResult.periodCode = SO2
    And Pakistan soResult.score is 8/1 (with SO overs when NO Pos=SO2IN1 exists)
    And India soResult.score is YTB
    And soResult does not expose SO1 scores 13/0
    And toss is omitted
    And DT_MEDALLISTS has not been ingested yet

  Scenario: Finished multi Super Over keeps only latest soResult (SO5)
    Given now is 2026-09-09T15:15:00+02:00
    When the client opens schedulesPerDay/2026-09-08
    Then CKTMT20 GP2-000600 is FINISHED Pakistan vs India
    And FINAL_RESULT is TIED
    And ODF contains SO1..SO5 period rows
    And both competitors expose soResult.periodCode = SO5
    And soResult.score is 6/0 for both sides
    And soResult does not concatenate earlier Super Over lines
    And toss is omitted

  Scenario: Mid-morning — Women's first Super Over live (SO + YTB)
    Given only messages up to 2026-09-09-090001000 have been ingested
    And now is 2026-09-09T09:00:01+02:00
    Then CKTWT20 GP1A000200 is RUNNING with liveFlag true
    And liveCurrentProgress is SO1IN1
    And soResult.periodCode is SO
    And Barbados soResult.score is 4/0
    And India soResult.score is YTB
    And innings result.result remains the main innings scores (61/8 vs 61/2) with overs when present
    And toss is omitted
    And DT_MEDALLISTS has not been ingested yet

  Scenario: Women's first Super Over OFFICIAL WON_SO
    Given only messages up to 2026-09-09-091600000 have been ingested
    And now is 2026-09-09T09:16:00+02:00
    Then CKTWT20 GP1A000200 is FINISHED
    And FINAL_RESULT is WON_SO
    And soResult.periodCode is SO
    And India soResult.score is 12/0 and Barbados soResult.score is 11/2
    And finalResultDescription follows WON_SO template (India beat Barbados in Super Over)
    And toss is omitted

  Scenario: Pre-start after toss — no YTB and no toss in schedules API
    Given only messages up to 2026-09-09-142900000 have been ingested
    And now is 2026-09-09T14:29:00+02:00
    Then CKTMT20 FNL-000100 is SCHEDULED
    And ResultStatus was START_LIST (ODF may still carry ER/TOSS)
    And schedules competitors expose team names only
    And neither competitor has result.result (no YTB pair)
    And toss is omitted on both competitors
    And soResult is omitted
    And medalFlag is 1
    And DT_MEDALS has not been ingested yet

  Scenario: Mid-afternoon — Gold live first innings exposes toss
    Given only messages up to 2026-09-09-143000500 have been ingested
    And now is 2026-09-09T14:30:00.500+02:00
    Then CKTMT20 FNL-000100 is RUNNING with liveFlag true
    And liveCurrentProgress is IN1
    And New Zealand result.result is 72/2 with overs when BATTING/NO present
    And South Africa result.result is YTB
    And South Africa has toss = FIELD
    And New Zealand has no toss field
    And soResult is omitted
    And medalFlag is 1
    And DT_MEDALLISTS has not been ingested yet

  Scenario: Mid-afternoon — Gold live second innings hides toss
    Given only messages up to 2026-09-09-143001000 have been ingested
    And now is 2026-09-09T14:30:01+02:00
    Then CKTMT20 FNL-000100 is RUNNING with liveFlag true
    And liveCurrentProgress is IN2
    And New Zealand score is 164/9 and South Africa is 19/0
    And neither competitor has YTB
    And toss is omitted on both competitors
    And soResult is omitted
    And medalFlag is 1
    And DT_MEDALLISTS has not been ingested yet

  Scenario: After full ingest — Gold WON_RUN, women WON_SO, medals order
    Given now is 2026-09-09T15:15:00+02:00
    When the client requests schedulesPerDay/2026-09-09 for CKT
    Then the listed competition tiles are:
      | CKTWT20---------------GP1A000200-- | FINISHED | India vs Barbados WON_SO |
      | CKTMT20---------------FNL-000200-- | FINISHED | Australia vs Pakistan bronze |
      | CKTMT20---------------FNL-000100-- | FINISHED | New Zealand vs South Africa gold |
    And Gold FINAL_RESULT is WON_RUN
    And finalResultDescription is New Zealand beat South Africa by 145 runs
    And Gold competitors have Rank 1 / 2 with WLT W / L
    And Women GP1A000200 FINAL_RESULT is WON_SO with soResult.periodCode SO
    And DT_MEDALLISTS was ingested before DT_MEDALS
    And medallists are NZL gold, RSA silver, PAK bronze
    And DT_MEDALS standings match medallists only (NZL 1G, RSA 1S, PAK 1B — no women's medals)
    And Victory Ceremony is not listed on WMR:
      | CKTMT20---------------VICTMEDAL--- |
    And UNSCHEDULED meetings are not listed:
      | CKTMT20---------------MEET000100-- |
      | CKTWT20---------------MEET000100-- |

  Scenario: CC Schedule flag is Y not S
    Given now is 2026-09-09T15:15:00+02:00
    Then every listed competition unit is CC Schedule=Y
    And CKT has zero Schedule=S units in CC @Unit

  Scenario: Card click always goes to unit results
    Given now is 2026-09-09T15:15:00+02:00
    When the user clicks any listed competition tile
    Then the href is the unit-results URL for that RSC
    And the href does not change between before, during and after
    And WMR uses the compact CKT path shape for group / final units
