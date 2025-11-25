# Bug Testing & Reporting System

**Created:** 2025-11-24
**Purpose:** Systematic testing and bug documentation for WavelengthWatch

---

## Quick Start

1. **Read the testing plan:** Start with `00-testing-plan.md`
2. **Run through test categories** systematically
3. **When you find a bug:**
   - Choose appropriate template from list below
   - Copy template to `reports/` directory
   - Fill out all sections
   - Capture screenshots/video in `screenshots/[bug-name]/`
   - Create GitHub issue

---

## File Structure

```
bugs/
├── README.md                          ← You are here
├── 00-testing-plan.md                 ← Start here! Comprehensive test plan
│
├── Bug Templates (Choose one based on issue type):
├── bug-template-layout.md             ← Layout/sizing issues, clipping
├── bug-template-navigation.md         ← Navigation/scrolling issues
├── bug-template-functional.md         ← Features not working correctly
├── bug-template-data.md               ← Data loading/sync issues
├── bug-template-performance.md        ← Performance/lag issues
├── bug-template-state.md              ← State management issues
└── bug-template-ui.md                 ← Visual/styling issues
│
├── reports/                           ← Save filled bug reports here
│   ├── YYYY-MM-DD-bug-name.md
│   └── ...
│
└── screenshots/                       ← Save screenshots/videos here
    ├── bug-name/
    │   ├── screenshot-1.png
    │   ├── screenshot-2.png
    │   └── recording.mov
    └── ...
```

---

## Bug Templates Guide

### When to Use Each Template

**bug-template-layout.md** 🟦 Layout & Sizing
- Content clipped or cut off
- Elements not visible on specific watch sizes
- Font sizes inconsistent
- Spacing/padding issues
- Safe area problems
- **Examples:**
  - "View Details" button cut off on 41mm watch
  - Phase labels different sizes
  - Bottom glow not visible

**bug-template-navigation.md** 🟩 Navigation
- Scrolling not working correctly
- Navigation to wrong view
- Back button issues
- Gesture problems
- Digital Crown issues
- **Examples:**
  - Phase wrapping doesn't work
  - Swipe gesture not responsive
  - Back button missing

**bug-template-functional.md** 🟨 Functionality
- Features completely broken
- Actions not working
- Buttons not responding
- Forms not submitting
- **Examples:**
  - Journal flow hangs at strategy selection
  - Menu button does nothing
  - Cannot select emotion

**bug-template-data.md** 🟪 Data & Loading
- Data not loading
- Wrong data displayed
- Sync issues
- Network errors
- Cache problems
- **Examples:**
  - Catalog fails to load
  - Journal entries not saving
  - Offline mode broken

**bug-template-performance.md** 🟥 Performance
- UI lag or stuttering
- Slow rendering
- Dropped frames
- App freeze/hang
- High memory usage
- **Examples:**
  - Scrolling stutters
  - Transitions slow
  - App becomes unresponsive

**bug-template-state.md** 🟫 State Management
- Navigation position lost
- Settings not persisting
- UI out of sync with data
- State reset unexpectedly
- **Examples:**
  - Returns to wrong layer after detail view
  - Selected phase resets
  - Menu state incorrect

**bug-template-ui.md** ⬜ UI & Visual
- Visual inconsistencies
- Wrong colors/fonts
- Styling issues
- Alignment problems
- **Examples:**
  - Button wrong color
  - Text misaligned
  - Icon missing

---

## Workflow

### 1. Before Testing

- [ ] Read `00-testing-plan.md` completely
- [ ] Set up environment (backend running, simulators ready)
- [ ] Create local API configuration if needed

### 2. During Testing

- [ ] Follow test plan systematically
- [ ] When you find a bug:
  1. **Stop** and try to reproduce it
  2. **Choose** appropriate template
  3. **Copy** template to `reports/YYYY-MM-DD-brief-name.md`
  4. **Fill out** all sections
  5. **Capture** screenshots/video
  6. **Continue** testing

### 3. After Testing

- [ ] Review all bug reports
- [ ] Create GitHub issues for bugs
- [ ] Link related bugs together
- [ ] Create testing summary document
- [ ] Prioritize fixes

---

## Bug Report Naming Convention

**Format:** `YYYY-MM-DD-category-brief-description.md`

**Examples:**
- `2025-11-24-layout-button-clipped-41mm.md`
- `2025-11-24-navigation-phase-wrapping-broken.md`
- `2025-11-24-functional-journal-flow-hangs.md`
- `2025-11-24-data-catalog-load-timeout.md`
- `2025-11-24-performance-scroll-lag.md`
- `2025-11-24-state-layer-selection-reset.md`
- `2025-11-24-ui-inconsistent-fonts.md`

---

## Screenshot Organization

**Directory structure:**

```
screenshots/
├── brief-bug-name/
│   ├── 01-before.png
│   ├── 02-during.png
│   ├── 03-after.png
│   ├── 04-annotated.png         (with red circles/arrows)
│   ├── 05-comparison.png        (side-by-side)
│   ├── recording.mov             (screen recording)
│   └── console-log.txt           (if relevant)
```

**Naming tips:**
- Use descriptive names
- Number files in sequence
- Include annotations where helpful
- Save console logs as `.txt`

---

## Severity & Priority Guidelines

### Severity (Impact on users)

**🔴 Critical**
- App crashes
- Data loss/corruption
- Core features completely broken
- Security vulnerabilities

**🟠 High**
- Major features broken
- Significant UX degradation
- Wrong data/behavior
- Performance severely impacted

**🟡 Medium**
- Minor features broken
- Cosmetic issues affecting UX
- Workarounds available
- Inconsistencies

**🟢 Low**
- Polish items
- Very minor visual issues
- Edge cases
- Nice-to-haves

### Priority (When to fix)

**P0** - Fix immediately
- Blocks release
- Critical bugs
- Data loss risks

**P1** - Fix before next release
- High severity bugs
- Important features broken

**P2** - Fix in upcoming release
- Medium severity bugs
- Quality improvements

**P3** - Fix when time permits
- Low severity bugs
- Polish items
- Nice-to-haves

---

## Template Checklist

Every bug report should have:

- [ ] Clear, descriptive title
- [ ] Severity & priority set
- [ ] Environment documented
- [ ] Reproduction steps (detailed)
- [ ] Expected vs actual behavior
- [ ] Screenshots/video evidence
- [ ] Code locations identified (if possible)
- [ ] Related issues linked
- [ ] Reproduction rate noted
- [ ] All sections filled out

---

## Tips for Good Bug Reports

### Be Specific
❌ "Navigation is broken"
✅ "Swiping left from last phase ('Clearing') causes 2-second freeze before wrapping to first phase ('Rising')"

### Include Context
- What were you trying to do?
- What did you expect?
- What actually happened?
- How often does it occur?

### Provide Evidence
- Screenshots show the problem
- Videos show the full context
- Console logs show technical details
- Measurements quantify the issue

### Make It Reproducible
- Clear step-by-step instructions
- Include all preconditions
- Specify environment details
- Note any variations

---

## Testing Tips

### Test Systematically
- Follow the test plan in order
- Don't skip steps
- Test all watch sizes
- Test both happy paths and edge cases

### Document Everything
- Take notes as you test
- Screenshot anything unexpected
- Log console output for crashes
- Record videos for complex issues

### Reproduce Before Reporting
- Try to trigger the bug 2-3 times
- Verify it's consistent
- Try on different watch sizes
- Try with different data

---

## Creating GitHub Issues

### From Bug Report

After filling out a bug report template:

1. **Review** the report for completeness
2. **Create** GitHub issue with:
   - Title from bug report
   - Severity/priority labels
   - Relevant labels (layout, navigation, etc.)
   - Copy key sections from report
   - Link to full bug report in `prompts/claude-comm/bugs/reports/`
3. **Link** related issues/PRs
4. **Upload** screenshots to GitHub issue
5. **Update** bug report with GitHub issue number

### Template for GitHub Issue

```markdown
# [Brief Title]

**Severity:** 🔴 Critical / 🟠 High / 🟡 Medium / 🟢 Low
**Priority:** P0 / P1 / P2 / P3
**Category:** [Layout/Navigation/Functional/etc.]

## Summary
[One sentence description]

## Environment
- Watch: 41mm/45mm/49mm
- watchOS: X.X
- Build: [SHA]

## Steps to Reproduce
1. [Step 1]
2. [Step 2]
3. [Step 3]

## Expected vs Actual
**Expected:** [What should happen]
**Actual:** [What does happen]

## Evidence
[Screenshots/video]

## Full Report
See detailed bug report: `prompts/claude-comm/bugs/reports/YYYY-MM-DD-bug-name.md`

## Related
- Related to: #XXX
- Blocks: #XXX
```

---

## After Filing Bugs

### Organize & Prioritize

1. **Group related bugs** - Link bugs that affect same feature
2. **Prioritize fixes** - P0 first, then P1, etc.
3. **Plan fix order** - Some fixes may resolve multiple bugs
4. **Communicate** - Share findings with team

### Track Progress

- Update bug reports as fixes are implemented
- Link PR numbers to bug reports
- Verify fixes when PRs merge
- Retest fixed bugs

---

## Questions?

If you're unsure which template to use:

1. **Start with functional template** - It's the most general
2. **Switch templates** if you realize it's a different category
3. **Use multiple templates** if bug spans multiple categories
4. **Ask for help** if you're really stuck

Remember: A partially filled template is better than no report at all!

---

**Happy testing! 🧪**
