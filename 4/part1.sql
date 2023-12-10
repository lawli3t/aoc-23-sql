WITH points AS (
    SELECT
	c.game_id, POWER(2, COUNT(*) - 1) AS pts
    FROM 
	candidates c
	INNER JOIN winners w
	    ON c.game_id = w.game_id AND c.n = w.n
    GROUP BY c.game_id
)
SELECT SUM(pts) FROM points;
