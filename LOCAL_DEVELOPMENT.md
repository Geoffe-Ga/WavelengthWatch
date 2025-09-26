# Local Development Setup

This guide explains how to set up local development for testing the WavelengthWatch app on a physical Apple Watch.

## Quick Setup

### 1. **Run the Setup Script**
```bash
bash scripts/setup-local-api.sh
```

This will:
- Detect your Mac's local IP address
- Create `APIConfiguration-Local.plist` with the correct local server URL
- The local config file is gitignored and won't be committed

### 2. **Start the Backend Server**
```bash
uvicorn backend.app:app --host 0.0.0.0 --port 8000 --reload
```

**Important**: Use `--host 0.0.0.0` to make the server accessible from your watch on the local network.

### 3. **Build and Run the Watch App**
The app will automatically use your local server when `APIConfiguration-Local.plist` exists.

## Manual Setup

If you prefer to set up manually:

1. **Find your Mac's IP address:**
   ```bash
   ifconfig | grep "inet " | grep -v 127.0.0.1
   ```

2. **Copy the template:**
   ```bash
   cp "frontend/WavelengthWatch/WavelengthWatch Watch App/Resources/APIConfiguration-Template.plist" \
      "frontend/WavelengthWatch/WavelengthWatch Watch App/Resources/APIConfiguration-Local.plist"
   ```

3. **Edit the local config:**
   ```xml
   <key>API_BASE_URL</key>
   <string>http://192.168.1.XXX:8000</string>  <!-- Your IP here -->
   ```

## Configuration Priority

The app loads configuration in this order:
1. **Info.plist** (build-time configuration)
2. **APIConfiguration-Local.plist** (local development - gitignored)
3. **APIConfiguration.plist** (production configuration)
4. **Fallback** to placeholder URL

## Security Notes

- `APIConfiguration-Local.plist` is gitignored and never committed
- `APIConfiguration.plist` contains safe placeholder URLs for production
- Local IP addresses are never stored in the repository

## Troubleshooting

### Watch Can't Connect
- Ensure your Mac and Watch are on the same WiFi network
- Check firewall settings on your Mac
- Verify the backend server is running with `--host 0.0.0.0`

### Server Not Accessible
```bash
# Test server accessibility from another device
curl http://YOUR_MAC_IP:8000/health
```

### Reset Configuration
```bash
rm "frontend/WavelengthWatch/WavelengthWatch Watch App/Resources/APIConfiguration-Local.plist"
```
