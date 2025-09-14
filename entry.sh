set -e
echo "App ID: ${application_id}"

if [ -z "$application_id" ]; then
  echo "Error: application_id input is required, sometimes." >&2
  exit 1
fi

# Make the API request (replace the URL with your actual endpoint)
# RESPONSE=$(curl -s -H "Authorization: Bearer $INPUT_APPLICATION_ID" "https://api.example.com/application/metadata")

RESPONSE='{
  "project_key": "my-project-key",
  "repositories": [
    {
      "type": "local",
      "repo_key": "my-local-repo"
    },
    {
      "type": "remote",
      "repo_key": "my-remote-repo"
    }
  ]
}'

# Parse the metadata (requires jq)
PROJECT_KEY=$(echo "$RESPONSE" | jq -r '.project_key')
REPOSITORIES=$(echo "$RESPONSE" | jq -c '.repositories')

# echo "Project Key: $PROJECT_KEY"
echo "Repositories: $REPOSITORIES"

echo "$REPOSITORIES" | jq -c '.[]' | while read repo; do
  TYPE=$(echo "$repo" | jq -r '.type')
  REPO_KEY=$(echo "$repo" | jq -r '.repo_key')
  echo "Repository_Type=$TYPE" >> "$GITHUB_OUTPUT" 
  echo "Repo_Key=$REPO_KEY" >> "$GITHUB_OUTPUT"
done
echo "repo_list=${REPOSITORIES}" >> "$GITHUB_OUTPUT"
