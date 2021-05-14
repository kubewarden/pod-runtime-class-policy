import kubewardenSdk
import wapc
import BusinessLogic

@_cdecl("__guest_call")
func __guest_call(operation_size: UInt, payload_size: UInt) -> Bool {
    return wapc.handleCall(operation_size: operation_size, payload_size: payload_size)
}

wapc.registerFunction(name: "validate", fn: validate)
wapc.registerFunction(name: "protocol_version", fn: protocolVersionCallback)

let settingsValidator = SettingsValidator<Settings>()
wapc.registerFunction(name: "validate_settings", fn: settingsValidator.validate)
