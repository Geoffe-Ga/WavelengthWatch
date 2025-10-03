## Objective: Add headers and subheaders to each screen that correspond to the `layer` the user is viewing

### Background

I have a project with this layout:

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
│ │ ├── headers.json # TODO: Make this file for this PR by adding functionality to csv_to_json.py
│ │ └── images/ # optional static images
│ ├── tools/
│ │ ├── csv_to_json.py # converts by detecting csv headers, then creating data/*.json files
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

### Data Dictionary:
- `layer`: [Strategies, Beige, Purple, Red, Blue, Orange, Green, Yellow, Teal, Ultraviolet, Clear Light]
  - each has a `title` and `subtitle`
  - `layer`s besides `Strategies` are all also called "APTITUDE Stages"
- `phase`: [Rising, Peaking, Withdrawal, Diminishing, Bottoming Out, Restoration]
  - for layers other than `Strategies`, each `phase` has a `medicine` and a `toxic` expression (`data/curriculum.json`)
  - for `Strategies`, each `phase` has a `list` of `strategies`
- `strategies`: everything in `backend/data/strategies.json`

### Key User Story:
As a person with **Bipolar Disorder**, I want to be able to see the Self-Care ***Strategies*** that are recommended
in the Archetypal Wavelength APTITUDE Curriculum for each Phase of the sine curve of my mood (_Rising, Peaking,
Withdrawal, Diminishing, Bottoming Out, Restoration_) so that when I am, for example, moving from Peaking (mania)
into Withdrawal (anxiety or paranoia) on the way to Bottoming Out (depression) I know what kinds of activities
I can engage in in order to reduce my activation level and improve my stability, ultimately promoting temperance
and euthymia.

### User Experience Objectives
- ***Example***: on the `"Rising"` Phase `screen` of the "Strategies" `layer`
  show the title `"Self-Care Strategies"`, and the "subtitle": `"(For Surfing)"` above the word `"Rising"`
  - When the user taps the word Rising, hide the title and subtitle and only show the list of Self-Care strategies, just as it is shown now.
- Objective is to see clear headers for each `phase` screen on the watch (e.g. screens saying one of
  `[Rising, Peaking, Withdrawal, Diminishing, Bottoming Out, Restoration]` )
    - This will be captured in `backend/data/headers.json`. Example data structure:
    ```
    "Strategies": {  # "Strategies" is a `layer`
        "title": "Self-Care"
        "subtitle": "(For Surfing)"
    },
    "Beige": {  # "Beige" is another `layer`
        "title": "INHABIT"
        "subtitle": "(Do)"
    },
    "Purple": {...},...
    ```
    - Titles and Subtitles are shown on the Strategy screen according to the data file in `backend/data/a-w-headers.csv`
    - When I am scrolling horizontally through the Strategies `layer` (all that is currently implemented), I want to see the "Strategies" headers;
      When I then scroll vertically into Beige (Not yet implemented), I want to see the header and subheader associated with Beige on all screens I
      scroll horizontally through.

### Deliverables
- WatchOS SwiftUI code that builds successfully on the simulator that displays appropriate headers and subheaders on the appropriate screens
- Completed `backend/data/headers.json` file
- Upgraded `backend/data/csv_to_json.py` file so that it can ingest future data
  structured such as `backend/data/a-w-headers.csv` and transform it into `backend/data/headers.json`
- WatchOS SwiftUI pulls from `headers.json` to visualize headers and subheaders.
- Tests verify all working code
- CI and pre-commit pass green

### Guardrails
- Development should keep in mind support for future integration of vertical scroll between APTITUDE Stages
    - e.g. scrolling up from the Rising Phase of the Strategies screen, will go to the Beige Stage's Rising Phase screen
    and then scrolling up again will go to the Purple Stage, then Red, Blue, etc.
      - At each point, the next vertical level's Header and Subheader will need to be displayed
    - Vertical scroll data is captured in `backend/data/curriculum.json`
- All code must be verified by working tests
- Pre-commit and CI must pass green
