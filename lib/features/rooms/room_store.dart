import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'room.dart';

/// 房间/工作区存储。
///
/// 管理房间列表、当前选中房间、以及房间与对话的映射。
/// 所有数据存在 SharedPreferences，不改动 Drift 数据库。
class RoomStore extends ChangeNotifier {
  static const String _roomsKey = 'rooms_v1';
  static const String _activeKey = 'active_room_id_v1';

  final List<Room> _rooms = [];
  String? _activeId;

  List<Room> get rooms => List.unmodifiable(_rooms);
  String? get activeId => _activeId;

  Room? get activeRoom {
    if (_activeId == null) return null;
    try {
      return _rooms.firstWhere((r) => r.id == _activeId);
    } catch (_) {
      return null;
    }
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_roomsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        _rooms.clear();
        _rooms.addAll(list.map((e) => Room.fromJson(e as Map<String, dynamic>)));
      } catch (_) {}
    }
    _activeId = prefs.getString(_activeKey);
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _roomsKey,
      jsonEncode(_rooms.map((r) => r.toJson()).toList()),
    );
    if (_activeId != null) {
      await prefs.setString(_activeKey, _activeId!);
    } else {
      await prefs.remove(_activeKey);
    }
  }

  Future<Room> create({
    required String name,
    int? colorValue,
  }) async {
    final room = Room(
      name: name,
      colorValue: colorValue ?? 0xFF4D5C92,
    );
    _rooms.add(room);
    await _persist();
    notifyListeners();
    return room;
  }

  Future<void> update(Room room) async {
    final idx = _rooms.indexWhere((r) => r.id == room.id);
    if (idx >= 0) {
      _rooms[idx] = room;
      await _persist();
      notifyListeners();
    }
  }

  Future<void> delete(String id) async {
    _rooms.removeWhere((r) => r.id == id);
    if (_activeId == id) {
      _activeId = _rooms.isNotEmpty ? _rooms.first.id : null;
    }
    await _persist();
    notifyListeners();
  }

  Future<void> setActive(String? id) async {
    _activeId = id;
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove(_activeKey);
    } else {
      await prefs.setString(_activeKey, id);
    }
    notifyListeners();
  }

  /// 把对话移动到某个房间（先从所有房间移除，再加到目标房间）
  Future<void> moveConversationToRoom(String roomId, String conversationId) async {
    for (final room in _rooms) {
      if (room.conversationIds.contains(conversationId)) {
        final newIds = room.conversationIds.where((id) => id != conversationId).toList();
        await update(room.copyWith(conversationIds: newIds));
      }
    }
    await addConversation(roomId, conversationId);
  }

  /// 把对话 ID 加到某个房间
  Future<void> addConversation(String roomId, String conversationId) async {
    final idx = _rooms.indexWhere((r) => r.id == roomId);
    if (idx < 0) return;
    final room = _rooms[idx];
    if (room.conversationIds.contains(conversationId)) return;
    final newIds = [...room.conversationIds, conversationId];
    _rooms[idx] = room.copyWith(conversationIds: newIds);
    await _persist();
    notifyListeners();
  }

  /// 从某个房间移除对话 ID
  Future<void> removeConversation(String roomId, String conversationId) async {
    final idx = _rooms.indexWhere((r) => r.id == roomId);
    if (idx < 0) return;
    final room = _rooms[idx];
    final newIds = room.conversationIds.where((id) => id != conversationId).toList();
    _rooms[idx] = room.copyWith(conversationIds: newIds);
    await _persist();
    notifyListeners();
  }

  /// 查询对话属于哪些房间（理论上可以属于多个，但通常只归一个）
  List<Room> roomsOf(String conversationId) {
    return _rooms.where((r) => r.conversationIds.contains(conversationId)).toList();
  }
}
