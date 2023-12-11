DROP MATERIALIZED VIEW IF EXISTS iterations;

CREATE MATERIALIZED VIEW iterations AS
WITH RECURSIVE dfs AS (
    SELECT
	nodes.id AS node_id,
	walk.direction,
	successor.id AS successor_id,
	successor.name AS successor_name,
	successor.l AS l,
	successor.r AS r,
	nodes.name AS start_node,
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
    WHERE nodes.name ILIKE '%A'
    UNION ALL
    SELECT
	successor_id AS node_id,
	walk.direction,
	successor.id AS successor_id,
	successor.name AS successor_name,
	successor.l AS l,
	successor.r AS r,
	start_node,
	iteration + 1 AS iteration
    FROM
	(
	    SELECT * FROM (
		SELECT
		    *,
		    rank() OVER (PARTITION BY start_node ORDER BY iteration DESC) AS n
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
    WHERE successor_name NOT ILIKE '%Z'
)
SELECT start_node, MAX(iteration)::bigint AS i FROM dfs GROUP BY start_node;

WITH RECURSIVE result AS (
    SELECT trim_array(i, 1) AS queue, i[cardinality(i)] AS cur, i[cardinality(i)] AS kgv FROM (
	SELECT array_agg(i) AS i FROM iterations
    ) x
    UNION
    SELECT trim_array(queue, 1) AS queue, queue[cardinality(queue)] AS cur, lcm(kgv, queue[cardinality(queue)]) AS kgv FROM result
    WHERE cardinality(queue) > 0
)
SELECT kgv FROM result ORDER BY kgv DESC LIMIT 1;
