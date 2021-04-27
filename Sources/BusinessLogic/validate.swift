import Foundation
import kubewardenSdk
import SwiftPath
import Foundation
import GenericJSON


func mutateOrReject(payload: String, fallbackRuntime: String?, rejectionMessage: String) -> String {
  if let newRuntime = fallbackRuntime,
    let mutatedObject = patchRuntime(payload: payload, newRuntime: newRuntime)
  {
    return mutateRequest(mutatedObject: mutatedObject)
  }

  return rejectRequest(message: rejectionMessage, code: nil)
}

func patchRuntime(payload: String, newRuntime: String) -> JSON? {
  let objPath = SwiftPath("$.request.object")!
  if let match = try! objPath.evaluate(with: payload),
    var obj = match as? [String: Any] {
      var spec = obj["spec"] as! [String: Any]
      spec["runtimeClassName"] = newRuntime
      obj["spec"] = spec

      return try? JSON.init(obj)
  }
  return nil
}

public func validate(payload: String) -> String {
  let vr : ValidationRequest<Settings> = try! JSONDecoder().decode(
    ValidationRequest<Settings>.self, from: Data(payload.utf8))

  let jsonPath = SwiftPath("$.request.object.spec.runtimeClassName")!

  if let match = try? jsonPath.evaluate(with: payload),
    let runtimeClassName = match as? String
  {
    if vr.settings.reservedRuntimes.contains(runtimeClassName) {
      return mutateOrReject(
        payload: payload,
        fallbackRuntime: vr.settings.fallbackRuntime,
        rejectionMessage: "runtime '\(runtimeClassName)' is reserved")
    }
    return acceptRequest()
  }

  // we're here because no runtimeClassName is specified

  if vr.settings.defaultRuntimeReserved {
    return mutateOrReject(
      payload: payload,
      fallbackRuntime: vr.settings.fallbackRuntime,
      rejectionMessage: "Usage of the default runtime is reserved")
  }

  if let fallbackRuntime = vr.settings.fallbackRuntime,
    let mutatedObject = patchRuntime(payload: payload, newRuntime: fallbackRuntime) {
    return mutateRequest(mutatedObject: mutatedObject)
  }

  return acceptRequest()
}
