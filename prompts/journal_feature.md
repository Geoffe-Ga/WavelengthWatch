## Deliverable
Please build me an Epic roadmap of task stubs, clearly indicating which can be run in parallel
and which need to be run sequentially and propose as many as are necessary (possibly dozens) to make this happen.

## Goal: Add a "journal" feature that persists responses (`stage`/`phase`/`dosage` combos with `timestamp` and `self-care`)

### User Story
As a person with Bipolar disorder, I want to be prodded to introspect into my mood states regularly, so that I
can become familiar with my moods, identify patterns in my moods (e.g. I am "Peaking" every day at 11am), be prompted
to experience their somatic components more fully, and appropriately apply self-care strategies based on my current
Wavelength Phase.

### User Experience
1. Set a schedule (e.g. Ask the user about their mood every day at—user configured—8am, 12pm, 4pm, and 8pm)
    using a clock feature, similar to the Timer or Alarm WatchOS apps.
   - We will need a place for this to live. Maybe a 3 dot menu?
2. Flow starts: A notification goes off at one of those times or the user loads the app during the day operating on their own volition
3. The user gets a notif "What Mode, Phase, and Dosage of the Wavelength were you just experiencing?": tap to clear
4. The user browses through the `stages` and `phases` and taps a `stage`/`phase`/`dosage` combo,
    e.g. `{"stage": "Red", "phase": "Rising", "dosage": "medicine"}` and completes via confirmation.
5. Option to add secondary `stage`, `phase`, and `dosage` combo (experiencing more than one at once is very typical)
6. Answer is persisted with timestamp and whether the logging was self-initiated or timer-started to backend SQL storage.
7. Exit by surfacing the Self-Care strategies for that `phase`.
8. Allow user to tap on a Self-Care strategy. If they do, raise a dialogue box and offer to persist that to storage
    too, with its own timestamp

### Note
Another repo will handle building a website that visualizes the data that is created through this process. But please
make sure you are including enough information in the SQL storage that we can visualize the data in
interesting and actionable ways.

### Guardrails
- Explain your reasoning for each Task Stub
- Prefer to make the task stubs atomized and parallelizable, but indicate when they must be run in sequence
- Ensure the task stubs are logical and sane in scope—if a change requires more than about 300 lines diff, split it up
- Include writing tests to verify code functions as intended as a necessary part of each proposed task stub
- If offering Task Stubs that must be done in sequence, use the "Pragmatic Programmer" technique of "Tracer Code":
  - Connect systems end to end first
  - Have a working demo available at any step
  - Build from an MVP and then flesh out the idea afterward
