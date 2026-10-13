Feature: CKT schedule tiles — multi-day team freeze (DRES-33389)
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
    And both competitors expose soResult.periodCode = SO2IN1
    And Pakistan soResult.score is 8/1 (with SO overs when NO Pos=SO2IN1 exists)
    And India soResult.score is YTB
    And soResult does not expose SO1 scores 13/0
    And DT_MEDALLISTS has not been ingested yet

  Scenario: Finished multi Super Over keeps only latest soResult (SO5)
    Given now is 2026-09-09T15:15:00+02:00
    When the client opens schedulesPerDay/2026-09-08
    Then CKTMT20 GP2-000600 is FINISHED Pakistan vs India
    And FINAL_RESULT is TIED
    And ODF contains SO1..SO5 period rows
    And both competitors expose soResult.periodCode = SO5IN2
    And soResult.score is 6/0 for both sides
    And soResult does not concatenate earlier Super Over lines

  Scenario: Mid-morning — Women's single Super Over live (SO1 + YTB)
    Given only messages up to 2026-09-09-090001000 have been ingested
    And now is 2026-09-09T09:00:01+02:00
    Then CKTWT20 GP1A000200 is RUNNING with liveFlag true
    And liveCurrentProgress is SO1IN1
    And soResult.periodCode is SO1IN1
    And Barbados soResult.score is 4/0
    And India soResult.score is YTB
    And innings result.result remains the main innings scores (61/8 vs 61/2) with overs when present
    And toss is omitted (match already started)
    And DT_MEDALLISTS has not been ingested yet

  Scenario: Women's single Super Over OFFICIAL WON_SO
    Given only messages up to 2026-09-09-091600000 have been ingested
    And now is 2026-09-09T09:16:00+02:00
    Then CKTWT20 GP1A000200 is FINISHED
    And FINAL_RESULT is WON_SO
    And soResult.periodCode is SO1IN2
    And India soResult.score is 12/0 and Barbados soResult.score is 11/2
    And finalResultDescription follows WON_SO template (India beat Barbados in Super Over)
    And toss is omitted

  Scenario: Pre-start after toss — toss exposed, no innings scores yet
    Given only messages up to 2026-09-09-142900000 have been ingested
    And now is 2026-09-09T14:29:00+02:00
    Then CKTMT20 FNL-000100 is SCHEDULED
    And ResultStatus was START_LIST
    And South Africa competitor has toss = FIELD
    And New Zealand competitor has no toss field
    And neither competitor has a numeric innings score yet (YTB / empty)
    And soResult is omitted
    And medalFlag is 1
    And DT_MEDALS has not been ingested yet

  Scenario: Mid-afternoon — Gold live first innings hides toss
    Given only messages up to 2026-09-09-143000500 have been ingested
    And now is 2026-09-09T14:30:00.500+02:00
    Then CKTMT20 FNL-000100 is RUNNING with liveFlag true
    And liveCurrentProgress is IN1
    And New Zealand result.result is 72/2 with overs when BATTING/NO present
    And South Africa result.result is YTB
    And toss is omitted on both competitors (even though ODF still has ER/TOSS)
    And soResult is omitted
    And medalFlag is 1
    And DT_MEDALS has not been ingested yet

  Scenario: Mid-afternoon — Gold live second innings
    Given only messages up to 2026-09-09-143001000 have been ingested
    And now is 2026-09-09T14:30:01+02:00
    Then CKTMT20 FNL-000100 is RUNNING with liveFlag true
    And liveCurrentProgress is IN2
    And New Zealand score is 164/9 and South Africa is 19/0
    And toss is omitted
    And soResult is omitted
    And medalFlag is 1
    And DT_MEDALS has not been ingested yet

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
    And Women GP1A000200 FINAL_RESULT is WON_SO with soResult from SO1IN2
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
