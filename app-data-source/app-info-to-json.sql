
SELECT 
    jp.project_key AS project_key,
    jp.project_name AS project_name,
    jp.application_key AS application_key,
    a.application_name AS application_name,
    r.repository_key AS repository_key,
    r.repository_name AS repository_name,
    r.repository_type AS repository_type,
    r.lifestage AS repository_lifestage
FROM jfrog_projects jp
JOIN applications a ON jp.application_key = a.application_key
JOIN repositories r ON a.application_key = r.application_key;