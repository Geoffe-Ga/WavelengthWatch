# Bug Report: [Brief Title - Performance Issue]

**Date:** YYYY-MM-DD
**Reporter:** [Your Name]
**Category:** Performance
**Status:** 🔴 New

---

## Bug Summary

[One sentence description of the performance issue]

---

## Severity & Priority

**Severity:** [Choose one]
- 🔴 Critical - App hangs, freezes, or becomes unresponsive
- 🟠 High - Significant lag affects core UX
- 🟡 Medium - Noticeable performance degradation
- 🟢 Low - Minor performance issue

**Priority:** [Choose one]
- P0 - Fix immediately before any release
- P1 - Fix before next release
- P2 - Fix in upcoming release
- P3 - Nice to have

---

## Environment

**Device/Simulator:**
- [ ] 41mm Apple Watch Series 9
- [ ] 45mm Apple Watch Series 9
- [ ] 49mm Apple Watch Ultra 2
- [ ] Real hardware: [Model]

**Software:**
- watchOS Version: [e.g., 10.0]
- Xcode Version: [e.g., 16.4]
- Build/Commit: [SHA or branch name]
- Build Configuration: [ ] Debug [ ] Release

**Backend:**
- Status: [ ] Running [ ] Offline
- Response time: [ms]

---

## Performance Metric

**What type of performance issue?**

- [ ] UI lag/stutter
- [ ] Slow rendering
- [ ] Dropped frames
- [ ] Slow navigation transitions
- [ ] Slow data loading
- [ ] High memory usage
- [ ] Battery drain
- [ ] Slow animation
- [ ] App freeze/hang
- [ ] Other: _________________

---

## Steps to Reproduce

1. [First step - be specific]
2. [Second step]
3. [Third step]
4. [Action that triggers performance issue]

**Example:**
1. Launch app
2. Navigate to Purple layer
3. Rapidly swipe left/right through phases 10 times
4. Observe scrolling performance

---

## Expected Performance

[Describe expected performance behavior]

**Example:**
Phase transitions should be smooth at 60fps with no stuttering. Swiping should feel responsive with immediate feedback.

**Measurements:**
- Frame rate: 60fps
- Transition time: <300ms
- Response latency: <16ms

---

## Actual Performance

[Describe actual performance behavior]

**Example:**
Phase transitions stutter noticeably, dropping to ~20fps during swipes. There's a 1-2 second delay before each transition completes. UI feels sluggish and unresponsive.

**Measurements:**
- Frame rate: [fps]
- Transition time: [ms]
- Response latency: [ms]
- Time to first interaction: [ms]

---

## Visual Evidence

### Screenshots

**Location:** `prompts/claude-comm/bugs/screenshots/[issue-name]/`

- [ ] Screenshot of Xcode Instruments trace
- [ ] Screenshot of Time Profiler
- [ ] Screenshot of memory graph
- [ ] Screenshot showing UI lag

### Video

- [ ] Screen recording showing performance issue: `[filename].mov`
- [ ] Duration: [X seconds]
- [ ] Side-by-side comparison (if available)

### Instruments Data

- [ ] Time Profiler trace: `[filename].trace`
- [ ] Allocations trace: `[filename].trace`
- [ ] Energy Log: `[filename].trace`

---

## Performance Profiling

**Xcode Instruments Data:**

**CPU Usage:**
- Peak CPU: [%]
- Average CPU: [%]
- Duration of high CPU: [seconds]

**Memory:**
- Memory at start: [MB]
- Memory at peak: [MB]
- Memory leaked: [MB]
- Persistent allocations: [count]

**Energy:**
- Energy impact: [ ] Low [ ] Medium [ ] High [ ] Very High
- Background time: [seconds]

**Frame Rate:**
- Target FPS: 60
- Actual FPS: [value]
- Dropped frames: [count]
- Frame time: [ms]

---

## Hot Path Analysis

**Xcode Time Profiler - Top Functions:**

1. Function: _____________ | Time: ___% | Location: _____________
2. Function: _____________ | Time: ___% | Location: _____________
3. Function: _____________ | Time: ___% | Location: _____________

**Call Stack:**

```
[Paste relevant call stack from Instruments]
```

---

## Triggering Conditions

**When does performance degrade?**

- [ ] Always
- [ ] After X seconds: _______
- [ ] After X interactions: _______
- [ ] When specific data loaded: _______
- [ ] When multiple views open: _______
- [ ] When memory pressure high
- [ ] Other: _________________

**Does performance recover?**

- [ ] Yes, after time: _______ seconds
- [ ] Yes, after action: _______
- [ ] No, persists until app restart
- [ ] No, persists until device restart

---

## Affected Operations

**Which operations are slow?**

- [ ] View rendering
- [ ] Scrolling (vertical/horizontal)
- [ ] Navigation transitions
- [ ] Data parsing
- [ ] Network requests
- [ ] Cache reads/writes
- [ ] Image loading
- [ ] Animation
- [ ] Other: _________________

---

## Resource Usage

**System Resources:**

**Before issue:**
- CPU: [%]
- Memory: [MB]
- Disk I/O: [ ] Low [ ] High
- Network: [ ] Idle [ ] Active

**During issue:**
- CPU: [%]
- Memory: [MB]
- Disk I/O: [ ] Low [ ] High
- Network: [ ] Idle [ ] Active

**Console Warnings:**

```
[Paste any performance-related console warnings]
```

---

## Code Locations

**Suspected files:**

- [ ] File: _____________ - Lines: _______ - Reason: _____________
- [ ] File: _____________ - Lines: _______ - Reason: _____________
- [ ] File: _____________ - Lines: _______ - Reason: _____________

**Suspected causes:**

- [ ] Expensive computation on main thread
- [ ] Synchronous I/O operations
- [ ] Large data set processing
- [ ] Inefficient algorithm
- [ ] Unnecessary re-renders
- [ ] Memory leaks
- [ ] Excessive allocations
- [ ] N+1 query problem
- [ ] Missing caching
- [ ] Other: _________________

---

## Related Issues

**GitHub Issues:**
- Related to: #______
- Duplicate of: #______
- Blocks: #______
- Blocked by: #______

**Pull Requests:**
- Introduced in: PR #______
- Fixed in: PR #______ (if applicable)

---

## Comparison

**Performance in previous version:**

- Build/Commit: [SHA]
- Performance: [Describe - was it better/worse/same?]
- Measurement: [fps, ms, etc.]

**Did something change?**

- [ ] Yes - PR/Commit: _______
- [ ] No - Always been slow
- [ ] Unknown

---

## User Impact

**How does this affect users?**

[Describe the UX impact]

**Is the app still usable?**

- [ ] Yes - Annoying but functional
- [ ] Barely - Significantly impacts UX
- [ ] No - App unusable due to performance

**Frequency of operation:**

- [ ] High - Core interaction, happens constantly
- [ ] Medium - Common operation
- [ ] Low - Rare operation

---

## Suggested Fix

**Proposed optimization:**

[If you have ideas for how to optimize, describe them here]

**Example:**
1. Move data processing off main thread using async/await
2. Add debouncing to scroll handler (currently fires on every frame)
3. Cache computed layout values instead of recalculating
4. Use LazyVStack/LazyHStack for large lists
5. Add .drawingGroup() modifier for complex rendering

**Expected improvement:**

- Target frame rate: 60fps
- Target transition time: <300ms
- CPU reduction: From __% to __%

**Files to modify:**

- [ ] File: _____________ - Change: _____________
- [ ] File: _____________ - Change: _____________

---

## Workaround

**Is there a temporary workaround?**

[Describe any way to avoid the performance issue]

**Example:**
Navigate more slowly through phases (1-2 second pause between swipes). This gives the app time to complete transitions and avoids frame drops.

---

## Regression

- [ ] Performance was better before
- [ ] This is a new feature (no baseline)
- [ ] Unknown

**If regression, when did performance degrade?**

- Commit/PR: [SHA or PR number]
- What changed: [Brief description]

---

## Optimization Priority

**Business justification:**

- [ ] Core UX is affected
- [ ] Users complaining
- [ ] Battery drain concern
- [ ] Competitive advantage
- [ ] Nice to have polish

---

## Reproduction Rate

**How often does this occur?**

- [ ] Always (100%)
- [ ] Frequently (>75%)
- [ ] Sometimes (25-75%)
- [ ] Rarely (<25%)
- [ ] Device-specific

**Hardware dependency:**

- [ ] Only on older hardware
- [ ] Only on specific watch size
- [ ] All devices affected

---

## Checklist

- [ ] Bug reproduced at least twice
- [ ] Video recording captured
- [ ] Instruments trace captured
- [ ] Hot path identified
- [ ] Performance measurements recorded
- [ ] All relevant information filled out
- [ ] GitHub issue created: #______
- [ ] Related issues linked

---

## Notes

[Any additional notes, observations, or context about the performance issue]
