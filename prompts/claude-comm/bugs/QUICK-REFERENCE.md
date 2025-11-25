# Bug Testing Quick Reference Card

**Quick lookup for template selection and severity/priority guidelines**

---

## Template Selection

| **You see...** | **Use template...** |
|----------------|---------------------|
| Content clipped, cut off | `bug-template-layout.md` |
| Font sizes inconsistent | `bug-template-layout.md` |
| Elements not visible on 41mm | `bug-template-layout.md` |
| Scrolling broken | `bug-template-navigation.md` |
| Wrong view appears | `bug-template-navigation.md` |
| Back button missing/broken | `bug-template-navigation.md` |
| Feature doesn't work | `bug-template-functional.md` |
| Button does nothing | `bug-template-functional.md` |
| App crashes | `bug-template-functional.md` |
| Data won't load | `bug-template-data.md` |
| Wrong data shown | `bug-template-data.md` |
| Sync fails | `bug-template-data.md` |
| UI lags/stutters | `bug-template-performance.md` |
| App freezes | `bug-template-performance.md` |
| Slow transitions | `bug-template-performance.md` |
| Position resets | `bug-template-state.md` |
| Settings don't persist | `bug-template-state.md` |
| UI out of sync | `bug-template-state.md` |
| Wrong color/font | `bug-template-ui.md` |
| Misalignment | `bug-template-ui.md` |
| Visual inconsistency | `bug-template-ui.md` |

---

## Severity Decision Tree

```
Does it crash the app or lose data?
├─ YES → 🔴 Critical
└─ NO ↓

Does it break a core feature completely?
├─ YES → 🟠 High
└─ NO ↓

Does it affect UX significantly?
├─ YES → 🟡 Medium
└─ NO ↓

Is it a minor visual/polish issue?
└─ YES → 🟢 Low
```

---

## Priority Decision Tree

```
Does it block shipping/release?
├─ YES → P0 (Fix immediately)
└─ NO ↓

Is it high/critical severity?
├─ YES → P1 (Fix before next release)
└─ NO ↓

Is it medium severity or important?
├─ YES → P2 (Fix in upcoming release)
└─ NO ↓

Is it low severity or nice-to-have?
└─ YES → P3 (Fix when time permits)
```

---

## Watch Size Testing Priority

**Always test in this order:**

1. **41mm** (smallest) ← Most likely to show clipping
2. **45mm** (medium) ← Most common size
3. **49mm** (largest) ← Check for wasted space

---

## Common Bug Patterns

| **Pattern** | **Likely Template** | **Common Cause** |
|-------------|-------------------|------------------|
| Works on 45mm, broken on 41mm | Layout | Hardcoded sizes |
| Works first time, broken after | State | State not persisting |
| Works offline, broken online | Data | Network error handling |
| Slow after many actions | Performance | Memory leak |
| Different labels, different sizes | Layout/UI | Non-responsive styling |
| Button visible in detail view | Functional | Environment key issue |

---

## Reproduction Rate Translation

| **How Often** | **Rate** | **Note** |
|---------------|----------|----------|
| Every single time | Always (100%) | Easy to debug |
| Most of the time | Frequently (>75%) | Check timing |
| About half the time | Sometimes (25-75%) | Race condition? |
| Once in a while | Rarely (<25%) | Hard to debug |
| Just saw it once | Once | Try to reproduce! |

---

## Screenshot Checklist

For every bug, capture:

- [ ] Screenshot showing the problem
- [ ] Screenshot with annotations (red circles/arrows)
- [ ] Screenshot of correct behavior (if available)
- [ ] Screen recording (if behavior is dynamic)
- [ ] Console logs (if app crashed/errored)

---

## Bug Report Filename Format

`YYYY-MM-DD-category-brief-description.md`

**Examples:**
- `2025-11-24-layout-bottom-clipped.md`
- `2025-11-24-navigation-phase-wrap.md`
- `2025-11-24-functional-menu-crash.md`

---

## Essential Information (Don't Skip!)

Every report MUST have:

1. ✅ Reproduction steps (detailed!)
2. ✅ Expected vs actual behavior
3. ✅ Screenshot or video
4. ✅ Watch size tested
5. ✅ Severity and priority
6. ✅ Reproduction rate

---

## Testing Flow

```
1. START → Follow test plan
            ↓
2. FOUND BUG → Try to reproduce (2-3x)
            ↓
3. CAN REPRODUCE?
   ├─ YES → Choose template → Fill report → Continue
   └─ NO → Note it → Continue
            ↓
4. END → Review all reports → Create GitHub issues
```

---

## Time-Saving Tips

**Template reuse:**
- Copy previous report with similar issue
- Update relevant sections
- Faster than starting from scratch

**Batch testing:**
- Test all watch sizes for one feature at once
- Capture all screenshots together
- Write reports in batch

**Mark your place:**
- Use checkboxes in test plan
- Note where you stopped
- Easy to resume testing

---

## GitHub Issue Speed Template

```markdown
# [Title]

**Severity:** [🔴/🟠/🟡/🟢] **Priority:** [P0/P1/P2/P3]

## Reproduce
1. [Step]
2. [Step]
3. [Issue appears]

## Expected
[What should happen]

## Actual
[What does happen]

## Evidence
[Screenshot/video]

**Watch:** [41mm/45mm/49mm]
**Full report:** `prompts/claude-comm/bugs/reports/[filename].md`
```

---

## Need Help?

**Can't decide on template?** → Start with `bug-template-functional.md`

**Can't decide severity?** → Ask: "Can I still use the app?"
- No → High/Critical
- Yes but annoying → Medium
- Yes barely notice → Low

**Can't reproduce?** → Note it in test plan, continue testing

**Too many bugs?** → Batch related bugs into one issue

---

**Keep this card handy while testing!** 📋
