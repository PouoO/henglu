import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/services/api/chat_api_service.dart';
import '../../../theme/custom_theme.dart';

/// AI 主题生成服务。
///
/// 调用用户当前配置的 LLM 提供商，把自然语言描述转成一套
/// CustomColorScheme（浅色 + 深色），并包装成 CustomTheme。
/// 不硬写任何密钥或 endpoint，全部复用 Kelivo 现有的 provider 配置。
class AiThemeService {
  /// 从描述生成主题。
  ///
  /// [prompt] 可以是 "奶霜莓粉"、"深夜赛博" 等描述。
  /// [config] / [modelId] 取当前选中的 provider。
  static Future<CustomTheme> generateTheme({
    required String prompt,
    required ProviderConfig config,
    required String modelId,
  }) async {
    final instruction = _buildPrompt(prompt);
    final response = await ChatApiService.generateText(
      config: config,
      modelId: modelId,
      prompt: instruction,
    );

    final jsonStr = _extractJson(response);
    if (jsonStr == null || jsonStr.isEmpty) {
      throw const AiThemeException('模型没有返回可用的 JSON 主题');
    }

    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return _parseTheme(map, name: prompt.trim());
  }

  static String _buildPrompt(String userPrompt) {
    return '''
你是一个 Material Design 3 配色助手。请根据下面的描述，生成一套适合聊天应用的浅色/深色 ColorScheme。

要求：
1. 只返回合法的 JSON，不要 Markdown、不要解释。
2. JSON 结构如下（所有颜色都是 0xFFRRGGBB 格式的整数）：
{
  "light": {
    "primary": 0xFF4D5C92,
    "onPrimary": 0xFFFFFFFF,
    "primaryContainer": 0xFFDCE1FF,
    "onPrimaryContainer": 0xFF03174B,
    "secondary": 0xFF595D72,
    "onSecondary": 0xFFFFFFFF,
    "secondaryContainer": 0xFFDEE1F9,
    "onSecondaryContainer": 0xFF161B2C,
    "tertiary": 0xFF75546F,
    "onTertiary": 0xFFFFFFFF,
    "tertiaryContainer": 0xFFFFD7F6,
    "onTertiaryContainer": 0xFF2C122A,
    "surface": 0xFFF7F7F7,
    "onSurface": 0xFF202020,
    "onSurfaceVariant": 0xFF646464,
    "outline": 0x1A000000,
    "outlineVariant": 0xFF000000,
    "inverseSurface": 0xFF121213,
    "onInverseSurface": 0xFFF9F9F9,
    "inversePrimary": 0xFF4D5C92
  },
  "dark": {
    "primary": 0xFFB6C4FF,
    ...同上
  }
}
3. 颜色必须对比度合适，可读性优先。
4. 主题名称直接取用户描述的首句。

用户描述：$userPrompt
'.trim();
  }

  static String? _extractJson(String text) {
    final trimmed = text.trim();
    // 优先提取 ```json ... ``` 代码块
    final codeBlock = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```', caseSensitive: false);
    final match = codeBlock.firstMatch(trimmed);
    if (match != null) {
      final inner = match.group(1)!.trim();
      if (inner.startsWith('{')) return inner;
    }
    // 否则直接找第一个 { ... }
    final start = trimmed.indexOf('{');
    final end = trimmed.lastIndexOf('}');
    if (start != -1 && end != -1 && end > start) {
      return trimmed.substring(start, end + 1);
    }
    return null;
  }

  static CustomTheme _parseTheme(Map<String, dynamic> map, {required String name}) {
    final lightMap = map['light'] as Map<String, dynamic>?;
    final darkMap = map['dark'] as Map<String, dynamic>?;
    if (lightMap == null || darkMap == null) {
      throw const AiThemeException('JSON 缺少 light 或 dark 字段');
    }
    final light = _parseColorScheme(lightMap);
    final dark = _parseColorScheme(darkMap);
    return CustomTheme.create(
      name: name.isNotEmpty ? name : 'AI 主题',
      light: light,
      dark: dark,
    );
  }

  static CustomColorScheme _parseColorScheme(Map<String, dynamic> map) {
    final fields = <String, int>{};
    for (final key in _requiredFields) {
      final value = map[key];
      if (value == null) {
        throw AiThemeException('缺少颜色字段: $key');
      }
      if (value is int) {
        fields[key] = value;
      } else if (value is String) {
        final parsed = int.tryParse(value.replaceAll('0x', '').replaceAll('#', ''), radix: 16);
        if (parsed == null) {
          throw AiThemeException('颜色字段格式错误: $key = $value');
        }
        // 如果用户写 RRGGBB（不带 alpha），补 FF
        fields[key] = parsed | 0xFF000000;
      } else {
        throw AiThemeException('颜色字段类型错误: $key');
      }
    }
    return CustomColorScheme.fromJson(fields);
  }

  static const List<String> _requiredFields = <String>[
    'primary',
    'onPrimary',
    'primaryContainer',
    'onPrimaryContainer',
    'secondary',
    'onSecondary',
    'secondaryContainer',
    'onSecondaryContainer',
    'tertiary',
    'onTertiary',
    'tertiaryContainer',
    'onTertiaryContainer',
    'surface',
    'onSurface',
    'onSurfaceVariant',
    'outline',
    'outlineVariant',
    'inverseSurface',
    'onInverseSurface',
    'inversePrimary',
  ];
}

class AiThemeException implements Exception {
  final String message;
  const AiThemeException(this.message);
  @override
  String toString() => message;
}
