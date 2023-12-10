CREATE AGGREGATE mul(bigint) ( SFUNC = int8mul, STYPE=bigint );

WITH hold_durations AS (
    SELECT
	id,
	duration,
	record,
	generate_series(1, duration) AS hold_duration
    FROM
	races
),
ways_to_win AS (
    SELECT 
	id,
	COUNT(*) AS cnt
    FROM
	hold_durations
    WHERE
	(hold_duration * (duration - hold_duration)) > record
    GROUP BY
	id
)
SELECT mul(cnt) FROM ways_to_win;
