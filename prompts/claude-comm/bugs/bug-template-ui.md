# Bug Report: [Brief Title - UI Issue]

**Date:** YYYY-MM-DD
**Reporter:** [Your Name]
**Category:** UI / Visual / Styling
**Status:** 🔴 New

---

## Bug Summary

[One sentence description of the UI issue]

---

## Severity & Priority

**Severity:** [Choose one]
- 🔴 Critical - UI unusable, content inaccessible
- 🟠 High - Significant visual issue affects UX
- 🟡 Medium - Cosmetic issue, minor visual problem
- 🟢 Low - Polish item, very minor visual inconsistency

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

**Software:**
- watchOS Version: [e.g., 10.0]
- Xcode Version: [e.g., 16.4]
- Build/Commit: [SHA or branch name]

**Appearance:**
- [ ] Light mode
- [ ] Dark mode
- [ ] Both

---

## UI Element Affected

**Which UI element has the issue?**

- [ ] Button
- [ ] Label/Text
- [ ] Icon
- [ ] Color/Background
- [ ] Border/Shadow
- [ ] Spacing/Padding
- [ ] Font/Typography
- [ ] Animation
- [ ] Alignment
- [ ] Image
- [ ] Other: _________________

---

## Steps to Reproduce

1. [First step]
2. [Second step]
3. [Continue until UI issue is visible]

**Example:**
1. Launch app
2. Navigate to Purple layer
3. Observe the phase label "BOTTOMING OUT"
4. Compare with "RISING" phase label

---

## Expected Appearance

[Describe how the UI should look]

**Example:**
All phase labels should use the same font size and container width. The "BOTTOMING OUT" label should be the same size as "RISING", with consistent styling.

**Design Specs (if available):**
- Font size: [pt]
- Font weight: [Regular/Medium/Bold]
- Color: [Hex or name]
- Padding: [pt]
- Corner radius: [pt]
- Shadow/Glow: [specs]

---

## Actual Appearance

[Describe how the UI actually looks]

**Example:**
The "BOTTOMING OUT" label uses a smaller font size (12pt) compared to "RISING" (18pt). The container width is also wider (80pt vs 60pt). This creates visual inconsistency.

**Measurements:**
- Font size: [pt] (expected: [pt])
- Color: [Hex] (expected: [Hex])
- Spacing: [pt] (expected: [pt])
- Other: _________________

---

## Visual Evidence

### Screenshots

**Location:** `prompts/claude-comm/bugs/screenshots/[issue-name]/`

- [ ] Screenshot showing the UI issue
- [ ] Screenshot with annotations (red circles/arrows)
- [ ] Screenshot of correct appearance (for comparison)
- [ ] Screenshots from different watch sizes

### Mockup/Expected Design

- [ ] Design mockup: `[filename].png`
- [ ] Figma link: [URL]

### Video

- [ ] Screen recording showing UI issue: `[filename].mov`
- [ ] Duration: [X seconds]

---

## Visual Comparison

**Side-by-side comparison:**

| Watch Size | Element | Current | Expected | Difference |
|------------|---------|---------|----------|------------|
| 41mm | Font size | 12pt | 14pt | -2pt |
| 45mm | Font size | 14pt | 14pt | ✅ |
| 49mm | Font size | 16pt | 14pt | +2pt |

---

## Styling Details

**Colors:**
- Current: [Hex or SwiftUI Color]
- Expected: [Hex or SwiftUI Color]

**Fonts:**
- Current: [Font family, size, weight]
- Expected: [Font family, size, weight]

**Spacing:**
- Current padding: [top, leading, bottom, trailing]
- Expected padding: [top, leading, bottom, trailing]

**Other Styling:**
- Border: [width, color, radius]
- Shadow: [radius, offset, color]
- Opacity: [value]
- Other: _________________

---

## Responsive Behavior

**Does issue vary by watch size?**

- [ ] Yes - Different on each size
- [ ] Yes - Only on specific size: _______
- [ ] No - Same on all sizes

**Does issue vary by content?**

- [ ] Yes - Only with long text
- [ ] Yes - Only with specific data
- [ ] No - Always present

---

## Accessibility

**Does this affect accessibility?**

- [ ] Yes - Text not readable
- [ ] Yes - Color contrast insufficient
- [ ] Yes - Touch target too small (<44pt)
- [ ] Yes - VoiceOver label incorrect
- [ ] No - Cosmetic only

**If yes, describe:**

[How does this affect accessibility?]

---

## Code Locations

**Suspected files:**

- [ ] View file: _____________ - Lines: _______
- [ ] Style/modifier: _____________ - Lines: _______
- [ ] Constants: _____________ - Lines: _______

**Current styling code:**

```swift
// Paste relevant SwiftUI view code
Text(phaseName)
  .font(.system(size: 18))  // ❌ Should be dynamic
  .foregroundColor(.white)
  .padding(.horizontal, 12)
```

**Suspected causes:**

- [ ] Hardcoded values not scaling
- [ ] Missing responsive styling
- [ ] Inconsistent styling across views
- [ ] Wrong color used
- [ ] Wrong font/size used
- [ ] Missing design system values
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

## Design System

**Does app have a design system?**

- [ ] Yes - Located: _______
- [ ] Partial - Some constants defined
- [ ] No - Inline styles everywhere

**If yes, is this following the design system?**

- [ ] Yes - Design system is wrong
- [ ] No - Implementation doesn't follow design system
- [ ] Unknown

---

## User Impact

**How does this affect users?**

[Describe the UX impact]

**Is content still accessible?**

- [ ] Yes - Fully accessible (cosmetic issue)
- [ ] Partially - Some content hard to read/access
- [ ] No - Content inaccessible

---

## Regression

- [ ] This looked correct before
- [ ] This is a new UI element
- [ ] Unknown

**If regression, when did it change?**

- Commit/PR: [SHA or PR number]
- What changed: [Brief description]

---

## Suggested Fix

**Proposed solution:**

[If you have ideas for how to fix this, describe them here]

**Example:**
1. Create a `PhaseLabel` component with consistent styling
2. Use GeometryReader to calculate max width needed for longest label
3. Apply that width to all phase labels
4. Use dynamic font size based on container width
5. Add constants to design system file

**SwiftUI code suggestion:**

```swift
struct PhaseLabel: View {
  let text: String
  let maxWidth: CGFloat

  var body: some View {
    Text(text)
      .font(.system(size: fontSize(for: text, maxWidth: maxWidth)))
      .frame(width: maxWidth)
      .padding(.horizontal, 12)
      .background(
        RoundedRectangle(cornerRadius: 20)
          .fill(Color.white.opacity(0.2))
      )
  }

  func fontSize(for text: String, maxWidth: CGFloat) -> CGFloat {
    // Calculate appropriate font size
  }
}
```

**Files to modify:**

- [ ] File: _____________ - Change: _____________
- [ ] File: _____________ - Change: _____________

---

## Workaround

**Is there a workaround?**

[Describe any temporary workaround]

**Example:**
Test only on 45mm simulator where the font size happens to be correct.

---

## Reproduction Rate

**How often is this visible?**

- [ ] Always (100%)
- [ ] Only on specific watch sizes
- [ ] Only with specific content/data
- [ ] Intermittently

---

## Checklist

- [ ] Bug reproduced at least twice
- [ ] Screenshots captured
- [ ] Measurements documented
- [ ] Tested on multiple watch sizes
- [ ] Tested in dark/light mode (if applicable)
- [ ] All relevant information filled out
- [ ] GitHub issue created: #______
- [ ] Related issues linked

---

## Notes

[Any additional notes, observations, or context about the UI issue]
