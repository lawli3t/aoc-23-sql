DROP TABLE IF EXISTS candidates;
DROP TABLE IF EXISTS winners;

CREATE TABLE candidates (
    game_id int,
    n int
);

CREATE TABLE winners (
    game_id int,
    n int
);

WITH split_input AS (
    SELECT id, string_to_array(line, ':') AS split FROM input
),
split_numbers AS (
    SELECT id, string_to_array(TRIM(split[2]) , '|') AS split FROM split_input
),
candidates AS (
    SELECT id, unnest(regexp_split_to_array(TRIM(split[2]), '\s+')) AS n FROM split_numbers
)
INSERT INTO candidates SELECT id, n::int FROM candidates;

WITH split_input AS (
    SELECT id, string_to_array(line, ':') AS split FROM input
),
split_numbers AS (
    SELECT id, string_to_array(TRIM(split[2]) , '|') AS split FROM split_input
),
winners AS (
    SELECT id, unnest(regexp_split_to_array(TRIM(split[1]), '\s+')) AS n FROM split_numbers
)
INSERT INTO winners SELECT id, n::int FROM winners;
