-- Grain: one row per motor vehicle collision

WITH crashes AS (
    SELECT
        *,
        -- Same formula as dim_crash_time
        CASE
            WHEN crash_hour BETWEEN 0 AND 23 AND crash_minute BETWEEN 0 AND 59
            THEN crash_hour * 60 + crash_minute + 1
        END AS calc_time_key,

        -- Severity rule from our dimensional model
        CASE
            WHEN persons_killed > 0 THEN 3
            WHEN persons_injured > 0 THEN 2
            WHEN persons_killed = 0 AND persons_injured = 0 THEN 1
            ELSE 0
        END AS calc_severity_key
    FROM {{ ref('stg_project_collisions') }}
)

SELECT
    FARM_FINGERPRINT(CAST(c.collision_id AS STRING)) AS collision_key,
    c.collision_id,

    -- Dimension keys (0 = Unknown)
    COALESCE(d.date_key, 0) AS date_key,
    COALESCE(l.location_key, 0) AS location_key,
    COALESCE(t.time_key, 0) AS time_key,
    COALESCE(sv.severity_key, 0) AS severity_key,

    -- Measures
    c.persons_injured,
    c.persons_killed,
    c.pedestrians_injured,
    c.pedestrians_killed,
    c.cyclists_injured,
    c.cyclists_killed,
    c.motorists_injured,
    c.motorists_killed,
    1 AS crash_count

FROM crashes c

LEFT JOIN {{ ref('dim_project_date') }} d
    ON d.full_date = c.crash_date

LEFT JOIN {{ ref('dim_project_location') }} l
    ON l.zip_code = c.zip_code

LEFT JOIN {{ ref('dim_crash_time') }} t
    ON t.time_key = c.calc_time_key

LEFT JOIN {{ ref('dim_crash_severity') }} sv
    ON sv.severity_key = c.calc_severity_key