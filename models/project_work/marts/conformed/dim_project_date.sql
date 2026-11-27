{{ config(alias='dim_date') }}

-- Grain: one row per calendar day from 2020-01-01 to today
-- Special keys: 0 = Unknown, -1 = Not yet closed

WITH calendar AS (
    SELECT full_date
    FROM UNNEST(GENERATE_DATE_ARRAY('2020-01-01', CURRENT_DATE())) AS full_date
)

SELECT
    CAST(FORMAT_DATE('%Y%m%d', full_date) AS INT64) AS date_key,
    full_date,
    EXTRACT(DAY FROM full_date) AS day_of_month,
    EXTRACT(MONTH FROM full_date) AS month,
    FORMAT_DATE('%B', full_date) AS month_name,
    EXTRACT(QUARTER FROM full_date) AS quarter,
    EXTRACT(YEAR FROM full_date) AS year,
    FORMAT_DATE('%A', full_date) AS day_of_week
FROM calendar

UNION ALL

SELECT 0, NULL, NULL, NULL, 'Unknown', NULL, NULL, 'Unknown'

UNION ALL

SELECT -1, NULL, NULL, NULL, 'Not yet closed', NULL, NULL, 'Not yet closed'