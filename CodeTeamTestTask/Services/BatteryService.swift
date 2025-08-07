import Foundation

final class BatteryService {
  
  private let url = URL(string: "https://jsonplaceholder.typicode.com/posts")!
  
  private var session: URLSession {
    let configuration = URLSessionConfiguration.default
    configuration.timeoutIntervalForRequest = 20
    configuration.timeoutIntervalForResource = 20
    return URLSession(configuration: configuration)
  }
  
  // Sends battery data asynchronously with retry logic
  func send(data: BatteryInfo, retryCount: Int = 3) async {
    guard retryCount > 0 else {
      debugPrint("❌ Max retry attempts reached.")
      return
    }
    
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    
    guard let jsonData = try? encoder.encode(data) else {
      debugPrint("❌ Failed to encode BatteryInfo.")
      return
    }
    
    // Encode data to JSON
    let encodedData = jsonData.base64EncodedString()
    
    // Prepare HTTP request
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try? JSONEncoder().encode(["data": encodedData])
    
    do {
      // Send request
      let (_, response) = try await URLSession.shared.data(for: request)
      
      // Check HTTP response status
      if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
        try await Task.sleep(nanoseconds: 2_000_000_000)
        await self.send(data: data, retryCount: retryCount - 1)
      } else {
        debugPrint("Battery level: ~\(data.level * 100)%")
        debugPrint("✅ Battery data sent successfully.")
        debugPrint("---------------------")
      }
    } catch {
      // Handle network or other errors by retrying
      try? await Task.sleep(nanoseconds: 2_000_000_000)
      await self.send(data: data, retryCount: retryCount - 1)
    }
  }
}
