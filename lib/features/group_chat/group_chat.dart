import 'dart:convert';

/// 群聊配置。
///
/// 不改动 Conversation 数据库，把“一个对话有哪些 assistant 成员”
/// 存在 SharedPreferences 里。
class GroupChat {
  final String conversationId;
  final String name;
  final List<String> assistantIds;

  GroupChat({
    required this.conversationId,
    required this.name,
    this.assistantIds = const [],
  });

  GroupChat copyWith({
    String? name,
    List<String>? assistantIds,
  }) {
    return GroupChat(
      conversationId: conversationId,
      name: name ?? this.name,
      assistantIds: assistantIds ?? this.assistantIds,
    );
  }

  Map<String, dynamic> toJson() => {
        'conversationId': conversationId,
        'name': name,
        'assistantIds': assistantIds,
      };

  factory GroupChat.fromJson(Map<String, dynamic> json) {
    return GroupChat(
      conversationId: json['conversationId'] as String,
      name: json['name'] as String,
      assistantIds:
          (json['assistantIds'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }
}
