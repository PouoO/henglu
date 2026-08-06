import 'package:flutter/material.dart';
import 'dart:convert';

/// 聊天界面视觉扩展主题。
///
/// 让主题不只停留在 Material ColorScheme，还能细调聊天页里
/// 气泡、顶栏、输入区、头像等视觉元素。灵感来自 Polaris 的 theme CSS。
@immutable
class ChatTheme extends ThemeExtension<ChatTheme> {
  final Color userBubbleColor;
  final Color userBubbleTextColor;
  final Color assistantBubbleColor;
  final Color assistantBubbleTextColor;
  final Color inputBarColor;
  final Color topBarColor;
  final Color? backgroundColor;
  final double messageBorderRadius;
  final double messageSmallRadius;
  final double avatarRadius;
  final double messageSpacing;
  final Color userAvatarFrameColor;
  final Color assistantAvatarFrameColor;

  const ChatTheme({
    required this.userBubbleColor,
    required this.userBubbleTextColor,
    required this.assistantBubbleColor,
    required this.assistantBubbleTextColor,
    required this.inputBarColor,
    required this.topBarColor,
    this.backgroundColor,
    this.messageBorderRadius = 18,
    this.messageSmallRadius = 4,
    this.avatarRadius = 16,
    this.messageSpacing = 8,
    required this.userAvatarFrameColor,
    required this.assistantAvatarFrameColor,
  });

  /// 从 ColorScheme 派生一套默认聊天主题
  factory ChatTheme.fromColorScheme(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    return ChatTheme(
      userBubbleColor: scheme.primary,
      userBubbleTextColor: scheme.onPrimary,
      assistantBubbleColor: isDark ? scheme.surface.withValues(alpha: 0.3) : scheme.surface,
      assistantBubbleTextColor: scheme.onSurface,
      inputBarColor: scheme.surface,
      topBarColor: scheme.surface,
      backgroundColor: null,
      userAvatarFrameColor: scheme.primary,
      assistantAvatarFrameColor: scheme.secondary,
    );
  }

  ChatTheme copyWith({
    Color? userBubbleColor,
    Color? userBubbleTextColor,
    Color? assistantBubbleColor,
    Color? assistantBubbleTextColor,
    Color? inputBarColor,
    Color? topBarColor,
    Color? backgroundColor,
    double? messageBorderRadius,
    double? messageSmallRadius,
    double? avatarRadius,
    double? messageSpacing,
    Color? userAvatarFrameColor,
    Color? assistantAvatarFrameColor,
  }) {
    return ChatTheme(
      userBubbleColor: userBubbleColor ?? this.userBubbleColor,
      userBubbleTextColor: userBubbleTextColor ?? this.userBubbleTextColor,
      assistantBubbleColor: assistantBubbleColor ?? this.assistantBubbleColor,
      assistantBubbleTextColor: assistantBubbleTextColor ?? this.assistantBubbleTextColor,
      inputBarColor: inputBarColor ?? this.inputBarColor,
      topBarColor: topBarColor ?? this.topBarColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      messageBorderRadius: messageBorderRadius ?? this.messageBorderRadius,
      messageSmallRadius: messageSmallRadius ?? this.messageSmallRadius,
      avatarRadius: avatarRadius ?? this.avatarRadius,
      messageSpacing: messageSpacing ?? this.messageSpacing,
      userAvatarFrameColor: userAvatarFrameColor ?? this.userAvatarFrameColor,
      assistantAvatarFrameColor: assistantAvatarFrameColor ?? this.assistantAvatarFrameColor,
    );
  }

  @override
  ChatTheme copyWithLerp(ChatTheme? other, double t) {
    if (other == null) return this;
    return ChatTheme(
      userBubbleColor: Color.lerp(userBubbleColor, other.userBubbleColor, t)!,
      userBubbleTextColor: Color.lerp(userBubbleTextColor, other.userBubbleTextColor, t)!,
      assistantBubbleColor: Color.lerp(assistantBubbleColor, other.assistantBubbleColor, t)!,
      assistantBubbleTextColor: Color.lerp(assistantBubbleTextColor, other.assistantBubbleTextColor, t)!,
      inputBarColor: Color.lerp(inputBarColor, other.inputBarColor, t)!,
      topBarColor: Color.lerp(topBarColor, other.topBarColor, t)!,
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t),
      messageBorderRadius: lerpDouble(messageBorderRadius, other.messageBorderRadius, t)!,
      messageSmallRadius: lerpDouble(messageSmallRadius, other.messageSmallRadius, t)!,
      avatarRadius: lerpDouble(avatarRadius, other.avatarRadius, t)!,
      messageSpacing: lerpDouble(messageSpacing, other.messageSpacing, t)!,
      userAvatarFrameColor: Color.lerp(userAvatarFrameColor, other.userAvatarFrameColor, t)!,
      assistantAvatarFrameColor: Color.lerp(assistantAvatarFrameColor, other.assistantAvatarFrameColor, t)!,
    );
  }

  @override
  ChatTheme lerp(ChatTheme? other, double t) => copyWithLerp(other, t);

  Map<String, dynamic> toJson() => {
        'userBubbleColor': userBubbleColor.value,
        'userBubbleTextColor': userBubbleTextColor.value,
        'assistantBubbleColor': assistantBubbleColor.value,
        'assistantBubbleTextColor': assistantBubbleTextColor.value,
        'inputBarColor': inputBarColor.value,
        'topBarColor': topBarColor.value,
        'backgroundColor': backgroundColor?.value,
        'messageBorderRadius': messageBorderRadius,
        'messageSmallRadius': messageSmallRadius,
        'avatarRadius': avatarRadius,
        'messageSpacing': messageSpacing,
        'userAvatarFrameColor': userAvatarFrameColor.value,
        'assistantAvatarFrameColor': assistantAvatarFrameColor.value,
      };

  static ChatTheme fromJson(Map<String, dynamic> json) {
    return ChatTheme(
      userBubbleColor: Color(json['userBubbleColor'] as int),
      userBubbleTextColor: Color(json['userBubbleTextColor'] as int),
      assistantBubbleColor: Color(json['assistantBubbleColor'] as int),
      assistantBubbleTextColor: Color(json['assistantBubbleTextColor'] as int),
      inputBarColor: Color(json['inputBarColor'] as int),
      topBarColor: Color(json['topBarColor'] as int),
      backgroundColor: json['backgroundColor'] == null
          ? null
          : Color(json['backgroundColor'] as int),
      messageBorderRadius: (json['messageBorderRadius'] as num).toDouble(),
      messageSmallRadius: (json['messageSmallRadius'] as num).toDouble(),
      avatarRadius: (json['avatarRadius'] as num).toDouble(),
      messageSpacing: (json['messageSpacing'] as num).toDouble(),
      userAvatarFrameColor: Color(json['userAvatarFrameColor'] as int),
      assistantAvatarFrameColor: Color(json['assistantAvatarFrameColor'] as int),
    );
  }
}
