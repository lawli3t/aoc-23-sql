WITH RECURSIVE hashes AS (
    SELECT
	id,
	elements[1] AS curr,
	elements[2:] AS elements,
	MOD(ASCII(elements[1]) * 17, 256) AS hash
    FROM instructions
    UNION
    SELECT
	id,
	elements[1],
	elements[2:] AS elements,
	MOD(((hash + ASCII(elements[1])) * 17), 256) AS hash
    FROM hashes
    WHERE ARRAY_LENGTH(elements, 1) > 0
)
SELECT SUM(hash) FROM hashes WHERE elements = '{}';
