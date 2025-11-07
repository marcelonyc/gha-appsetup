CREATE TABLE applications (
    application_key TEXT PRIMARY KEY,
    application_name TEXT NOT NULL UNIQUE,
    jfrog_project_key TEXT NOT NULL,
    description TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE jfrog_projects (
    project_key TEXT PRIMARY KEY,
    project_name TEXT NOT NULL UNIQUE,
    description TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
, application_key TEXT);

CREATE TABLE repositories (
    repository_key TEXT PRIMARY KEY,
    repository_name TEXT NOT NULL,
    repository_type TEXT NOT NULL, -- e.g., Maven, Docker, NPM, etc.
    application_key TEXT NOT NULL,
    lifestage TEXT NOT NULL, -- e.g., Development, Testing, Production
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);