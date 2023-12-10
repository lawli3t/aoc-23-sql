CREATE AGGREGATE mul(bigint) ( SFUNC = int8mul, STYPE=bigint );

WITH asterisks AS (
    SELECT x, y FROM map WHERE symbol = '*'
),
asterisk_neighbors AS (
    SELECT 
	a_x AS x,
	a_y AS y,
	a.x AS map_x,
	a.y AS map_y
    FROM
	(SELECT x, y, generate_series(x-1, x+1) AS a_x FROM asterisks) a
	JOIN (SELECT x, y, generate_series(y-1, y+1) AS a_y FROM asterisks) b
	    ON a.x = b.x AND a.y = b.y
),
number_coordinates AS (
    SELECT
	id,
	generate_series(x, x_end) AS x,
	y,
	n
    FROM number_map
),
gear_candidates AS (
    SELECT
	n.n, a.map_x, a.map_y
    FROM
	number_coordinates n
	INNER JOIN asterisk_neighbors a
	    ON n.x = a.x AND n.y = a.y
    GROUP BY a.map_x, a.map_y, n.id, n.n
),
gear_ratios AS (
    SELECT
	mul(n) AS n, map_y, map_x
    FROM gear_candidates
    GROUP BY map_y, map_x
    HAVING COUNT(*) = 2
)
SELECT SUM(n) FROM gear_ratios;
