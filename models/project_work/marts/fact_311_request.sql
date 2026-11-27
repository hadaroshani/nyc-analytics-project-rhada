-- Grain: one row per NYC 311 DOT service request

WITH requests AS (
    SELECT * FROM {{ ref('stg_project_311') }}
)

SELECT
    FARM_FINGERPRINT(r.unique_key) AS request_key,
    r.unique_key,

    -- Date keys (0 = Unknown, -1 = Not yet closed)
    COALESCE(cd.date_key, 0) AS created_date_key,
    CASE
        WHEN r.closed_date IS NULL THEN -1
        ELSE COALESCE(cl.date_key, 0)
    END AS closed_date_key,

    -- Other dimension keys (0 = Unknown location)
    COALESCE(l.location_key, 0) AS location_key,
    p.problem_key,
    s.status_key,

    -- Measures
    CASE
        WHEN DATE_DIFF(DATE(r.closed_date), DATE(r.created_date), DAY) >= 0
        THEN DATE_DIFF(DATE(r.closed_date), DATE(r.created_date), DAY)
        ELSE NULL
    END AS resolution_days,
    1 AS request_count

FROM requests r

LEFT JOIN {{ ref('dim_project_date') }} cd
    ON cd.full_date = DATE(r.created_date)

LEFT JOIN {{ ref('dim_project_date') }} cl
    ON cl.full_date = DATE(r.closed_date)

LEFT JOIN {{ ref('dim_project_location') }} l
    ON l.zip_code = r.zip_code

LEFT JOIN {{ ref('dim_311_problem') }} p
    ON p.problem = COALESCE(r.problem, 'Unknown')
   AND COALESCE(p.problem_detail, '') = COALESCE(r.problem_detail, '')

LEFT JOIN {{ ref('dim_311_status') }} s
    ON s.status = COALESCE(r.status, 'UNKNOWN')