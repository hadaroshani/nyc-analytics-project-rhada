-- Clean and standardize DOB NOW job filings data
-- One row per job filing

WITH source AS (
    SELECT * FROM {{ source('raw', 'source_nyc_dob_job_apps') }}
),

cleaned AS (
    SELECT
        -- Keep all other columns as-is, except the ones cleaned below
        * EXCEPT (
            job_filing_number,
            filing_status,
            filing_date,
            current_status_date,
            first_permit_date,
            approved_date,
            signoff_date,
            initial_cost,
            borough,
            zip,
            postcode,
            council_district,
            commmunity_board
        ),

        -- Identifier
        CAST(job_filing_number AS STRING) AS job_filing_number,

        -- Status
        UPPER(TRIM(filing_status)) AS filing_status,

        -- Dates (already timestamps, cast to be explicit)
        CAST(filing_date AS TIMESTAMP) AS filing_date,
        CAST(current_status_date AS TIMESTAMP) AS current_status_date,
        CAST(first_permit_date AS TIMESTAMP) AS first_permit_date,
        CAST(approved_date AS TIMESTAMP) AS approved_date,
        CAST(signoff_date AS TIMESTAMP) AS signoff_date,

        -- Cost: strip $ and commas, convert text to a number
        SAFE_CAST(REGEXP_REPLACE(initial_cost, r'[$,]', '') AS NUMERIC) AS initial_cost,

        -- Location - standardized borough, matches 311 staging
        CASE
            WHEN UPPER(TRIM(borough)) IN ('MANHATTAN', 'NEW YORK COUNTY') THEN 'Manhattan'
            WHEN UPPER(TRIM(borough)) IN ('BRONX', 'THE BRONX') THEN 'Bronx'
            WHEN UPPER(TRIM(borough)) IN ('BROOKLYN', 'KINGS COUNTY') THEN 'Brooklyn'
            WHEN UPPER(TRIM(borough)) IN ('QUEENS', 'QUEEN', 'QUEENS COUNTY') THEN 'Queens'
            WHEN UPPER(TRIM(borough)) IN ('STATEN ISLAND', 'RICHMOND COUNTY') THEN 'Staten Island'
            ELSE 'UNKNOWN or CITYWIDE'
        END AS borough,

        -- Location - one clean zip from zip or postcode, first 5 digits only
        CASE
            WHEN REGEXP_CONTAINS(COALESCE(NULLIF(TRIM(zip), ''), NULLIF(TRIM(postcode), '')), r'^\d{5}')
            THEN LEFT(COALESCE(NULLIF(TRIM(zip), ''), NULLIF(TRIM(postcode), '')), 5)
            ELSE NULL
        END AS zip,

        -- Location - council district, blanks become NULL
        NULLIF(TRIM(council_district), '') AS council_district,

        -- Fix typo in raw column name
        commmunity_board AS community_board,

        -- Metadata
        CURRENT_TIMESTAMP() AS _stg_loaded_at

    FROM source

    -- Filters
    WHERE job_filing_number IS NOT NULL
      AND filing_date IS NOT NULL

    -- Deduplicate: keep the most recent status per filing
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY job_filing_number
        ORDER BY current_status_date DESC
    ) = 1
)

SELECT * FROM cleaned