import Foundation

public struct ValidationResult : Codable{
  let accepted: Bool
  let message: String
}

let relevantOperations: Set<String> = ["CREATE", "UPDATE"]

public func validate(rawJSON: String, config: Config) -> ValidationResult {
  // TODO: the code that deals with JSON can be hugely simplified once
  // this swiftwasm bug is solved: https://github.com/swiftwasm/swift/issues/2223

  let jsonData = rawJSON.data(using: .utf8)!
  let request = try! JSONSerialization.jsonObject(with: jsonData, options: [])
  let reqDict = request as! [String: Any]

  if !relevantOperations.contains(reqDict["operation"] as! String) {
    return ValidationResult(
      accepted: true,
      message: "")
  }

  let userInfo = reqDict["userInfo"] as! [String: Any]
  let username = userInfo["username"] as! String
  let isUserTrusted = config.trustedUsers.contains(username)

  let groups: Set<String>
  if let g = userInfo["groups"] as? [String] {
    groups = Set(g)
  } else {
    groups = Set<String>()
  }
  let isUserMemberOfTrustedGroup = !groups.isDisjoint(with: config.trustedGroups)

  let objDict = reqDict["object"] as! [String: Any]
  let podSpec = objDict["spec"] as! [String: Any]
  let result: ValidationResult

  if let runtimeClass = podSpec["runtimeClassName"] as? String {
    // the Pod Spec has a runtimeClassName defined
    switch runtimeClass {
    case config.reservedRuntime where (isUserTrusted || isUserMemberOfTrustedGroup):
      result = ValidationResult(accepted: true, message: "")
    case config.reservedRuntime:
      result = ValidationResult(
        accepted: false,
        message: "User is not authorized to schedule Pods with the reserved runtime \(runtimeClass)")
    default:
      result = ValidationResult(accepted: true, message: "")
    } 
  } else {
    // the Pod Spec doesn't have a runtimeClassName defined -> the default one
    // would be used
    switch config.defaultRuntimeReserved {
      case true where (isUserTrusted || isUserMemberOfTrustedGroup):
        result = ValidationResult(accepted: true, message: "")
      case true:
        result = ValidationResult(
          accepted: false,
          message: "User is not authorized to schedule Pods using the default runtime class")
      case false:
        result = ValidationResult(accepted: true, message: "")
    }
  }

  return result
}

