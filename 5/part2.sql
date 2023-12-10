WITH seed_ranges AS (
    SELECT 
	int8range(a.id, b.id + a.id) as range
    FROM 
	(SELECT *, row_number() OVER () AS n FROM seeds WHERE MOD(idx, 2) = 1) a
	JOIN (SELECT *, row_number() OVER () AS n FROM seeds WHERE MOD(idx, 2) = 0) b
	    ON a.n = b.n
),
soil_ranges AS (
    SELECT
	int8range(
	    LOWER(intersection) - LOWER(seed_id) + LOWER(soil_id),
	    UPPER(intersection) - LOWER(seed_id) + LOWER(soil_id)
	) as range
    FROM (
	SELECT
	    seed_id,
	    soil_id,
	    range * seed_soil.seed_id AS intersection
	FROM seed_ranges
	    INNER JOIN seed_soil ON range && seed_soil.seed_id
    ) x
),
fertilizer_ranges AS (
    SELECT
	int8range(
	    LOWER(intersection) - LOWER(soil_id) + LOWER(fertilizer_id),
	    UPPER(intersection) - LOWER(soil_id) + LOWER(fertilizer_id)
	) as range
    FROM (
	SELECT
	    soil_id,
	    fertilizer_id,
	    range * soil_id AS intersection
	FROM soil_ranges
	    INNER JOIN soil_fertilizer ON range && soil_id
    ) x
),
water_ranges AS (
    SELECT
	int8range(
	    LOWER(intersection) - LOWER(fertilizer_id) + LOWER(water_id),
	    UPPER(intersection) - LOWER(fertilizer_id) + LOWER(water_id)
	) as range
    FROM (
	SELECT
	    fertilizer_id,
	    water_id,
	    range * fertilizer_id AS intersection
	FROM fertilizer_ranges
	    INNER JOIN fertilizer_water ON range && fertilizer_id
    ) x
),
light_ranges AS (
    SELECT
	int8range(
	    LOWER(intersection) - LOWER(water_id) + LOWER(light_id),
	    UPPER(intersection) - LOWER(water_id) + LOWER(light_id)
	) as range
    FROM (
	SELECT
	    water_id,
	    light_id,
	    range * water_id AS intersection
	FROM water_ranges
	    INNER JOIN water_light ON range && water_id
    ) x
),
temperature_ranges AS (
    SELECT
	int8range(
	    LOWER(intersection) - LOWER(light_id) + LOWER(temperature_id),
	    UPPER(intersection) - LOWER(light_id) + LOWER(temperature_id)
	) as range
    FROM (
	SELECT
	    light_id,
	    temperature_id,
	    range * light_id AS intersection
	FROM light_ranges
	    INNER JOIN light_temperature ON range && light_id
    ) x
),
humidity_ranges AS (
    SELECT
	int8range(
	    LOWER(intersection) - LOWER(temperature_id) + LOWER(humidity_id),
	    UPPER(intersection) - LOWER(temperature_id) + LOWER(humidity_id)
	) as range
    FROM (
	SELECT
	    temperature_id,
	    humidity_id,
	    range * temperature_id AS intersection
	FROM temperature_ranges
	    INNER JOIN temperature_humidity ON range && temperature_id
    ) x
),
location_ranges AS (
    SELECT
	int8range(
	    LOWER(intersection) - LOWER(humidity_id) + LOWER(location_id),
	    UPPER(intersection) - LOWER(humidity_id) + LOWER(location_id)
	) as range
    FROM (
	SELECT
	    humidity_id,
	    location_id,
	    range * humidity_id AS intersection
	FROM humidity_ranges
	    INNER JOIN humidity_location ON range && humidity_id
    ) x
)
SELECT MIN(LOWER(range)) FROM location_ranges;
