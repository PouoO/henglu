import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../theme/custom_theme.dart';
import '../../../theme/custom_theme_store.dart';
import '../../../theme/theme_factory.dart';
import '../../../core/services/haptics.dart';
import '../../../icons/lucide_adapter.dart';
import '../services/ai_theme_service.dart';
import 'custom_theme_editor_page.dart';

class AiThemeGeneratorPage extends StatefulWidget {
  const AiThemeGeneratorPage({super.key});

  @override
  State<AiThemeGeneratorPage> createState() => _AiThemeGeneratorPageState();
}

class _AiThemeGeneratorPageState extends State<AiThemeGeneratorPage> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final prompt = _controller.text.trim();
    if (prompt.isEmpty) return;
    final settings = context.read<SettingsProvider>();
    final providerKey = settings.currentModelProvider;
    final modelId = settings.currentModelId;
    if (providerKey == null || modelId == null) {
      setState(() => _error = '请先在设置中配置并选中一个模型');
      return;
    }
    final config = settings.getProviderConfig(providerKey);
    if (config == null) {
      setState(() => _error = '找不到当前 provider 配置');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final theme = await AiThemeService.generateTheme(
        prompt: prompt,
        config: config,
        modelId: modelId,
      );
      if (!mounted) return;
      final store = context.read<CustomThemeStore>();
      store.tryOn(theme);
      Haptics.soft();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const CustomThemeEditorPage()),
      );
    } on AiThemeException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = '生成失败: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 生成主题'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '用一句话描述你想要的视觉风格，\nAI 会帮你生成一套浅色 + 深色主题。',
            style: TextStyle(
              fontSize: 14,
              color: cs.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            maxLines: 2,
            minLines: 1,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _generate(),
            decoration: InputDecoration(
              hintText: '例如：奶霜莓粉、深夜赛博、纸感书房、薄荷苏打...',
              filled: true,
              fillColor: cs.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            style: TextStyle(color: cs.onSurface),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: _loading ? null : _generate,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('生成主题'),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _error!,
                style: TextStyle(color: cs.onErrorContainer, fontSize: 13),
              ),
            ),
          ],
          const SizedBox(height: 24),
          _quickPrompts(),
        ],
      ),
    );
  }

  Widget _quickPrompts() {
    final cs = Theme.of(context).colorScheme;
    final prompts = <String>[
      '奶霜莓粉',
      '深夜赛博',
      '纸感书房',
      '薄荷苏打',
      '暖橙日落',
      '冷松晨雾',
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: prompts.map((p) {
        return ActionChip(
          label: Text(p),
          onPressed: () {
            _controller.text = p;
            _generate();
          },
          backgroundColor: cs.surface,
          side: BorderSide.none,
        );
      }).toList(),
    );
  }
}
