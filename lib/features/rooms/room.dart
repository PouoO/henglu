import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// 房间/工作区模型。
///
/// 不改动 Conversation 数据库，只是把一组对话 ID 归到一个房间里。
/// 房间可以有自己的名字和颜色，用来在主页做分组过滤。
class Room {
  final String id;
  String name;
  int colorValue;
  final List<String> conversationIds;
  final DateTime createdAt;
  DateTime updatedAt;

  Room({
    String? id,
    required this.name,
    this.colorValue = 0xFF4D5C92,
    List<String>? conversationIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        conversationIds = conversationIds ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Color get color => Color(colorValue);

  Room copyWith({
    String? name,
    int? colorValue,
    List<String>? conversationIds,
  }) {
    return Room(
      id: id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      conversationIds: conversationIds ?? List.unmodifiable(this.conversationIds),
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'colorValue': colorValue,
        'conversationIds': conversationIds,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'] as String,
      name: json['name'] as String,
      colorValue: json['colorValue'] as int? ?? 0xFF4D5C92,
      conversationIds:
          (json['conversationIds'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
