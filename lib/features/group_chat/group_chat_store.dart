import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'group_chat.dart';

/// 群聊配置存储。
///
/// key: `group_chats_v1`
/// value: List<GroupChat> 的 JSON
class GroupChatStore extends ChangeNotifier {
  static const String _key = 'group_chats_v1';

  List<GroupChat> _groups = [];
  List<GroupChat> get groups => _groups;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      final list = jsonDecode(raw) as List<dynamic>;
      _groups = list
          .map((e) => GroupChat.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(_groups.map((g) => g.toJson()).toList()),
    );
  }

  GroupChat? forConversation(String conversationId) {
    try {
      return _groups.firstWhere((g) => g.conversationId == conversationId);
    } catch (_) {
      return null;
    }
  }

  Future<GroupChat> createOrUpdate({
    required String conversationId,
    String? name,
    List<String>? assistantIds,
  }) async {
    final idx = _groups.indexWhere((g) => g.conversationId == conversationId);
    final existing = idx >= 0 ? _groups[idx] : null;
    final group = GroupChat(
      conversationId: conversationId,
      name: name ?? existing?.name ?? '群聊',
      assistantIds: assistantIds ?? existing?.assistantIds ?? [],
    );
    if (existing != null) {
      _groups[idx] = group;
    } else {
      _groups.add(group);
    }
    await _persist();
    notifyListeners();
    return group;
  }

  Future<void> delete(String conversationId) async {
    _groups.removeWhere((g) => g.conversationId == conversationId);
    await _persist();
    notifyListeners();
  }
}
