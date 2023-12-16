DROP TABLE IF EXISTS symbols;
DROP TABLE IF EXISTS patterns;

CREATE TABLE symbols (
    id int,
    idx int,
    symbol char
);

INSERT INTO symbols
SELECT
    id,
    idx,
    symbol
FROM (
    SELECT
	id,
	string_to_array(line, ' ') AS split
    FROM input
) x, unnest(string_to_array(x.split[1], NULL)) WITH ORDINALITY AS a(symbol, idx);

CREATE TABLE patterns (
    id int,
    pattern int[]
);

INSERT INTO patterns
SELECT
    id,
    string_to_array(x.split[2], ',')::int[]
FROM (
    SELECT
	id,
	string_to_array(line, ' ') AS split
    FROM input
) x
