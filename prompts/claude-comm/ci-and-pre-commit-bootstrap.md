## We are building CI and pre-commit for an Apple Watch -only app with a Swift frontend and a minimal FastAPI python backed, with json data storage.

For CI and pre-commit, we are going to start from scratch.

I have a directory with this layout:

```
WavelengthWatch/
├── frontend/ # watchOS SwiftUI app
│ └── WavelengthWatch/ # Xcode project + assets
│
├── backend/ # FastAPI service
│ ├── app.py # FastAPI entrypoint
│ ├── data/
│ │ ├── curriculum.json # stage/phase + medicinal/toxic
│ │ ├── strategies.json # self-care strategies
│ │ └── images/ # optional static images
│ └── requirements.txt
│
├── tests/ # shared test root
│ ├── backend/ # pytest for FastAPI
│ └── frontend/ # Swift XCTest / Swift Testing (lives in Xcode)
│
├── .github/workflows/ci.yml # CI pipeline
├── .pre-commit-config.yaml # pre-commit hooks
└── AGENTS.md # Guardrails for AI Agents in pair programming
```
Files present:
- `frontend` is just a `Hello World` right now, but properly initialized via Xcode and confirmed running in a watch simulator
- `backend` only has `app.py` (*minimal* FastAPI app) and `tools/csv_to_json.py` (ETL from Google Sheets-generated CSVs to json usable by the watch app). Neither of these files has been tested.
- AGENTS.md and README.md both exist with information to new Agents or Humans visiting the repo
- .gitignore exists and has some basic rules in it
- `github/workflows` does not have anything in it.

Here are my system settings, if that helps:
Macbook Air M4 Chip
MacOS: Sequoia 15.6.1
Xcode Version: 16.4
Apple Watch Series 9
WatchOS version: 11.6.1
iPhone 13 Pro Max
iOS version: 18.6.2

## We are building CI and pre-commit for an Apple Watch -only app with a Swift frontend and a minimal FastAPI python backed, with json data storage.

For CI and pre-commit, we are going to start from scratch.

I have a directory with this layout:

```
WavelengthWatch/
├── frontend/ # watchOS SwiftUI app
│ └── WavelengthWatch/ # Xcode project + assets
│
├── backend/ # FastAPI service
│ ├── app.py # FastAPI entrypoint
│ ├── data/
│ │ ├── curriculum.json # stage/phase + medicinal/toxic
│ │ ├── strategies.json # self-care strategies
│ │ └── images/ # optional static images
│ └── requirements.txt
│
├── tests/ # shared test root
│ ├── backend/ # pytest for FastAPI
│ └── frontend/ # Swift XCTest / Swift Testing (lives in Xcode)
│
├── .github/workflows/ci.yml # CI pipeline
├── .pre-commit-config.yaml # pre-commit hooks
└── AGENTS.md # Guardrails for AI Agents in pair programming
```
Files present:
- `frontend` is just a `Hello World` right now, but properly initialized via Xcode and confirmed running in a watch simulator
- `backend` only has `app.py` (*minimal* FastAPI app) and `tools/csv_to_json.py` (ETL from Google Sheets-generated CSVs to json usable by the watch app). Neither of these files has been tested.
- AGENTS.md and README.md both exist with information to new Agents or Humans visiting the repo
- .gitignore exists and has some basic rules in it
- `github/workflows` does not have anything in it.

Here are my system settings, if that helps:
Macbook Air M4 Chip
MacOS: Sequoia 15.6.1
Xcode Version: 16.4
Apple Watch Series 9
WatchOS version: 11.6.1
iPhone 13 Pro Max
iOS version: 18.6.2

Here is the result of `xcodebuild -list`
```
Command line invocation:
    /Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -list -project frontend/WavelengthWatch/WavelengthWatch.xcodeproj

Information about project "WavelengthWatch":
    Targets:
        WavelengthWatch
        WavelengthWatch Watch App
        WavelengthWatch Watch AppTests
        WavelengthWatch Watch AppUITests

    Build Configurations:
        Debug
        Release

    If no build configuration is specified and -scheme is not passed then "Release" is used.

    Schemes:
        WavelengthWatch Watch App

Command line invocation:
    /Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -project frontend/WavelengthWatch/WavelengthWatch.xcodeproj -scheme "WavelengthWatch Watch App" -showdestinations



        Available destinations for the "WavelengthWatch Watch App" scheme:
                { platform:watchOS, id:dvtdevice-DVTiOSDevicePlaceholder-watchos:placeholder, name:Any watchOS Device }
                { platform:watchOS Simulator, id:dvtdevice-DVTiOSDeviceSimulatorPlaceholder-watchsimulator:placeholder, name:Any watchOS Simulator Device }
                { platform:watchOS Simulator, arch:arm64, id:44BF2149-5BCA-4B4E-97F4-5A8624C234D4, OS:11.5, name:Apple Watch SE (40mm) (2nd generation) }
                { platform:watchOS Simulator, arch:arm64, id:47624108-1650-4D0D-9BE0-E4DC09238942, OS:11.5, name:Apple Watch SE (44mm) (2nd generation) }
                { platform:watchOS Simulator, arch:arm64, id:D160199D-1BFF-4DDA-BD48-4F28BF1A298C, OS:11.5, name:Apple Watch Series 10 (42mm) }
                { platform:watchOS Simulator, arch:arm64, id:F05E12A3-3DB4-421B-AB6F-BB3C9FFF68F4, OS:11.5, name:Apple Watch Series 10 (46mm) }
                { platform:watchOS Simulator, arch:arm64, id:ADBA4BAB-F7FC-4EB9-85B6-8CFA3DDA367A, OS:11.5, name:Apple Watch Ultra 2 (49mm) }
```
