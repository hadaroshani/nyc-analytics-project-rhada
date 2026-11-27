-- Grain: one row per distinct problem + problem_detail combination

WITH problems AS (
    SELECT DISTINCT
        COALESCE(problem, 'Unknown') AS problem,
        problem_detail
    FROM {{ ref('stg_project_311') }}
)

SELECT
    FARM_FINGERPRINT(CONCAT(problem, '|', COALESCE(problem_detail, ''))) AS problem_key,
    problem,
    problem_detail
FROM problems