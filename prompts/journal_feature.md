## Deliverable
Please build me a roadmap of task stubs, clearly indicating which can be run in parallel
and which need to be run sequentially and propose as many as are necessary to make this happen.

## Goal: Add a "journal" feature that persists responses (`stage`/`phase` combos)

### User Story
As a person with Bipolar disorder, I want to introspect into my mood states regularly, so that I
can become familiar with my moods, identify patterns in my moods (e.g. I am "Peaking" every day at 11am)
and be prompted to experience their somatic components more fully.

### User Experience
1. Set a schedule (e.g. Ask me about my mood every day at 8am, 12pm, 4pm, and 8pm)
    using a clock feature, similar to the Timer app.
2. A notification goes off at one of those times / the user loads the app during the day operating on their own volition
3. The user gets a notif "What Mode of the Wavelength were you just experiencing?": tap to clear
4. The user browses through the `stages` and `phases` and taps a `stage`/`phase`/`dosage` combo,
   e.g. `{"stage": "Red", "phase": "Rising", "dosage": "medicine"}` and completes via confirmation.
5. Answer is persisted with timestamp and whether it was self-initiated or timer-started to backend SQL storage.
6. Exit by surfacing the Self-Care strategies for that `phase`.

### Note
Another repo will handle building a website that visualizes the data that is created through this process. But please
make sure you are including enough information in the SQL storage that we can visualize the data.

### Guardrails
- Prefer to make the task stubs atomized and parallelizable, but indicate when they must be run in sequence
- Ensure the task stubs are logical and sane in scope—if a change requires more than about 300 lines diff, split it up
- Include writing tests as a necessary part of each proposed task stub
