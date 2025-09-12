# Xcode Build Setup Instructions

This document explains how to add the Run Script Phase to automatically convert CSV files to JSON during the Xcode build process.

## Adding the Run Script Phase

To ensure the latest JSON data is available in the watch app on every build, follow these steps:

### 1. Open the Project in Xcode
- Open `frontend/WavelengthWatch/WavelengthWatch.xcodeproj` in Xcode

### 2. Select the Watch App Target
- In the project navigator, select the `WavelengthWatch` project
- In the target list, select `WavelengthWatch Watch App`

### 3. Add the Run Script Phase
- Go to the "Build Phases" tab
- Click the "+" button and select "New Run Script Phase"
- **Important**: Drag this new Run Script Phase to be positioned **BEFORE** the "Copy Bundle Resources" phase

### 4. Configure the Run Script
In the Run Script phase configuration:

**Shell**: `/bin/bash`

**Script**:
```bash
# Use the existing convert_csv_to_json.sh script
PROJECT_ROOT="$SRCROOT/../.."
SCRIPT_PATH="$PROJECT_ROOT/scripts/convert_csv_to_json.sh"

# Run the conversion script
"$SCRIPT_PATH"

# Copy the generated JSON files to Resources for bundling
RESOURCES_DIR="$SRCROOT/WavelengthWatch Watch App/Resources"
mkdir -p "$RESOURCES_DIR"
cp "$PROJECT_ROOT/backend/data/prod/"*.json "$RESOURCES_DIR/"
echo "📁 JSON files copied to Resources directory"
```

**Input Files**: (Add these paths)
- `$(SRCROOT)/../../backend/data/a-w-curriculum.csv`
- `$(SRCROOT)/../../backend/data/a-w-headers.csv`
- `$(SRCROOT)/../../backend/data/a-w-strategies.csv`

**Output Files**: (Add these paths)
- `$(SRCROOT)/WavelengthWatch Watch App/Resources/a-w-curriculum.json`
- `$(SRCROOT)/WavelengthWatch Watch App/Resources/a-w-headers.json`
- `$(SRCROOT)/WavelengthWatch Watch App/Resources/a-w-strategies.json`

### 5. Build Phase Order
Ensure the build phases are in this order:
1. **[Your new Run Script Phase]** - Convert CSV to JSON
2. Copy Bundle Resources - Copy JSON files to app bundle
3. Compile Sources
4. Link Binary With Libraries

## What This Setup Achieves

1. **Automatic CSV Processing**: Every time you build the watch app, the latest CSV data is converted to JSON
2. **Fresh Data**: The watch app always contains the most recent data from the CSV files
3. **Build Integration**: No manual steps required - everything happens automatically during Xcode builds
4. **Incremental Builds**: Xcode will only run the script when CSV files have changed (due to Input/Output file specification)

## Testing the Setup

After adding the Run Script Phase:

1. **Clean Build**: Product → Clean Build Folder
2. **Build**: Product → Build
3. **Check Console**: Look for the conversion messages in the build log
4. **Verify**: The app should load data from JSON files instead of hardcoded strings

## Troubleshooting

- **"python3 not found"**: Install Python 3 or ensure it's in your PATH
- **"Script not found"**: Make sure you're running the script from the correct directory
- **"Permission denied"**: The `chmod +x` command should fix this
- **JSON files not bundled**: Ensure the Resources directory exists and JSON files are copied there

The build script is located at: `scripts/convert_csv_to_json.sh`
