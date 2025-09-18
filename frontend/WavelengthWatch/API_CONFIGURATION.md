# Watch API Configuration

The watch target reads `API_BASE_URL` from `WavelengthWatch Watch App/Resources/APIConfiguration.plist`. The default entry points at
`https://api.not-configured.local`, a placeholder that will never resolve. Update the value before running on a simulator or device.

## Quick Reference

1. In Xcode, select the **WavelengthWatch Watch App** target.
2. Navigate to **Build Settings → Info.plist Values**.
3. Override `API_BASE_URL` for each configuration that needs a different backend endpoint.
4. Commit the plist change (or add a configuration-specific plist) so teammates inherit the update.

`AppConfiguration` asserts in debug builds when the placeholder host is still active and logs using `os.Logger` in all builds. You can
watch these messages in the Xcode console to verify that the correct host is loaded.

For local development against the FastAPI server, run:

```bash
uvicorn backend.app:app --reload --host 0.0.0.0 --port 8000
```

Then update the plist to `http://127.0.0.1:8000` (or your tunnel URL) before launching the watch app.
