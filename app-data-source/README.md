# App Data Source Configuration  

This document explains how to configure the `app-data-source` to use a data repository. By default, the application is set up to use a generic repository in JFrog. However, you can configure it to use any other database or endpoint that returns JSON data.  

## Default Configuration: JFrog  

The default setup assumes that the data is published in a generic repository in JFrog. To configure JFrog as the data source, you need to provide the following fields:  

### Required Fields for JFrog Configuration  

1. **Repository URL**  
    - The URL of the JFrog repository where the data is stored.  
    - Example: `https://your-jfrog-instance/artifactory/generic-repo-name/`  

2. **Authentication Token**  
    - The API token or credentials required to access the repository.  
    - Ensure that the token has read permissions for the repository.  

3. **File Path**  
    - The relative path to the JSON file within the repository.  
    - Example: `data/config.json`  

4. **Repository Name**  
    - The name of the generic repository in JFrog.  
    - Example: `generic-repo-name`  

## Custom Configuration: Other Databases or Endpoints  

You can configure the `app-data-source` to use other databases or endpoints that return JSON data. Below are the fields required for custom configuration:  

### Required Fields for Custom Configuration  

1. **Endpoint URL**  
    - The URL of the database or endpoint that provides the JSON data.  
    - Example: `https://api.example.com/data-source`  

2. **Authentication Details**  
    - If the endpoint requires authentication, provide the necessary credentials (e.g., API key, username/password).  
    - Example:  
      ```json  
      {  
         "apiKey": "your-api-key"  
      }  
      ```  

3. **Query Parameters (Optional)**  
    - Any query parameters required to fetch the data.  
    - Example: `?type=config&version=1.0`  

4. **Response Format**  
    - Ensure the endpoint returns data in JSON format.  

5. **Connection Timeout (Optional)**  
    - Specify the timeout duration for the connection to the endpoint.  
    - Default: `30 seconds`  

## Example Configuration  

Below is an example configuration for both JFrog and a custom endpoint:  

### JFrog Configuration  

```json  
{  
  "repositoryUrl": "https://your-jfrog-instance/artifactory/generic-repo-name/",  
  "authToken": "your-auth-token",  
  "filePath": "data/config.json",  
  "repositoryName": "generic-repo-name"  
}  
```  

### Custom Endpoint Configuration  

```json  
{  
  "endpointUrl": "https://api.example.com/data-source",  
  "authDetails": {  
     "apiKey": "your-api-key"  
  },  
  "queryParams": "?type=config&version=1.0",  
  "timeout": 30  
}  
```  

## Database Schema for Application Information

When using a database as the data source, the following tables and fields are required to provide comprehensive application information:

### Applications Table

```sql
CREATE TABLE applications (
    application_key TEXT PRIMARY KEY,      -- Unique identifier for the application
    application_name TEXT NOT NULL UNIQUE, -- Human-readable name of the application  
    jfrog_project_key TEXT NOT NULL,      -- Link to the JFrog project
    description TEXT,                      -- Optional description of the application
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

**Required Fields:**
- `application_key`: Primary key, unique identifier for each application
- `application_name`: Unique, human-readable application name
- `jfrog_project_key`: References the associated JFrog project

### JFrog Projects Table

```sql
CREATE TABLE jfrog_projects (
    project_key TEXT PRIMARY KEY,         -- JFrog project identifier
    project_name TEXT NOT NULL UNIQUE,    -- Human-readable project name
    description TEXT,                      -- Optional project description
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    application_key TEXT                   -- Link back to the application
);
```

**Required Fields:**
- `project_key`: Primary key, matches JFrog project key
- `project_name`: Unique, human-readable project name
- `application_key`: Foreign key linking to applications table

### Repositories Table

```sql
CREATE TABLE repositories (
    repository_key TEXT PRIMARY KEY,      -- Unique repository identifier
    repository_name TEXT NOT NULL,        -- Human-readable repository name
    repository_type TEXT NOT NULL,        -- Type: Maven, Docker, NPM, Python, etc.
    application_key TEXT NOT NULL,        -- Link to parent application
    lifestage TEXT NOT NULL,              -- Development, Testing, Production, etc.
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

**Required Fields:**
- `repository_key`: Primary key, unique repository identifier
- `repository_name`: Human-readable repository name
- `repository_type`: Repository type (e.g., `maven`, `docker`, `npm`, `python`, `generic`)
- `application_key`: Foreign key linking to applications table
- `lifestage`: Environment/lifecycle stage (e.g., `development`, `testing`, `production`)

## JSON Output Format

The database query generates JSON with the following structure:

```json
[
  {
    "project_key": "example-proj",
    "project_name": "Example Project",
    "application_key": "app-001",
    "application_name": "My Application",
    "repository_key": "app-001-maven-dev",
    "repository_name": "Application Maven Dev",
    "repository_type": "maven",
    "repository_lifestage": "development"
  }
]
```

## Database Configuration

To set up the database connection, create a configuration file at `~/.app-manager`:

```bash
# Location of your SQLite database file
DB_PATH="/path/to/your/app-manager-database.db"
```

## Generating JSON Data

Use the provided script to generate JSON data from your database:

```bash
./generate-json.sh output.json
```

This script:
1. Reads the database path from `~/.app-manager`
2. Executes the SQL query to join all application data
3. Outputs JSON formatted data to the specified file

## Notes  

- Ensure that the data source is accessible and the credentials provided have the necessary permissions.  
- Validate the JSON structure returned by the endpoint to ensure compatibility with the application.
- For SQLite databases, ensure the database file path is correctly configured in `~/.app-manager`
- Repository types should follow JFrog Artifactory naming conventions (maven, docker, npm, python, generic, etc.)
- Lifestage values should be consistent across your organization (development, testing, staging, production, etc.)

````