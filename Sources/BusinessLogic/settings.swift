import Foundation
import kubewardenSdk

public class Settings: Codable, Validatable {
  let reservedRuntimes: Set<String>
  let defaultRuntimeReserved: Bool
  let fallbackRuntime: String?

  public init(reservedRuntimes: Set<String>, defaultRuntimeReserved: Bool, fallbackRuntime: String?) {
    self.reservedRuntimes = reservedRuntimes
    self.defaultRuntimeReserved = defaultRuntimeReserved
    self.fallbackRuntime = fallbackRuntime
  }

  required public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    if let defaultRuntimeReserved = try container.decodeIfPresent(Bool.self, forKey: .defaultRuntimeReserved) {
        self.defaultRuntimeReserved = defaultRuntimeReserved
    } else {
        self.defaultRuntimeReserved = true
    }

    if let reservedRuntimes = try container.decodeIfPresent(Set<String>.self, forKey: .reservedRuntimes) {
      self.reservedRuntimes = reservedRuntimes
    } else {
      self.reservedRuntimes = Set<String>()
    }

    self.fallbackRuntime = try container.decodeIfPresent(String.self, forKey: .fallbackRuntime)
  }

  public var debugDescription: String {
    return "\(self) - reservedRuntimes: \(reservedRuntimes), defaultRuntimeReserved: \(defaultRuntimeReserved) - fallbackRuntime: \(fallbackRuntime ?? "N/A")"
  }

  public func validate() throws {
    if let fallbackRuntime = self.fallbackRuntime {
      guard !self.reservedRuntimes.contains(fallbackRuntime) else {
        throw SettingsValidationError.validationFailure(message: "fallback runtime \(fallbackRuntime) cannot be part of the reserved runtimes")
      }
    }
  }
}
