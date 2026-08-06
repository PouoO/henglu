import Flutter
import UIKit

public class IshSandboxPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "ish_sandbox", binaryMessenger: registrar.messenger())
        let instance = IshSandboxPlugin()
        channel.setMethodCallHandler(instance.handle(_:result:))
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "boot":
            do {
                try RootfsManager.shared.installIfNeeded()
                let code = ISHKernel.shared.boot(withRootPath: RootfsManager.shared.rootfsPath.path)
                result(code == 0 ? true : false)
            } catch {
                result(FlutterError(code: "BOOT_ERROR", message: error.localizedDescription, details: nil))
            }
        case "execute":
            guard let command = call.arguments as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "expected command string", details: nil))
                return
            }
            let pid = ISHShellExecutor.executeCommand(command, lineCallback: nil, completion: nil)
            result(pid)
        case "isBooted":
            result(ISHKernel.shared.isBooted)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
