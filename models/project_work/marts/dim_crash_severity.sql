-- Grain: one row per crash severity category, plus Unknown

SELECT severity_key, severity_category
FROM UNNEST([
    STRUCT(0 AS severity_key, 'Unknown' AS severity_category),
    STRUCT(1, 'No Injury'),
    STRUCT(2, 'Injury'),
    STRUCT(3, 'Fatal')
])