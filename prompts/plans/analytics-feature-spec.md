# Analytics Feature Specification
**Version**: 1.0
**Date**: 2026-01-05
**Status**: Planning
**Platform**: watchOS (on-device analytics)

---

## Executive Summary

The Analytics feature provides users with meaningful insights into their emotional patterns, self-care practices, and developmental trajectory based on their journal entries. Designed for watchOS constraints (small screen, limited interaction), the feature prioritizes **glanceable insights** with optional drill-down for deeper exploration.

### Design Philosophy
- **Insight-First**: Show what matters, not just data dumps
- **Actionable**: Help users understand patterns and make adjustments
- **Respectful**: Quick loading, minimal scrolling, clear hierarchy
- **Progressive**: Summary → Detail → Deep Dive structure
- **Privacy-First**: All analytics computed on-device when possible

---

## Data Foundation

### Available Data (from Journal Model)
```swift
struct JournalEntry {
    created_at: DateTime          // When logged
    user_id: Int                  // User identifier
    curriculum_id: Int            // Primary emotion (required)
    secondary_curriculum_id: Int? // Secondary emotion (optional)
    strategy_id: Int?             // Self-care strategy (optional)
    initiated_by: InitiatedBy     // "self" or "scheduled"
}
```

### Enriched Data (via relationships)
- **Primary Emotion**: layer, phase, dosage (Medicinal/Toxic), expression
- **Secondary Emotion**: same attributes as primary
- **Strategy**: strategy text, layer, color_layer, phase

### Reference Data
- **Layers (11)**: Strategies, Beige, Purple, Red, Blue, Orange, Green, Yellow, Teal, Ultraviolet, Clear Light
- **Phases (6)**: Rising, Peaking, Withdrawal, Diminishing, Bottoming Out, Restoration
- **Dosages (2)**: Medicinal, Toxic

---

## Analytics Sections

### 1. Overview (Summary Dashboard)

**Purpose**: Immediate, glanceable insights about overall patterns
**Screen**: Single scrollable view with key metrics

#### Metrics Displayed

**A. Check-In Activity**
- **Total Entries**: "42 check-ins" (all time or filtered period)
- **Current Streak**: "5 days in a row" (consecutive days with at least 1 entry)
- **Avg Frequency**: "2.3 per day" (entries per day over selected period)
- **Last Check-In**: "2 hours ago" (relative time)

**B. Emotional Health Score**
- **Medicinal Ratio**: "73% Medicinal" (medicinal entries / total entries)
  - Visual: Circular progress indicator with color (green >70%, yellow 50-70%, orange <50%)
  - Trend indicator: ↑ "Up 5% this week" or ↓ "Down 3% this week"

**C. Current State Snapshot**
- **Dominant Mode (Last 7 Days)**: "Green (Collaborate/Feel)" with color swatch
- **Dominant Phase (Last 7 Days)**: "Peaking" with phase icon
- **Dosage Split**: Bar chart showing Medicinal vs Toxic for last 7/30 days

**D. Quick Stats**
- **Unique Emotions Logged**: "18 different emotions" (distinct curriculum entries)
- **Strategies Used**: "12 strategies practiced" (distinct strategies)
- **Secondary Emotions**: "65% with secondary" (entries with secondary_curriculum_id)

#### Visual Design
```
┌─────────────────────────────┐
│  ANALYTICS                  │
│  ────────────────           │
│                             │
│  📊 42 Check-Ins           │
│  🔥 5 Day Streak           │
│  ⏱️  2 hours ago           │
│                             │
│  ┌───────────────────────┐ │
│  │  Emotional Health     │ │
│  │     ⬤ 73%            │ │  <- Circular progress
│  │   Medicinal           │ │
│  │   ↑ Up 5% this week   │ │
│  └───────────────────────┘ │
│                             │
│  Current State (7 days)     │
│  🟢 Green (Collaborate)    │
│  ⬆️ Peaking                │
│                             │
│  [View Detailed Insights] → │
└─────────────────────────────┘
```

---

### 2. Emotional Landscape

**Purpose**: Understand which emotions and layers are most active
**Navigation**: Tap "View Detailed Insights" → Select "Emotional Landscape"

#### Sub-Sections

**A. Layer Distribution**
- **Visual**: Horizontal bar chart showing % of entries per layer (known in UX as a Mode)
- **Data**: Percentage of entries for each layer (excluding Strategies layer 0) with layers listed in order (not sorted by histogram)
- **Filters**: Last 7 days / 30 days / All time
- **Interaction**: Tap layer to see emotions logged in that layer

Example:
```
Mode Distribution (Last 30 days)
────────────────────────────────
...
Green   ████████████ 24%
Orange  █████████ 18%
Blue    ██████ 12%
Red     █████ 10%
...
```

**B. Phase Journey**
- **Visual**: Timeline showing phase distribution over time
- **Data**: Percentage of entries per phase
- **Insight**: "You spend most time Peaking (32%) and Rising (28%)"
- **Actionable**: "Consider strategies for smoother transitions from Peaking to Withdrawal"

**C. Emotion Frequency**
- **Top 5 Most Logged Emotions** (primary + secondary combined)
  - Show: Expression, Layer color swatch, Dosage, Count
  - Example: "Diligence (Beige/Medicinal) - 12 times"
- **Recently Logged**: Last 5 unique emotions (deduplicated)
- **Emerging Emotions**: Emotions logged in last 7 days but not in previous 30 days

**D. Dosage Deep Dive**
- **Medicinal vs Toxic Over Time**: Line chart (7-day moving average)
- **Toxic Patterns**:
  - Most common toxic emotions
  - Time of day when toxic emotions peak
  - Correlation with specific phases (e.g., "Toxic emotions 2x more common during Bottoming Out")
- **Medicinal Patterns**:
  - Growth trend: "Medicinal entries increased 15% over last 30 days"
  - Layer diversity: "Medicinal emotions from 7 different layers"

---

### 3. Self-Care Insights

**Purpose**: Understand strategy usage and effectiveness
**Navigation**: "Emotional Landscape" → "Self-Care Insights"

#### Sub-Sections

**A. Strategy Usage**
- **Top 5 Most Used Strategies**: Count + percentage
  - Example: "Breathwork - 15 times (23%)"
- **Strategy Diversity Score**: Unique strategies / total strategy entries
  - Example: "12 unique strategies out of 18 entries = 67% diversity"
  - Insight: "Good variety - you adapt strategies to your needs"
- **Recent Strategies**: Last 5 strategies used (deduplicated)

---

### 4. Temporal Patterns

**Purpose**: Understand when you log emotions and identify time-based patterns
**Navigation**: "Emotional Landscape" → "Temporal Patterns"

#### Sub-Sections

**A. Time of Day Analysis**
- **Hourly Distribution**: Bar chart showing entries by hour
  - Example: "Most check-ins at 8am (12 entries) and 9pm (10 entries)"
- **Emotional Tone by Time**:
  - Morning (5am-11am): "68% Medicinal"
  - Afternoon (12pm-5pm): "55% Medicinal"
  - Evening (6pm-11pm): "72% Medicinal"
  - Night (12am-4am): "45% Medicinal" (if any entries)
- **Insight**: "Your mornings are most balanced - evenings show stronger medicinal trend"

**B. Streak & Consistency**
- **Current Streak**: Consecutive days with at least 1 entry
- **Longest Streak**: Historical best
- **Consistency Score**: Days with entries / total days (last 30 days)
  - Example: "25 of 30 days (83% consistency)"
- **Gap Analysis**: Longest gap between entries
  - Example: "Longest break: 4 days (Dec 15-18)"

**C. Initiated By Analysis** (if scheduled notifications used)
- **Self vs Scheduled**: Percentage breakdown
  - Example: "78% Self-initiated | 22% Scheduled"
- **Scheduled Effectiveness**: Of scheduled notifications, how many result in entries?
  - (Requires notification tracking - future enhancement)

---

### 5. Growth Indicators

**Purpose**: Long-term trends showing personal development trajectory
**Navigation**: "Emotional Landscape" → "Growth Indicators"

#### Sub-Sections

**A. Medicinal Trend**
- **30-Day Moving Average**: Line chart of medicinal ratio over time
- **All-Time Trajectory**: Is medicinal ratio increasing, stable, or decreasing?
  - Example: "↑ +12% over last 90 days"
- **Milestone**: "You crossed 75% medicinal for the first time on Jan 1st!"

**B. Layer Ascension**
- **Spiral Dynamics Progression**: Track movement toward "higher" layers
  - Assumption: Clear Light > Ultraviolet > Teal > Yellow > Green > Orange > Blue > Red > Purple > Beige
  - Show: "Your center of gravity shifted from Blue to Green over last 60 days"
- **Integration Depth**: Are you accessing emotions from multiple layers simultaneously?
  - Example: "You logged emotions from 8 different layers in last 30 days"

**C. Phase Mastery**
- **Phase Comfort Zones**: Which phases you log most vs least
  - Example: "Comfortable with: Peaking, Rising | Underexplored: Bottoming Out"
- **Balanced Wavelength**: Are you experiencing all 6 phases?
  - Goal: Healthy emotional range includes all phases
  - Example: "You've experienced 5 of 6 phases in last 30 days (missing: Restoration)"

---

## User Interface Design

### Interaction Patterns

**1. Time Period Filters** (Available on most screens)
- Segmented control: `7 Days | 30 Days | All Time`
- Persists per section (remembered in UserDefaults)
- Default: 30 Days

**2. Drill-Down Pattern**
- Tap chart/stat → See detail view
- Example: Tap "Green 24%" → See all Green emotions logged
- Example: Tap "Breathwork 15 times" → See journal entries where Breathwork was used

**3. Export Capability** (Future)
- "Share Insights" button on Overview
- Generates summary text or image for sharing/saving

### Visual Components

**Charts to Implement:**
1. **Circular Progress Indicator**: For percentages (Medicinal ratio, consistency score)
2. **Horizontal Bar Chart**: For layer/phase distribution
3. **Line Chart**: For trends over time (medicinal ratio, phase cycles)
4. **Heatmap**: For strategy-phase alignment, phase transitions
5. **Timeline View**: For wavelength cycles visualization

**Color Coding:**
- **Layers**: Use existing color scheme (Beige, Purple, Red, etc.)
- **Dosage**: Green (Medicinal), Red (Toxic)
- **Trends**: Green (↑), Red (↓), Gray (→)
- **Background**: Consistent with app (black gradients)

### Accessibility

- **VoiceOver**: All charts have descriptive labels
  - Example: "Medicinal ratio: 73%, up 5% from last week"
- **Dynamic Type**: Support larger text sizes
- **Haptic Feedback**: On significant milestones or insights
- **Reduced Motion**: Static alternatives to animated charts

---

## Implementation Plan

### Phase 1: Foundation & Overview (MVP)
**Goal**: Ship basic analytics that provide immediate value
**Timeline**: 2-3 weeks

#### Backend Changes
1. **New Endpoint: `/api/v1/analytics/overview`**
   - **Input**: `user_id`, `start_date`, `end_date`
   - **Output**: JSON with summary stats
   - **Computation**:
     - Total entries, streak calculation
     - Medicinal ratio (current + trend)
     - Dominant layer/phase
     - Strategy count
   - **Caching**: Consider caching for common queries (last 7/30 days)

2. **Database Indexes** (if not exist)
   - `CREATE INDEX idx_journal_user_created ON journal(user_id, created_at DESC);`
   - `CREATE INDEX idx_journal_curriculum ON journal(curriculum_id);`
   - `CREATE INDEX idx_journal_strategy ON journal(strategy_id);`

#### Frontend Changes
1. **New SwiftUI Views**
   - `AnalyticsViewModel`: Fetches data from backend, computes additional metrics
   - `AnalyticsOverviewView`: Replaces current placeholder
   - `MedicinalHealthCard`: Circular progress indicator component
   - `QuickStatsRow`: Reusable stat display component

2. **Networking**
   - Add `getAnalyticsOverview(startDate:endDate:)` to `APIClient`
   - Handle loading states, errors, empty states

3. **State Management**
   - Cache analytics data in memory (refresh on pull-to-refresh)
   - Persist time period selection in `UserDefaults`

4. **UI Components**
   - Circular progress view (SwiftUI shape + animation)
   - Trend indicator (↑↓→ with color)
   - Streak display with 🔥 icon

#### Testing
- **Backend**:
  - Unit tests for analytics calculations
  - Test edge cases (no entries, single entry, gaps in data)
- **Frontend**:
  - UI tests for AnalyticsOverviewView rendering
  - Test empty state (no journal entries yet)
  - Test loading state
  - Test error state (backend unavailable)

#### Success Metrics
- Users can see their medicinal ratio and streak on first launch
- Analytics load in <2 seconds on typical network
- No crashes when viewing analytics with empty journal

---

### Phase 2: Emotional Landscape
**Goal**: Deep insights into layer, phase, and emotion patterns
**Timeline**: 2-3 weeks

#### Backend Changes
1. **New Endpoint: `/api/v1/analytics/emotional-landscape`**
   - Layer distribution (count per layer, percentage)
   - Phase distribution (count per phase, percentage)
   - Top emotions (primary + secondary, ranked by frequency)
   - Dosage over time (daily medicinal ratio for charting)

2. **Optimization**
   - Use SQL aggregation for efficient computation
   - Example: `SELECT layer_id, COUNT(*) FROM journal JOIN curriculum WHERE ... GROUP BY layer_id`

#### Frontend Changes
1. **New Views**
   - `EmotionalLandscapeView`: Main navigation hub
   - `LayerDistributionView`: Horizontal bar chart
   - `PhaseJourneyView`: Phase distribution + insights
   - `EmotionFrequencyView`: Top emotions list
   - `DosageDeepDiveView`: Line chart + toxic/medicinal breakdowns

2. **Chart Components**
   - `HorizontalBarChart`: Reusable for layer/phase distribution
   - `LineChart`: For dosage trend over time
   - `EmotionRow`: Displays emotion with layer color, dosage badge, count

3. **Drill-Down**
   - Tap layer bar → See list of journal entries for that layer
   - Tap emotion → See journal entries where that emotion was logged

#### Testing
- Chart rendering accuracy (correct percentages, colors)
- Drill-down navigation works correctly
- Handles edge cases (all entries in 1 layer, etc.)

---

### Phase 3: Wavelength Patterns & Self-Care
**Goal**: Cycle detection, strategy insights
**Timeline**: 3-4 weeks (more complex algorithms)

#### Backend Changes
1. **New Endpoint: `/api/v1/analytics/wavelength`**
   - Phase trajectory detection (sequence analysis)
   - Layer evolution (30-day trends per layer)
   - Cycle detection (full 6-phase sequences)
   - Integration score calculation

2. **New Endpoint: `/api/v1/analytics/self-care`**
   - Strategy frequency and diversity
   - Strategy-phase alignment (heatmap data)
   - Correlational analysis (strategy → medicinal ratio)

3. **Algorithms**
   - **Cycle Detection**: Sliding window to find Rising→Peaking→...→Restoration sequences
   - **Trajectory Prediction**: Use last N entries to predict likely next phase
   - **Correlation**: Compare medicinal ratio with/without specific strategies

#### Frontend Changes
1. **New Views**
   - `WavelengthPatternsView`: Phase trajectory, cycles, layer evolution
   - `SelfCareInsightsView`: Strategy usage, effectiveness, recommendations
   - `PhaseTrajectoryCard`: Visual showing current trajectory
   - `StrategyEffectivenessRow`: Strategy + correlation stat

2. **Advanced Components**
   - `Heatmap`: For strategy-phase alignment
   - `CycleTimelineView`: Visual representation of wavelength cycles
   - `TrendIndicator`: Reusable ↑↓→ component with percentage change

#### Testing
- Cycle detection accuracy (test with known sequences)
- Correlation calculations (verify math)
- Edge cases (no strategies, single phase, etc.)

---

### Phase 4: Temporal Patterns & Growth
**Goal**: Time-based insights and long-term trends
**Timeline**: 2 weeks

#### Backend Changes
1. **New Endpoint: `/api/v1/analytics/temporal`**
   - Hourly distribution (count per hour)
   - Day of week distribution
   - Streak calculation (current, longest, consistency score)
   - Initiated-by breakdown

2. **New Endpoint: `/api/v1/analytics/growth`**
   - Medicinal trend (30-day moving average)
   - Layer ascension metrics
   - Complexity metrics (secondary usage, strategy adoption)
   - Phase balance (coverage across all 6 phases)

#### Frontend Changes
1. **New Views**
   - `TemporalPatternsView`: Time of day, day of week, streaks
   - `GrowthIndicatorsView`: Long-term trends and milestones
   - `HourlyDistributionChart`: Bar chart by hour
   - `WeeklyDistributionChart`: Bar chart by day of week
   - `GrowthTrendChart`: Line chart showing medicinal ratio over time

2. **Milestone Celebrations**
   - Detect milestones (first 75% medicinal day, 30-day streak)
   - Show confetti animation or special badge

#### Testing
- Time zone handling (ensure created_at is correctly parsed)
- Streak calculation accuracy (test edge cases: gaps, time zones)
- Moving average calculation (verify math)

---

### Phase 5: Polish & Optimization
**Goal**: Performance, caching, UX refinement
**Timeline**: 1-2 weeks

#### Performance Optimization
1. **Backend Caching**
   - Cache analytics for common queries (last 7/30 days)
   - Invalidate cache on new journal entry
   - Use Redis or in-memory cache

2. **Frontend Optimization**
   - Lazy load chart components
   - Paginate long lists (e.g., all journal entries for a layer)
   - Debounce time period filter changes

3. **Precomputation**
   - Consider background job to precompute analytics daily
   - Store results in separate `analytics_cache` table

#### UX Refinement
1. **Empty States**
   - "Not enough data yet" when <5 journal entries
   - Suggestions: "Log 5 more emotions to unlock insights"

2. **Loading States**
   - Skeleton screens for charts
   - Progressive loading (show cached data while fetching new)

3. **Error Handling**
   - Graceful degradation if backend unavailable
   - Retry mechanism for failed requests

4. **Animations**
   - Smooth chart entrance animations
   - Trend indicator transitions
   - Pull-to-refresh with haptic feedback

#### Testing
- Load testing (100+ journal entries, 1000+ entries)
- Network interruption handling
- Memory profiling (ensure no leaks)

---

## Data Privacy & Ethics

### Privacy Considerations
1. **On-Device First**: Compute simple metrics on-device when possible
2. **Minimal Data Transfer**: Only send user_id + date range, receive aggregated results
3. **No Third-Party Analytics**: All analytics stay within the app ecosystem
4. **User Control**: Future: Allow users to export or delete analytics data

### Ethical Considerations
1. **Non-Judgmental Language**: Avoid "good" vs "bad" framing
   - ✅ "Medicinal ratio: 73%"
   - ❌ "You're doing great!"
2. **Balanced Insights**: Don't over-emphasize toxic emotions negatively
   - Frame as "part of the human experience" not "failure"
3. **Growth Mindset**: Focus on trends and patterns, not absolute scores
4. **No Gamification**: Avoid unhealthy competition with self (e.g., no "beat your record" language)
5. **Respect Complexity**: Acknowledge that lower medicinal ratio might indicate necessary processing work

---

## Future Enhancements (Post-Launch)

### 1. Export & Sharing
- Export analytics summary as PDF or image
- Share specific insights to journal or notes app

### 2. Comparative Analytics (Web)
- Anonymous aggregate data (opt-in)
- "Users with similar patterns often find X helpful"

### 3. Predictive Insights
- "Based on your patterns, you typically enter Bottoming Out on Wednesdays"
- "You might benefit from a strategy check-in at 3pm"

### 4. Journal Entry Deep Links
- Tap any stat → See specific journal entries that contributed
- "12 times" → List of those 12 entries with timestamps

### 5. Custom Time Ranges
- Beyond 7/30/All, allow "Last 90 days", "This month", "Last year"

### 6. Annotations
- Allow users to add notes to timeline ("Started new job on Jan 1")
- Correlate life events with emotional patterns

### 7. Integration Scores by Layer Pair
- Show which layer combinations appear together most (e.g., Green primary + Blue secondary)

### 8. Strategy Recommendations Engine
- ML-based: "Users with similar patterns found 'Breathwork' helpful during Bottoming Out"

---

## Success Metrics (Post-Launch)

### User Engagement
- % of users who visit Analytics at least once per week
- Average time spent in Analytics section
- Most viewed analytics screen (Overview, Emotional Landscape, etc.)

### Retention Impact
- Do users with analytics access have higher retention?
- Correlation between analytics usage and journal frequency

### Feature Discovery
- % of users who drill down into detailed views
- % of users who change time period filters

### User Feedback
- Qualitative: Survey users on most/least valuable insights
- Track: Which insights lead to behavior change (more strategies, balanced phases, etc.)

---

## Technical Architecture

### Backend
```
/api/v1/analytics/
  ├─ overview              GET (user_id, start_date, end_date)
  ├─ emotional-landscape   GET (user_id, start_date, end_date)
  ├─ wavelength            GET (user_id, start_date, end_date)
  ├─ self-care             GET (user_id, start_date, end_date)
  ├─ temporal              GET (user_id, start_date, end_date)
  └─ growth                GET (user_id, start_date, end_date)
```

### Frontend (watchOS)
```
Services/
  └─ AnalyticsService.swift         // API client for analytics endpoints

ViewModels/
  ├─ AnalyticsViewModel.swift       // Main analytics state management
  ├─ EmotionalLandscapeViewModel.swift
  ├─ WavelengthPatternsViewModel.swift
  ├─ SelfCareInsightsViewModel.swift
  ├─ TemporalPatternsViewModel.swift
  └─ GrowthIndicatorsViewModel.swift

Views/Analytics/
  ├─ AnalyticsOverviewView.swift
  ├─ EmotionalLandscape/
  │   ├─ EmotionalLandscapeView.swift
  │   ├─ LayerDistributionView.swift
  │   ├─ PhaseJourneyView.swift
  │   └─ DosageDeepDiveView.swift
  ├─ WavelengthPatterns/
  │   ├─ WavelengthPatternsView.swift
  │   └─ ...
  ├─ SelfCareInsights/
  │   └─ ...
  ├─ TemporalPatterns/
  │   └─ ...
  ├─ GrowthIndicators/
  │   └─ ...
  └─ Components/
      ├─ CircularProgressView.swift
      ├─ HorizontalBarChart.swift
      ├─ LineChart.swift
      ├─ Heatmap.swift
      ├─ TrendIndicator.swift
      └─ EmotionRow.swift

Models/Analytics/
  ├─ AnalyticsOverview.swift        // Response models
  ├─ EmotionalLandscape.swift
  ├─ WavelengthPatterns.swift
  └─ ...
```

### Database Schema (Optional Cache)
```sql
-- Optional: Precomputed analytics cache
CREATE TABLE analytics_cache (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    period VARCHAR(20) NOT NULL,  -- '7d', '30d', 'all'
    computed_at TIMESTAMP NOT NULL,
    data JSONB NOT NULL,          -- Cached analytics JSON
    UNIQUE(user_id, period)
);

CREATE INDEX idx_analytics_cache_user ON analytics_cache(user_id);
```

---

## Implementation Risks & Mitigations

### Risk 1: Performance with Large Datasets
- **Risk**: Slow analytics queries when user has 1000+ journal entries
- **Mitigation**:
  - Database indexes on user_id, created_at
  - Limit time ranges (max 1 year for "All Time")
  - Precompute common queries (7d, 30d) via background job

### Risk 2: Complex Calculations on watchOS
- **Risk**: Battery drain from heavy computation on-device
- **Mitigation**:
  - Perform all aggregations on backend
  - Watch only renders pre-computed results
  - Cache results locally to avoid repeated network calls

### Risk 3: Empty States (New Users)
- **Risk**: Analytics look sparse or meaningless with <10 entries
- **Mitigation**:
  - Show helpful empty states ("Log 5 more emotions to unlock insights")
  - Hide certain sections until minimum data threshold met
  - Provide sample data explanation ("Here's what you'll see...")

### Risk 4: Privacy Concerns
- **Risk**: Users uncomfortable with data aggregation
- **Mitigation**:
  - Clear privacy policy (all analytics on-device or user-specific backend)
  - No cross-user comparisons or data sharing (in initial version)
  - Allow users to clear analytics cache

### Risk 5: Misleading Insights
- **Risk**: Correlation ≠ causation, users misinterpret patterns
- **Mitigation**:
  - Use careful language ("correlates with" not "causes")
  - Educational tooltips explaining metrics
  - Avoid overly definitive statements

---

## Open Questions (For Discussion)

1. **Normative Framing**: Should we suggest an "ideal" medicinal ratio (e.g., 70%+) or remain fully descriptive?

A: Remain descriptive

2. **Layer Hierarchy**: Do we assume Clear Light is "higher" than Beige, or treat all layers as equally valid?

A: All layers are equally valid. And they are called "Modes" in the UI, which should help clarify that they are not hierarchical.

3. **Cycle Definition**: Is Rising→Peaking→Withdrawal→Diminishing→Bottoming Out→Restoration the *only* valid cycle, or do we detect other patterns?

A: Let's not prioritize surfacing other patterns, but this will be an interesting avenue to pursue for internal data analysis once there are many users on the app.

4. **Strategy Effectiveness**: How do we avoid false positives (correlation vs causation)? Should we use 48-hour window after strategy to measure impact?

A: Let's not assume we can measure a strategy's effectiveness until such a time that we decide to do a follow-up ping 30 minutes later or something that says "Did it work?" I don't want to commit to doing that right now though.

5. **Privacy vs Usefulness**: Should we allow opt-in anonymous aggregate comparisons ("Your medicinal ratio is in the top 20% of users")?

A: Actually, external storage of data at all should be opt-in. This will require a massive refactor of its own, but we should have a feature flag that indicates that a user is willing to share their data with the backend system and expect to only populate a local SQLite db if not. The analytics should read from this local SQLite db, and so this change blocks the entire project. After that, the user can opt to log their emotions locally or on our backend servers, with the benefits being anonymous aggregate comparisons, and the potential promise of a more detailed website view if there is interest - it is not yet under construction.

6. **Data Retention**: How long should we keep journal entries for analytics? Forever, or time-boxed (e.g., 1 year)?

A: Let's assume forever unless we get a GDPR request or similar.

7. **Notifications**: Should analytics trigger notifications ("Your 7-day streak is at risk!" or "Congrats on 30 days!")? Or keep it passive?

A: No notifs

---

## Conclusion

The Analytics feature transforms raw journal data into **actionable insights** about emotional patterns, self-care effectiveness, and personal growth. By respecting watchOS constraints and user privacy, the feature provides **glanceable value** (Overview) with **optional depth** (detailed sections), empowering users to understand their Archetypal Wavelength journey.

**Next Steps:**
1. Review and refine this spec (especially Open Questions)
2. Prioritize sections (likely start with Phase 1: Overview)
3. Design mockups for key screens
4. Implement Phase 1 backend endpoints
5. Implement Phase 1 frontend views
6. User testing and iteration

---

**Document Version History:**
- v1.0 (2026-01-05): Initial specification
- v1.1 (2026-01-05): Geoff's edits (mostly deleting useless stats that were pitched and also answering open questions)
