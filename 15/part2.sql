DROP VIEW IF EXISTS instructions_hashes;
DROP VIEW IF EXISTS hash_data;
DROP TABLE IF EXISTS instructions2;

CREATE TABLE instructions2 (
    id SERIAL,
    instruction text[]
);

INSERT INTO instructions2(id, instruction)
SELECT
    id,
    regexp_match(array_to_string(elements, ''), '([a-z]*)([-=])([0-9]*)')
FROM instructions;

CREATE VIEW hash_data AS (
    SELECT
	id,
	string_to_array(instruction[1], NULL) AS elements
    FROM instructions2
);

CREATE VIEW instructions_hashes AS
WITH RECURSIVE hashes AS (
    SELECT
	id,
	elements[1] AS curr,
	elements[2:] AS elements,
	MOD(ASCII(elements[1]) * 17, 256) AS hash
    FROM hash_data
    UNION
    SELECT
	id,
	elements[1],
	elements[2:] AS elements,
	MOD(((hash + ASCII(elements[1])) * 17), 256) AS hash
    FROM hashes
    WHERE ARRAY_LENGTH(elements, 1) > 0
)
SELECT
    instructions2.*, hash
FROM instructions2
    INNER JOIN hashes ON hashes.id = instructions2.id
WHERE elements = '{}';

EXPLAIN ANALYZE
WITH RECURSIVE hashmap AS (
    SELECT
	generate_series(0, 255) AS id,
	ARRAY[]::int[] AS focal_lengths,
	ARRAY[]::text[] AS contents,
	NULL::text[] AS instruction,
	0 as iteration
    UNION
    SELECT
	hashmap.id,
	CASE 
	    WHEN i.instruction[2] = '=' AND contents @> ARRAY[i.instruction[1]] THEN
		focal_lengths[1:(ARRAY_POSITION(contents, i.instruction[1]) - 1)]
		|| ARRAY[i.instruction[3]::int]
		|| focal_lengths[(ARRAY_POSITION(contents, i.instruction[1]) + 1):2147483647]
	    WHEN i.instruction[2] = '=' AND NOT (contents @> ARRAY[i.instruction[1]]) THEN
		focal_lengths || ARRAY[i.instruction[3]::int]
	    WHEN i.instruction[2] = '-' AND contents @> ARRAY[i.instruction[1]] THEN
		focal_lengths[1:(ARRAY_POSITION(contents, i.instruction[1]) - 1)]
		|| focal_lengths[(ARRAY_POSITION(contents, i.instruction[1]) + 1):2147483647]
	    ELSE focal_lengths
	END,
	CASE 
	    WHEN i.instruction[2] = '=' AND NOT (contents @> ARRAY[i.instruction[1]]) THEN
		contents || i.instruction[1]
	    WHEN i.instruction[2] = '-' THEN
		ARRAY_REMOVE(contents, i.instruction[1])
	    ELSE contents
	END,
	i.instruction,
	iteration + 1 AS iteration
    FROM hashmap
    LEFT JOIN instructions_hashes i
	ON hashmap.iteration + 1 = i.id AND hashmap.id = i.hash
    WHERE iteration < (SELECT MAX(id) FROM instructions2)
)
SELECT SUM(box * focal_length * idx) FROM (
    SELECT
	id + 1 AS box,
	iteration,
	unnest(focal_lengths) AS focal_length,
	generate_series(1, ARRAY_LENGTH(contents, 1)) AS idx
    FROM hashmap
    WHERE
	iteration = (SELECT MAX(iteration) FROM hashmap)
    ORDER BY iteration, idx
) x
