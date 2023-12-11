DROP INDEX IF EXISTS idx_map;
DROP VIEW IF EXISTS connected_neighbors;
DROP VIEW IF EXISTS neighbors;

CREATE UNIQUE INDEX idx_map ON map(y, x);

CREATE VIEW neighbors AS
SELECT
    map.x, map.y, map.symbol, neighbors.x AS neighbor_x, neighbors.y AS neighbor_y, neighbors.symbol AS neighbor_symbol
FROM map
INNER JOIN map neighbors
    ON map.x BETWEEN neighbors.x - 1 AND neighbors.x + 1
    AND map.y BETWEEN neighbors.y - 1 AND neighbors.y + 1
WHERE
    (neighbors.x = map.x OR neighbors.y = map.y)
    AND NOT (neighbors.x = map.x AND neighbors.y = map.y)
    AND (
	map.symbol = 'S'
	OR
	(
	    neighbors.x = CASE
		WHEN map.symbol = '-' THEN map.x - 1
		WHEN map.symbol = '|' THEN map.x
		WHEN map.symbol = '7' THEN map.x - 1
		WHEN map.symbol = 'L' THEN map.x
		WHEN map.symbol = 'J' THEN map.x - 1
		WHEN map.symbol = 'F' THEN map.x + 1
	    END
	    AND neighbors.y = CASE
		WHEN map.symbol = '-' THEN map.y
		WHEN map.symbol = '|' THEN map.y - 1
		WHEN map.symbol = '7' THEN map.y
		WHEN map.symbol = 'L' THEN map.y - 1
		WHEN map.symbol = 'J' THEN map.y
		WHEN map.symbol = 'F' THEN map.y
	    END
	)
	OR
	(
	    neighbors.x = CASE
		WHEN map.symbol = '-' THEN map.x + 1
		WHEN map.symbol = '|' THEN map.x
		WHEN map.symbol = '7' THEN map.x
		WHEN map.symbol = 'L' THEN map.x + 1
		WHEN map.symbol = 'J' THEN map.x
		WHEN map.symbol = 'F' THEN map.x
	    END
	    AND neighbors.y = CASE
		WHEN map.symbol = '-' THEN map.y
		WHEN map.symbol = '|' THEN map.y + 1
		WHEN map.symbol = '7' THEN map.y + 1
		WHEN map.symbol = 'L' THEN map.y
		WHEN map.symbol = 'J' THEN map.y - 1
		WHEN map.symbol = 'F' THEN map.y + 1
	    END
	)
    )
;

CREATE VIEW connected_neighbors AS
SELECT
    n.*
FROM neighbors n
INNER JOIN neighbors n2
    ON n.x = n2.neighbor_x AND n.y = n2.neighbor_y
    AND n.neighbor_x = n2.x AND n.neighbor_y = n2.y;

WITH RECURSIVE depths AS (
    SELECT
	s.x AS x,
	s.y AS y,
	s.symbol AS symbol,
	s.x as previous_x,
	s.x as previous_y,
	s.neighbor_x as next_x,
	s.neighbor_y as next_y,
	s.neighbor_symbol as next_symbol,
	0 AS d
    FROM connected_neighbors s
    WHERE s.symbol = 'S'
    UNION
    SELECT
	n.x AS x,
	n.y AS y,
	n.symbol AS symbol,
	s.x as previous_x,
	s.y as previous_y,
	n.neighbor_x as next_x,
	n.neighbor_y as next_y,
	n.neighbor_symbol as next_symbol,
	d + 1 AS d
    FROM depths s
    INNER JOIN connected_neighbors n
    ON s.next_x = n.x AND s.next_y = n.y
    WHERE (n.neighbor_x != s.x OR n.neighbor_y != s.y)
    AND n.symbol NOT IN ('S', '.')
)
SELECT MAX(d) FROM (
    SELECT x, y, MIN(d) AS d FROM depths GROUP BY x, y
) x;
