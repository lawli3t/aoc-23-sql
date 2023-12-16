DROP MATERIALIZED VIEW IF EXISTS combinations;

DROP INDEX IF EXISTS idx_combinations;
DROP INDEX IF EXISTS idx_symbols;
CREATE UNIQUE INDEX idx_symbols ON symbols (id, idx);

CREATE MATERIALIZED VIEW combinations AS
WITH RECURSIVE combinations AS (
    SELECT
	s1.id,
	ARRAY[COALESCE(s2.symbol, s1.symbol)] AS line,
	s1.idx
    FROM symbols s1
    LEFT JOIN (
	SELECT
	    id, idx,
	    unnest(ARRAY['.', '#']) AS symbol
	FROM symbols x
	WHERE x.symbol = '?'
    ) s2 ON s1.id = s2.id AND s1.idx = s2.idx
    WHERE s1.idx = 1
    UNION
    SELECT
	c.id,
	line || COALESCE(s2.symbol, s1.symbol),
	s1.idx
    FROM combinations c
    INNER JOIN symbols s1 ON s1.id = c.id AND s1.idx = c.idx + 1
    LEFT JOIN (
	SELECT
	    x.id, x.idx,
	    unnest(ARRAY['.', '#']) AS symbol
	FROM symbols x
	WHERE
	    x.symbol ='?'
    ) s2 ON s2.id = c.id AND s2.idx = c.idx + 1
)
SELECT 
    id, line, row_number() OVER () AS combination_id
FROM combinations
WHERE idx = (SELECT MAX(idx) FROM symbols x WHERE x.id = combinations.id);

CREATE UNIQUE INDEX idx_combinations ON combinations(id, combination_id);

WITH grouped_elements AS (
    SELECT id, combination_id, elem, idx - row_number() OVER (PARTITION BY id, combination_id ORDER BY elem, idx) AS grp, idx FROM combinations x, unnest(line) WITH ORDINALITY AS a(elem, idx)
),
counted_groups AS (
    SELECT id, combination_id, COUNT(*) AS cnt, MIN(idx) AS idx FROM grouped_elements WHERE elem ='#' GROUP BY id, combination_id, grp
),
aggregated_groups AS (
    SELECT
	id, array_agg(cnt) AS pattern
    FROM counted_groups 
    GROUP BY id, combination_id
),
counted_matches AS (
    SELECT patterns.id, COUNT(*) AS cnt FROM aggregated_groups
    INNER JOIN patterns ON patterns.id = aggregated_groups.id AND patterns.pattern::bigint[] = aggregated_groups.pattern
    GROUP BY patterns.id
)
SELECT SUM(cnt) FROM counted_matches;
