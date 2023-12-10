CREATE AGGREGATE mul(bigint) ( SFUNC = int8mul, STYPE=bigint );

WITH races(id, duration, record) AS (
    SELECT
	1,
	string_agg(duration::text, '')::bigint AS duration,
	string_agg(record::text, '')::bigint AS record
    FROM races
),
hold_durations AS (
    SELECT
	id,
	duration,
	record,
	generate_series(1, duration) AS hold_duration
    FROM
	races
)
SELECT 
    (duration - hold_duration) - hold_duration + 1
FROM
    hold_durations
WHERE
    (hold_duration * (duration - hold_duration)) > record
LIMIT 1;
