# Bug Report: [Brief Title - Layout Issue]

**Date:** YYYY-MM-DD
**Reporter:** [Your Name]
**Category:** Layout / UI Sizing
**Status:** 🔴 New

---

## Bug Summary

[One sentence description of the layout issue]

---

## Severity & Priority

**Severity:** [Choose one]
- 🔴 Critical - Blocks core functionality, content completely inaccessible
- 🟠 High - Significant UX impact, content partially inaccessible
- 🟡 Medium - Minor UX impact, cosmetic issues
- 🟢 Low - Polish items, very minor visual inconsistencies

**Priority:** [Choose one]
- P0 - Fix immediately before any release
- P1 - Fix before next release
- P2 - Fix in upcoming release
- P3 - Nice to have

---

## Environment

**Device/Simulator:**
- [ ] 41mm Apple Watch Series 9 (smallest - most likely to show clipping)
- [ ] 45mm Apple Watch Series 9
- [ ] 49mm Apple Watch Ultra 2

**Software:**
- watchOS Version: [e.g., 10.0]
- Xcode Version: [e.g., 16.4]
- Build/Commit: [SHA or branch name]

**Screen Orientation:**
- [ ] Portrait (normal)
- [ ] Landscape (if applicable)

---

## Steps to Reproduce

1. [First step - be specific]
2. [Second step]
3. [Third step]
4. [Continue until issue appears]

**Example:**
1. Launch app on 41mm simulator
2. Navigate to Purple layer using Digital Crown
3. Observe the "View Details" button

---

## Expected Behavior

[What should happen - describe the correct layout]

**Example:**
The "View Details" button should be fully visible at the bottom of the content box with proper spacing from the screen edge.

---

## Actual Behavior

[What actually happens - describe the incorrect layout]

**Example:**
The "View Details" button is cut off at the bottom. Only the top half of the button text is visible. The glow effect is completely hidden.

---

## Visual Evidence

### Screenshots

**Location:** `prompts/claude-comm/bugs/screenshots/[issue-name]/`

- [ ] Screenshot showing the layout issue
- [ ] Screenshot showing affected watch size
- [ ] Screenshot showing correct behavior on other sizes (for comparison)
- [ ] Screenshot with red annotations marking the problem area

### Video

- [ ] Screen recording showing the issue: `[filename].mov`
- [ ] Duration: [X seconds]

---

## Layout Measurements

**If applicable, provide measurements:**

**Content Box:**
- Visible height: [Xpt]
- Expected height: [Xpt]
- Clipped amount: [Xpt]

**Button:**
- Visible: [Yes/No/Partial]
- Touch target size: [Xpt x Xpt] (should be ≥44pt x 44pt)

**Safe Area:**
- Top inset: [Xpt]
- Bottom inset: [Xpt]
- Status: [Respected/Ignored]

---

## Affected Areas

**Which UI elements are affected?**

- [ ] Phase labels
- [ ] Content boxes
- [ ] Detail buttons
- [ ] Menu button
- [ ] Navigation elements
- [ ] Text content
- [ ] Glow effects
- [ ] Other: _________________

**Which watch sizes are affected?**

- [ ] 41mm only (critical - smallest screen)
- [ ] 45mm only
- [ ] 49mm only
- [ ] Multiple sizes: _________________
- [ ] All sizes

---

## Code Locations

**Suspected files:**

- [ ] `ContentView.swift` - Lines: _______
- [ ] `LayerCardView.swift` - Lines: _______
- [ ] `PhaseView.swift` - Lines: _______
- [ ] Other: _________________

**Suspected causes:**

- [ ] Hardcoded dimensions not scaling
- [ ] Safe area not respected
- [ ] Font sizes not responsive
- [ ] Padding/spacing issues
- [ ] GeometryReader not used
- [ ] Other: _________________

---

## Related Issues

**GitHub Issues:**
- Related to: #119 (Responsive sizing)
- Related to: #______
- Blocks: #______
- Blocked by: #______

**Pull Requests:**
- Introduced in: PR #______
- Fixed in: PR #______ (if applicable)

---

## Workaround

**Is there a temporary workaround?**

[Describe any way to work around this issue, if one exists]

**Example:**
Test only on 45mm or 49mm simulators until this is fixed.

---

## Additional Context

**Design Requirements:**

[Any design specs or requirements this violates]

**User Impact:**

[How does this affect users? Can they still use the app?]

**Regression:**

- [ ] This worked correctly before
- [ ] This is a new feature/UI element
- [ ] Unknown

**If regression, what changed?**

[Describe what changed to cause this]

---

## Suggested Fix

**Proposed solution:**

[If you have ideas for how to fix this, describe them here]

**Example:**
1. Use GeometryReader to detect available screen height
2. Calculate scale factor: `screenHeight / referenceHeight`
3. Apply scale factor to content box heights, button sizes, and font sizes
4. Test on all three watch sizes to verify

**Files to modify:**

- [ ] `ContentView.swift`
- [ ] Other: _________________

---

## Reproduction Rate

**How often does this occur?**

- [ ] Always (100%)
- [ ] Frequently (>75%)
- [ ] Sometimes (25-75%)
- [ ] Rarely (<25%)
- [ ] Once

---

## Checklist

- [ ] Bug reproduced at least twice
- [ ] Screenshots captured
- [ ] Video recorded (if needed)
- [ ] All relevant information filled out
- [ ] GitHub issue created: #______
- [ ] Related issues linked
- [ ] Developer notified

---

## Notes

[Any additional notes, observations, or context]
