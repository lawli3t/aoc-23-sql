DROP INDEX IF EXISTS idx_smudge1;
DROP INDEX IF EXISTS idx_smudge2;
DROP VIEW IF EXISTS horizontal_reflections_smudge;
DROP VIEW IF EXISTS vertical_reflections_smudge;
DROP TABLE IF EXISTS smudge_patterns;
CREATE TABLE smudge_patterns AS TABLE patterns;
ALTER TABLE smudge_patterns ADD COLUMN variation_id int;
UPDATE smudge_patterns SET variation_id = 0;

INSERT INTO smudge_patterns(pattern_id, x, y, variation_id, symbol)
SELECT
    pattern_id,
    x,
    y,
    v.variation_id,
    CASE
	WHEN x + ((y - 1) * (SELECT MAX(x) FROM patterns p WHERE p.pattern_id = patterns.pattern_id)) = v.variation_id THEN
	    CASE 
		WHEN symbol = '.' THEN '#'
		WHEN symbol = '#' THEN '.'
	    END
	ELSE symbol
    END
FROM
    patterns,
    generate_series(1, (SELECT MAX(x) * MAX(y) FROM patterns p WHERE p.pattern_id = patterns.pattern_id)) v(variation_id);

CREATE UNIQUE INDEX idx_smudge1 ON smudge_patterns(pattern_id, variation_id, x, y);
CREATE UNIQUE INDEX idx_smudge2 ON smudge_patterns(pattern_id, variation_id, y, x);

CREATE VIEW horizontal_reflections_smudge AS
WITH matching_lines AS (
    SELECT
	COUNT(*) AS cnt, i1.y AS y1, i2.y AS y2, FLOOR((i1.y + i2.y) / 2) AS line, i1.pattern_id, i1.variation_id
    FROM smudge_patterns i1
    INNER JOIN smudge_patterns i2
	ON i1.symbol = i2.symbol AND i1.y < i2.y AND i1.pattern_id = i2.pattern_id AND i1.x = i2.x AND i1.variation_id = i2.variation_id
    WHERE MOD(i1.y + i2.y, 2) = 1
    GROUP BY i1.pattern_id, i1.variation_id, i1.y, i2.y
    HAVING COUNT(*) = (SELECT MAX(x) FROM patterns p WHERE p.pattern_id = i1.pattern_id)
)
SELECT
    line,
    COUNT(*),
    pattern_id,
    variation_id
FROM matching_lines
GROUP BY line, pattern_id, variation_id
HAVING (
    (SELECT MAX(y) FROM patterns p WHERE p.pattern_id = matching_lines.pattern_id) = line + COUNT(*)
    OR 0 = line - COUNT(*)
);

CREATE VIEW vertical_reflections_smudge AS
WITH matching_lines AS (
    SELECT
	COUNT(*) AS cnt, i1.x AS x1, i2.x AS x2, FLOOR((i1.x + i2.x) / 2) AS line, i1.pattern_id, i1.variation_id
    FROM smudge_patterns i1
    INNER JOIN smudge_patterns i2
	ON i1.symbol = i2.symbol AND i1.x < i2.x AND i1.pattern_id = i2.pattern_id AND i1.y = i2.y AND i1.variation_id = i2.variation_id
    WHERE MOD(i1.x + i2.x, 2) = 1
    GROUP BY i1.pattern_id, i1.variation_id, i1.x, i2.x
    HAVING COUNT(*) = (SELECT MAX(y) FROM patterns p WHERE p.pattern_id = i1.pattern_id)
)
SELECT
    line,
    COUNT(*),
    pattern_id,
    variation_id
FROM matching_lines
GROUP BY line, pattern_id, variation_id
HAVING (
    (SELECT MAX(x) FROM smudge_patterns p WHERE p.pattern_id = matching_lines.pattern_id) = line + COUNT(*)
    OR 0 = line - COUNT(*)
);

SELECT SUM(line) FROM (
    (SELECT line FROM vertical_reflections_smudge GROUP BY line, pattern_id HAVING MIN(variation_id) != 0)
    UNION ALL
    (SELECT line * 100 AS line FROM horizontal_reflections_smudge GROUP BY line, pattern_id HAVING MIN(variation_id) != 0)
) x;
