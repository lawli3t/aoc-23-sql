DROP TABLE IF EXISTS map;

CREATE TABLE map (
    id SERIAL,
    x int,
    y int,
    symbol char
);

INSERT INTO map (x, y, symbol)
SELECT
    generate_series(1, LENGTH(line)),
    id,
    unnest(string_to_array(line, NULL))::char
FROM input;

SELECT * FROM map;
