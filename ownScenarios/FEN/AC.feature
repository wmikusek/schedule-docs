Feature: FEN schedule tiles — mixed-day playback
  Background:
    Given competition OG2028-ITL and LogicalDate 2026-09-09
    And the FEN messages in own_scenarios/FEN/01_Schedule_Tile_Mixed_Day have been ingested in filename order
    And Schedule=S count for FEN is 0

  Scenario: After bootstrap schedule only — all before
    Given only messages up to 2026-09-09-080002000 have been ingested
    And now is 2026-09-09T08:00:02+02:00
    When the client requests schedulesPerDay/2026-09-09 for FEN
    Then these competition tiles are SCHEDULED:
      | FENMSABRE-------------R32-000100-- |
      | FENMSABRE-------------R32-000500-- |
      | FENWTEAMEPEE----------QFNL000200-- |
      | FENWTEAMSABR----------QFNL000100-- |
      | FENWTEAMSABR----------QFNL000400-- |
      | FENWTEAMSABR----------FNL-000100-- |
    And no tile shows liveFlag or V(T)
    And units in the same Session+PhaseRSC share a groupId per olympic-grouping-rules.csv

  Scenario: Mid day — live QF4 and V(T) finished bouts
    Given only messages up to 2026-09-09-130506000 have been ingested
    And now is 2026-09-09T13:05:00+02:00
    Then FENWTEAMSABR----------QFNL000400-- is RUNNING with liveFlag true and a POINTS score
    And FENMSABRE-------------R32-000500-- is FINISHED with winLoseTie V(T) on the winner and score 14-14
    And FENWTEAMEPEE----------QFNL000200-- is FINISHED with winLoseTie V(T) on the winner and score 36-36
    And FENWTEAMSABR----------FNL-000100-- is still SCHEDULED with medalFlag 1
    And FENWTEAMSABR----------FNL-000200-- is still SCHEDULED with medalFlag 3
    And the four FEN09 QFNL sabre-team units are groupable under one Session_PhaseRSC group

  Scenario: After full ingest — individual + team medals (2 events)
    Given now is 2026-09-09T17:00:00+02:00
    When the client requests schedulesPerDay/2026-09-09 for FEN
    Then FENMSABRE-------------FNL-000100-- is FINISHED with SAMELE ITA winner 15-13 and medalFlag 1
    And FENMSABRE-------------FNL-000200-- is FINISHED with OH KOR winner 15-7 and medalFlag 3
    And DT_MEDALLISTS has been ingested for FENMSABRE with Samele gold Apithy silver Oh bronze
    And FENWTEAMSABR----------FNL-000100-- is FINISHED with ALG winner 45-40 and medalFlag 1
    And FENWTEAMSABR----------FNL-000200-- is FINISHED with KOR winner 45-43 and medalFlag 3
    And DT_MEDALLISTS has been ingested for FENWTEAMSABR with ALG gold ITA silver KOR bronze
    And DT_MEDALS standings cover exactly 2 events (MSABRE + WTEAMSABR)
    And V(T) remains on the two finished non-medal bouts from mid ingest

  Scenario: Card click opens unit results
    Given now is 2026-09-09T17:00:00+02:00
    When the user clicks the tile for FENWTEAMSABR----------FNL-000100--
    Then CIS opens /en/OG2028/FEN/W/TEAMSABR----------/FNL-/000100--/results
    And WMR opens /en/la28/results/unit/fenwteamsabr----------fnl-000100--
