-- Clean and standardize 311 DOT service request data for the project
-- Grain: one row per service request

WITH source AS (
    SELECT * FROM {{ source('nyc_project_raw', 'source_311_dot_requests') }}
),

cleaned AS (
    SELECT
        -- Identifier
        CAST(unique_key AS STRING) AS unique_key,

        -- Dates
        CAST(created_date AS TIMESTAMP) AS created_date,
        CAST(closed_date AS TIMESTAMP) AS closed_date,

        -- Request details (renamed to match our dimensional model)
        CAST(agency AS STRING) AS agency,
        CAST(complaint_type AS STRING) AS problem,
        CAST(descriptor AS STRING) AS problem_detail,
        UPPER(TRIM(CAST(status AS STRING))) AS status,

        -- ZIP: keep first 5 digits so it can join with the collisions data
        CASE
            WHEN REGEXP_CONTAINS(TRIM(CAST(incident_zip AS STRING)), r'^\d{5}')
            THEN SUBSTR(TRIM(CAST(incident_zip AS STRING)), 1, 5)
            ELSE NULL
        END AS zip_code,

        -- Standardized borough
        CASE
            WHEN UPPER(TRIM(borough)) IN ('MANHATTAN', 'NEW YORK COUNTY') THEN 'Manhattan'
            WHEN UPPER(TRIM(borough)) IN ('BRONX', 'THE BRONX') THEN 'Bronx'
            WHEN UPPER(TRIM(borough)) IN ('BROOKLYN', 'KINGS COUNTY') THEN 'Brooklyn'
            WHEN UPPER(TRIM(borough)) IN ('QUEENS', 'QUEEN', 'QUEENS COUNTY') THEN 'Queens'
            WHEN UPPER(TRIM(borough)) IN ('STATEN ISLAND', 'RICHMOND COUNTY') THEN 'Staten Island'
            ELSE 'UNKNOWN or CITYWIDE'
        END AS borough,

        CAST(latitude AS DECIMAL) AS latitude,
        CAST(longitude AS DECIMAL) AS longitude,

        -- Metadata
        CURRENT_TIMESTAMP() AS _stg_loaded_at

    FROM source

    -- Filters
    WHERE agency = 'DOT'
      AND unique_key IS NOT NULL
      AND created_date IS NOT NULL
      AND CAST(created_date AS DATE) >= '2020-01-01'

    -- Deduplicate: keep one row per request
    QUALIFY ROW_NUMBER() OVER (PARTITION BY unique_key ORDER BY created_date DESC) = 1
)

SELECT * FROM cleaned