DROP INDEX IF EXISTS hands_id_idx;
DROP INDEX IF EXISTS hands_hand_id_idx_idx;
DROP TABLE IF EXISTS hands CASCADE;
DROP TYPE IF EXISTS face;

CREATE TYPE face AS ENUM (
    'A', 'K', 'Q', 'J', 'T', '9', '8', '7', '6', '5', '4', '3', '2'
);

CREATE TABLE hands (
    id SERIAL,
    hand_id int,
    idx int,
    face face,
    bid int
);

CREATE UNIQUE INDEX ON hands(id);
CREATE UNIQUE INDEX ON hands(hand_id, idx);

WITH split_lines AS (
    SELECT id, string_to_array(line, ' ') AS split FROM input
)
INSERT INTO hands(hand_id, idx, face, bid)
SELECT
    id AS hand_id,
    generate_series(1, 5),
    CAST(unnest(string_to_array(split[1], NULL)) AS face),
    split[2]::int
FROM split_lines;
