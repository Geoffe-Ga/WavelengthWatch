#!/bin/bash

# Script to set up local API configuration for WavelengthWatch development
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG_DIR="$PROJECT_ROOT/frontend/WavelengthWatch/WavelengthWatch Watch App/Resources"
LOCAL_CONFIG="$CONFIG_DIR/APIConfiguration-Local.plist"
TEMPLATE_CONFIG="$CONFIG_DIR/APIConfiguration-Template.plist"

echo "🔧 Setting up local API configuration for WavelengthWatch..."

# Get the local IP address (excluding localhost)
LOCAL_IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | head -1 | awk '{print $2}')

if [ -z "$LOCAL_IP" ]; then
    echo "❌ Could not detect local IP address"
    echo "Please manually find your IP with: ifconfig | grep 'inet '"
    exit 1
fi

echo "📍 Detected local IP: $LOCAL_IP"

# Create local configuration file
echo "📝 Creating APIConfiguration-Local.plist..."

cat > "$LOCAL_CONFIG" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>API_BASE_URL</key>
    <string>http://$LOCAL_IP:8000</string>
</dict>
</plist>
EOF

echo "✅ Created $LOCAL_CONFIG"
echo "🚀 Your watch app will now connect to: http://$LOCAL_IP:8000"
echo ""
echo "Next steps:"
echo "1. Start the backend server with: uvicorn backend.app:app --host 0.0.0.0 --port 8000 --reload"
echo "2. Build and run the watch app"
echo ""
echo "Note: APIConfiguration-Local.plist is gitignored and won't be committed."
