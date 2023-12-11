DROP TABLE IF EXISTS x_costs CASCADE;
DROP TABLE IF EXISTS y_costs CASCADE;

DROP TABLE IF EXISTS map2 CASCADE;
CREATE TABLE map2 AS TABLE map;

CREATE TABLE x_costs AS
SELECT DISTINCT x, 1 AS cost FROM map;

CREATE TABLE y_costs AS
SELECT DISTINCT y, 1 AS cost FROM map;

WITH y_shift AS (
    SELECT y, 1000000 AS cnt FROM map2 WHERE symbol = '.' GROUP BY y, symbol HAVING COUNT(*) = (SELECT MAX(x) FROM map2)
)
UPDATE
    y_costs
SET
    cost = cnt
FROM
    y_shift
WHERE
    y_shift.y = y_costs.y;

WITH x_shift AS (
    SELECT x, 1000000 AS cnt FROM map2 WHERE symbol = '.' GROUP BY x, symbol HAVING COUNT(*) = (SELECT MAX(y) FROM map2)
)
UPDATE
    x_costs
SET
    cost = cnt
FROM
    x_shift
WHERE
    x_shift.x = x_costs.x;

EXPLAIN ANALYZE
WITH galaxies AS (
    SELECT x, y, symbol, rank() OVER (ORDER BY y, x) AS i FROM map2 WHERE symbol = '#'
)
SELECT
    SUM (
	(SELECT SUM(cost) FROM y_costs WHERE y <= GREATEST(g1.y, g2.y) AND y >= LEAST(g1.y, g2.y))
	+ (SELECT SUM(cost) FROM x_costs WHERE x <= GREATEST(g1.x, g2.x) AND x >= LEAST(g1.x, g2.x))
	- 2
    ) AS distance
FROM galaxies g1 CROSS JOIN galaxies g2 WHERE g1.i < g2.i;
