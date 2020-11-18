import Foundation

public struct Config {
    let reservedRuntime: String
    let defaultRuntimeReserved:  Bool
    let trustedUsers: Set<String>
    let trustedGroups: Set<String>


    public init() {
        let defReserved: Bool
        let trustedUsers: String
        let trustedGroups: String

        if let value = getenv("DEFAULT_RUNTIME_RESERVED") {
            let r = String(utf8String: value)!
            defReserved = r == String("1")
        } else {
            defReserved = true
        }
        if let value = getenv("TRUSTED_USERS") {
            trustedUsers = String(utf8String: value)!
        } else {
            trustedUsers = String()
        }
        if let value = getenv("TRUSTED_GROUPS") {
            trustedGroups = String(utf8String: value)!
        } else {
            trustedGroups = String()
        }

        self.init(
            reservedRuntime: String(utf8String: getenv("RESERVED_RUNTIME"))!,
            defaultRuntimeReserved: defReserved,
            trustedUsers: trustedUsers,
            trustedGroups: trustedGroups)
    }

    public init(reservedRuntime: String,
                defaultRuntimeReserved: Bool,
                trustedUsers: String,
                trustedGroups: String) {
        self.reservedRuntime = reservedRuntime

        self.defaultRuntimeReserved = defaultRuntimeReserved
        self.trustedUsers = Set(trustedUsers.components(separatedBy: ","))
        self.trustedGroups = Set(trustedGroups.components(separatedBy: ","))
    }
}
