DROP VIEW IF EXISTS maximum_range;
DROP TABLE IF EXISTS seeds;
DROP TABLE IF EXISTS seed_soil;
DROP TABLE IF EXISTS soil_fertilizer;
DROP TABLE IF EXISTS fertilizer_water;
DROP TABLE IF EXISTS water_light;
DROP TABLE IF EXISTS light_temperature;
DROP TABLE IF EXISTS temperature_humidity;
DROP TABLE IF EXISTS humidity_location;

CREATE TABLE seeds (
    idx SERIAL,
    id bigint
);

CREATE TABLE seed_soil (
    seed_id int8range,
    soil_id int8range
);

CREATE TABLE soil_fertilizer (
    soil_id int8range,
    fertilizer_id int8range
);

CREATE TABLE fertilizer_water (
    fertilizer_id int8range,
    water_id int8range
);

CREATE TABLE water_light (
    water_id int8range,
    light_id int8range
);

CREATE TABLE light_temperature (
    light_id int8range,
    temperature_id int8range
);

CREATE TABLE temperature_humidity (
    temperature_id int8range,
    humidity_id int8range
);

CREATE TABLE humidity_location (
    humidity_id int8range,
    location_id int8range
);

INSERT INTO seeds(id) SELECT seed_id::bigint FROM (
    SELECT unnest(string_to_array(TRIM(split[2]), ' ')) AS seed_id FROM
    (SELECT string_to_array(line, ':') AS split FROM input WHERE line ILIKE 'seeds:%' LIMIT 1) x
) y;

WITH map AS (
    SELECT
	string_to_array(line, ' ') AS split
    FROM input
    WHERE id > (SELECT id FROM input WHERE line = 'seed-to-soil map:')
    AND id < (SELECT id FROM input WHERE line = 'soil-to-fertilizer map:')
    AND line != ''
)
INSERT INTO seed_soil
SELECT
    ('[' || split[2]::bigint || ',' || split[2]::bigint + split[3]::bigint || ')')::int8range,
    ('[' || split[1]::bigint || ',' || split[1]::bigint + split[3]::bigint || ')')::int8range
FROM map;

WITH map AS (
    SELECT
	string_to_array(line, ' ') AS split
    FROM input
    WHERE id > (SELECT id FROM input WHERE line = 'soil-to-fertilizer map:')
    AND id < (SELECT id FROM input WHERE line = 'fertilizer-to-water map:')
    AND line != ''
)
INSERT INTO soil_fertilizer
SELECT
    ('[' || split[2]::bigint || ',' || split[2]::bigint + split[3]::bigint || ')')::int8range,
    ('[' || split[1]::bigint || ',' || split[1]::bigint + split[3]::bigint || ')')::int8range
FROM map;

WITH map AS (
    SELECT
	string_to_array(line, ' ') AS split
    FROM input
    WHERE id > (SELECT id FROM input WHERE line = 'fertilizer-to-water map:')
    AND id < (SELECT id FROM input WHERE line = 'water-to-light map:')
    AND line != ''
)
INSERT INTO fertilizer_water
SELECT
    ('[' || split[2]::bigint || ',' || split[2]::bigint + split[3]::bigint || ')')::int8range,
    ('[' || split[1]::bigint || ',' || split[1]::bigint + split[3]::bigint || ')')::int8range
FROM map;

WITH map AS (
    SELECT
	string_to_array(line, ' ') AS split
    FROM input
    WHERE id > (SELECT id FROM input WHERE line = 'water-to-light map:')
    AND id < (SELECT id FROM input WHERE line = 'light-to-temperature map:')
    AND line != ''
)
INSERT INTO water_light
SELECT
    ('[' || split[2]::bigint || ',' || split[2]::bigint + split[3]::bigint || ')')::int8range,
    ('[' || split[1]::bigint || ',' || split[1]::bigint + split[3]::bigint || ')')::int8range
FROM map;

WITH map AS (
    SELECT
	string_to_array(line, ' ') AS split
    FROM input
    WHERE id > (SELECT id FROM input WHERE line = 'light-to-temperature map:')
    AND id < (SELECT id FROM input WHERE line = 'temperature-to-humidity map:')
    AND line != ''
)
INSERT INTO light_temperature
SELECT
    ('[' || split[2]::bigint || ',' || split[2]::bigint + split[3]::bigint || ')')::int8range,
    ('[' || split[1]::bigint || ',' || split[1]::bigint + split[3]::bigint || ')')::int8range
FROM map;

WITH map AS (
    SELECT
	string_to_array(line, ' ') AS split
    FROM input
    WHERE id > (SELECT id FROM input WHERE line = 'temperature-to-humidity map:')
    AND id < (SELECT id FROM input WHERE line = 'humidity-to-location map:')
    AND line != ''
)
INSERT INTO temperature_humidity
SELECT
    ('[' || split[2]::bigint || ',' || split[2]::bigint + split[3]::bigint || ')')::int8range,
    ('[' || split[1]::bigint || ',' || split[1]::bigint + split[3]::bigint || ')')::int8range
FROM map;

WITH map AS (
    SELECT
	string_to_array(line, ' ') AS split
    FROM input
    WHERE id > (SELECT id FROM input WHERE line = 'humidity-to-location map:')
    AND line != ''
)
INSERT INTO humidity_location
SELECT
    ('[' || split[2]::bigint || ',' || split[2]::bigint + split[3]::bigint || ')')::int8range,
    ('[' || split[1]::bigint || ',' || split[1]::bigint + split[3]::bigint || ')')::int8range
FROM map;

CREATE OR REPLACE VIEW maximum_range AS (
    WITH all_ranges(range) AS (
	SELECT seed_id FROM seed_soil
	UNION
	SELECT soil_id FROM seed_soil
	UNION
	SELECT soil_id FROM soil_fertilizer
	UNION
	SELECT fertilizer_id FROM soil_fertilizer
	UNION
	SELECT fertilizer_id FROM fertilizer_water
	UNION
	SELECT water_id FROM fertilizer_water
	UNION
	SELECT water_id FROM water_light
	UNION
	SELECT light_id FROM water_light
	UNION
	SELECT light_id FROM light_temperature
	UNION
	SELECT temperature_id FROM light_temperature
	UNION
	SELECT temperature_id FROM temperature_humidity
	UNION
	SELECT humidity_id FROM temperature_humidity
	UNION
	SELECT humidity_id FROM humidity_location
	UNION
	SELECT location_id FROM humidity_location
    ),
    maximum_id AS (
	SELECT MAX(id) AS id FROM (
	    SELECT MAX(UPPER(range)) AS id FROM all_ranges
	    UNION
	    SELECT MAX(id) AS id FROM seeds
	) x
    )
    SELECT ('{[0,'|| (SELECT id::text FROM maximum_id) ||']}')::int8multirange AS range
);

INSERT INTO seed_soil
SELECT identity_range, identity_range FROM (
    SELECT
	unnest(
	    (SELECT * FROM maximum_range)
	    - ('{'||string_agg(seed_id::text, ',')||'}')::int8multirange
	    - ('{'||string_agg(soil_id::text, ',')||'}')::int8multirange
	) AS identity_range
    FROM seed_soil
) x;
INSERT INTO soil_fertilizer
SELECT identity_range, identity_range FROM (
    SELECT
	unnest(
	    (SELECT * FROM maximum_range)
	    - ('{'||string_agg(soil_id::text, ',')||'}')::int8multirange
	    - ('{'||string_agg(fertilizer_id::text, ',')||'}')::int8multirange
	) AS identity_range
    FROM soil_fertilizer
) x;
INSERT INTO fertilizer_water
SELECT identity_range, identity_range FROM (
    SELECT
	unnest(
	    (SELECT * FROM maximum_range)
	    - ('{'||string_agg(fertilizer_id::text, ',')||'}')::int8multirange
	    - ('{'||string_agg(water_id::text, ',')||'}')::int8multirange
	) AS identity_range
    FROM fertilizer_water
) x;
INSERT INTO water_light
SELECT identity_range, identity_range FROM (
    SELECT
	unnest(
	    (SELECT * FROM maximum_range)
	    - ('{'||string_agg(water_id::text, ',')||'}')::int8multirange
	    - ('{'||string_agg(light_id::text, ',')||'}')::int8multirange
	) AS identity_range
    FROM water_light
) x;
INSERT INTO light_temperature
SELECT identity_range, identity_range FROM (
    SELECT
	unnest(
	    (SELECT * FROM maximum_range)
	    - ('{'||string_agg(light_id::text, ',')||'}')::int8multirange
	    - ('{'||string_agg(temperature_id::text, ',')||'}')::int8multirange
	) AS identity_range
    FROM light_temperature
) x;
INSERT INTO temperature_humidity
SELECT identity_range, identity_range FROM (
    SELECT
	unnest(
	    (SELECT * FROM maximum_range)
	    - ('{'||string_agg(temperature_id::text, ',')||'}')::int8multirange
	    - ('{'||string_agg(humidity_id::text, ',')||'}')::int8multirange
	) AS identity_range
    FROM temperature_humidity
) x;
INSERT INTO humidity_location
SELECT identity_range, identity_range FROM (
    SELECT
	unnest(
	    (SELECT * FROM maximum_range)
	    - ('{'||string_agg(humidity_id::text, ',')||'}')::int8multirange
	    - ('{'||string_agg(location_id::text, ',')||'}')::int8multirange
	) AS identity_range
    FROM humidity_location
) x;

CREATE INDEX idx_seed_soil_seed ON seed_soil USING GIST (seed_id);
CREATE INDEX idx_seed_soil_soil ON seed_soil USING GIST (soil_id);
CREATE INDEX idx_soil_fertilizer_soil ON soil_fertilizer USING GIST (soil_id);
CREATE INDEX idx_soil_fertilizer_fertilizer ON soil_fertilizer USING GIST (fertilizer_id);
CREATE INDEX idx_fetilizer_water_fertilizer ON fertilizer_water USING GIST (fertilizer_id);
CREATE INDEX idx_fetilizer_water_water ON fertilizer_water USING GIST (water_id);
CREATE INDEX idx_water_light_water ON water_light USING GIST (water_id);
CREATE INDEX idx_water_light_light ON water_light USING GIST (light_id);
CREATE INDEX idx_light_temperature_light ON light_temperature USING GIST (light_id);
CREATE INDEX idx_light_temperature_temperature ON light_temperature USING GIST (temperature_id);
CREATE INDEX idx_temperature_humidity_temperature ON temperature_humidity USING GIST (temperature_id);
CREATE INDEX idx_temperature_humidity_humidity ON temperature_humidity USING GIST (humidity_id);
CREATE INDEX idx_humidity_location_humidity ON humidity_location USING GIST (humidity_id);
CREATE INDEX idx_humidity_location_location ON humidity_location USING GIST (location_id);
