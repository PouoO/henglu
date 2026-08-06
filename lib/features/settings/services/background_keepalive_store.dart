import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/ios_background_keepalive.dart';

/// 后台保活开关状态。
///
/// 与具体业务无关，只负责：
/// - 持久化用户是否开启
/// - 切换时启动/停止无声音频
class BackgroundKeepAliveStore extends ChangeNotifier {
  static const String _key = 'background_keep_alive_enabled_v1';

  bool _enabled = false;
  bool get enabled => _enabled;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_key) ?? false;
    notifyListeners();
    if (_enabled) {
      await IosBackgroundKeepAlive().start();
    }
  }

  Future<void> setEnabled(bool value) async {
    if (_enabled == value) return;
    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
    notifyListeners();
    await IosBackgroundKeepAlive().setEnabled(value);
  }
}
