Feature: ARC schedule tiles on a mixed freeze day
  Background:
    Given competition OG2028-ITL and LogicalDate 2026-09-09
    And the ARC messages in own_scenarios/ARC/01_Schedule_Tile_Mixed_Day have been ingested in filename order
    And now is 2026-09-09T14:51:00+02:00

  Scenario: Default daily list is Y units only
    When the client requests schedulesPerDay/2026-09-09 for ARC
    Then every listed item has Common Codes Schedule = Y
    And no item is a phase RSC (all ARC phases are Schedule = N)
    And none of the following RSCs are listed:
      | ARCWTEAM3-------------QUAL000100-- |
      | ARCMTEAM3-------------QUAL000100-- |
      | ARCXTEAM2-------------QUAL000100-- |
      | ARCXTEAMC-------------QUAL00010000 |
      | ARCWINDIVID-----------R64-000100-- |
      | ARCWINDIVID-----------TMRY000500-- |
    And Women's Individual Ranking Round IS listed

  Scenario: Recurve Team/Mixed QUAL is visible only with By Event
    When the user filters the schedule by event Recurve Women's Team
    Then Women's Team Ranking Round (Schedule = S) is listed
    When the user opens the unfiltered daily list
    Then Women's Team Ranking Round is not listed

  Scenario: Compound Mixed QUAL subunits without the parent
    Then Women's Compound Qualification is listed as FINISHED
    And Men's Compound Qualification is listed as GETTING_READY
    And Compound Mixed Team Qualification Round QUAL00010000 is not listed
    When the user opens either Compound QUAL subunit tile
    Then the results destination RSC is ARCXTEAMC-------------QUAL00010000
    And that is the Schedule RSC override (one Compound Mixed QUAL page, not a Compound Individual event)

  Scenario: One event already has medallists
    Then Women's Team Gold is FINISHED with score 5-1 and medalFlag 1
    And Women's Team Bronze is FINISHED with score 6-2 and medalFlag 3
    And the Women's Team event exposes medallists KOR gold, CHN silver, NED bronze

  Scenario: Live gold match shows set score and current set
    Then Women's Individual Gold is RUNNING with liveFlag true
    And the tile shows Lim 4 and Nam 2
    And liveCurrentProgress is Set 3 from DISPLAY/CURRENT Pos=3
    And there is no Scheduled badge
    And medalFlag is 1

  Scenario: Finished match with IRM
    Then Women's Individual 1/8 8FNL000600 is FINISHED
    And Kaur is shown with set points 6 and winner
    And Choirunisa is shown with IRM DNS
    And the tile has no medal marker

  Scenario: Placeholder opponent is Winner {UnitNum}
    Then Mixed Team Quarterfinal lists Republic of Korea against "Winner 129"
    And Mixed Team Gold lists "Winner 142" against "Winner 143"
    And Mixed Team Gold hides UnitNum and start time
    And Mixed Team 1/8 units still show start time 15:30

  Scenario: Bye and unscheduled session rows never appear
    Then a unit with Competitor BYE and ScheduleStatus UNSCHEDULED is not listed
    And TMRY000500 is not listed even though CC Schedule = Y

  Scenario: Medal matches are not grouped
    When tiles are grouped by event for match rounds
    Then Women's Individual Bronze and Gold are not placed in that group
    And Mixed Team Gold is not placed in the Mixed 1/8 group

  Scenario: Card click always goes to unit results
    When the user clicks any listed tile that has no RSC override
    Then the href is the unit-results URL for that tile RSC
    And the href does not change between before, during and after

Feature: ARC All_Events freeze (Compound Mixed + Men Individual through finals)
  Background:
    Given competition OG2028-ITL
    And the ARC messages in ownScenarios/ARC/All_Events have been ingested in filename order
    And ODF bodies keep ITL competition dates (July 2028); filename prefixes are playback order only

  Scenario: Bootstrap loads only the two event entries
    When bootstrap messages are ingested
    Then DT_PARTIC_UPDATE and DT_PARTIC_TEAMS_UPDATE are loaded
    And DT_ENTRIES exist for ARCMINDIVID and ARCXTEAMC only
    And the initial DT_SCHEDULE_UPDATE contains the full ARC unit shell

  Scenario: No LIVE results are ingested
    When full All_Events ingest is complete
    Then no DT_RESULT has ResultStatus LIVE

  Scenario: Compound Mixed QUAL is Schedule S
    When the schedule feed includes ARCXTEAMC QUAL000100
    Then that unit may be hidden on the default daily list and shown under By Event

  Scenario: Compound Mixed finishes with medallists then medals
    When ingest has passed Compound Mixed gold OFFICIAL and DT_MEDALLISTS for ARCXTEAMC
    Then the next DT_MEDALS LastEvent is ARCXTEAMC with FinishedEvents 1
    And medallists are MEX gold IND silver GBR bronze

  Scenario: Men Individual finishes through gold
    When full All_Events ingest is complete
    Then OFFICIAL DT_RESULT exists for ARCMINDIVID FNL-000100 and FNL-000200
    And DT_MEDALLISTS for ARCMINDIVID lists TUR gold COL silver ITA bronze
    And the final DT_MEDALS covers only ARCXTEAMC and ARCMINDIVID

  Scenario: Medal matches are not grouped
    When tiles are grouped by event for match rounds
    Then ARCXTEAMC and ARCMINDIVID FNL units are not placed in elimination groups
