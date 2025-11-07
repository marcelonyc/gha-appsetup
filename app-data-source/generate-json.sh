#! /bin/bash

source ~/.app-manager

OUTPUT_FILE="$1"
QUERY=$(<app-info-to-json.sql)

sqlite3 -json "$DB_PATH" "$QUERY" > "$OUTPUT_FILE"

if [ $? -eq 0 ]; then
    echo "JSON data successfully exported to $OUTPUT_FILE"
else
    echo "Failed to export JSON data"
    exit 1
fi