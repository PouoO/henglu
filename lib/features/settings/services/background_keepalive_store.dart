import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/ios_background_keepalive.dart';
import '../../../core/services/android_background.dart';

/// 后台保活开关状态。
///
/// 与具体业务无关，只负责：
/// - 持久化用户是否开启
/// - iOS 用无声音频，Android 用 foreground service
class BackgroundKeepAliveStore extends ChangeNotifier {
  static const String _key = 'background_keep_alive_enabled_v1';

  bool _enabled = false;
  bool get enabled => _enabled;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_key) ?? false;
    notifyListeners();
    if (_enabled) {
      await _apply(true);
    }
  }

  Future<void> setEnabled(bool value) async {
    if (_enabled == value) return;
    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
    notifyListeners();
    await _apply(value);
  }

  Future<void> _apply(bool enabled) async {
    if (kIsWeb) return;
    if (Platform.isIOS) {
      await IosBackgroundKeepAlive().setEnabled(enabled);
    } else if (Platform.isAndroid) {
      await AndroidBackgroundManager.setEnabled(enabled);
    }
  }
}
