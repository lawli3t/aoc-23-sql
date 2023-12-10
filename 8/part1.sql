WITH RECURSIVE dfs AS (
    SELECT
	nodes.id AS node_id,
	walk.direction,
	successor.id AS successor_id,
	successor.name AS successor_name,
	successor.l AS l,
	successor.r AS r,
	1 AS iteration
    FROM nodes
    INNER JOIN walk
	ON walk.id = 1
    INNER JOIN nodes successor
	ON successor.id = (
	    CASE
		WHEN walk.direction = 'L' THEN nodes.l
		ELSE nodes.r
	    END
	)
    WHERE nodes.name = 'AAA'
    UNION ALL
    SELECT
	successor_id AS node_id,
	walk.direction,
	successor.id AS successor_id,
	successor.name AS successor_name,
	successor.l AS l,
	successor.r AS r,
	iteration + 1 AS iteration
    FROM
	(
	    SELECT * FROM (
		SELECT
		    *,
		    row_number() OVER () AS n
		FROM dfs
	    ) x WHERE n = 1
	) nodes
    JOIN walk
	ON walk.id = MOD(
	    iteration,
	    (SELECT MAX(id) FROM walk)
	) + 1
    JOIN nodes successor
	ON successor.id = (
	    CASE
		WHEN walk.direction = 'L' THEN nodes.l
		ELSE nodes.r
	    END
	)
    WHERE successor_name != 'ZZZ'
)
SELECT * FROM dfs;
