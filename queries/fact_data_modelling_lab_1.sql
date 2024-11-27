
-- check for duplicates first, identify the granularity of the table
/*
SELECT
	game_id, team_id, player_id, COUNT(1)
FROM game_details
GROUP BY 1,2,3
HAVING COUNT(1) > 1
*/
INSERT INTO fact_game_details
WITH deduped as (
	SELECT 
  g.game_date_est, 
  g.season,
  g.home_team_id,
  gd.*, 
  -- usually you also add a order by clause and pick the first record
  ROW_NUMBER() OVER(PARTITION BY gd.game_id, team_id, player_id
                   ORDER BY g.game_date_est) as row_num   
  FROM game_details gd
  JOIN games g
  ON g.game_id = gd.game_id
)
SELECT 
	game_date_est as dim_date,
  season as dim_season,
  team_id as team_id,
  player_id as dim_player_id,
  player_name as player_name,
  start_position as dim_start_position,
  team_id = home_team_id as dim_is_playing_at_home,
  COALESCE(POSITION('DNP' in comment),0) > 0 as dim_is_did_not_play,
  COALESCE(POSITION('DND' in comment),0) > 0 as dim_is_did_not_dress,
  COALESCE(POSITION('NWT' in comment),0) > 0 as dim_is_not_with_team,
  CAST(SPLIT_PART("min", ':',1) as REAL) 
  +(CAST(SPLIT_PART("min", ':',2) as REAL)/60) as m_minutes,
  fgm as m_fgm,
  fga as m_fga,
  fg3m as m_fg3m,
  fg3a as m_fg3a,
  ftm as m_ftm,
  fta as m_fta,
  oreb as m_oreb,
  dreb as m_dreb,
  reb as m_reb,
  ast as m_ast,
  stl as m_stl,
  blk as m_blk,
  "TO" as m_turnovers,
  pf as m_pf,
  pts as m_pts,
  plus_minus as m_plus_minus
FROM deduped
WHERE row_num = 1


CREATE TABLE fact_game_details (
  -- columns that are attributes should start with dim_ prefix
  -- columns that are measures should start with m_ prefix
  -- this helps analysts know which columns can be used for group by and which ones for aggregation
  dim_date DATE,
  dim_season INTEGER,
  dim_team_id INTEGER,
  dim_player_id INTEGER,
  dim_player_name TEXT,
  dim_start_position TEXT,
  dim_is_playing_at_home BOOLEAN,
  dim_is_did_not_play BOOLEAN,
  dim_is_did_not_dress BOOLEAN,
  dim_is_not_with_team BOOLEAN,
  m_minutes INTEGER,
  m_fgm INTEGER,
  m_fga INTEGER,
  m_fg3m INTEGER,
  m_fg3a INTEGER,
  m_ftm INTEGER,
  m_fta INTEGER,
  m_ore INTEGER,
  m_dre INTEGER,
  m_reb INTEGER,
  m_ast INTEGER,
  m_stl INTEGER,
  m_blk INTEGER,
  m_turnovers INTEGER,
  m_pf INTEGER,
  m_pts INTEGER,
  m_plus_minus INTEGER,
  PRIMARY KEY (dim_date, dim_team_id, dim_player_id)
)





