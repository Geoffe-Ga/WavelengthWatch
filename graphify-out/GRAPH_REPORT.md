# Graph Report - .  (2026-07-17)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 3125 nodes · 8027 edges · 183 communities (123 shown, 60 thin omitted)
- Extraction: 78% EXTRACTED · 22% INFERRED · 0% AMBIGUOUS · INFERRED: 1789 edges (avg confidence: 0.78)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `a9b23bc4`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Community 0
- Community 1
- Community 2
- Community 3
- Community 4
- Community 5
- Community 6
- Community 7
- Community 8
- Community 9
- Community 10
- Community 11
- Community 12
- Community 13
- Community 14
- Community 15
- Community 16
- Community 17
- Community 18
- Community 19
- Community 20
- Community 21
- Community 22
- Community 23
- Community 24
- Community 25
- Community 26
- Community 27
- Community 28
- Community 29
- Community 30
- Community 31
- Community 32
- Community 33
- Community 34
- Community 35
- Community 36
- Community 37
- Community 38
- Community 39
- Community 40
- Community 41
- Community 42
- Community 43
- Community 44
- Community 45
- Community 46
- Community 47
- Community 48
- Community 49
- Community 50
- Community 51
- Community 52
- Community 53
- Community 54
- Community 55
- Community 56
- Community 57
- Community 58
- Community 59
- Community 60
- Community 61
- Community 62
- Community 63
- Community 64
- Community 65
- Community 66
- Community 67
- Community 68
- Community 69
- Community 70
- Community 71
- Community 72
- Community 73
- Community 74
- Community 75
- Community 76
- Community 77
- Community 78
- Community 79
- Community 80
- Community 81
- Community 82
- Community 83
- Community 84
- Community 85
- Community 86
- Community 87
- Community 88
- Community 89
- Community 90
- Community 91
- Community 92
- Community 93
- Community 94
- Community 95
- Community 96
- Community 97
- Community 98
- Community 99
- Community 100
- Community 101
- Community 102
- Community 103
- Community 104
- Community 105
- Community 106
- Community 107
- Community 108
- Community 109
- Community 110
- Community 111
- Community 112
- Community 113
- Community 114
- Community 115
- Community 116
- Community 117
- Community 118
- Community 119
- Community 120
- Community 121
- Community 122
- Community 123
- Community 124
- Community 125
- Community 126
- Community 127
- Community 128
- Community 129
- Community 130
- Community 131
- Community 132
- Community 133
- Community 134
- Community 135
- Community 136
- Community 137
- Community 138
- Community 139
- Community 140
- Community 141
- Community 142
- Community 143
- Community 144
- Community 145
- Community 146
- Community 147
- Community 148
- Community 149
- Community 150
- Community 151
- Community 152
- Community 153
- Community 154
- Community 155
- Community 156
- Community 157
- Community 158
- Community 159
- Community 160
- Community 161
- Community 162
- Community 163
- Community 164
- Community 165
- Community 166
- Community 167
- Community 168
- Community 169
- Community 170
- Community 171
- Community 172
- Community 173
- Community 174
- Community 175
- Community 176
- Community 177
- Community 178
- Community 179
- Community 181

## God Nodes (most connected - your core abstractions)
1. `LocalJournalEntry` - 217 edges
2. `SwiftUI` - 108 edges
3. `SyncSettings` - 102 edges
4. `ContentViewModel` - 100 edges
5. `Foundation` - 80 edges
6. `InMemoryJournalRepository` - 80 edges
7. `JournalQueue` - 79 edges
8. `Testing` - 75 edges
9. `WavelengthWatch_Watch_App` - 75 edges
10. `LocalAnalyticsCalculator` - 70 edges

## Surprising Connections (you probably didn't know these)
- `test_catalog_returns_empty_payload_when_database_cleared()` --indirect_call--> `Phase`  [INFERRED]
  tests/backend/test_catalog_api.py → backend/models.py
- `test_catalog_returns_empty_payload_when_database_cleared()` --indirect_call--> `Strategy`  [INFERRED]
  tests/backend/test_catalog_api.py → backend/models.py
- `test_leaves_explicit_driver_and_sqlite_urls_untouched()` --calls--> `_normalize_database_url()`  [EXTRACTED]
  tests/backend/test_database_url.py → backend/database.py
- `test_normalizes_bare_postgres_schemes_to_psycopg()` --calls--> `_normalize_database_url()`  [EXTRACTED]
  tests/backend/test_database_url.py → backend/database.py
- `test_preserves_credentials_when_swapping_scheme()` --calls--> `_normalize_database_url()`  [EXTRACTED]
  tests/backend/test_database_url.py → backend/database.py

## Import Cycles
- None detected.

## Communities (183 total, 60 thin omitted)

### Community 0 - "Community 0"
Cohesion: 0.05
Nodes (35): AnalyticsViewModel, LoadingState, error, idle, loaded, loading, LocalCalculationError, fetchFailed (+27 more)

### Community 1 - "Community 1"
Cohesion: 0.05
Nodes (40): DateComponents, Encoder, JournalSchedule, Bool, Decoder, Int, Set, UUID (+32 more)

### Community 2 - "Community 2"
Cohesion: 0.07
Nodes (28): GrowthIndicatorsViewModel, LoadingState, error, idle, loaded, loading, Date, Double (+20 more)

### Community 3 - "Community 3"
Cohesion: 0.08
Nodes (13): CurriculumInfo, LocalAnalyticsCalculator, StrategyInfo, AnalyticsOverview, Date, Double, EmotionalLandscape, GrowthIndicators (+5 more)

### Community 4 - "Community 4"
Cohesion: 0.08
Nodes (14): CustomStringConvertible, LocalJournalEntry, Date, EntryType, InitiatedBy, Int, UUID, JournalRepository (+6 more)

### Community 5 - "Community 5"
Cohesion: 0.07
Nodes (30): FileManager, CatalogCacheEnvelope, Date, CatalogAPIService, CatalogCachePersisting, CatalogRemoteServicing, CatalogRepository, CatalogRepositoryLogging (+22 more)

### Community 6 - "Community 6"
Cohesion: 0.10
Nodes (58): Dosage, EntryType, InitiatedBy, Dosage categories for curriculum entries., Source of journal entry creation., Type of journal entry.      Only ``EMOTION`` remains; the rest-period feature wa, _accumulate_emotion_counts(), get_emotional_landscape() (+50 more)

### Community 7 - "Community 7"
Cohesion: 0.06
Nodes (24): Calendar, HourFormatter, DateFormatter, Int, String, JournalEntryDrilldownFilter, byCurriculum, byHour (+16 more)

### Community 8 - "Community 8"
Cohesion: 0.06
Nodes (52): alias, get_session(), FastAPI dependency that yields a transactional session., IdempotencyRecord, Idempotency key tracking for journal creation.      Stores mapping of user-scope, _base_query(), cleanup_expired_idempotency_records(), _create_idempotency_record() (+44 more)

### Community 9 - "Community 9"
Cohesion: 0.10
Nodes (20): Date, TemporalPatternsViewModel, MockAnalyticsService, MockJournalRepository, MockLocalAnalyticsCalculator, MockSyncSettingsPersistence, AnalyticsOverview, Bool (+12 more)

### Community 10 - "Community 10"
Cohesion: 0.08
Nodes (20): SyncStatus, failed, pending, synced, JournalDatabase, JournalDatabaseError, databaseNotOpen, failedToCreateTable (+12 more)

### Community 11 - "Community 11"
Cohesion: 0.10
Nodes (4): Foundation, CatalogTestHelper, Testing, WavelengthWatch_Watch_App

### Community 12 - "Community 12"
Cohesion: 0.11
Nodes (10): PhaseNavigator, Int, NavigationViewModel, AnyCancellable, Int, Set, MainContentStates, NavigationViewModelTests (+2 more)

### Community 13 - "Community 13"
Cohesion: 0.10
Nodes (15): JournalClient, Bool, FailingAPIClientSpy, FailingJournalRepository, InMemoryJournalQueueSpy, JournalClientLocalFirstTests, JournalClientQueueIntegrationTests, StubAPIClientSpy (+7 more)

### Community 14 - "Community 14"
Cohesion: 0.16
Nodes (6): FlowCoordinator, ClearLightEmotionCard, Content, View, ContentViewFlowIntegrationTests, Bool

### Community 15 - "Community 15"
Cohesion: 0.11
Nodes (13): GrowthIndicators, DiversityCoverageView, GrowthIndicatorsView, MedicinalTrendView, Bool, Color, GrowthIndicators, String (+5 more)

### Community 16 - "Community 16"
Cohesion: 0.14
Nodes (17): JournalSyncService, AnyCancellable, Bool, Date, NetworkMonitorProtocol, JournalSyncServiceTests, MockAPIClient, MockJournalQueue (+9 more)

### Community 17 - "Community 17"
Cohesion: 0.04
Nodes (44): CodingKey, CodingKeys, avgFrequency, count, currentStreak, curriculumId, diversityScore, dominantDosage (+36 more)

### Community 18 - "Community 18"
Cohesion: 0.17
Nodes (10): InMemoryJournalRepository, Content, View, ContentViewFilteringTests, ContentViewModelTests, CatalogRepositoryMock, ErrorStub, JournalClientMock (+2 more)

### Community 19 - "Community 19"
Cohesion: 0.09
Nodes (24): layers, LayerFilterMode, all, emotionsOnly, strategiesOnly, CatalogRepositoryProtocol, JournalClientProtocol, ContentViewModel (+16 more)

### Community 20 - "Community 20"
Cohesion: 0.11
Nodes (12): Bool, Date, SyncSettings, SyncSettingsPersisting, Bool, SyncSettingsViewModel, MockSyncSettingsPersistence, Bool (+4 more)

### Community 21 - "Community 21"
Cohesion: 0.13
Nodes (15): SelfCareViewModel, Double, Int, TopStrategyItem, MockAnalyticsService, MockLocalAnalyticsCalculator, MockSyncSettingsPersistence, SelfCareViewModelTests (+7 more)

### Community 22 - "Community 22"
Cohesion: 0.14
Nodes (14): APIClientError, Bool, Int, JournalQueueProtocol, APIClientErrorRetryableTests, OfflineQueueIntegrationTests, Bool, Encodable (+6 more)

### Community 23 - "Community 23"
Cohesion: 0.16
Nodes (4): JournalQueueTests, Int, String, UUID

### Community 24 - "Community 24"
Cohesion: 0.11
Nodes (33): create_test_entries(), measure_response_time(), perf_client(), TestClient, Performance tests for analytics endpoints.  Validates spec requirement: "Analyti, Test emotional landscape endpoint performance., Test self-care analytics endpoint performance., Test temporal patterns endpoint performance. (+25 more)

### Community 25 - "Community 25"
Cohesion: 0.20
Nodes (32): CompletedProcess, env(), _failing_pr(), _passing_pr(), _pending_pr(), MonkeyPatch, Path, End-to-end tests for ``scripts/pr-status.sh``.  The script shells out to ``gh pr (+24 more)

### Community 26 - "Community 26"
Cohesion: 0.09
Nodes (31): make_cache_key(), Simple in-memory cache with TTL for analytics endpoints.  This module provides a, Generate a deterministic cache key for analytics queries.      The key format is, _calculate_longest_streak(), _calculate_medicinal_ratio(), _calculate_medicinal_trend(), _calculate_streak(), get_analytics_overview() (+23 more)

### Community 27 - "Community 27"
Cohesion: 0.13
Nodes (12): HourlyDistributionItem, TemporalPatterns, HourlyRow, HourlySummary, Color, Date, Double, Int (+4 more)

### Community 28 - "Community 28"
Cohesion: 0.08
Nodes (22): CaseIterable, Error, FlowError, missingPrimaryEmotion, FlowStep, confirmingPrimary, confirmingSecondary, confirmingStrategy (+14 more)

### Community 29 - "Community 29"
Cohesion: 0.10
Nodes (24): configure_logging(), _is_sensitive_field(), Any, Logging configuration utilities that scrub PII before emission., Install the sensitive-data filter on known loggers., Apply lightweight regex scrubbing to formatted string messages., Return a copy of *value* with known PII fields redacted., Logging filter that redacts sensitive fields on the fly. (+16 more)

### Community 30 - "Community 30"
Cohesion: 0.15
Nodes (26): Curriculum, Journal, Layer, SQLModel, SQLModel table definitions for the WavelengthWatch backend., User journal entries representing runtime activity.      Performance note: The c, Reference table describing each spiral dynamics layer., Curriculum entries that map layers to phases and expressions. (+18 more)

### Community 31 - "Community 31"
Cohesion: 0.13
Nodes (15): EmotionalLandscapeViewModel, Int, LayerDistributionItem, PhaseDistributionItem, TopEmotionItem, EmotionalLandscapeViewModelTests, MockAnalyticsService, AnalyticsOverview (+7 more)

### Community 32 - "Community 32"
Cohesion: 0.14
Nodes (27): Self-care strategies associated with specific layers and phases., Strategy, _base_query(), create_strategy(), delete_strategy(), _ensure_strategy_id(), get_strategy(), _get_strategy_or_404() (+19 more)

### Community 33 - "Community 33"
Cohesion: 0.13
Nodes (25): get_catalog(), Response, SessionDep, Router exposing the aggregated catalog endpoint., Return the cached catalog payload for clients.      The payload nests medicinal/, CatalogCurriculumEntry, CatalogLayer, CatalogPhase (+17 more)

### Community 34 - "Community 34"
Cohesion: 0.07
Nodes (6): CGFloat, WLSpacingTokens, WLTheme, Date, TimePickerView, SwiftUI

### Community 35 - "Community 35"
Cohesion: 0.14
Nodes (14): JournalQueueError, databaseError, entryNotFound, insertFailed, invalidData, queryFailed, updateFailed, JournalQueue (+6 more)

### Community 36 - "Community 36"
Cohesion: 0.11
Nodes (18): App, UNUserNotificationCenter, MainContentDialogsModifier, Binding, Bool, Content, View, View (+10 more)

### Community 37 - "Community 37"
Cohesion: 0.11
Nodes (23): create_application(), _determine_allowed_origins(), FastAPI, FastAPI application entrypoint., Return CORS origins based on the current environment configuration., Configure and return the FastAPI application., RuntimeError, client() (+15 more)

### Community 38 - "Community 38"
Cohesion: 0.12
Nodes (15): DispatchQueue, ConnectionType, cellular, none, unknown, wifi, wired, NetworkMonitor (+7 more)

### Community 39 - "Community 39"
Cohesion: 0.20
Nodes (6): PresentationCoordinator, Binding, Bool, Int, PresentationCoordinatorTests, PresentationPolicyTests

### Community 40 - "Community 40"
Cohesion: 0.17
Nodes (14): CatalogCurriculumEntryModel, CatalogDosage, medicinal, toxic, CatalogLayerModel, CatalogPhaseModel, Int, String (+6 more)

### Community 41 - "Community 41"
Cohesion: 0.16
Nodes (10): CatalogStrategyModel, Selections, StrategyExpressionCard, String, StrategySummaryCard, Bool, Color, StrategyExpressionCardTests (+2 more)

### Community 42 - "Community 42"
Cohesion: 0.14
Nodes (6): MockJournalRepository, Date, Error, GrowthIndicators, TemporalPatterns, UUID

### Community 43 - "Community 43"
Cohesion: 0.11
Nodes (22): CodingKeys, createdAt, curriculumID, entryType, id, initiatedBy, secondaryCurriculumID, strategyID (+14 more)

### Community 44 - "Community 44"
Cohesion: 0.13
Nodes (8): CatalogResponseModel, MockCatalogRepository, Bool, MockCatalogRepository, Bool, MenuViewTests, Bool, Result

### Community 45 - "Community 45"
Cohesion: 0.13
Nodes (10): CurriculumCard, Color, String, StrategyCard, Bool, Color, Int, CurriculumCardTests (+2 more)

### Community 46 - "Community 46"
Cohesion: 0.19
Nodes (13): JournalDrilldownContext, AnalyticsService, AnalyticsServiceProtocol, JournalRepositoryProtocol, LocalAnalyticsCalculatorProtocol, Int, AnalyticsDetailHubView, GrowthIndicatorsDetailView (+5 more)

### Community 47 - "Community 47"
Cohesion: 0.16
Nodes (4): CircularProgressView, Font, String, CircularProgressViewTests

### Community 48 - "Community 48"
Cohesion: 0.21
Nodes (11): Codable, Equatable, AnalyticsOverview, EmotionalLandscape, LayerDistributionItem, PhaseDistributionItem, PhaseMedicinalRatioItem, Date (+3 more)

### Community 49 - "Community 49"
Cohesion: 0.15
Nodes (10): ContentViewDependencies, Bool, MainActor, String, ContentViewDependenciesTests, FactoryFailure, ReasonedFailure, String (+2 more)

### Community 50 - "Community 50"
Cohesion: 0.14
Nodes (15): ContentView, PhaseStrategyCardView, OnboardingView, OnboardingView_Previews, StorageMode, cloudSynced, localOnly, Bool (+7 more)

### Community 51 - "Community 51"
Cohesion: 0.19
Nodes (8): BarChartItem, BarRow, HorizontalBarChart, CGFloat, Color, Double, String, HorizontalBarChartTests

### Community 52 - "Community 52"
Cohesion: 0.10
Nodes (6): OnboardingViewUITests, WavelengthWatch_Watch_AppUITests, Bool, WavelengthWatch_Watch_AppUITestsLaunchTests, XCTest, XCTestCase

### Community 53 - "Community 53"
Cohesion: 0.15
Nodes (18): configure_engine(), create_db_and_tables(), _create_engine(), _is_sqlite(), _normalize_database_url(), Session, Database configuration and session utilities., Pin the psycopg driver on bare Postgres URLs; pass others through.      Schemes (+10 more)

### Community 54 - "Community 54"
Cohesion: 0.21
Nodes (19): Phase, Reference table of user energy phases., create_phase(), delete_phase(), get_phase(), _get_phase_or_404(), list_phases(), ge (+11 more)

### Community 55 - "Community 55"
Cohesion: 0.23
Nodes (19): _base_query(), create_curriculum(), delete_curriculum(), _ensure_curriculum_id(), get_curriculum(), _get_curriculum_or_404(), list_curriculum(), ge (+11 more)

### Community 56 - "Community 56"
Cohesion: 0.14
Nodes (7): Bool, Color, Double, LinearGradient, String, WLColorTokens, WLColorTokensTests

### Community 57 - "Community 57"
Cohesion: 0.18
Nodes (14): APIClient, badResponse, invalidURL, transport, Data, Encodable, JSONDecoder, JSONEncoder (+6 more)

### Community 58 - "Community 58"
Cohesion: 0.18
Nodes (8): ButtonStyle, Configuration, Color, View, View, WLPrimaryButtonStyle, WLSecondaryButtonStyle, WLButtonStyleTests

### Community 59 - "Community 59"
Cohesion: 0.14
Nodes (14): MarkdownBlock, blockquote, empty, header1, header2, header3, listItem, paragraph (+6 more)

### Community 60 - "Community 60"
Cohesion: 0.22
Nodes (16): API routers for the FastAPI application., create_layer(), delete_layer(), get_layer(), _get_layer_or_404(), list_layers(), ge, le (+8 more)

### Community 61 - "Community 61"
Cohesion: 0.21
Nodes (8): AppConfiguration, BundleProtocol, String, URL, AppConfigurationTests, String, MockBundle, OSLog

### Community 62 - "Community 62"
Cohesion: 0.31
Nodes (8): PhaseStrategyGroup, SelfCareAnalytics, Decoder, Double, TopStrategyItem, StrategyUsageView, SelfCareAnalytics, StrategyUsageViewTests

### Community 63 - "Community 63"
Cohesion: 0.16
Nodes (10): JournalQueueItem, QueueStatistics, QueueStatus, failed, pending, synced, syncing, Date (+2 more)

### Community 64 - "Community 64"
Cohesion: 0.14
Nodes (10): AnalyticsOverview, Date, EmotionalLandscape, GrowthIndicators, Int, SelfCareAnalytics, TemporalPatterns, APIClientProtocol (+2 more)

### Community 65 - "Community 65"
Cohesion: 0.12
Nodes (15): Action, curriculum, strategy, LogConfirmationRequest, Int, String, ActivePresentation, flowReview (+7 more)

### Community 66 - "Community 66"
Cohesion: 0.18
Nodes (5): PhaseJourneyView, Color, PhaseDistributionItem, String, PhaseJourneyViewTests

### Community 67 - "Community 67"
Cohesion: 0.26
Nodes (4): EmotionSummaryCard, Bool, Color, EmotionSummaryCardTests

### Community 68 - "Community 68"
Cohesion: 0.21
Nodes (6): RootPresentationHost, Content, String, View, View, RootPresentationHostTests

### Community 69 - "Community 69"
Cohesion: 0.12
Nodes (11): AnalyticsCache, CacheEntry, Any, Clear all cache entries.          Useful for testing or when a full cache invali, Return cache statistics for monitoring.          Returns:             Dictionary, A cached value with expiration timestamp., Thread-safe in-memory cache with TTL support.      Optimized for analytics endpo, Initialize cache with specified TTL.          Args:             ttl_seconds: Tim (+3 more)

### Community 70 - "Community 70"
Cohesion: 0.28
Nodes (4): Bundle, MarkdownContentLoader, ConceptExplainerViewTests, MarkdownContentLoaderTests

### Community 71 - "Community 71"
Cohesion: 0.21
Nodes (8): CGFloat, Color, View, WLGlassIntensity, prominent, regular, WLGlassModifier, WLGlassModifierTests

### Community 72 - "Community 72"
Cohesion: 0.24
Nodes (7): HeaderCapturingAPIClientSpy, Any, Encodable, Response, String, T, TrackingAPIClientSpy

### Community 73 - "Community 73"
Cohesion: 0.19
Nodes (8): Bool, CGFloat, Color, Content, View, View, WLCardModifier, WLCardModifierTests

### Community 74 - "Community 74"
Cohesion: 0.21
Nodes (7): FlowSubmissionPresenter, String, JournalFlowAlertsModifier, Content, View, View, FlowSubmissionPresenterTests

### Community 75 - "Community 75"
Cohesion: 0.21
Nodes (7): DosageDeepDiveView, EmotionRow, EmotionSection, Color, String, TopEmotionItem, DosageDeepDiveViewTests

### Community 76 - "Community 76"
Cohesion: 0.13
Nodes (9): LayerCardView, CGFloat, Int, LayerScrollView, CGSize, Double, Int, LayerCardViewTests (+1 more)

### Community 77 - "Community 77"
Cohesion: 0.21
Nodes (6): Alert, JournalFeedbackAlert, Int, String, Void, JournalFeedbackAlertTests

### Community 78 - "Community 78"
Cohesion: 0.23
Nodes (9): AnyShapeStyle, CGFloat, Color, Content, View, View, WLCardSurface, WLSurfaceModifierTests (+1 more)

### Community 79 - "Community 79"
Cohesion: 0.18
Nodes (10): MarkdownContent, MarkdownLoadError, fileNotFound, parsingFailed, readFailed, AttributedString, Result, String (+2 more)

### Community 80 - "Community 80"
Cohesion: 0.19
Nodes (9): AnalyticsEmptyView, Prominence, compact, prominent, CGFloat, Color, Font, String (+1 more)

### Community 81 - "Community 81"
Cohesion: 0.35
Nodes (6): AnalyticsPerformanceBenchmarks, Date, Double, Int, String, Void

### Community 83 - "Community 83"
Cohesion: 0.24
Nodes (7): FlowStepReaction, FlowStepReactionPolicy, ReviewSheetAction, dismissIfActive, present, Bool, FlowStepReactionPolicyTests

### Community 84 - "Community 84"
Cohesion: 0.23
Nodes (4): StreakDisplayView, Int, String, StreakDisplayViewTests

### Community 85 - "Community 85"
Cohesion: 0.22
Nodes (7): FlowConfirmationAlertsModifier, Binding, Bool, MainActor, Void, View, FlowConfirmationAlertsModifierTests

### Community 86 - "Community 86"
Cohesion: 0.19
Nodes (7): DetailDestination, curriculum, strategy, String, DetailDestinationView, DetailDestinationTests, Int

### Community 88 - "Community 88"
Cohesion: 0.29
Nodes (6): AnalyticsOverview, AnalyticsView, AnalyticsOverview, Int, String, View

### Community 89 - "Community 89"
Cohesion: 0.21
Nodes (8): APIClientSpy, Any, Encodable, JSONDecoder, JSONEncoder, Response, String, T

### Community 90 - "Community 90"
Cohesion: 0.24
Nodes (7): ci_human_line(), die_usage(), render_default(), render_summary(), pr-status.sh script, update_overall(), usage()

### Community 91 - "Community 91"
Cohesion: 0.21
Nodes (7): Color, String, LayerSideIndicator, Bool, CGSize, Int, LinearGradient

### Community 92 - "Community 92"
Cohesion: 0.21
Nodes (7): CurriculumDetailView, Bool, Color, LayeredEmotion, Color, Int, String

### Community 93 - "Community 93"
Cohesion: 0.17
Nodes (11): Tests for analytics endpoints., Test strategy diversity score calculation., Test self-care analytics uses 30-day default., Test per-phase medicinal ratio in emotional landscape., Test diversity score is calculated per phase., Test secondary emotions percentage calculation., test_analytics_overview_secondary_emotions_pct(), test_emotional_landscape_phase_medicinal_ratios() (+3 more)

### Community 94 - "Community 94"
Cohesion: 0.25
Nodes (5): Content, View, View, WLNavigationBarModifier, WLNavigationBarModifierTests

### Community 96 - "Community 96"
Cohesion: 0.27
Nodes (8): CardDepthShadow, CardIntensityLadder, PhaseCrystalCard, CGFloat, Color, Content, Double, String

### Community 97 - "Community 97"
Cohesion: 0.20
Nodes (7): SeedError, exec, open, Bool, Int, String, UUID

### Community 98 - "Community 98"
Cohesion: 0.24
Nodes (7): Animation, Content, Equatable, View, View, WLConditionalAnimation, V

### Community 99 - "Community 99"
Cohesion: 0.29
Nodes (4): AnalyticsErrorView, String, Void, AnalyticsErrorViewTests

### Community 102 - "Community 102"
Cohesion: 0.20
Nodes (9): Tests for journal entry_type behavior in the journal API., EMOTION entries work normally with curriculum_id., If entry_type is not specified, it defaults to EMOTION., The removed 'rest' entry_type is no longer accepted (#435)., EMOTION entries must have curriculum_id., test_create_emotion_entry_requires_curriculum(), test_create_emotion_entry_with_curriculum(), test_entry_type_defaults_to_emotion() (+1 more)

### Community 103 - "Community 103"
Cohesion: 0.22
Nodes (8): JournalSyncStatus, error, idle, success, syncing, Double, Error, Int

### Community 104 - "Community 104"
Cohesion: 0.25
Nodes (6): AnalyticsLoadingView, ShimmerModifier, CGFloat, Content, View, ViewModifier

### Community 105 - "Community 105"
Cohesion: 0.31
Nodes (3): EmotionExpressionCard, String, EmotionExpressionCardTests

### Community 107 - "Community 107"
Cohesion: 0.25
Nodes (7): LoadingState, error, idle, loaded, loading, EmotionalLandscape, Error

### Community 108 - "Community 108"
Cohesion: 0.25
Nodes (7): LoadingState, error, idle, loaded, loading, SelfCareAnalytics, String

### Community 109 - "Community 109"
Cohesion: 0.25
Nodes (7): LoadingState, error, idle, loaded, loading, String, TemporalPatterns

### Community 110 - "Community 110"
Cohesion: 0.39
Nodes (7): OverallDiversityView, ResolvedPhaseGroup, StrategyCardView, Double, Int, String, TopStrategyItem

### Community 112 - "Community 112"
Cohesion: 0.33
Nodes (3): ModeDistributionView, LayerDistributionItem, ModeDistributionViewTests

### Community 113 - "Community 113"
Cohesion: 0.38
Nodes (3): Binding, Bool, MainContentDialogsModifierTests

### Community 114 - "Community 114"
Cohesion: 0.29
Nodes (5): Encodable, Response, String, T, UInt64

### Community 115 - "Community 115"
Cohesion: 0.53
Nodes (3): _coerce_datetime(), datetime, Parse strings into timezone-aware datetimes in UTC.

### Community 116 - "Community 116"
Cohesion: 0.60
Nodes (5): _convert_curriculum(), _convert_headers(), _convert_strategies(), _detect(), main()

### Community 120 - "Community 120"
Cohesion: 0.33
Nodes (4): AnimatedProgressPreview, CGFloat, Color, Double

### Community 121 - "Community 121"
Cohesion: 0.33
Nodes (3): MysticalJournalIcon, Color, MysticalJournalIconTests

### Community 123 - "Community 123"
Cohesion: 0.40
Nodes (3): ClosedRange, Comparable, Self

### Community 124 - "Community 124"
Cohesion: 0.40
Nodes (4): colorSwatch(), Color, String, View

### Community 125 - "Community 125"
Cohesion: 0.40
Nodes (3): StrategyListView, Color, Int

### Community 126 - "Community 126"
Cohesion: 0.40
Nodes (4): LayerView, CGFloat, Double, Int

### Community 127 - "Community 127"
Cohesion: 0.40
Nodes (4): MainNavigationToolbar, Bool, Void, ToolbarContent

### Community 130 - "Community 130"
Cohesion: 0.50
Nodes (3): CGFloat, Font, WLTypographyTokens

### Community 132 - "Community 132"
Cohesion: 0.50
Nodes (3): EnvironmentValues, Binding, Bool

### Community 133 - "Community 133"
Cohesion: 0.50
Nodes (3): JournalEntryRowView, Int, String

### Community 139 - "Community 139"
Cohesion: 0.67
Nodes (3): Test dominant layer identification., test_analytics_overview_dominant_layer(), test_analytics_overview_dominant_phase()

## Knowledge Gaps
- **167 isolated node(s):** `dev-setup.sh script`, `AppStorageKeys`, `os`, `regular`, `prominent` (+162 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **60 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `LocalJournalEntry` connect `Community 4` to `Community 0`, `Community 2`, `Community 3`, `Community 133`, `Community 7`, `Community 9`, `Community 10`, `Community 13`, `Community 16`, `Community 18`, `Community 21`, `Community 22`, `Community 23`, `Community 35`, `Community 40`, `Community 42`, `Community 43`, `Community 48`, `Community 63`, `Community 81`, `Community 111`?**
  _High betweenness centrality (0.114) - this node is a cross-community bridge._
- **Why does `SwiftUI` connect `Community 34` to `Community 128`, `Community 129`, `Community 130`, `Community 131`, `Community 132`, `Community 133`, `Community 134`, `Community 7`, `Community 1`, `Community 11`, `Community 12`, `Community 15`, `Community 27`, `Community 28`, `Community 36`, `Community 38`, `Community 40`, `Community 41`, `Community 45`, `Community 46`, `Community 50`, `Community 51`, `Community 56`, `Community 58`, `Community 59`, `Community 65`, `Community 66`, `Community 67`, `Community 68`, `Community 71`, `Community 73`, `Community 74`, `Community 75`, `Community 76`, `Community 77`, `Community 78`, `Community 79`, `Community 80`, `Community 84`, `Community 85`, `Community 86`, `Community 88`, `Community 91`, `Community 92`, `Community 94`, `Community 96`, `Community 98`, `Community 99`, `Community 104`, `Community 105`, `Community 106`, `Community 110`, `Community 120`, `Community 121`, `Community 122`, `Community 124`, `Community 125`, `Community 126`, `Community 127`?**
  _High betweenness centrality (0.085) - this node is a cross-community bridge._
- **Why does `Foundation` connect `Community 11` to `Community 0`, `Community 2`, `Community 3`, `Community 4`, `Community 5`, `Community 7`, `Community 9`, `Community 10`, `Community 12`, `Community 13`, `Community 16`, `Community 17`, `Community 19`, `Community 20`, `Community 21`, `Community 28`, `Community 34`, `Community 40`, `Community 43`, `Community 46`, `Community 48`, `Community 49`, `Community 59`, `Community 61`, `Community 63`, `Community 64`, `Community 65`, `Community 74`, `Community 83`, `Community 106`, `Community 107`, `Community 108`, `Community 109`, `Community 117`, `Community 118`?**
  _High betweenness centrality (0.056) - this node is a cross-community bridge._
- **Are the 73 inferred relationships involving `LocalJournalEntry` (e.g. with `.fetch()` and `.fetchAll_tolerantOfInvalidSyncStatus()`) actually correct?**
  _`LocalJournalEntry` has 73 INFERRED edges - model-reasoned connections that need verification._
- **Are the 73 inferred relationships involving `SyncSettings` (e.g. with `.configureTestMode()` and `.layerDiversity_returnsValueWhenLoaded()`) actually correct?**
  _`SyncSettings` has 73 INFERRED edges - model-reasoned connections that need verification._
- **Are the 33 inferred relationships involving `ContentViewModel` (e.g. with `.observeModel()` and `.scrollView()`) actually correct?**
  _`ContentViewModel` has 33 INFERRED edges - model-reasoned connections that need verification._
- **What connects `dev-setup.sh script`, `AppStorageKeys`, `os` to the rest of the system?**
  _167 weakly-connected nodes found - possible documentation gaps or missing edges._