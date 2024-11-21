enum ActivityType {
  comment,    // Bình luận mới
  rating,     // Đánh giá mới
  favorite,   // Yêu thích phòng
  roomStatus, // Trạng thái phòng thay đổi
}

class ActivityModel {
  final String id;
  final String userId;
  final String roomId;
  final ActivityType type;
  final String content;
  final DateTime createdAt;
  final bool isRead;
  final String? roomTitle;
  final String? roomImage;

  ActivityModel({
    required this.id,
    required this.userId,
    required this.roomId,
    required this.type,
    required this.content,
    required this.createdAt,
    this.isRead = false,
    this.roomTitle,
    this.roomImage,
  });

  factory ActivityModel.fromMap(Map<String, dynamic> map, String id) {
    return ActivityModel(
      id: id,
      userId: map['userId'] ?? '',
      roomId: map['roomId'] ?? '',
      type: ActivityType.values[map['type'] ?? 0],
      content: map['content'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      isRead: map['isRead'] ?? false,
      roomTitle: map['roomTitle'],
      roomImage: map['roomImage'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'roomId': roomId,
      'type': type.index,
      'content': content,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isRead': isRead,
      'roomTitle': roomTitle,
      'roomImage': roomImage,
    };
  }
} 