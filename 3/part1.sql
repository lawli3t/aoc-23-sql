WITH neighbor_coordinates AS (
    SELECT a.id, a.n, x, y
    FROM
    (
	SELECT
	    id,
	    n,
	    generate_series(x - 1, x_end + 1) AS x
	FROM number_map
    ) a
    INNER JOIN
    (
	SELECT
	    id,
	    generate_series(y - 1, y + 1) AS y
	FROM number_map
    ) b
    ON a.id = b.id
),
part_ids AS (
    SELECT
	DISTINCT id
    FROM 
	neighbor_coordinates n
	INNER JOIN map m
	    ON m.x = n.x AND m.y = n.y
    WHERE
	symbol NOT IN ('1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '.')
)
SELECT SUM(n) FROM number_map WHERE id IN (SELECT id FROM part_ids);
