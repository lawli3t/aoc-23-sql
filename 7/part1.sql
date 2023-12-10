DROP VIEW IF EXISTS grouped_hands;

CREATE VIEW grouped_hands AS (
    SELECT hand_id, COUNT(*) AS cnt, face FROM hands GROUP BY hand_id, face
);

WITH evaluated_hands AS (
SELECT
    hands.hand_id,
    hands.bid,
    c1.face AS c1_face,
    c2.face AS c2_face,
    c3.face AS c3_face,
    c4.face AS c4_face,
    c5.face AS c5_face,
    EXISTS (SELECT FROM grouped_hands WHERE hand_id = hands.hand_id AND cnt = 5) AS five_of_a_kind,
    EXISTS (SELECT FROM grouped_hands WHERE hand_id = hands.hand_id AND cnt = 4) AS four_of_a_kind,
    (
	EXISTS (SELECT FROM grouped_hands WHERE hand_id = hands.hand_id AND cnt = 3)
	AND EXISTS (SELECT FROM grouped_hands WHERE hand_id = hands.hand_id AND cnt = 2)
    ) AS full_house,
    EXISTS (SELECT FROM grouped_hands WHERE hand_id = hands.hand_id AND cnt = 3) AS three_of_a_kind,
    (SELECT COUNT(*) FROM grouped_hands WHERE hand_id = hands.hand_id AND cnt = 2) = 2 AS two_pair,
    EXISTS (SELECT FROM grouped_hands WHERE hand_id = hands.hand_id AND cnt = 2) AS one_pair
FROM (
    SELECT hand_id, bid FROM hands GROUP BY hand_id, bid
) hands
    LEFT JOIN hands c1 ON c1.idx = 1 AND hands.hand_id = c1.hand_id
    LEFT JOIN hands c2 ON c2.idx = 2 AND hands.hand_id = c2.hand_id
    LEFT JOIN hands c3 ON c3.idx = 3 AND hands.hand_id = c3.hand_id
    LEFT JOIN hands c4 ON c4.idx = 4 AND hands.hand_id = c4.hand_id
    LEFT JOIN hands c5 ON c5.idx = 5 AND hands.hand_id = c5.hand_id
),
winnings AS (
    SELECT
	*,
	row_number() OVER (ORDER BY five_of_a_kind, four_of_a_kind, full_house, three_of_a_kind, two_pair, one_pair, c1_face DESC, c2_face DESC, c3_face DESC, c4_face DESC, c5_face DESC) * bid AS winnings
    FROM evaluated_hands
)
SELECT SUM(winnings) FROM winnings
;
