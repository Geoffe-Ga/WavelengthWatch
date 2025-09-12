#!/bin/bash

# Build script to convert CSV files to JSON for WavelengthWatch
# This script runs csv_to_json.py against all CSV files in backend/data/
# and outputs JSON files to backend/data/prod/ for bundling into the watch app

set -e

# Get the project root directory (assuming this script is in scripts/)
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_DATA_DIR="$PROJECT_ROOT/backend/data"
PROD_DIR="$BACKEND_DATA_DIR/prod"
CSV_TO_JSON_SCRIPT="$PROJECT_ROOT/backend/tools/csv_to_json.py"

echo "🔄 Converting CSV files to JSON for WavelengthWatch build..."
echo "Project root: $PROJECT_ROOT"
echo "Data directory: $BACKEND_DATA_DIR"
echo "Output directory: $PROD_DIR"

# Create prod directory if it doesn't exist
mkdir -p "$PROD_DIR"

# Check if python3 is available
if ! command -v python3 &> /dev/null; then
    echo "❌ Error: python3 not found in PATH"
    exit 1
fi

# Check if the csv_to_json.py script exists
if [ ! -f "$CSV_TO_JSON_SCRIPT" ]; then
    echo "❌ Error: csv_to_json.py script not found at $CSV_TO_JSON_SCRIPT"
    exit 1
fi

# Process each CSV file
csv_files_found=false
for csv_file in "$BACKEND_DATA_DIR"/*.csv; do
    if [ -f "$csv_file" ]; then
        csv_files_found=true
        filename=$(basename "$csv_file" .csv)
        echo "Processing $filename.csv..."

        # Run csv_to_json.py with output directed to prod directory
        python3 "$CSV_TO_JSON_SCRIPT" "$csv_file" --out "$PROD_DIR/$filename.json"

        if [ $? -eq 0 ]; then
            echo "✅ Generated $filename.json"
        else
            echo "❌ Failed to process $filename.csv"
            exit 1
        fi
    fi
done

if [ "$csv_files_found" = false ]; then
    echo "⚠️  No CSV files found in $BACKEND_DATA_DIR"
    exit 1
fi

echo "✅ All CSV files converted successfully!"
echo "📁 JSON files are available in: $PROD_DIR"
