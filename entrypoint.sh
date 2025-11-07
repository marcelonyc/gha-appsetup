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
RESPONSE=$(curl -s -H "Authorization: Bearer $AMS_TOKEN" "$AMS_ENDPOINT")

# echo "response=$RESPONSE" 

# RESPONSE = [{"project_key":"dvr","project_name":"dvr","application_key":"dvr-rental","application_name":"DVR aRental","repository_key":"dvr-docker-local-all-stages","repository_name":"dvr-docker-local-all-stages","repository_type":"docker","repository_lifestage":"all"},
# {"project_key":"dvr","project_name":"dvr","application_key":"dvr-rental","application_name":"DVR aRental","repository_key":"dvr-generic-local-all-stages","repository_name":"dvr-generic-local-all-stages","repository_type":"generic","repository_lifestage":"all"}]

echo "$RESPONSE" | jq -c --arg app_key "$APPLICATION_KEY" '.[] | select(.application_key == $app_key)' | while read -r record; do
  repository_type=$(echo "$record" | jq -r '.repository_type')
  repository_lifestage=$(echo "$record" | jq -r '.repository_lifestage')
  repository_key=$(echo "$record" | jq -r '.repository_key')
  {
  echo "stdout<<EOF
  {repository_type}-${repository_lifestage}=${repository_key}
  EOF" >> "$GITHUB_OUTPUT"
  }
done
