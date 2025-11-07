#!/bin/bash

source ~/.app-manager

# Define the output directory for exported data
OUTPUT_DIR="$1"
mkdir -p "$OUTPUT_DIR"

# Export data from jfrog_projectm table
sqlite3 "$DB_FILE" -header -csv "SELECT * FROM jfrog_projects;" > "$OUTPUT_DIR/jfrog_projectm.csv"

# Export data from applications table
sqlite3 "$DB_FILE" -header -csv "SELECT * FROM applications;" > "$OUTPUT_DIR/applications.csv"

# Export data from repositories table
sqlite3 "$DB_FILE" -header -csv "SELECT * FROM repositories;" > "$OUTPUT_DIR/repositories.csv"

echo "Data export completed. Files are saved in $OUTPUT_DIR"