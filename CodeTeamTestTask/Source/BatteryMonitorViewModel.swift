import UIKit
import Combine

@MainActor
protocol BatteryMonitorInputProtocol {
  func start()
}

final class BatteryMonitorViewModel: BatteryMonitorInputProtocol {
  
  // Public access to the input interface.
  var input: BatteryMonitorInputProtocol { return self }
  
  // Timer that triggers periodic battery data sending.
  private var timer: Timer?
  
  // Service responsible for sending battery data to the server.
  private let batteryService = BatteryService()
  
  // Identifier for the background task to keep the app running in the background during the send operation.
  private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
  
  // The last time battery data was sent.
  private var lastSentDate: Date?
  private var cancellables = Set<AnyCancellable>()
  
  // Initializes the view model and subscribes to app state notifications.
  init() {
    NotificationCenter.default
      .publisher(for: UIApplication.didBecomeActiveNotification)
      .sink { [weak self] _ in
        self?.handleAppDidBecomeActive()
      }
      .store(in: &cancellables)
  }
  
  // Starts the periodic battery monitoring.
  func start() {
    guard timer == nil else { return }
    
    // Create a repeating timer that triggers every 120 seconds
    timer = Timer.scheduledTimer(withTimeInterval: 120, repeats: true) { [weak self] _ in
      Task {
        await self?.send()
      }
    }
    
    // Send the initial battery data immediately
    send()
  }
  
  // Sends the current battery level to the server.
  private func send() {
    let level = UIDevice.current.batteryLevel
    let data = BatteryInfo(level: level, timestamp: Date())
    lastSentDate = Date()
    
    let service = batteryService
    
    // Start background task to ensure data sending finishes even if the app goes to the background
    beginBackgroundTask()
    
    Task {
      await service.send(data: data)
      endBackgroundTask()
    }
  }
  
  // Called when the app becomes active.
  private func handleAppDidBecomeActive() {
    // Restart timer if it was stopped
    if timer == nil {
      start()
    }
    
    // If more than 2 minutes have passed since last send, send data immediately
    if let last = lastSentDate, Date().timeIntervalSince(last) > 120 {
      send()
    }
  }
  
  // Begins a background task so that the app continues to run while sending data.
  private func beginBackgroundTask() {
    backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "SendBatteryData") { [weak self] in
      guard let self = self else { return }
      
      // End the task if time expires
      UIApplication.shared.endBackgroundTask(self.backgroundTask)
      self.backgroundTask = .invalid
    }
  }
  
  // Ends the previously started background task.
  private func endBackgroundTask() {
    UIApplication.shared.endBackgroundTask(backgroundTask)
    backgroundTask = .invalid
  }
}
