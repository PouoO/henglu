import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:audio_session/audio_session.dart' as asession;
import 'package:flutter/services.dart';

/// 通用后台保活服务。
///
/// 通过循环播放一段无声音频，让 iOS 在后台时不立即挂起 app，
/// 从而保持 long polling / WebSocket / 蓝牙连接等网络链路存活。
///
/// 不含任何业务逻辑或敏感信息，所有开关由用户控制，
/// 默认关闭，避免不必要耗电。
class IosBackgroundKeepAlive {
  static final IosBackgroundKeepAlive _instance = IosBackgroundKeepAlive._();
  factory IosBackgroundKeepAlive() => _instance;
  IosBackgroundKeepAlive._();

  AudioPlayer? _player;
  bool _initialized = false;
  bool _playing = false;

  bool get isPlaying => _playing;

  /// 初始化音频会话。应用启动时调用一次即可。
  Future<void> initialize() async {
    if (!kIsWeb && Platform.isIOS) {
      final session = await asession.AudioSession.instance;
      await session.configure(const asession.AudioSessionConfiguration(
        avAudioSessionCategory: asession.AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions: asession.AVAudioSessionCategoryOptions.mixWithOthers,
        avAudioSessionMode: asession.AVAudioSessionMode.defaultMode,
      ));
      _initialized = true;
    }
  }

  /// 开始后台保活。
  Future<void> start() async {
    if (_playing) return;
    if (kIsWeb || !Platform.isIOS) return;

    try {
      if (!_initialized) await initialize();

      _player?.dispose();
      final player = AudioPlayer();
      _player = player;

      // 循环播放无声音频
      await player.setReleaseMode(ReleaseMode.loop);
      await player.play(AssetSource('silence.mp3'), volume: 0.0);
      _playing = true;
    } catch (e) {
      debugPrint('[IosBackgroundKeepAlive] start error: $e');
    }
  }

  /// 停止后台保活。
  Future<void> stop() async {
    if (!_playing) return;
    try {
      await _player?.stop();
      _player?.dispose();
      _player = null;
      _playing = false;
    } catch (e) {
      debugPrint('[IosBackgroundKeepAlive] stop error: $e');
    }
  }

  /// 切换开关。
  Future<void> setEnabled(bool enabled) async {
    if (enabled) {
      await start();
    } else {
      await stop();
    }
  }
}
