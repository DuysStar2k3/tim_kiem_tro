class CommentModel {
  final String id;
  final String roomId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final String? userAvatar;
  final String? userName;
  final String? parentId;
  final List<String> likes;
  final List<CommentModel> replies;

  CommentModel({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.userAvatar,
    this.userName,
    this.parentId,
    this.likes = const [],
    this.replies = const [],
  });

  factory CommentModel.fromMap(Map<String, dynamic> map, String id) {
    return CommentModel(
      id: id,
      roomId: map['roomId'] ?? '',
      userId: map['userId'] ?? '',
      content: map['content'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      userAvatar: map['userAvatar'],
      userName: map['userName'],
      parentId: map['parentId'],
      likes: List<String>.from(map['likes'] ?? []),
      replies: (map['replies'] as List<dynamic>? ?? [])
          .map((reply) => CommentModel.fromMap(reply, reply['id']))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'userId': userId,
      'content': content,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'userAvatar': userAvatar,
      'userName': userName,
      'parentId': parentId,
      'likes': likes,
      'replies': replies.map((reply) => reply.toMap()).toList(),
    };
  }
} 