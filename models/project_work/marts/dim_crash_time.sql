-- Grain: one row per minute of the day, plus an Unknown row

WITH minutes AS (
    SELECT
        DIV(m, 60) AS hour,
        MOD(m, 60) AS minute
    FROM UNNEST(GENERATE_ARRAY(0, 1439)) AS m
)

SELECT
    hour * 60 + minute + 1 AS time_key,
    hour,
    minute,
    CASE
        WHEN hour BETWEEN 6 AND 11 THEN 'Morning'
        WHEN hour BETWEEN 12 AND 17 THEN 'Afternoon'
        WHEN hour BETWEEN 18 AND 21 THEN 'Evening'
        ELSE 'Night'
    END AS time_period
FROM minutes

UNION ALL

SELECT
    0 AS time_key,
    CAST(NULL AS INT64) AS hour,
    CAST(NULL AS INT64) AS minute,
    'Unknown' AS time_period