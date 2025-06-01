class UserChatModel {
  final String name;
  final String lastMessage;
  final DateTime time;
  final int unreadCount;
  final String avatar;
  final bool isOnline;
  final bool isGroup;

  UserChatModel({
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.unreadCount,
    required this.avatar,
    this.isOnline = false,
    this.isGroup = false,
  });
}