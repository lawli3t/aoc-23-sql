WITH seed_soils AS (
    SELECT
	id,
	id - LOWER(seed_id) + LOWER (soil_id) AS soil_id
    FROM seeds
	LEFT JOIN seed_soil ON seed_soil.seed_id @> id
),
soils_fertilizer AS (
    SELECT
	a.*,
	a.soil_id - LOWER(b.soil_id) + LOWER (b.fertilizer_id) AS fertilizer_id
    FROM seed_soils a
	LEFT JOIN soil_fertilizer b ON b.soil_id @> a.soil_id
),
fertilizer_waters AS (
    SELECT
	a.*,
	a.fertilizer_id - LOWER(b.fertilizer_id) + LOWER (b.water_id) AS water_id
    FROM soils_fertilizer a
	LEFT JOIN fertilizer_water b ON b.fertilizer_id @> a.fertilizer_id
),
water_lights AS (
    SELECT
	a.*,
	a.water_id - LOWER(b.water_id) + LOWER (b.light_id) AS light_id
    FROM fertilizer_waters a
	LEFT JOIN water_light b ON b.water_id @> a.water_id
),
light_temperatures AS (
    SELECT
	a.*,
	a.light_id - LOWER(b.light_id) + LOWER (b.temperature_id) AS temperature_id
    FROM water_lights a
	LEFT JOIN light_temperature b ON b.light_id @> a.light_id
),
temperature_humidities AS (
    SELECT
	a.*,
	a.temperature_id - LOWER(b.temperature_id) + LOWER (b.humidity_id) AS humidity_id
    FROM light_temperatures a
	LEFT JOIN temperature_humidity b ON b.temperature_id @> a.temperature_id
),
humidity_locations AS (
    SELECT
	a.*,
	a.humidity_id - LOWER(b.humidity_id) + LOWER (b.location_id) AS location_id
    FROM temperature_humidities a
	LEFT JOIN humidity_location b ON b.humidity_id @> a.humidity_id
)
SELECT MIN(location_id) FROM humidity_locations;
