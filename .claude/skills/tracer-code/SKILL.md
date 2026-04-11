---
name: tracer-code
description: >-
  Tracer code development methodology for building working systems
  incrementally. Use when starting complex features, working under
  time constraints, or when you need a buildable app at every stage.
  Wire the skeleton first, then replace stubs with real logic one at a time.
  Do NOT use for small bug fixes or single-function tasks.
metadata:
  author: Geoff
  version: 1.0.0
---

# Tracer Code Development

Wire the entire system end-to-end with stubs, then iteratively replace them with real implementations - always maintaining a buildable, testable application.

## Instructions

### Phase 1: Wire the Skeleton (10-15% of time budget)

1. **Define the surface** - All views/endpoints with placeholder content
2. **Stub everything** - Return mock data matching expected types
3. **Connect all layers** - View -> ViewModel -> Service, even if one-liners
4. **Verify it builds** - Confirm Xcode build succeeds, backend starts
5. **Write smoke tests** - One test per component proving it renders/returns

```swift
// Stubbed view example
struct PhaseDetailView: View {
    let phase: Phase

    var body: some View {
        // TODO: implement real layout
        Text(phase.name)
            .wlCard()
    }
}
```

**Gate check**: Build succeeds, tests pass. You now have a demoable skeleton.

### Phase 2: Prioritize and Iterate (75-80% of time budget)

Replace stubs with real implementations one at a time, in priority order:

1. Rank features by user impact
2. For each feature: write failing test -> implement -> verify -> commit
3. Never break the skeleton - if stuck, keep the stub and move on
4. Reassess priority after each feature

**Priority heuristic**:
- **P0**: Core interaction (the thing the user touches first)
- **P1**: Data display and formatting
- **P2**: Edge cases and secondary interactions
- **P3**: Polish (animations, transitions, micro-interactions)

### Phase 3: Polish (5-10% of time budget)

- Add edge case tests for implemented features
- Improve error states and empty states
- Clean up remaining TODOs in implemented code
- Do NOT start new features - polish what works

### Decision Framework

At any point, ask: "If I stopped right now, would this build and be testable?"
- **Yes** -> Keep going, pick next highest-impact feature
- **No** -> Stop. Get back to green. Stub it out and move on.

## Examples

### Example 1: Liquid Glass View Rebuild

**Phase 1** (skeleton):
```swift
struct LayerView: View {
    let layer: Layer
    var body: some View {
        Text(layer.name) // Stub
    }
}
```

**Phase 2** (real implementation):
```swift
struct LayerView: View {
    let layer: Layer
    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack {
                ForEach(layer.phases) { phase in
                    PhaseCardView(phase: phase, layerColor: layer.color)
                }
            }
        }
        .wlGlass()
    }
}
```

## Troubleshooting

### Error: Feature is harder than expected and breaking the build
- Revert the change immediately
- Keep the stub for that feature
- Move to the next priority item

### Error: Spending too long on one feature
- A building skeleton with 3 real features beats a broken app with 1 perfect feature
