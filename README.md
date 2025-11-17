# Retrieve Application Metadata GitHub Action

A GitHub Action that retrieves application metadata from an Application Management System (AMS) and provides easy access to JFrog Artifactory repository information for your CI/CD pipelines.

## What is the Application Data Source?

The Application Data Source is a centralized system that maintains metadata about applications and their associated JFrog Artifactory repositories. This data source:

- **Stores application configurations**: Maps applications to their corresponding JFrog projects and repositories
- **Manages repository information**: Tracks repository types (Docker, Maven, NPM, Python, etc.) and lifecycle stages (development, testing, production)
- **Provides API access**: Exposes application metadata through a REST API endpoint
- **Supports multiple data backends**: Can be backed by databases (SQLite, PostgreSQL, etc.) or other data stores

The data source returns JSON containing application metadata including:
- JFrog project keys and names
- Repository keys, names, types, and lifecycle stages
- Application keys and names

## Usage

### Basic Usage

```yaml
- name: Retrieve Application Metadata
  uses: your-org/gha-appsetup@v1
  with:
    application_key: "my-app-001"
    ams_token: ${{ secrets.AMS_TOKEN }}
    ams_endpoint: "https://your-ams-api.com/applications"
```

### Complete Workflow Example

```yaml
name: Build and Deploy Application
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Retrieve Application Metadata
        id: app-metadata
        uses: your-org/gha-appsetup@v1
        with:
          application_key: "my-app-001"
          ams_token: ${{ secrets.AMS_TOKEN }}
          ams_endpoint: "https://your-ams-api.com/applications"

      - name: Get Docker Repository
        id: docker-repo
        run: |
          DOCKER_REPO=$(appconfig docker DEV)
          echo "repository=$DOCKER_REPO" >> $GITHUB_OUTPUT

      - name: Get Maven Repository  
        id: maven-repo
        run: |
          MAVEN_REPO=$(appconfig maven DEV)
          echo "repository=$MAVEN_REPO" >> $GITHUB_OUTPUT

      - name: Build Docker Image
        run: |
          docker build -t ${{ steps.docker-repo.outputs.repository }}/my-app:${{ github.sha }} .

      - name: Deploy Maven Artifacts
        run: |
          mvn deploy -DrepositoryUrl=${{ steps.maven-repo.outputs.repository }}
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `application_key` | The unique identifier for your application | ✅ Yes | - |
| `ams_token` | Authentication token for the AMS API | ✅ Yes | - |
| `ams_endpoint` | The AMS API endpoint URL that returns JSON metadata | ✅ Yes | - |

## Outputs

| Output | Description |
|--------|-------------|
| `metadata` | The complete application metadata JSON response |
| `repo_list` | Filtered list of repositories for the specified application |

## Using the `appconfig` Command

After the action executes, it installs the `appconfig` command-line utility that allows you to easily retrieve specific repository keys based on repository type and lifecycle stage.

### Command Syntax

```bash
appconfig <repository_type> <lifestage>
```

### Parameters

- **repository_type**: The type of repository (e.g., `docker`, `maven`, `npm`, `python`, `generic`)
- **lifestage**: The lifecycle stage (e.g., `development`, `testing`, `production`, `all`)

### Examples

#### Get Docker Repository for Production

```yaml
- name: Get Production Docker Repository
  id: docker-prod
  run: |
    REPO_KEY=$(appconfig docker production)
    echo "repository=$REPO_KEY" >> $GITHUB_OUTPUT
```

#### Get Maven Repository for Development

```yaml
- name: Get Development Maven Repository  
  run: |
    MAVEN_REPO=$(appconfig maven development)
    echo "Maven repository: $MAVEN_REPO"
```

#### Get NPM Repository for Testing

```yaml
- name: Get Testing NPM Repository
  run: |
    NPM_REPO=$(appconfig npm testing)
    npm config set registry $NPM_REPO
```

#### Get Generic Repository (All Stages)

```yaml
- name: Get Generic Repository
  run: |
    GENERIC_REPO=$(appconfig generic all)
    echo "Generic repository: $GENERIC_REPO"
```

### Repository Matching Logic

The `appconfig` command uses the following matching logic:

1. **Exact Match**: First tries to find a repository with the exact `repository_type` and `lifestage` combination
2. **Fallback to "all"**: If no exact match is found, looks for a repository with the same `repository_type` and `lifestage` set to "all"
3. **Error Handling**: Returns an error if no matching repository is found

### Example Data Structure

The action retrieves data in the following JSON format:

```json
[
  {
    "project_key": "dvr",
    "project_name": "DVR Project",
    "application_key": "dvr-rental",
    "application_name": "DVR Rental",
    "repository_key": "dvr-docker-local-prod",
    "repository_name": "DVR Docker Production",
    "repository_type": "docker",
    "repository_lifestage": "production"
  },
  {
    "project_key": "dvr",
    "project_name": "DVR Project", 
    "application_key": "dvr-rental",
    "application_name": "DVR Rental",
    "repository_key": "dvr-maven-local-dev",
    "repository_name": "DVR Maven Development",
    "repository_type": "maven",
    "repository_lifestage": "development"
  }
]
```

## Setup Requirements

### Secrets Configuration

Add the following secrets to your GitHub repository:

- `AMS_TOKEN`: Authentication token for your AMS API endpoint

### AMS API Endpoint

Your AMS endpoint should:
- Accept Bearer token authentication
- Return JSON data in the expected format (see example above)
- Be accessible from GitHub Actions runners

## Error Handling

The action will fail with clear error messages if:
- Required inputs are missing
- API authentication fails
- AMS endpoint is unreachable
- Invalid JSON is returned
- No matching repositories are found when using `appconfig`

## Advanced Usage

### Using with Matrix Builds

```yaml
strategy:
  matrix:
    environment: [development, testing, production]
    
steps:
  - name: Retrieve Application Metadata
    uses: your-org/gha-appsetup@v1
    with:
      application_key: "my-app-001"
      ams_token: ${{ secrets.AMS_TOKEN }}
      ams_endpoint: ${{ vars.AMS_ENDPOINT }}

  - name: Get Repository for Environment
    run: |
      REPO=$(appconfig docker ${{ matrix.environment }})
      echo "Deploying to: $REPO"
```

### Conditional Repository Selection

```yaml
- name: Select Repository Based on Branch
  run: |
    if [[ "${{ github.ref }}" == "refs/heads/main" ]]; then
      REPO=$(appconfig docker production)
    else
      REPO=$(appconfig docker development)
    fi
    echo "repository=$REPO" >> $GITHUB_OUTPUT
```

## Contributing

Please see our [contributing guidelines](CONTRIBUTING.md) for information on how to contribute to this project.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.