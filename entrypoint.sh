#! /bin/bash
set -e

mkdir -p ~/appconfig
cp .env ~/appconfig/.env

source ~/appconfig/.env

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

# RESPONSE = '[{"project_key":"dvr","project_name":"dvr","application_key":"dvr-rental","application_name":"DVR aRental","repository_key":"dvr-docker-local-all-stages","repository_name":"dvr-docker-local-all-stages","repository_type":"docker","repository_lifestage":"all"},
# {"project_key":"dvr","project_name":"dvr","application_key":"dvr-rental","application_name":"DVR aRental","repository_key":"dvr-generic-local-all-stages","repository_name":"dvr-generic-local-all-stages","repository_type":"generic","repository_lifestage":"all"}]'

cp commands/appconfig /usr/local/bin/appconfig
if [ $? -ne 0 ]; then
  echo "Error: Failed to copy appconfig command to /usr/local/bin." >&2
  exit 1
fi


# echo "$RESPONSE" | jq -c --arg app_key "$APPLICATION_KEY" '.[] | select(.application_key == $app_key)' | while read -r record; do
#   repository_type=$(echo "$record" | jq -r '.repository_type')
#   repository_lifestage=$(echo "$record" | jq -r '.repository_lifestage')
#   repository_key=$(echo "$record" | jq -r '.repository_key')
#   echo "${repository_type}-${repository_lifestage}=${repository_key}" >> ${config_cache_file}
# done

# Filter the RESPONSE to create a new list containing only matching application_key
filtered_response=$(echo "$RESPONSE" | jq -c --arg app_key "$APPLICATION_KEY" '[.[] | select(.application_key == $app_key)]')

# Print the filtered list for debugging or further processing
echo $filtered_response > ${config_cache_file}

# echo "repo_list=${config_cache_file}" >> "${GITHUB_OUTPUT}"

