import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../room_store.dart';
import '../room.dart';
import '../../../icons/lucide_adapter.dart';
import '../../../theme/app_font_weights.dart';

/// 房间/工作区管理页。
///
/// 可以新建、编辑、删除房间。
class RoomsPage extends StatelessWidget {
  const RoomsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final store = context.watch<RoomStore>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('房间 / 工作区'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: store.rooms.length + 1,
        itemBuilder: (context, index) {
          if (index == store.rooms.length) {
            return _buildAddButton(context, cs);
          }
          final room = store.rooms[index];
          return _RoomCard(
            room: room,
            onTap: () => _showEditDialog(context, room),
            onLongPress: () => _confirmDelete(context, room),
          );
        },
      ),
    );
  }

  Widget _buildAddButton(BuildContext context, ColorScheme cs) {
    return Card(
      child: ListTile(
        leading: Icon(Lucide.Plus, color: cs.primary),
        title: const Text('新建房间'),
        onTap: () => _showAddDialog(context),
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('新建房间'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: '房间名'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  final color = _randomColor();
                  await context.read<RoomStore>().create(
                        name: name,
                        colorValue: color,
                      );
                }
                if (context.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('创建'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditDialog(BuildContext context, Room room) async {
    final controller = TextEditingController(text: room.name);
    return showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('编辑房间'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: '房间名'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  await context.read<RoomStore>().update(room.copyWith(name: name));
                }
                if (context.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, Room room) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除房间'),
        content: Text('删除「${room.name}」？其中的对话不会被删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              await context.read<RoomStore>().delete(room.id);
              if (context.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  int _randomColor() {
    final colors = [
      0xFF4D5C92,
      0xFF75546F,
      0xFF8E6E53,
      0xFF6B8E23,
      0xFF4682B4,
      0xFFD2691E,
    ];
    return colors[Random().nextInt(colors.length)];
  }
}

class _RoomCard extends StatelessWidget {
  final Room room;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _RoomCard({
    required this.room,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: room.color,
          child: Text(
            room.name.isNotEmpty ? room.name.substring(0, 1) : '?',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(room.name),
        subtitle: Text('${room.conversationIds.length} 个对话'),
        trailing: Icon(Lucide.ChevronRight, size: 18, color: cs.onSurface.withValues(alpha: 0.3)),
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}
