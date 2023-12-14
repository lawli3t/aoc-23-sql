DROP VIEW IF EXISTS horizontal_reflections;
DROP VIEW IF EXISTS vertical_reflections;

CREATE VIEW horizontal_reflections AS
WITH matching_lines AS (
    SELECT
	COUNT(*) AS cnt, i1.y AS y1, i2.y AS y2, FLOOR((i1.y + i2.y) / 2) AS line, i1.pattern_id
    FROM patterns i1
    INNER JOIN patterns i2
	ON i1.symbol = i2.symbol AND i1.y < i2.y AND i1.pattern_id = i2.pattern_id AND i1.x = i2.x
    WHERE MOD(i1.y + i2.y, 2) = 1
    GROUP BY i1.pattern_id, i1.y, i2.y
    HAVING COUNT(*) = (SELECT MAX(x) FROM patterns p WHERE p.pattern_id = i1.pattern_id)
)
SELECT
    line,
    COUNT(*),
    pattern_id
FROM matching_lines
GROUP BY line, pattern_id
HAVING (
    (SELECT MAX(y) FROM patterns p WHERE p.pattern_id = matching_lines.pattern_id) = line + COUNT(*)
    OR 0 = line - COUNT(*)
);

CREATE VIEW vertical_reflections AS
WITH matching_lines AS (
    SELECT
	COUNT(*) AS cnt, i1.x AS x1, i2.x AS x2, FLOOR((i1.x + i2.x) / 2) AS line, i1.pattern_id
    FROM patterns i1
    INNER JOIN patterns i2
	ON i1.symbol = i2.symbol AND i1.x < i2.x AND i1.pattern_id = i2.pattern_id AND i1.y = i2.y
    WHERE MOD(i1.x + i2.x, 2) = 1
    GROUP BY i1.pattern_id, i1.x, i2.x
    HAVING COUNT(*) = (SELECT MAX(y) FROM patterns p WHERE p.pattern_id = i1.pattern_id)
)
SELECT
    line,
    COUNT(*),
    pattern_id
FROM matching_lines
GROUP BY line, pattern_id
HAVING (
    (SELECT MAX(x) FROM patterns p WHERE p.pattern_id = matching_lines.pattern_id) = line + COUNT(*)
    OR 0 = line - COUNT(*)
);

SELECT SUM(line) FROM (
    SELECT line AS line FROM vertical_reflections
    UNION ALL
    SELECT line * 100 AS line FROM horizontal_reflections
) x
