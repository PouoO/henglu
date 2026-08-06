import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/chat_theme.dart';
import '../../../theme/custom_theme_store.dart';
import '../../../theme/custom_theme.dart';
import '../../../icons/lucide_adapter.dart';
import '../../../theme/app_font_weights.dart';

/// 聊天界面主题编辑器。
///
/// 让用户手动调整聊天气泡、顶栏、输入区、头像框等视觉 token，
/// 顶部实时预览，底部保存后生效。
class ChatThemeEditorPage extends StatelessWidget {
  const ChatThemeEditorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final store = context.watch<CustomThemeStore>();
    final isLight = Theme.of(context).brightness == Brightness.light;
    final theme = store.tryingOn ?? store.currentTheme;
    final chatTheme = isLight
        ? theme?.lightChatTheme
        : theme?.darkChatTheme;
    if (chatTheme == null) {
      return const Scaffold(body: Center(child: Text('暂无聊天主题')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('聊天界面主题')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _PreviewCard(chatTheme: chatTheme),
          const SizedBox(height: 16),
          _buildSectionTitle('颜色'),
          _ColorTile(
            label: '我的气泡',
            color: chatTheme.userBubbleColor,
            onChanged: (c) => store.updateTryingChatTheme(
              isLight,
              (t) => t.copyWith(userBubbleColor: c, userBubbleTextColor: _textFor(c)),
            ),
          ),
          _ColorTile(
            label: 'AI 气泡',
            color: chatTheme.assistantBubbleColor,
            onChanged: (c) => store.updateTryingChatTheme(
              isLight,
              (t) => t.copyWith(assistantBubbleColor: c, assistantBubbleTextColor: _textFor(c)),
            ),
          ),
          _ColorTile(
            label: '输入栏',
            color: chatTheme.inputBarColor,
            onChanged: (c) => store.updateTryingChatTheme(
              isLight,
              (t) => t.copyWith(inputBarColor: c),
            ),
          ),
          _ColorTile(
            label: '顶栏',
            color: chatTheme.topBarColor,
            onChanged: (c) => store.updateTryingChatTheme(
              isLight,
              (t) => t.copyWith(topBarColor: c),
            ),
          ),
          _ColorTile(
            label: '背景',
            color: chatTheme.backgroundColor ?? cs.surface,
            onChanged: (c) => store.updateTryingChatTheme(
              isLight,
              (t) => t.copyWith(backgroundColor: c),
            ),
          ),
          _ColorTile(
            label: '我的头像框',
            color: chatTheme.userAvatarFrameColor,
            onChanged: (c) => store.updateTryingChatTheme(
              isLight,
              (t) => t.copyWith(userAvatarFrameColor: c),
            ),
          ),
          _ColorTile(
            label: 'AI 头像框',
            color: chatTheme.assistantAvatarFrameColor,
            onChanged: (c) => store.updateTryingChatTheme(
              isLight,
              (t) => t.copyWith(assistantAvatarFrameColor: c),
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionTitle('形状'),
          _SliderTile(
            label: '气泡圆角',
            value: chatTheme.messageBorderRadius,
            min: 0,
            max: 32,
            onChanged: (v) => store.updateTryingChatTheme(
              isLight,
              (t) => t.copyWith(messageBorderRadius: v),
            ),
          ),
          _SliderTile(
            label: '小圆角',
            value: chatTheme.messageSmallRadius,
            min: 0,
            max: 16,
            onChanged: (v) => store.updateTryingChatTheme(
              isLight,
              (t) => t.copyWith(messageSmallRadius: v),
            ),
          ),
          _SliderTile(
            label: '头像圆角',
            value: chatTheme.avatarRadius,
            min: 0,
            max: 32,
            onChanged: (v) => store.updateTryingChatTheme(
              isLight,
              (t) => t.copyWith(avatarRadius: v),
            ),
          ),
          _SliderTile(
            label: '消息间距',
            value: chatTheme.messageSpacing,
            min: 0,
            max: 24,
            onChanged: (v) => store.updateTryingChatTheme(
              isLight,
              (t) => t.copyWith(messageSpacing: v),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: AppFontWeights.semibold),
      ),
    );
  }

  /// 根据背景色简单判断文字用黑还是白
  static Color _textFor(Color bg) {
    return bg.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }
}

class _PreviewCard extends StatelessWidget {
  final ChatTheme chatTheme;
  const _PreviewCard({required this.chatTheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: chatTheme.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            height: 44,
            color: chatTheme.topBarColor,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Text('预览', style: TextStyle(fontSize: 15, fontWeight: AppFontWeights.semibold)),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _buildMessage(
                  text: '你好呀',
                  isUser: true,
                  color: chatTheme.userBubbleColor,
                  textColor: chatTheme.userBubbleTextColor,
                ),
                SizedBox(height: chatTheme.messageSpacing),
                _buildMessage(
                  text: '我在',
                  isUser: false,
                  color: chatTheme.assistantBubbleColor,
                  textColor: chatTheme.assistantBubbleTextColor,
                ),
              ],
            ),
          ),
          Container(
            height: 48,
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: chatTheme.inputBarColor,
              borderRadius: BorderRadius.circular(chatTheme.messageBorderRadius),
            ),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('输入点什么...', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage({
    required String text,
    required bool isUser,
    required Color color,
    required Color textColor,
  }) {
    return Row(
      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isUser) _buildAvatar(chatTheme.assistantAvatarFrameColor),
        if (!isUser) const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(chatTheme.messageBorderRadius),
          ),
          child: Text(text, style: TextStyle(color: textColor)),
        ),
        if (isUser) const SizedBox(width: 8),
        if (isUser) _buildAvatar(chatTheme.userAvatarFrameColor),
      ],
    );
  }

  Widget _buildAvatar(Color frameColor) {
    return Container(
      width: chatTheme.avatarRadius * 2,
      height: chatTheme.avatarRadius * 2,
      decoration: BoxDecoration(
        color: frameColor,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _ColorTile extends StatelessWidget {
  final String label;
  final Color color;
  final ValueChanged<Color> onChanged;

  const _ColorTile({
    required this.label,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
      ),
      title: Text(label, style: const TextStyle(fontSize: 15)),
      trailing: Icon(Lucide.ChevronRight, size: 18, color: Colors.grey),
      onTap: () => _pickColor(context, color, onChanged),
    );
  }

  void _pickColor(BuildContext context, Color current, ValueChanged<Color> onChanged) {
    final controller = TextEditingController(text: _hex(current));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('输入颜色'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '#FF000000'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('取消')),
          TextButton(
            onPressed: () {
              final c = _parseColor(controller.text);
              if (c != null) onChanged(c);
              Navigator.of(ctx).pop();
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  static String _hex(Color c) =>
      '#${c.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';

  static Color? _parseColor(String text) {
    final clean = text.replaceAll('#', '').replaceAll('0x', '').trim();
    if (clean.length == 6 || clean.length == 8) {
      final value = int.tryParse(clean, radix: 16);
      if (value != null) {
        return Color(clean.length == 6 ? (value | 0xFF000000) : value);
      }
    }
    return null;
  }
}

class _SliderTile extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _SliderTile({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 15)),
            Text(value.toStringAsFixed(1), style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
