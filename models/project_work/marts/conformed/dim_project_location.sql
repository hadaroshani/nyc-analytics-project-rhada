{{ config(alias='dim_location') }}

-- Grain: one row per ZIP code, plus an Unknown row (key 0)

WITH all_locations AS (
    SELECT zip_code, borough FROM {{ ref('stg_project_311') }}
    WHERE zip_code IS NOT NULL

    UNION ALL

    SELECT zip_code, borough FROM {{ ref('stg_project_collisions') }}
    WHERE zip_code IS NOT NULL
),

-- Count how often each borough appears for each ZIP
borough_votes AS (
    SELECT zip_code, borough, COUNT(*) AS n
    FROM all_locations
    WHERE borough != 'UNKNOWN or CITYWIDE'
    GROUP BY zip_code, borough
),

-- Keep the most common borough per ZIP
winning_borough AS (
    SELECT zip_code, borough
    FROM borough_votes
    QUALIFY ROW_NUMBER() OVER (PARTITION BY zip_code ORDER BY n DESC, borough) = 1
),

zips AS (
    SELECT DISTINCT zip_code FROM all_locations
)

SELECT
    FARM_FINGERPRINT(z.zip_code) AS location_key,
    z.zip_code,
    COALESCE(w.borough, 'UNKNOWN or CITYWIDE') AS borough
FROM zips z
LEFT JOIN winning_borough w USING (zip_code)

UNION ALL

SELECT 0, NULL, 'UNKNOWN or CITYWIDE'