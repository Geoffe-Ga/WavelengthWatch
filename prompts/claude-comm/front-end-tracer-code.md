## Objective: build a minimal frontend MVP out of SwiftUI for the "WavelengthWatch" Apple Watch app.

### Background

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

### Key User Story:
As a person with **Bipolar Disorder**, I want to be able to see the Self-Care ***Strategies*** that are recommended
in the Archetypal Wavelength APTITUDE Curriculum for each Phase of the sine curve of my mood (_Rising, Peaking,
Withdrawal, Diminishing, Bottoming Out, Restoration_) so that when I am, for example, moving from Peaking (mania)
into Withdrawal (anxiety or paranoia) on the way to Bottoming Out (depression) I know what kinds of activities
I can engage in in order to reduce my activation level and improve my stability, ultimately promoting temperance
and euthymia.


### User Experience Objectives
- Horizontally scroll between Phases of the Wavelength
    - (Rising <--> Peaking <--> Withdrawal <--> Diminishing <--> Bottoming Out <--> Restoration)
    - Scrolling past Restoration returns to Rising (Restoration <--> Rising)
- On tapping a Phase, a scrollable list of Self-Care Strategies is brought up
    - This will be captured in `backend/data/strategies.json`. Example data structure:
    ```
    "Rising": [
    {"color": "Green", "strategy": "One"},
    {"color": "Red", "strategy": "Two"},
    {"color": "Teal", "strategy": "Three"}
    ],
    "Peaking": [...],...
    ```
    - Strategies are shown in font colors corresponding to their APTITUDE Stage (Beige, Purple, Red, Blue, Orange, Green,
      Yellow, Teal, Ultraviolet, Clear Light) (stage information be captured as a property in `backend/data/strategies.json`)
    - Exit to return to the "Strategy" screen (Phase screen with horizontal scroll).

### Deliverables
- WatchOS SwiftUI code that builds successfully on the simulator that meets all the criteria of the UX
- Tests verify all working code
- CI and pre-commit pass green

### Guardrails
- Development should keep in mind support for future integration of vertical scroll between APTITUDE Stages
    - e.g. scrolling up from the Rising Phase of the Strategies screen, will go to the Beige Stage's Rising Phase screen
    and then scrolling up again will go to the Purple Stage, then Red, Blue, etc.
    - Vertical scroll data is captured in `backend/data/curriculum.json`
- All code must be verified by working tests
- Pre-commit and CI must pass green
