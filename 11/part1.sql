DROP TABLE IF EXISTS map1;
CREATE TABLE map1 AS TABLE map;

WITH y_expand AS (
    SELECT COUNT(*), symbol, y FROM map1 WHERE symbol = '.' GROUP BY y, symbol HAVING COUNT(*) = (SELECT MAX(x) FROM map1)
),
y_shift AS (
    SELECT a.y AS y, COUNT(*) AS cnt FROM (SELECT DISTINCT y FROM map1) a INNER JOIN y_expand ON a.y >= y_expand.y GROUP BY a.y
)
UPDATE
    map1
SET
    y = map1.y + cnt
FROM
    y_shift
WHERE
    y_shift.y = map1.y;

WITH new_y AS (
    SELECT generate_series(1, (SELECT MAX(y) FROM map1)) AS y
    EXCEPT
    SELECT DISTINCT y FROM map1
)
INSERT INTO map1 (x, y, symbol)
SELECT generate_series(1, (SELECT MAX(x) FROM map1)), y, '.' FROM new_y;

WITH x_expand AS (
    SELECT COUNT(*), symbol, x FROM map1 WHERE symbol = '.' GROUP BY x, symbol HAVING COUNT(*) = (SELECT MAX(y) FROM map1)
),
x_shift AS (
    SELECT a.x AS x, COUNT(*) AS cnt FROM (SELECT DISTINCT x FROM map1) a INNER JOIN x_expand ON a.x >= x_expand.x GROUP BY a.x
)
UPDATE
    map1
SET
    x = map1.x + cnt
FROM
    x_shift
WHERE
    x_shift.x = map1.x;

WITH new_x AS (
    SELECT generate_series(1, (SELECT MAX(x) FROM map1)) AS x
    EXCEPT
    SELECT DISTINCT x FROM map1
)
INSERT INTO map1 (x, y, symbol)
SELECT x, generate_series(1, (SELECT MAX(y) FROM map1)), '.' FROM new_x;

SELECT string_agg(symbol, ''), COUNT(*) FROM (SELECT x, y, symbol FROM map1 ORDER BY y,x) a GROUP BY y ORDER BY y;

WITH galaxies AS (
    SELECT x, y, symbol, rank() OVER (ORDER BY y, x) AS i FROM map1 WHERE symbol = '#'
)
SELECT SUM(ABS(g1.x - g2.x) + ABS(g1.y - g2.y)) AS distance FROM galaxies g1 CROSS JOIN galaxies g2 WHERE g1.i < g2.i;
