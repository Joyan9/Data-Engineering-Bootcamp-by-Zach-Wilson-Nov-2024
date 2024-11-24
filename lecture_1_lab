/*
CREATE TYPE
  season_stats AS (
    season INTEGER,
    gp INTEGER,
    pts REAL,
    reb REAL,
    ast REAL
  );

CREATE TYPE
  scoring_class AS ENUM('star', 'good', 'avg', 'bad');

CREATE TABLE
  players (
    player_name TEXT,
    height TEXT,
    college TEXT,
    country TEXT,
    draft_year TEXT,
    draft_round TEXT,
    draft_number TEXT,
    season_stats season_stats[], -- Correctly reference the type
    scoring_class scoring_class,
    years_since_last_season INTEGER,
    current_season INTEGER,
    PRIMARY KEY (player_name, current_season)
  );

*/
INSERT INTO PLAYERS
WITH
  yesterday as (
    SELECT
      *
    FROM
      players
    WHERE
      current_season = 1997
  ),
  today as (
    SELECT
      *
    FROM
      player_seasons
    WHERE
      season = 1998
  )
SELECT
  COALESCE(t.player_name, y.player_name) as player_name,
  COALESCE(t.height, y.height) as height,
  COALESCE(t.college, y.college) as college,
  COALESCE(t.country, y.country) as country,
  COALESCE(t.draft_year, y.draft_year) as draft_year,
  COALESCE(t.draft_round, y.draft_round) as draft_round,
  COALESCE(t.draft_number, y.draft_number) as draft_number,
  CASE
    WHEN y.season_stats IS NULL -- if player joined this season
    THEN ARRAY[
      ROW (t.season, t.gp, t.pts, t.reb, t.ast)::season_stats
    ]
    WHEN t.season IS NOT NULL -- if player is playing this season
    THEN y.season_stats || ARRAY[
      ROW (t.season, t.gp, t.pts, t.reb, t.ast)::season_stats
    ]
    ELSE y.season_stats -- player not present in this season
  END AS season_stats,
  CASE
    WHEN t.season IS NOT NULL THEN 
    CASE
      WHEN t.pts > 20 THEN 'star'
      WHEN t.pts > 15 THEN 'good'
      WHEN t.pts > 10 THEN 'avg'
      ELSE 'bad'
    END::scoring_class
    ELSE y.scoring_class
  END as scoring_class,
  CASE
    WHEN t.season IS NOT NULL THEN 0
    ELSE y.years_since_last_season + 1
  END as years_since_last_season,
  COALESCE(t.season, y.current_season + 1) as current_season
FROM
  today t
  FULL OUTER JOIN yesterday y ON t.player_name = y.player_name;

/*
How to unnest a cumulative table
WITH unnested as( 
SELECT player_name,
UNNEST(season_stats)::season_stats as season_stats
FROM players
WHERE current_season = 2001
AND player_name = 'Michael Jordan')

SELECT player_name,
(season_stats::season_stats).*
FROM unnested
 */
 
-- Which player had the biggest improvement as compared to their 1st season
SELECT
player_name,
((season_stats[CARDINALITY(season_stats)]::season_stats).pts/ -- Retrieves the last element in the array
CASE WHEN (season_stats[1]::season_stats).pts = 0 THEN 1 
ELSE (season_stats[1]::season_stats).pts
 END) as improvement
FROM players
WHERE current_season = 1998
ORDER BY 2 DESC;
