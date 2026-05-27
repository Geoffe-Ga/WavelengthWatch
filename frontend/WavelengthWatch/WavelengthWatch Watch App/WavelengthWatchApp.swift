//
//  WavelengthWatchApp.swift
//  WavelengthWatch Watch App
//
//  Created by Geoff Gallinger on 9/10/25.
//

import SwiftUI
import UserNotifications

@main
struct WavelengthWatch_Watch_AppApp: App {
  // MARK: - Dependency Ownership

  //
  // All app-wide ObservableObject ownership roots here so ContentView
  // can stay a thin composition shell holding only its own @State and
  // forwarding the dependencies into the view hierarchy.

  @StateObject private var notificationDelegate: NotificationDelegate = {
    let delegate = NotificationDelegate()
    // Register delegate immediately upon creation to avoid race condition
    NotificationDelegateShim.shared.delegate = delegate
    UNUserNotificationCenter.current().delegate = NotificationDelegateShim.shared
    return delegate
  }()

  @StateObject private var viewModel: ContentViewModel
  @StateObject private var flowCoordinator: FlowCoordinator
  @StateObject private var syncSettingsViewModel: SyncSettingsViewModel
  @StateObject private var networkMonitor: NetworkMonitor
  @StateObject private var journalQueue: JournalQueue
  @StateObject private var syncService: JournalSyncService
  @StateObject private var navigationViewModel: NavigationViewModel

  private let journalClient: JournalClientProtocol
  private let journalRepository: JournalRepositoryProtocol
  private let catalogRepository: CatalogRepositoryProtocol

  init() {
    let deps = ContentViewDependencies.live()
    _viewModel = StateObject(wrappedValue: deps.viewModel)
    _flowCoordinator = StateObject(wrappedValue: deps.flowCoordinator)
    _syncSettingsViewModel = StateObject(wrappedValue: deps.syncSettingsViewModel)
    _networkMonitor = StateObject(wrappedValue: deps.networkMonitor)
    _journalQueue = StateObject(wrappedValue: deps.journalQueue)
    _syncService = StateObject(wrappedValue: deps.syncService)
    _navigationViewModel = StateObject(wrappedValue: deps.navigationViewModel)
    self.journalClient = deps.journalClient
    self.journalRepository = deps.journalRepository
    self.catalogRepository = deps.catalogRepository
    configureNotificationCategories()
    configureTestMode()
  }

  private func configureTestMode() {
    #if DEBUG
    // Reset onboarding for UI tests
    if ProcessInfo.processInfo.arguments.contains("RESET_ONBOARDING") {
      SyncSettings().reset()
    }
    #endif
  }

  private func configureNotificationCategories() {
    let logEmotionsAction = UNNotificationAction(
      identifier: "LOG_EMOTIONS",
      title: "Log Emotions",
      options: [.foreground]
    )

    let category = UNNotificationCategory(
      identifier: "JOURNAL_CHECKIN",
      actions: [logEmotionsAction],
      intentIdentifiers: [],
      options: []
    )

    UNUserNotificationCenter.current().setNotificationCategories([category])
  }

  var body: some Scene {
    WindowGroup {
      ContentView(
        viewModel: viewModel,
        flowCoordinator: flowCoordinator,
        syncSettingsViewModel: syncSettingsViewModel,
        networkMonitor: networkMonitor,
        journalQueue: journalQueue,
        syncService: syncService,
        navigationViewModel: navigationViewModel,
        journalClient: journalClient,
        journalRepository: journalRepository,
        catalogRepository: catalogRepository
      )
      .environmentObject(notificationDelegate)
    }
  }
}

// MARK: - Notification Handling

struct ScheduledNotification: Equatable {
  let scheduleId: String
  let initiatedBy: InitiatedBy
}

@MainActor
final class NotificationDelegate: ObservableObject {
  @Published var scheduledNotificationReceived: ScheduledNotification?

  func handleNotificationResponse(_ response: UNNotificationResponse) {
    let userInfo = response.notification.request.content.userInfo

    if let scheduleId = userInfo["scheduleId"] as? String,
       let initiatedByString = userInfo["initiatedBy"] as? String,
       initiatedByString == "scheduled"
    {
      scheduledNotificationReceived = ScheduledNotification(
        scheduleId: scheduleId,
        initiatedBy: .scheduled
      )
    }
  }

  func clearNotificationState() {
    scheduledNotificationReceived = nil
  }
}

/// Shim to bridge UNUserNotificationCenterDelegate to our NotificationDelegate
final class NotificationDelegateShim: NSObject, UNUserNotificationCenterDelegate {
  static let shared = NotificationDelegateShim()
  weak var delegate: NotificationDelegate?

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    Task { @MainActor in
      delegate?.handleNotificationResponse(response)
      completionHandler()
    }
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.banner, .sound])
  }
}
