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

For detailed information about the database schema, setup instructions, and example implementations, see the [app-data-source](./app-data-source/) folder which contains:
- Database schema definitions and required fields
- Sample SQL queries for data retrieval
- JSON output format examples
- Setup and configuration guidance

### Using with Backstage or Other Application Management Tools

If you're using **Backstage**, **Port**, **OpsLevel**, or any other application management platform, you can easily adapt this action to work with your existing system:

1. **Clone and Fork**: Fork this repository to create your own version
2. **Modify the API Integration**: Update the `entrypoint.sh` script to call your platform's API instead of the default AMS endpoint
3. **Adapt Data Mapping**: Modify the JSON parsing logic to map your platform's data structure to the expected format
4. **Customize Authentication**: Update the authentication mechanism to work with your platform (API keys, OAuth, etc.)

**Example for Backstage Integration:**
- Use the Backstage Software Catalog API to retrieve component metadata
- Map Backstage component annotations to JFrog repository information
- Leverage existing Backstage entity relationships and metadata

**Example for Port Integration:**
- Query Port's API using entity blueprints and properties
- Map Port entity properties to repository configurations
- Use Port's relationship system to link applications to their repositories

This approach allows you to maintain the same workflow patterns while integrating with your organization's existing application management infrastructure.

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
    permissions:
      id-token: write
      contents: read
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup JFrog CLI
        uses: jfrog/setup-jfrog-cli@v4
        id: jf-cli
        env:
          JF_URL: ${{ vars.JF_URL }}
        with:
          oidc-provider-name: ${{ vars.JF_OIDC_PROVIDER_NAME }}

      - name: Retrieve Application Metadata
        id: app-metadata
        uses: your-org/gha-appsetup@v1
        with:
          application_key: "my-app-001"
          ams_token: ${{ secrets.AMS_TOKEN }} # If using a generic Jfrog repo this should be ${{ steps.jf-cli.outputs.oidc-token }}
          ams_endpoint: "https://your-ams-api.com/applications"

      - name: Get Docker Repository
        id: docker-repo
        run: |
          DOCKER_REPO=$(appconfig docker production)
          echo "repository=$DOCKER_REPO" >> $GITHUB_OUTPUT

      - name: Get Maven Repository  
        id: maven-repo
        run: |
          MAVEN_REPO=$(appconfig maven development)
          echo "repository=$MAVEN_REPO" >> $GITHUB_OUTPUT

      - name: Build and Push Docker Image
        run: |
          # Build Docker image
          jf docker build -t ${{ steps.docker-repo.outputs.repository }}/my-app:${{ github.sha }} .
          # Push to JFrog Artifactory
          jf docker push ${{ steps.docker-repo.outputs.repository }}/my-app:${{ github.sha }}

      - name: Build and Deploy Maven Artifacts
        run: |
          # Configure Maven to use JFrog repository
          jf mvn-config --repo-resolve-releases ${{ steps.maven-repo.outputs.repository }} \
                        --repo-resolve-snapshots ${{ steps.maven-repo.outputs.repository }} \
                        --repo-deploy-releases ${{ steps.maven-repo.outputs.repository }} \
                        --repo-deploy-snapshots ${{ steps.maven-repo.outputs.repository }}
          # Build and deploy
          jf mvn clean deploy

      - name: Publish Build Info
        run: |
          jf rt build-publish
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

- name: Build and Push Docker Image
  run: |
    jf docker build -t ${{ steps.docker-prod.outputs.repository }}/my-app:latest .
    jf docker push ${{ steps.docker-prod.outputs.repository }}/my-app:latest
```

#### Get Maven Repository for Development

```yaml
- name: Get Development Maven Repository  
  id: maven-dev
  run: |
    MAVEN_REPO=$(appconfig maven development)
    echo "repository=$MAVEN_REPO" >> $GITHUB_OUTPUT

- name: Configure and Deploy Maven
  run: |
    jf mvn-config --repo-resolve-releases ${{ steps.maven-dev.outputs.repository }} \
                  --repo-deploy-releases ${{ steps.maven-dev.outputs.repository }}
    jf mvn clean deploy
```

#### Get NPM Repository for Testing

```yaml
- name: Get Testing NPM Repository
  id: npm-test
  run: |
    NPM_REPO=$(appconfig npm testing)
    echo "repository=$NPM_REPO" >> $GITHUB_OUTPUT

- name: Configure and Publish NPM Package
  run: |
    jf npm-config --repo-resolve ${{ steps.npm-test.outputs.repository }} \
                  --repo-deploy ${{ steps.npm-test.outputs.repository }}
    jf npm install
    jf npm publish
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

### Variables Configuration

Add the following variables to your GitHub repository:

- `JF_URL`: Your JFrog Platform URL (e.g., `https://mycompany.jfrog.io`)
- `JF_OIDC_PROVIDER_NAME`: The OIDC provider name configured in JFrog Platform
- `AMS_ENDPOINT`: Your AMS API endpoint URL

### JFrog OIDC Configuration

Before using this action, you must configure OIDC integration in your JFrog Platform:

1. **Create OIDC Integration**: In JFrog Platform, go to Administration → Identity and Access → OIDC Integrations
2. **Configure GitHub OIDC Provider**: 
   - Provider Type: `Custom`
   - Provider URL: `https://token.actions.githubusercontent.com`
   - Audience: `jfrog-github`
3. **Create Identity Mapping**: Map GitHub repository to JFrog users/groups based on claims
4. **Set Permissions**: Ensure the mapped identity has appropriate permissions for your repositories

### Workflow Permissions

Ensure your workflow has the required permissions:

```yaml
permissions:
  id-token: write  # Required for OIDC authentication
  contents: read   # Required for repository access
```

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
jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    strategy:
      matrix:
        environment: [development, testing, production]
        
    steps:
      - name: Setup JFrog CLI
        uses: jfrog/setup-jfrog-cli@v4
        env:
          JF_URL: ${{ vars.JF_URL }}
        with:
          oidc-provider-name: ${{ vars.JF_OIDC_PROVIDER_NAME }}

      - name: Retrieve Application Metadata
        uses: your-org/gha-appsetup@v1
        with:
          application_key: "my-app-001"
          ams_token: ${{ secrets.AMS_TOKEN }}
          ams_endpoint: ${{ vars.AMS_ENDPOINT }}

      - name: Deploy to Environment
        run: |
          REPO=$(appconfig docker ${{ matrix.environment }})
          jf docker build -t $REPO/my-app:${{ github.sha }} .
          jf docker push $REPO/my-app:${{ github.sha }}
          echo "Deployed to: $REPO"
```

### Conditional Repository Selection

```yaml
- name: Select Repository Based on Branch
  id: repo-selection
  run: |
    if [[ "${{ github.ref }}" == "refs/heads/main" ]]; then
      REPO=$(appconfig docker production)
    else
      REPO=$(appconfig docker development)
    fi
    echo "repository=$REPO" >> $GITHUB_OUTPUT

- name: Build and Push to Selected Repository
  run: |
    jf docker build -t ${{ steps.repo-selection.outputs.repository }}/my-app:${{ github.sha }} .
    jf docker push ${{ steps.repo-selection.outputs.repository }}/my-app:${{ github.sha }}
```

## Contributing

Please see our [contributing guidelines](CONTRIBUTING.md) for information on how to contribute to this project.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.