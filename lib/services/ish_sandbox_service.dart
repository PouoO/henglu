import 'package:flutter/services.dart';

class IshSandboxService {
  static const MethodChannel _channel = MethodChannel('ish_sandbox');
  static const IshSandboxService instance = IshSandboxService._();

  const IshSandboxService._();

  Future<bool> boot() async {
    final result = await _channel.invokeMethod<bool>('boot');
    return result ?? false;
  }

  Future<bool> get isBooted async {
    final result = await _channel.invokeMethod<bool>('isBooted');
    return result ?? false;
  }

  /// Execute a shell command in the iSH sandbox.
  /// Returns the guest PID, or a negative value on failure.
  Future<int> execute(String command) async {
    final result = await _channel.invokeMethod<int>('execute', command);
    return result ?? -1;
  }
}
