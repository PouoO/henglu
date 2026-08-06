import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/assistant_provider.dart';
import '../../../icons/lucide_adapter.dart';
import '../../../theme/app_font_weights.dart';
import '../group_chat_store.dart';

/// 群聊管理页。
///
/// 给当前对话添加/移除 assistant 成员。
class GroupChatPage extends StatefulWidget {
  final String conversationId;

  const GroupChatPage({super.key, required this.conversationId});

  @override
  State<GroupChatPage> createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  late TextEditingController _nameCtl;

  @override
  void initState() {
    super.initState();
    final store = context.read<GroupChatStore>();
    final group = store.forConversation(widget.conversationId);
    _nameCtl = TextEditingController(text: group?.name ?? '群聊');
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final store = context.read<GroupChatStore>();
    await store.createOrUpdate(
      conversationId: widget.conversationId,
      name: _nameCtl.text.trim().isNotEmpty ? _nameCtl.text.trim() : '群聊',
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final store = context.watch<GroupChatStore>();
    final group = store.forConversation(widget.conversationId);
    final memberIds = group?.assistantIds ?? [];
    final assistantProvider = context.watch<AssistantProvider>();
    final assistants = assistantProvider.assistants;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        title: const Text('群聊成员'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameCtl,
            decoration: const InputDecoration(
              labelText: '群聊名称',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Text('成员', style: TextStyle(fontSize: 15, fontWeight: AppFontWeights.semibold)),
          const SizedBox(height: 8),
          if (assistants.isEmpty) const Text('没有可用的 assistant'),
          ...assistants.map((a) {
            final isMember = memberIds.contains(a.id);
            return CheckboxListTile(
              value: isMember,
              onChanged: (v) async {
                final ids = memberIds.toList();
                if (v == true) {
                  if (!ids.contains(a.id)) ids.add(a.id);
                } else {
                  ids.remove(a.id);
                }
                await store.createOrUpdate(
                  conversationId: widget.conversationId,
                  name: _nameCtl.text.trim().isNotEmpty ? _nameCtl.text.trim() : '群聊',
                  assistantIds: ids,
                );
              },
              title: Text(a.name),
              secondary: a.avatar != null && a.avatar!.isNotEmpty
                  ? const Icon(Lucide.Bot, size: 20)
                  : null,
            );
          }),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Lucide.Check),
            label: const Text('保存'),
          ),
        ),
      ),
    );
  }
}
