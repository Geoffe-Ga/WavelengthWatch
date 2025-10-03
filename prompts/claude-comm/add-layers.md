## Objective: Add `layers` denoted by `color` `stages` accessible via Vertical scrolling that correspond to the `Stage`/`level` and `Phase`  the user wishes to view

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
│ │ ├── headers.json # Lists headers and subheaders for each `layer` of vertical scrolling
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
- `phase`: [Rising, Peaking, Withdrawal, Diminishing, Bottoming Out, Restoration]
  - for layers other than `Strategies`, each `phase` has a `medicine` and a `toxic` expression (`data/curriculum.json`)
  - for `Strategies`, each `phase` has a list of `strategies`
- `strategies`: everything in `backend/data/strategies.json`

### Key User Story:
As a person with **Bipolar Disorder**, I want to be able to see the ***Modes*** of the Archetypal Wavelength
APTITUDE **Curriculum** for each Phase of the sine curve of my mood (_Rising, Peaking,
Withdrawal, Diminishing, Bottoming Out, Restoration_) so that when I am, for example, moving from Rising in the Beige
Stage, I know that making Commitments at this point is Medicinal while Overcommitting is Toxic: too high a dose of my
building manic energy. This will help me modulate my choices in order to reduce my activation level and improve my stability, ultimately promoting temperance
and euthymia.


### User Experience Objectives
- Scrolling horizontally moves between Phases on the current `layer`.
  - This is captured in `backend/data/curriculum.json` for all `layers` (colors) other than "Stratgies", example data:
```
    {
  "Beige": {
    "Rising": {
      "Medicine": "Commitment",
      "Toxic": "Overcommitment"
    },
    "Peaking": {
      "Medicine": "Diligence",
      "Toxic": "Thriving"
    },...
  },
  "Purple": {...}...
```

- Scrolling **vertically** moves ***between*** `layers`.
  - "Strategies" (currently implemented) is one `layer`, the others are colors listed in `backend/data/curriculum.json`, eg "Purple", "Blue", etc.
  - The `phase` button for each `layer` should be the color appropriate to the `layer`
    - Blue button saying "Rising" for `Blue` `layer`, horizontal scroll shows another Blue button. Vertical scroll and button changes color.
- Each `layer` should have the appropriate title, subtitle attached to it.
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
    - When I am scrolling horizontally through the Strategies `layer` (all that is currently implemented),
      I want to see the "Strategies" headers; When I then scroll vertically into Beige (TODO: implement now!),
      I want to see the header and subheader associated with Beige on all screens I scroll horizontally through.
      - e.g. scrolling up from the Rising Phase of the Strategies screen, will go to the Beige Stage's Rising Phase screen
      and then scrolling up again will go to the Purple Stage, then Red, Blue, etc.
        - At each point, the next vertical level's Header and Subheader will need to be displayed
      - Vertical scroll data is captured in `backend/data/curriculum.json`


### Deliverables
- WatchOS SwiftUI code that builds successfully on the simulator that meets all UX requirements above
- WatchOS SwiftUI pulls from `headers.json`, `curriculum.json` and `strategies.json` to visualize all app data
- Tests verify all working code
- CI and pre-commit pass green

### Gaurdrails
- Make sure the `Strategies` `layer` still works as it works now
- Tests, CI, and Pre-commit all pass green.
