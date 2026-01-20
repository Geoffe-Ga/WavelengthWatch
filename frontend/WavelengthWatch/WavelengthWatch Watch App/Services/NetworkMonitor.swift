import Foundation
import Network

/// Network connection types detected by NWPathMonitor.
enum ConnectionType {
  case wifi
  case cellular
  case wired
  case unknown
  case none
}

/// Monitors network reachability and publishes connectivity state changes.
///
/// Uses Apple's Network framework (`NWPathMonitor`) to detect network availability
/// and connection type. Updates are published on the MainActor to ensure UI safety.
///
/// ## Usage
/// ```swift
/// @StateObject private var networkMonitor = NetworkMonitor()
///
/// var body: some View {
///   if networkMonitor.isConnected {
///     Text("Online (\(networkMonitor.connectionType))")
///   } else {
///     Text("Offline")
///   }
/// }
/// ```
///
/// ## Implementation Details
/// - Automatically starts monitoring on initialization
/// - Path updates run on background queue, state updates on MainActor
/// - Properly cancels monitoring on deinit to prevent leaks
/// - Distinguishes between wifi, cellular, wired, and no connection
@MainActor
final class NetworkMonitor: ObservableObject {
  // MARK: - Published Properties

  /// Current network connection status.
  @Published private(set) var isConnected: Bool = false

  /// Type of connection currently active.
  @Published private(set) var connectionType: ConnectionType = .unknown

  // MARK: - Private Properties

  private let monitor: NWPathMonitor
  private let queue: DispatchQueue

  // MARK: - Initialization

  /// Creates and starts network monitoring.
  ///
  /// The monitor begins observing network changes immediately upon initialization.
  /// Path update callbacks run on a background queue, with state updates dispatched
  /// to the MainActor for thread-safe UI updates.
  init() {
    self.monitor = NWPathMonitor()
    self.queue = DispatchQueue(label: "com.wavelengthwatch.networkmonitor")

    monitor.pathUpdateHandler = { [weak self] path in
      Task { @MainActor in
        self?.updateStatus(from: path)
      }
    }

    monitor.start(queue: queue)
  }

  // MARK: - Deinitialization

  deinit {
    monitor.cancel()
  }

  // MARK: - Public Methods

  /// Starts the network monitor.
  ///
  /// Note: The monitor starts automatically on init. This method is provided
  /// for cases where monitoring was explicitly stopped via `stop()`.
  func start() {
    monitor.start(queue: queue)
  }

  /// Stops the network monitor.
  ///
  /// Call this to temporarily pause monitoring. Use `start()` to resume.
  /// The monitor is automatically cancelled on deinit.
  func stop() {
    monitor.cancel()
  }

  // MARK: - Private Methods

  /// Updates connection status based on NWPath.
  ///
  /// Determines connection status and type from path properties.
  /// Priority order: wifi > cellular > wired > unknown > none.
  ///
  /// - Parameter path: Current network path from NWPathMonitor
  private func updateStatus(from path: NWPath) {
    isConnected = path.status == .satisfied

    if path.usesInterfaceType(.wifi) {
      connectionType = .wifi
    } else if path.usesInterfaceType(.cellular) {
      connectionType = .cellular
    } else if path.usesInterfaceType(.wiredEthernet) {
      connectionType = .wired
    } else if path.status == .satisfied {
      connectionType = .unknown
    } else {
      connectionType = .none
    }
  }
}
