DROP TABLE data CASCADE;
DROP TYPE IF EXISTS color CASCADE;

CREATE TYPE color AS ENUM (
    'red',
    'green',
    'blue'
);

CREATE TABLE data (
    game_id INT NOT NULL,
    try_id INT NOT NULL,
    amount INT NOT NULL,
    color color NOT NULL
);

WITH parsed_input AS (
    SELECT
	substring(split[1] FROM '\d+') as game_id,
	try_id,
	string_to_array(
	    TRIM(unnest(string_to_array(TRIM(game), ','))),
	    ' '
	) AS balls
    FROM
	(SELECT string_to_array(line, ':') AS split FROM input) x,
	unnest(string_to_array(x.split[2], ';')) WITH ORDINALITY AS s (game, try_id)
)
INSERT INTO data (
    SELECT game_id::int, try_id::int, balls[1]::int, balls[2]::color FROM parsed_input
);

CREATE VIEW maximum_values AS (
    SELECT
	game_id,
	MAX(amount) FILTER (where color = 'green') AS max_green,
	MAX(amount) FILTER (where color = 'red') AS max_red,
	MAX(amount) FILTER (where color = 'blue') AS max_blue
    FROM data
    GROUP BY game_id
);

SELECT * FROM data;
SELECT * FROM maximum_values;
