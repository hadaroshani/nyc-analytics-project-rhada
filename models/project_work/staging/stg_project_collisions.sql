-- Clean and standardize motor vehicle collision data for the project
-- Grain: one row per collision

WITH source AS (
    SELECT * FROM {{ source('nyc_project_raw', 'source_motor_vehicle_collisions') }}
),

cleaned AS (
    SELECT
        -- Identifier
        CAST(collision_id AS INT64) AS collision_id,

        -- Date (keep only the date part)
        DATE(crash_date) AS crash_date,

        -- Time: raw values look like '9:05', so split into hour and minute
        SAFE_CAST(SPLIT(TRIM(crash_time), ':')[SAFE_OFFSET(0)] AS INT64) AS crash_hour,
        SAFE_CAST(SPLIT(TRIM(crash_time), ':')[SAFE_OFFSET(1)] AS INT64) AS crash_minute,

        -- ZIP: keep first 5 digits so it matches the 311 data
        CASE
            WHEN REGEXP_CONTAINS(TRIM(CAST(zip_code AS STRING)), r'^\d{5}')
            THEN SUBSTR(TRIM(CAST(zip_code AS STRING)), 1, 5)
            ELSE NULL
        END AS zip_code,

        -- Borough: same rules as the 311 staging model so they match
        CASE
            WHEN UPPER(TRIM(borough)) IN ('MANHATTAN', 'NEW YORK COUNTY') THEN 'Manhattan'
            WHEN UPPER(TRIM(borough)) IN ('BRONX', 'THE BRONX') THEN 'Bronx'
            WHEN UPPER(TRIM(borough)) IN ('BROOKLYN', 'KINGS COUNTY') THEN 'Brooklyn'
            WHEN UPPER(TRIM(borough)) IN ('QUEENS', 'QUEEN', 'QUEENS COUNTY') THEN 'Queens'
            WHEN UPPER(TRIM(borough)) IN ('STATEN ISLAND', 'RICHMOND COUNTY') THEN 'Staten Island'
            ELSE 'UNKNOWN or CITYWIDE'
        END AS borough,

        -- Injury and fatality counts
        CAST(number_of_persons_injured AS INT64) AS persons_injured,
        CAST(number_of_persons_killed AS INT64) AS persons_killed,
        CAST(number_of_pedestrians_injured AS INT64) AS pedestrians_injured,
        CAST(number_of_pedestrians_killed AS INT64) AS pedestrians_killed,
        CAST(number_of_cyclist_injured AS INT64) AS cyclists_injured,
        CAST(number_of_cyclist_killed AS INT64) AS cyclists_killed,
        CAST(number_of_motorist_injured AS INT64) AS motorists_injured,
        CAST(number_of_motorist_killed AS INT64) AS motorists_killed,

        -- Metadata
        CURRENT_TIMESTAMP() AS _stg_loaded_at

    FROM source

    -- Filters
    WHERE collision_id IS NOT NULL
      AND crash_date IS NOT NULL
      AND DATE(crash_date) >= '2020-01-01'

    -- Deduplicate: keep one row per collision
    QUALIFY ROW_NUMBER() OVER (PARTITION BY collision_id ORDER BY crash_date DESC) = 1
)

SELECT * FROM cleaned