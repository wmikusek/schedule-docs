# Cricket Score – process and data sources

## 1. Build each team line

### Team name

`@Code` is converted into translated team name. Teams should come from schedule, not DT_RESULT.

### Main score

Use the first of these that has a value:

1. `Result/@IRM` – the irregular result code, for example `DSQ`.
2. `Result/@Result` – the score, for example `148/7` or `33/2`. If the score
   is all out (wickets = 10, for example `148/10`) the wickets are dropped and
   only the runs are shown (`148`). Text from the feed such as `YTB` is shown
   as given.
3. Otherwise the score is left blank.

### Overs for the main score

If there is a score (not blank, not an IRM, not `YTB`), the overs completed are
added in brackets after it, for example `148 (18.1)`.

- Source: the team's `Competitor/StatsItems/StatsItem` where `@Code` is
  `BATTING` and `@Pos` is the normal innings (for example `IN1` or `IN2`, i.e.
  not starting `SO`), then the `ExtendedStat` with `@Code="NO"`.
- If there is no such value, no overs are shown.

### Super overs

A team has one `BATTING` stats item per super over it has batted in, under
`Competitor/StatsItems/StatsItem`, with `@Pos` such as `SO1IN1` or `SO1IN2`.
For each one, in order:

- **Score** = `ExtendedStat @Code="R"` (runs) and `ExtendedStat @Code="WCK"`
  (wickets), shown as `runs/wickets`. Wickets default to 0. The same all-out
  rule applies.
- **Overs** = `ExtendedStat @Code="NO"`, shown in brackets after the score.
- A super over with no runs value is skipped.

The super over is added after the main score, introduced by `SO`:

- If the message has only one super over: ` SO 4/1 (1)`
- If any team has a second super over (a `@Pos` starting `SO2`), each is
  numbered after its `@Pos`: ` SO1 4/1 (1) SO2 7/2 (0.4)`

## 2. Examples

```
09:00  Group A
India      61/8 (12) SO 12/0 (0.4)
Barbados   61/2 (12) SO 11/2 (0.5)
```

Several super overs:

```
India      148/7 SO1 4/1 (1) SO2 7/2 (0.4)
```

Nothing in the feed (blank), the feed's own `YTB`, and an IRM:

```
Team A
Team B     YTB
Team C     DSQ
```

## 3. PT1 Messages

The current test messages are faulty (more than two `Result` elements, with
super over data in the extra ones). We can look for each team's in every `Result` 
for that team (matched by `Competitor/@Code`). This should work even when the messages are corrected so no rework.
