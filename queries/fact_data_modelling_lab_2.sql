/*
SELECT MAX(event_time) FROM events;

CREATE TABLE users_cumulated (
user_id TEXT,
-- list of dates in the past where the user was active
dates_active DATE[],
-- the current date
date DATE,
PRIMARY KEY (user_id, date)
)

INSERT INTO
users_cumulated
WITH
yesterday as (
SELECT
 *
FROM
users_cumulated
WHERE
date = '2023-01-30'
),
today as (
SELECT
CAST(user_id as TEXT) as user_id,
CAST(event_time AS DATE) AS date_active
FROM
events
WHERE
CAST(event_time AS DATE) = '2023-01-31'
AND user_id IS NOT NULL
GROUP BY
1,
2
)
SELECT
COALESCE(t.user_id, y.user_id) as user_id,
CASE
WHEN y.dates_active IS NULL THEN ARRAY[t.date_active]
WHEN t.date_active IS NULL THEN y.dates_active
ELSE ARRAY[t.date_active] || y.dates_active
END AS dates_active,
-- date_active might not be in today's data
COALESCE(t.date_active, y.date + INTERVAL '1 day') as date
FROM
today t
FULL OUTER JOIN yesterday y ON t.user_id = y.user_id
 */
WITH
  users AS (
    -- here  we have list of dates where the users where active
    SELECT
      *
    FROM
      users_cumulated
    WHERE
      date = '2023-01-31'
  ),
  series AS (
    SELECT
      generate_series(
        '2023-01-01'::DATE,
        '2023-01-31'::DATE,
        INTERVAL '1 day'
      ) AS series_date
  ), 
  
  placeholder_ints as (
    SELECT
      /*
      This checks if the array column dates_active in the users_cumulated table contains the specific series_date.
      The @> operator is a PostgreSQL array operator meaning "contains". 
      It evaluates to TRUE if the left-hand array includes all elements of the right-hand array.
      
      dates_active @> ARRAY [series.series_date::DATE]
      
       */
      CASE
    	-- date - series.series_date::DATE: Calculates the difference (in days) between 2023-01-31 and the active date.
    	-- POW(2, ...): Calculates a power of 2 for the day difference and using 2 for converting to bits later
    	-- 
        WHEN dates_active @> ARRAY[series.series_date::DATE] THEN CAST(
          POW (2, 32 - (date - series.series_date::DATE)) AS BIGINT
        )
      END as placeholder_int_value,
      *
    FROM
      users
      CROSS JOIN series
   -- WHERE user_id = '10060569187331700000'
  )
/*
The query encodes user activity as a 32-bit integer 
where each bit represents whether the user was active on a specific date in January 2023:
Bit 0 (Least Significant Bit): Represents 2023-01-31.
Bit 1: Represents 2023-01-30.
...
Bit 31 (Most Significant Bit): Represents 2023-01-01.
*/
SELECT
user_id,
CAST(CAST(SUM(placeholder_int_value) AS BIGINT) AS BIT(32)),
BIT_COUNT(CAST(CAST(SUM(placeholder_int_value) AS BIGINT) AS BIT(32))) > 0 as dim_is_monthly_active,
-- for weekly active users
BIT_COUNT(
CAST('1111111000000000000000000000000' AS BIT(32))
& -- think of this as an AND gate, where only if both values are true then you get true
-- since we are only concerned with the last 7 days we set it the first 7 bits as 1 rest 0
CAST(CAST(SUM(placeholder_int_value) AS BIGINT) AS BIT(32))) > 0 as dim_is_lastweek_active
FROM placeholder_ints
GROUP BY 1
