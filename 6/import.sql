DROP TABLE IF EXISTS races;

CREATE TABLE races (
    id SERIAL,
    duration int,
    record int
);

INSERT INTO races (duration, record)
SELECT duration::int, record::int FROM (
    SELECT
	unnest(regexp_split_to_array(TRIM(x.line[2]), '\s+')) AS duration,
	unnest(regexp_split_to_array(TRIM(y.line[2]), '\s+')) AS record
    FROM
    (
	SELECT row_number() OVER () AS idx, string_to_array(line, ':') AS line FROM input WHERE id = 1
    ) x,
    (
	SELECT row_number() OVER () AS idx, string_to_array(line, ':') AS line FROM input WHERE id = 2
    ) y
    WHERE x.idx = y.idx
) a
