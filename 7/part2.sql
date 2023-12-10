DROP INDEX IF EXISTS hand_variations_hand_id_variation_id_idx_idx;
DROP VIEW IF EXISTS joker_variations;
DROP VIEW IF EXISTS grouped_hands;
DROP TABLE IF EXISTS hand_variations;
DROP TYPE IF EXISTS face_variations;

CREATE TYPE face_variations AS ENUM (
    'A', 'K', 'Q', 'T', '9', '8', '7', '6', '5', '4', '3', '2', 'J'
);

CREATE TABLE hand_variations (
    id SERIAL,
    hand_id int,
    variation_id int,
    idx int,
    face face_variations,
    bid int
);

INSERT INTO hand_variations (hand_id, variation_id, idx, face, bid)
SELECT 
    hand_id,
    1,
    idx,
    face::char::face_variations,
    bid
FROM hands WHERE hand_id NOT IN (
    SELECT DISTINCT hand_id FROM hands h WHERE h.face = 'J'
);

CREATE VIEW joker_variations AS (
    SELECT
	hand_id,
	idx,
	unnest(enum_range('A'::face_variations, '2'::face_variations)) as face
    FROM hands 
    WHERE face = 'J'
);

WITH generated_hands AS (
    SELECT
	h2.hand_id,
	h2.idx,
	h2.face::char::face_variations AS face,
	h2.bid,
	v1.face AS v1_face,
	v2.face AS v2_face,
	v3.face AS v3_face,
	v4.face AS v4_face,
	v5.face AS v5_face,
	RANK() OVER (PARTITION BY hands.hand_id ORDER BY v1.face, v2.face, v3.face, v4.face, v5.face) AS variation_id
    FROM
	(SELECT DISTINCT hand_id FROM hands WHERE face = 'J') hands
	LEFT OUTER JOIN joker_variations v1
	    ON v1.hand_id = hands.hand_id AND v1.idx = 1
	LEFT OUTER JOIN joker_variations v2
	    ON v2.hand_id = hands.hand_id AND v2.idx = 2
	LEFT OUTER JOIN joker_variations v3
	    ON v3.hand_id = hands.hand_id AND v3.idx = 3
	LEFT OUTER JOIN joker_variations v4
	    ON v4.hand_id = hands.hand_id AND v4.idx = 4
	LEFT OUTER JOIN joker_variations v5
	    ON v5.hand_id = hands.hand_id AND v5.idx = 5
	INNER JOIN hands h2
	    ON h2.hand_id = hands.hand_id
)
INSERT INTO hand_variations(hand_id, variation_id, idx, face, bid)
SELECT
    hand_id, variation_id, idx,
    CASE
	WHEN idx = 1 THEN COALESCE(v1_face, face)
	WHEN idx = 2 THEN COALESCE(v2_face, face)
	WHEN idx = 3 THEN COALESCE(v3_face, face)
	WHEN idx = 4 THEN COALESCE(v4_face, face)
	WHEN idx = 5 THEN COALESCE(v5_face, face)
    END AS face,
    bid
FROM generated_hands
ORDER BY hand_id, variation_id, idx
;

CREATE UNIQUE INDEX ON hand_variations(hand_id, variation_id, idx);

CREATE VIEW grouped_hands AS (
    SELECT hand_id, variation_id, COUNT(*) AS cnt, face FROM hand_variations GROUP BY hand_id, variation_id, face
);

WITH evaluated_hands AS (
    SELECT
	h.id,
	h.hand_id,
	h.variation_id,
	h.bid,
	c1.face::char::face_variations AS c1_face,
	c2.face::char::face_variations AS c2_face,
	c3.face::char::face_variations AS c3_face,
	c4.face::char::face_variations AS c4_face,
	c5.face::char::face_variations AS c5_face,
	EXISTS (SELECT FROM grouped_hands WHERE hand_id = h.hand_id AND variation_id = h.variation_id AND cnt = 5) AS five_of_a_kind,
	EXISTS (SELECT FROM grouped_hands WHERE hand_id = h.hand_id AND variation_id = h.variation_id AND cnt = 4) AS four_of_a_kind,
	(
	    EXISTS (SELECT FROM grouped_hands WHERE hand_id = h.hand_id AND variation_id = h.variation_id AND cnt = 3)
	    AND EXISTS (SELECT FROM grouped_hands WHERE hand_id = h.hand_id AND variation_id = h.variation_id AND cnt = 2)
	) AS full_house,
	EXISTS (SELECT FROM grouped_hands WHERE hand_id = h.hand_id AND variation_id = h.variation_id AND cnt = 3) AS three_of_a_kind,
	(SELECT COUNT(*) FROM grouped_hands WHERE hand_id = h.hand_id AND variation_id = h.variation_id AND cnt = 2) = 2 AS two_pair,
	EXISTS (SELECT FROM grouped_hands WHERE hand_id = h.hand_id AND variation_id = h.variation_id AND cnt = 2) AS one_pair
    FROM (
	SELECT MAX(id) AS id, hand_id, variation_id, MAX(bid) AS bid FROM hand_variations GROUP BY hand_id, variation_id
    ) h
	LEFT JOIN hands c1 ON c1.idx = 1 AND h.hand_id = c1.hand_id
	LEFT JOIN hands c2 ON c2.idx = 2 AND h.hand_id = c2.hand_id
	LEFT JOIN hands c3 ON c3.idx = 3 AND h.hand_id = c3.hand_id
	LEFT JOIN hands c4 ON c4.idx = 4 AND h.hand_id = c4.hand_id
	LEFT JOIN hands c5 ON c5.idx = 5 AND h.hand_id = c5.hand_id
),
ranked_hands AS (
    SELECT
    *,
    RANK() OVER (PARTITION BY hand_id ORDER BY five_of_a_kind DESC, four_of_a_kind DESC, full_house DESC, three_of_a_kind DESC, two_pair DESC, one_pair DESC, c1_face, c2_face, c3_face, c4_face, c5_face) AS r
    FROM evaluated_hands
),
best_hands AS (
    SELECT * FROM ranked_hands WHERE r = 1
),
winnings AS (
    SELECT
	*,
	row_number() OVER (ORDER BY five_of_a_kind, four_of_a_kind, full_house, three_of_a_kind, two_pair, one_pair, c1_face DESC, c2_face DESC, c3_face DESC, c4_face DESC, c5_face DESC) * bid AS winnings
    FROM best_hands
WHERE id = (SELECT MIN(id) FROM best_hands bh WHERE bh.hand_id = best_hands.hand_id)
)
SELECT SUM(winnings) FROM winnings;
