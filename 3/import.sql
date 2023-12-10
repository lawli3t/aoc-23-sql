DROP INDEX IF EXISTS idx_map;
DROP INDEX IF EXISTS idx_number_map_id;
DROP INDEX IF EXISTS idx_number_map;

DROP TABLE IF EXISTS map CASCADE;
DROP TABLE IF EXISTS number_map CASCADE;

CREATE TABLE map (
    x int,
    y int,
    symbol char
);

CREATE TABLE number_map (
    id serial,
    x int,
    y int,
    n int,
    x_end int GENERATED ALWAYS AS (x + LENGTH(n::text) - 1) STORED
);

WITH parsed_input AS (
    SELECT
	x,
	id as y,
	symbol
    FROM 
	input,
	unnest(string_to_array(line, NULL)) WITH ORDINALITY AS i(symbol, x)
)
INSERT INTO map SELECT * FROM parsed_input;


WITH grouped_digits AS (
    SELECT
	symbol,
	x,
	y,
	(
	    x + ((y-1) * ((SELECT MAX(x) FROM map)))
	    -
	    row_number() OVER (ORDER BY (y, x))
	) AS grp
    FROM map
    WHERE
	symbol IN ('1','2','3','4','5','6','7','8','9','0')
),
aggregated_numbers AS (
    SELECT
	MIN(x) as x,
	MIN(y) as y,
	string_agg(symbol, '')::int
    FROM grouped_digits
    GROUP BY grp, y
)
INSERT INTO number_map(x, y, n) SELECT * FROM aggregated_numbers;

CREATE UNIQUE INDEX idx_map ON map(x, y);
CREATE UNIQUE INDEX idx_number_map_id ON number_map(id);
CREATE UNIQUE INDEX idx_number_map ON number_map(x, y);
