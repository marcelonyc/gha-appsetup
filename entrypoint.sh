set -e

APPLICATION_KEY=${1}
AMS_TOKEN=${2}
AMS_ENDPOINT=${3}

if [ -z "$APPLICATION_KEY" ]; then
  echo "Error: application_key input is required." >&2
  exit 1
fi

if [ -z "$AMS_TOKEN" ]; then
  echo "Error: AMS_TOKEN input is required." >&2
  exit 1
fi

if [ -z "$AMS_ENDPOINT" ]; then
  echo "Error: AMS_ENDPOINT input is required." >&2
  exit 1
fi

# Make the API request (replace the URL with your actual endpoint)
RESPONSE=$(curl -s -H "Authorization: Bearer $APPLICATION_KEY" "$AMS_ENDPOINT")

echo "response=$RESPONSE" 

# # Parse the metadata (requires jq)
# PROJECT_KEY=$(echo "$RESPONSE" | jq -r '.project_key')
# REPOSITORIES=$(echo "$RESPONSE" | jq -c '.repositories')

# echo "Project Key: $PROJECT_KEY"
# echo "Repositories: $REPOSITORIES"

# REPO_PAIRS=$(echo "$REPOSITORIES" | jq -r '.[] | "\(.type):\(.repo_key)"' | paste -sd "," -)
# echo "repositories=$REPO_PAIRS" >> "$GITHUB_OUTPUT"
