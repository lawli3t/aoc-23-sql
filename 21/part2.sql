WITH RECURSIVE fields AS (
    SELECT
	x, y,
	0 as iteration
    FROM symbols WHERE symbol = 'S'
    UNION
    SELECT
	n.x,
	n.y,
	n.iteration
    FROM (
	SELECT
	    unnest(ARRAY[x + 1, x - 1, x, x]) AS x,
	    unnest(ARRAY[y, y, y + 1, y - 1]) AS y,
	    iteration + 1 AS iteration
	FROM (SELECT x, y, iteration, rank() OVER (ORDER BY iteration DESC) AS r FROM fields) f
	WHERE f.r = 1
    ) n
    INNER JOIN symbols
	ON (symbols.x = MOD(MOD(n.x, 131) + 131, 131)) AND (symbols.y = MOD(MOD(n.y, 131) + 131, 131))
    WHERE symbols.symbol != '#'
    AND iteration <= (SELECT x FROM symbols WHERE symbol = 'S') + (SELECT COUNT(DISTINCT y) FROM symbols) * 2
),
data AS (
    SELECT
	i,
	(
	    SELECT COUNT(*) AS cnt FROM
	    (SELECT FROM fields WHERE iteration > 0 AND iteration <= a.i GROUP BY x, y HAVING MOD(MIN(iteration), 2) = MOD(a.i, 2)) t
	)
    FROM (
	VALUES
	((SELECT x FROM symbols WHERE symbol = 'S')),
	((SELECT x FROM symbols WHERE symbol = 'S') + (SELECT COUNT(DISTINCT y) FROM symbols)),
	((SELECT x FROM symbols WHERE symbol = 'S') + (SELECT COUNT(DISTINCT y) FROM symbols) * 2)
    ) AS a(i)
),
f AS (
    SELECT array_agg(cnt) AS f FROM (SELECT cnt FROM data ORDER BY i) x
)
SELECT a * POW(n, 2) + b * n + c, * FROM (
    SELECT
	(f[3] - 2 * f[2] + f[1]) / 2 AS a,
	(f[2] - f[1] - ((f[3] - 2 * f[2] + f[1]) / 2)) AS b,
	f[1] AS c,
	(26501365 - (SELECT x FROM symbols WHERE symbol = 'S')) / (SELECT COUNT(DISTINCT y) FROM symbols) AS n
    FROM f
) x;
