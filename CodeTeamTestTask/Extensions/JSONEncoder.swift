import Foundation

extension JSONEncoder {
  func base64Encoded<T: Encodable>(_ value: T) -> String? {
    guard let data = try? self.encode(value) else { return nil }
    return data.base64EncodedString()
  }
}
