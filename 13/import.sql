DROP INDEX IF EXISTS idx_patterns;
DROP INDEX IF EXISTS idx_patterns2;
DROP TABLE IF EXISTS patterns;

CREATE TABLE patterns (
    id SERIAL,
    x int,
    y int,
    symbol char,
    pattern_id int
);

INSERT INTO patterns (x, y, symbol, pattern_id)
SELECT
    idx,
    id AS y,
    symbol,
    (SELECT COUNT(*) FROM input i WHERE i.line = '' AND i.id < input.id) + 1 AS pattern_id
FROM input, unnest(string_to_array(line, NULL)) WITH ORDINALITY a(symbol, idx);

CREATE UNIQUE INDEX idx_patterns ON patterns(pattern_id, y, x);
CREATE UNIQUE INDEX idx_patterns2 ON patterns(pattern_id, x, y);

UPDATE patterns
SET y = y - (SELECT MIN(p.y) - 1 FROM patterns p WHERE p.pattern_id = patterns.pattern_id);
