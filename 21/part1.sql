WITH RECURSIVE fields AS (
    SELECT
	x, y, symbol,
	0 as iteration
    FROM symbols WHERE symbol = 'S'
    UNION
    SELECT
	neighbors.neighbor_x,
	neighbors.neighbor_y,
	neighbors.symbol,
	iteration + 1 AS iteration
    FROM (
	SELECT *, rank() OVER (ORDER BY iteration DESC) AS r FROM fields
    ) fields
    INNER JOIN neighbors ON (fields.x = neighbors.x AND fields.y = neighbors.y)
    WHERE neighbors.symbol != '#'
    AND iteration < 64
    AND fields.r = 1
)
SELECT COUNT(*) FROM fields WHERE iteration = 64;
