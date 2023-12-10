DROP TABLE IF EXISTS points;

CREATE TABLE points (
    game_id int,
    cnt int
);

DROP INDEX IF EXISTS idx_points_game_id;
CREATE UNIQUE INDEX on points(game_id);

WITH points AS (
    SELECT
	c.game_id, COUNT(*) AS cnt
    FROM 
	candidates c
	INNER JOIN winners w
	    ON c.game_id = w.game_id AND c.n = w.n
    GROUP BY c.game_id
)
INSERT INTO points
SELECT
    a.game_id,
    COALESCE(cnt, 0)
FROM
    (SELECT distinct game_id FROM candidates) a
    LEFT JOIN points
	ON (a.game_id = points.game_id);

WITH RECURSIVE games(game_id, cnt, d) AS (
    SELECT *, 1 FROM points
    UNION ALL
    SELECT points.game_id, points.cnt, g.d FROM
    (
	SELECT
	    cnt,
	    d + 1 as d,
	    generate_series(game_id + 1, game_id + cnt) AS game_id
	FROM (
	    SELECT
		*,
		RANK() OVER (ORDER BY d DESC) AS r
	    FROM
		games
	) x
	WHERE x.r = 1
    ) g
    INNER JOIN points ON g.game_id = points.game_id
)
SELECT COUNT(*) FROM games;
