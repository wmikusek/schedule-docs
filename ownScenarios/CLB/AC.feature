Feature: CLB schedule tiles on a mixed freeze day
  Background:
    Given competition OG2028-ITL and LogicalDate 2026-09-09
    And the CLB messages in own_scenarios/CLB/01_Schedule_Tile_Mixed_Day have been ingested in filename order
    And now is 2026-09-09T09:33:00+02:00

  Scenario: Default daily list is schedule=Y only
    When the client requests schedulesPerDay/2026-09-09 for CLB
    Then the listed tiles are:
      | CLBWLEAD--------------FNL-000100-- | FINISHED      |
      | CLBMSPEED-------------QFNL-------- | FINISHED      |
      | CLBMSPEED-------------SFNL-------- | RUNNING       |
      | CLBMSPEED-------------FNL--------- | SCHEDULED     |
      | CLBWBOULDER-----------FNL-000100-- | GETTING_READY |
    And Speed pair units with ScheduleFlag = S are not listed:
      | CLBMSPEED-------------QFNL000100-- |
      | CLBMSPEED-------------QFNL000200-- |
      | CLBMSPEED-------------QFNL000300-- |
      | CLBMSPEED-------------QFNL000400-- |
      | CLBMSPEED-------------SFNL000100-- |
      | CLBMSPEED-------------SFNL000200-- |
      | CLBMSPEED-------------FNL-000100-- |
      | CLBMSPEED-------------FNL-000200-- |

  Scenario: Finished Lead shows medallists and no climbing score
    Then Women's Lead Final is FINISHED
    And the tile shows three medallists Nakagawa JPN, Bertone FRA, Thompson-Smith GBR
    And the tile does not show a climbing score
    And medalFlag is 1

  Scenario: Speed phase rows have no IRM or times on the tile
    Then Men's Speed Quarterfinals is FINISHED with no IRM and no race times on the tile
    And Men's Speed Semifinals is RUNNING with liveFlag true
    And the SF tile does not show Leonardo vs Zurloni race time
    And there is no Scheduled badge on Men's Speed Finals
    And Men's Speed Finals has a medal marker

  Scenario: Boulder Final is before with medal marker and no medallists
    Then Women's Boulder Final is GETTING_READY
    And the tile has a medal marker
    And the tile does not show medallists yet

  Scenario: Speed S-unit results stay off the schedule tile
    Then Speed QF1 result is DNS Maimuratov vs DQB David
    And Speed SF1 result is Alipour vs NOCOMP
    And Speed SF2 is LIVE Leonardo vs Zurloni
    And Speed Big Final start list is Alipour vs TBD WSF2
    And Speed Small Final start list is NOCOMP vs TBD LSF2
    And QF2 has UI/RERUN = Y
    But none of those scores, IRMs or placeholders appear on the Y phase tiles

  Scenario: Speed QF SF and FNL cards share one results page
    When the user clicks Men's Speed Quarterfinals, Semifinals or Finals
    Then each card redirects to CLBMSPEED-------------FNL-000100--
    And that is the Schedule RSC override for the Speed Final bracket

  Scenario: Card click does not change by tile phase
    When the user clicks Women's Lead Final or Women's Boulder Final
    Then the href is the unit-results URL for that tile RSC
    And the href does not change between before, during and after

Feature: CLB All_Events mega freeze
  Background:
    Given competition OG2028-ITL
    And the CLB messages in own_scenarios/CLB/All_Events have been ingested in filename order
    And ODF body StartDates keep July 2028 competition days

  Scenario: After full ingest Men Speed phases are finished with unofficial medals
    When the client requests schedulesPerDay/2028-07-26 for CLB
    Then Men's Speed QFNL SFNL and FNL phase tiles are FINISHED
    And Men's Speed pair ScheduleFlag=S units are not listed as separate cards
    And Men's Speed event medallists are UNOFFICIAL (IRI gold, ITA silver, INA bronze)
    And there is no OFFICIAL DT_MEDALLISTS and no DT_MEDALS for Men's Speed

  Scenario: Women's Speed QFNL stays live
    When the client requests schedulesPerDay/2028-07-26 for CLB
    Then Women's Speed Quarterfinals phase CLBWSPEED-------------QFNL-------- is RUNNING
    And there is a LIVE DT_RESULT for CLBWSPEED-------------QFNL000100--
    And Women's Speed SFNL and FNL phase tiles are not present as FINISHED

  Scenario: Men's Lead SFNL stays live
    When the client requests schedulesPerDay/2028-07-25 for CLB
    Then Men's Lead Semifinal CLBMLEAD--------------SFNL000100-- is RUNNING
    And there is a LIVE DT_RESULT for CLBMLEAD--------------SFNL000100--
    And Men's Lead Final is not FINISHED in this freeze

  Scenario: Men's Boulder through gold on the following day
    When the client requests schedulesPerDay/2028-07-27 for CLB
    Then Men's Boulder Final CLBMBOULDER-----------FNL-000100-- is FINISHED
    And the tile shows UNOFFICIAL medallists ESP Gines Lopez, USA Grupper, CHN Pan
    And there is no OFFICIAL DT_MEDALLISTS and no DT_MEDALS for Men's Boulder

  Scenario: Speed phase cards use RSC override
    When the user clicks Men's Speed Finals or Women's Speed Quarterfinals
    Then the href prefers overrideRsc to the Big Final unit when configured
