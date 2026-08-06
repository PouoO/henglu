import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../room_store.dart';
import '../room.dart';
import '../../../theme/app_font_weights.dart';

/// 房间筛选栏。
///
/// 显示“全部”和每个房间，当前选中的房间高亮。
/// 用于主页侧边栏的会话列表上方。
class RoomFilterBar extends StatelessWidget {
  const RoomFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final roomStore = context.watch<RoomStore>();
    final rooms = roomStore.rooms;
    final selectedId = roomStore.selectedRoomId;
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        children: [
          _Chip(
            label: '全部',
            color: cs.primary,
            selected: selectedId == null,
            onTap: () => roomStore.selectRoom(null),
          ),
          for (final room in rooms)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _Chip(
                label: room.name,
                color: room.color,
                selected: selectedId == room.id,
                onTap: () => roomStore.selectRoom(room.id),
              ),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = selected ? color.withValues(alpha: 0.15) : cs.surface.withValues(alpha: 0.5);
    final border = selected ? color.withValues(alpha: 0.4) : cs.outlineVariant.withValues(alpha: 0.12);
    final fg = selected ? color : cs.onSurface;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: border, width: 0.8),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? AppFontWeights.semibold : AppFontWeights.medium,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}
