-- Grain: one row per distinct 311 request status

WITH statuses AS (
    SELECT DISTINCT
        COALESCE(status, 'UNKNOWN') AS status
    FROM {{ ref('stg_project_311') }}
)

SELECT
    FARM_FINGERPRINT(status) AS status_key,
    status,
    status = 'CLOSED' AS is_resolved
FROM statuses