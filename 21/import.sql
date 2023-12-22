DROP INDEX IF EXISTS idx_symbols1;
DROP INDEX IF EXISTS idx_symbols2;
DROP VIEW IF EXISTS neighbors;
DROP TABLE IF EXISTS symbols;

CREATE TABLE symbols (
    id SERIAL,
    x int,
    y int,
    symbol char
);

CREATE UNIQUE INDEX idx_symbols1 ON symbols (y, x);
CREATE UNIQUE INDEX idx_symbols2 ON symbols (x, y);

INSERT INTO symbols(y, x, symbol)
SELECT id - 1, idx - 1, symbol FROM input, unnest(string_to_array(line, NULL)) WITH ORDINALITY AS a(symbol, idx);

CREATE VIEW neighbors AS
SELECT
    n.x AS neighbor_x,
    n.y AS neighbor_y,
    s.x AS x,
    s.y AS y,
    n.symbol
FROM symbols s
INNER JOIN symbols n
    ON (
	(s.x = n.x AND s.y = n.y + 1)
	OR (s.x = n.x AND s.y = n.y - 1)
	OR (s.x = n.x + 1 AND s.y = n.y)
	OR (s.x = n.x - 1 AND s.y = n.y)
    )
;

SELECT * FROM neighbors ORDER BY y, x;

SELECT * FROM symbols WHERE symbol = 'S';
