# GitHub Issues Created - Emotion Logging Flow

**Date**: 2025-11-19
**Epic Issue**: [#92](https://github.com/Geoffe-Ga/WavelengthWatch/issues/92)

## Summary

Created **21 GitHub issues** (1 epic + 20 implementation tasks) for the Multi-Step Emotion Logging Flow feature.

## Labels Created

- `epic:emotion-logging-flow` - Epic-level tracking
- `phase:0-foundation` - Layer filtering foundation
- `phase:1-flow-foundation` - Flow coordinator and state management
- `phase:2-primary-selection` - Primary emotion selection
- `phase:3-secondary-selection` - Secondary emotion selection
- `phase:4-strategy-selection` - Strategy selection
- `phase:5-review-submit` - Review and submission
- `phase:6-integration` - Integration and polish
- `test-driven` - TDD required
- `documentation` - Documentation tasks

## Issues by Phase

### Epic
- [#92](https://github.com/Geoffe-Ga/WavelengthWatch/issues/92) - **[EPIC] Multi-Step Emotion Logging Flow**

### Phase 0: Foundation (3 tasks)
- [#72](https://github.com/Geoffe-Ga/WavelengthWatch/issues/72) - [Phase 0.1] Create LayerFilterMode Enum
- [#73](https://github.com/Geoffe-Ga/WavelengthWatch/issues/73) - [Phase 0.2] Add Layer Filtering to ContentViewModel
- [#74](https://github.com/Geoffe-Ga/WavelengthWatch/issues/74) - [Phase 0.3] Update ContentView to Support Filtered Navigation

### Phase 1: Flow Foundation (3 tasks)
- [#75](https://github.com/Geoffe-Ga/WavelengthWatch/issues/75) - [Phase 1.1] Create JournalFlowViewModel
- [#76](https://github.com/Geoffe-Ga/WavelengthWatch/issues/76) - [Phase 1.2] Create Flow Coordinator View
- [#77](https://github.com/Geoffe-Ga/WavelengthWatch/issues/77) - [Phase 1.3] Add Log Emotion Entry Point to Menu

### Phase 2: Primary Selection (2 tasks)
- [#78](https://github.com/Geoffe-Ga/WavelengthWatch/issues/78) - [Phase 2.1] Create Primary Emotion Selection View
- [#79](https://github.com/Geoffe-Ga/WavelengthWatch/issues/79) - [Phase 2.2] Create FilteredLayerNavigationView Component

### Phase 3: Secondary Selection (3 tasks)
- [#80](https://github.com/Geoffe-Ga/WavelengthWatch/issues/80) - [Phase 3.1] Create Secondary Emotion Prompt View
- [#81](https://github.com/Geoffe-Ga/WavelengthWatch/issues/81) - [Phase 3.2] Create Secondary Emotion Selection View
- [#82](https://github.com/Geoffe-Ga/WavelengthWatch/issues/82) - [Phase 3.3] Create EmotionSummaryCard Component

### Phase 4: Strategy Selection (2 tasks)
- [#83](https://github.com/Geoffe-Ga/WavelengthWatch/issues/83) - [Phase 4.1] Create Strategy Selection View
- [#84](https://github.com/Geoffe-Ga/WavelengthWatch/issues/84) - [Phase 4.2] Enhance FilteredLayerNavigationView for Strategy Tapping

### Phase 5: Review & Submit (2 tasks)
- [#85](https://github.com/Geoffe-Ga/WavelengthWatch/issues/85) - [Phase 5.1] Create Journal Review View
- [#86](https://github.com/Geoffe-Ga/WavelengthWatch/issues/86) - [Phase 5.2] Create StrategyCard Component

### Phase 6: Integration (5 tasks)
- [#87](https://github.com/Geoffe-Ga/WavelengthWatch/issues/87) - [Phase 6.1] Update NotificationDelegate to Route to Flow
- [#88](https://github.com/Geoffe-Ga/WavelengthWatch/issues/88) - [Phase 6.2] Add Flow Entry Point from Detail Views
- [#89](https://github.com/Geoffe-Ga/WavelengthWatch/issues/89) - [Phase 6.3] End-to-End Integration Tests
- [#90](https://github.com/Geoffe-Ga/WavelengthWatch/issues/90) - [Phase 6.4] Accessibility & VoiceOver Support
- [#91](https://github.com/Geoffe-Ga/WavelengthWatch/issues/91) - [Phase 6.5] Documentation Updates

## Dependency Chains

### Critical Path (Sequential)
```
#72 → #73 → #74 → #75 → #76 → #77 → #78 → #80 → #81 → #83 → #84 → #85 → #87 → #89
```

### Parallel Track 1 (Components)
```
#79 (can start with Phase 2)
#82 (can start with Phase 3)
#86 (can start with Phase 5)
#90 (can start with Phase 5)
```

### Parallel Track 2 (Integration & Docs)
```
#88 (can start with Phase 5)
#91 (can start when all implementation done)
```

## Work Stream Recommendations

### Stream 1: Critical Path Developer
Focus on sequential tasks that unlock subsequent phases:
- Phase 0: #72 → #73 → #74
- Phase 1: #75 → #76 → #77
- Phase 2: #78
- Phase 3: #80 → #81
- Phase 4: #83 → #84
- Phase 5: #85
- Phase 6: #87 → #89

### Stream 2: Components Developer
Build reusable components in parallel:
- Phase 2: #79 (FilteredLayerNavigationView)
- Phase 3: #82 (EmotionSummaryCard)
- Phase 5: #86 (StrategyCard)
- Phase 6: #90 (Accessibility)

### Stream 3: Integration Developer
Handle integration and polish:
- Phase 6: #88 (Detail view entry points)
- Phase 6: #91 (Documentation)

## Quick Start Commands

View all issues:
```bash
gh issue list --label "epic:emotion-logging-flow" --state open
```

View Phase 0 tasks:
```bash
gh issue list --label "phase:0-foundation" --state open
```

View the epic:
```bash
gh issue view 92
```

Start working on first task:
```bash
gh issue view 72
git checkout -b feat/layer-filter-mode
```

## Estimates

- **Total Tasks**: 20
- **Estimated Time (Serial)**: 66-91 hours (8-12 days)
- **Estimated Time (Parallel, 2-3 devs)**: 6-8 days
- **Average PR Size**: ~200 lines per task

## Next Actions

1. **Assign Phase 0 tasks** to kick off foundation work
2. **Create project board** (optional) for visual tracking
3. **Begin with #72** (LayerFilterMode enum) - no dependencies
4. **Review epic #92** for overall progress tracking

## Notes

- All tasks include comprehensive test requirements
- Each task is designed for TDD (tests before implementation)
- Dependencies clearly marked in issue descriptions
- All issues reference the spec and implementation plan
- Labels allow filtering by phase, epic, and type
