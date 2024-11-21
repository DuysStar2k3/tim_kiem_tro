import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/room_model.dart';
import '../models/comment_model.dart';
import '../models/activity_model.dart';

class RoomController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<RoomModel> _rooms = [];
  bool _isLoading = false;
  String? _error;

  List<RoomModel> get rooms => _rooms;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchRooms() async {
    if (_isLoading) return; // Tránh tải lại khi đang tải

    try {
      _isLoading = true;
      notifyListeners();

      final snapshot = await _firestore
          .collection('rooms')
          .orderBy('createdAt', descending: true)
          .get();

      _rooms = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Thêm id vào data
        return RoomModel.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Thêm phương thức lấy phòng đã duyệt
  List<RoomModel> getApprovedRooms() {
    return _rooms.where((room) => room.isApproved).toList();
  }

  // Thêm phương thức lấy phòng theo landlordId
  List<RoomModel> getRoomsByLandlord(String landlordId) {
    return _rooms.where((room) => room.landlordId == landlordId).toList();
  }

  // Phê duyệt phòng
  Future<void> approveRoom(String roomId) async {
    try {
      final room = _rooms.firstWhere((r) => r.id == roomId);
      await _firestore.collection('rooms').doc(roomId).update({
        'isApproved': true,
        'approvedAt': DateTime.now().millisecondsSinceEpoch,
      });

      // Thêm hoạt động cho chủ phòng
      await addActivity(
        userId: room.landlordId,
        roomId: roomId,
        type: ActivityType.roomStatus,
        content: 'Phòng trọ của bạn đã được duyệt',
        roomTitle: room.title,
        roomImage: room.images.isNotEmpty ? room.images.first : null,
      );

      notifyListeners();
    } catch (e) {
      print('Error approving room: $e');
      _error = e.toString();
    }
  }

  // Từ chối phòng
  Future<void> rejectRoom(String roomId, String reason) async {
    try {
      final room = _rooms.firstWhere((r) => r.id == roomId);
      await _firestore.collection('rooms').doc(roomId).update({
        'isRejected': true,
        'rejectionReason': reason,
        'rejectedAt': DateTime.now().millisecondsSinceEpoch,
      });

      // Thêm hoạt động cho chủ phòng
      await addActivity(
        userId: room.landlordId,
        roomId: roomId,
        type: ActivityType.roomStatus,
        content: 'Phòng trọ của bạn đã bị từ chối: $reason',
        roomTitle: room.title,
        roomImage: room.images.isNotEmpty ? room.images.first : null,
      );

      notifyListeners();
    } catch (e) {
      print('Error rejecting room: $e');
      _error = e.toString();
    }
  }

  // Lấy phòng theo ID
  Future<RoomModel?> getRoomById(String roomId) async {
    try {
      final doc = await _firestore.collection('rooms').doc(roomId).get();
      if (doc.exists) {
        return RoomModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Lỗi khi lấy thông tin phòng: $e');
      throw Exception('Không thể lấy thông tin phòng: $e');
    }
  }

  // Thêm phương thức createRoom vào RoomController
  Future<void> createRoom(RoomModel room) async {
    try {
      _isLoading = true;
      notifyListeners();

      final docRef = await _firestore.collection('rooms').add({
        'title': room.title,
        'address': room.address,
        'price': room.price,
        'description': room.description,
        'images': room.images,
        'landlordId': room.landlordId,
        'latitude': room.latitude,
        'longitude': room.longitude,
        'isApproved': false,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'roomType': room.roomType,
        'area': room.area,
        'deposit': room.deposit,
        'phone': room.phone,
        'gender': room.gender,
        'maxTenants': room.maxTenants,
        'hasParking': room.hasParking,
        'hasWifi': room.hasWifi,
        'hasAC': room.hasAC,
        'hasFridge': room.hasFridge,
        'hasWasher': room.hasWasher,
        'hasPrivateBathroom': room.hasPrivateBathroom,
        'hasKitchen': room.hasKitchen,
        'hasFreedom': room.hasFreedom,
        'isRejected': false,
        'rejectionReason': null,
      });

      final newRoom = room.copyWith(id: docRef.id);
      _rooms.add(newRoom);
      
    } catch (e) {
      print('Lỗi khi tạo phòng: $e');
      _error = e.toString();
      throw Exception('Không thể tạo phòng: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> incrementViews(String roomId, String userId) async {
    try {
      // Lấy thông tin phòng hiện tại
      final roomDoc = await _firestore.collection('rooms').doc(roomId).get();
      if (!roomDoc.exists) return;

      final roomData = roomDoc.data()!;
      final List<String> viewedBy = List<String>.from(roomData['viewedBy'] ?? []);

      // Kiểm tra xem người dùng đã xem chưa
      if (!viewedBy.contains(userId)) {
        // Cập nhật Firestore
        await _firestore.collection('rooms').doc(roomId).update({
          'views': FieldValue.increment(1),
          'viewedBy': FieldValue.arrayUnion([userId]),
        });

        // Cập nhật state local
        final index = _rooms.indexWhere((room) => room.id == roomId);
        if (index != -1) {
          final room = _rooms[index];
          _rooms[index] = RoomModel(
            id: room.id,
            title: room.title,
            address: room.address,
            price: room.price,
            description: room.description,
            images: room.images,
            landlordId: room.landlordId,
            latitude: room.latitude,
            longitude: room.longitude,
            isApproved: room.isApproved,
            createdAt: room.createdAt,
            views: room.views + 1,
            viewedBy: [...room.viewedBy, userId],
            // ... các trường khác giữ nguyên
          );
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error incrementing views: $e');
    }
  }

  // Thêm phương thức đánh giá phòng
  Future<void> rateRoom(String roomId, String userId, double rating) async {
    try {
      final room = _rooms.firstWhere((r) => r.id == roomId);
      await _firestore.collection('rooms').doc(roomId).update({
        'rating': rating,
        'ratedBy': FieldValue.arrayUnion([userId]),
      });

      // Thêm hoạt động
      await addActivity(
        userId: userId,
        roomId: roomId,
        type: ActivityType.rating,
        content: 'Bạn đã đánh giá ${rating.toStringAsFixed(1)} sao',
        roomTitle: room.title,
        roomImage: room.images.isNotEmpty ? room.images.first : null,
      );

      notifyListeners();
    } catch (e) {
      print('Error rating room: $e');
      _error = e.toString();
    }
  }

  // Thêm phương thức toggle yêu thích
  Future<void> toggleFavorite(String roomId, String userId) async {
    try {
      final room = _rooms.firstWhere((r) => r.id == roomId);
      final isFavorited = room.favoriteBy.contains(userId);

      await _firestore.collection('rooms').doc(roomId).update({
        'favoriteBy': isFavorited
            ? FieldValue.arrayRemove([userId])
            : FieldValue.arrayUnion([userId]),
      });

      // Thêm hoạt động
      await addActivity(
        userId: userId,
        roomId: roomId,
        type: ActivityType.favorite,
        content: isFavorited 
            ? 'Bạn đã bỏ thích phòng trọ này'
            : 'Bạn đã thích phòng trọ này',
        roomTitle: room.title,
        roomImage: room.images.isNotEmpty ? room.images.first : null,
      );

      notifyListeners();
    } catch (e) {
      print('Error toggling favorite: $e');
      _error = e.toString();
    }
  }

  // Thêm bình luận mới
  Future<void> addRoomComment(
    String roomId,
    String userId,
    String content, {
    String? parentId,
  }) async {
    try {
      final user = await _firestore.collection('users').doc(userId).get();
      final userData = user.data();

      final commentData = {
        'roomId': roomId,
        'userId': userId,
        'content': content,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'userAvatar': userData?['avatar'],
        'userName': userData?['fullName'] ?? 'Người dùng',
        'parentId': parentId,
        'likes': [],
      };

      await _firestore.collection('comments').add(commentData);

      // Thêm hoạt động
      final room = _rooms.firstWhere((r) => r.id == roomId);
      await addActivity(
        userId: userId,
        roomId: roomId,
        type: ActivityType.comment,
        content: 'Bạn đã bình luận: "$content"',
        roomTitle: room.title,
        roomImage: room.images.isNotEmpty ? room.images.first : null,
      );

      notifyListeners();
    } catch (e) {
      print('Error adding comment: $e');
      _error = e.toString();
    }
  }

  // Lấy danh sách bình luận theo roomId
  Stream<List<CommentModel>> getRoomComments(String roomId) {
    return _firestore
        .collection('comments')
        .where('roomId', isEqualTo: roomId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CommentModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Like/Unlike bình luận
  Future<void> toggleCommentLike(String commentId, String userId) async {
    try {
      final commentDoc = await _firestore.collection('comments').doc(commentId).get();
      if (!commentDoc.exists) return;

      final likes = List<String>.from(commentDoc.data()?['likes'] ?? []);
      
      if (likes.contains(userId)) {
        // Unlike
        await _firestore.collection('comments').doc(commentId).update({
          'likes': FieldValue.arrayRemove([userId]),
        });
      } else {
        // Like
        await _firestore.collection('comments').doc(commentId).update({
          'likes': FieldValue.arrayUnion([userId]),
        });
      }
      
      notifyListeners();
    } catch (e) {
      print('Error toggling comment like: $e');
      _error = e.toString();
    }
  }

  // Xóa bình luận
  Future<void> deleteComment(String commentId) async {
    try {
      await _firestore.collection('comments').doc(commentId).delete();
      notifyListeners();
    } catch (e) {
      print('Error deleting comment: $e');
      _error = e.toString();
    }
  }

  // Cập nhật bình luận
  Future<void> updateComment(String commentId, String newContent) async {
    try {
      await _firestore.collection('comments').doc(commentId).update({
        'content': newContent,
        'editedAt': DateTime.now().millisecondsSinceEpoch,
      });
      notifyListeners();
    } catch (e) {
      print('Error updating comment: $e');
      _error = e.toString();
    }
  }

  // Thêm vào RoomController
  Stream<List<ActivityModel>> getUserActivities(String userId) {
    return _firestore
        .collection('activities')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ActivityModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Thêm hoạt động mới
  Future<void> addActivity({
    required String userId,
    required String roomId,
    required ActivityType type,
    required String content,
    String? roomTitle,
    String? roomImage,
  }) async {
    try {
      final activityData = ActivityModel(
        id: '',
        userId: userId,
        roomId: roomId,
        type: type,
        content: content,
        createdAt: DateTime.now(),
        roomTitle: roomTitle,
        roomImage: roomImage,
      ).toMap();

      await _firestore.collection('activities').add(activityData);
    } catch (e) {
      print('Error adding activity: $e');
      _error = e.toString();
    }
  }

  // Đánh dấu hoạt động đã đọc
  Future<void> markActivityAsRead(String activityId) async {
    try {
      await _firestore.collection('activities').doc(activityId).update({
        'isRead': true,
      });
    } catch (e) {
      print('Error marking activity as read: $e');
      _error = e.toString();
    }
  }

  // Xóa hoạt động
  Future<void> deleteActivity(String activityId) async {
    try {
      await _firestore.collection('activities').doc(activityId).delete();
    } catch (e) {
      print('Error deleting activity: $e');
      _error = e.toString();
    }
  }

  // Thêm vào RoomController
  Stream<int> getUnreadActivitiesCount(String userId) {
    return _firestore
        .collection('activities')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> deleteRoom(String roomId) async {
    try {
      await _firestore.collection('rooms').doc(roomId).delete();
      _rooms.removeWhere((room) => room.id == roomId);
      notifyListeners();
    } catch (e) {
      print('Error deleting room: $e');
      _error = e.toString();
      throw Exception('Không thể xóa phòng: $e');
    }
  }

  // Thêm các phương thức để lấy thống kê
  int getUserFavoriteCount(String userId) {
    return _rooms.where((room) => room.favoriteBy.contains(userId)).length;
  }

  int getUserViewCount(String userId) {
    return _rooms.where((room) => room.viewedBy.contains(userId)).length;
  }

  double getUserAverageRating(String userId) {
    final ratedRooms = _rooms.where((room) => room.ratedBy.contains(userId));
    if (ratedRooms.isEmpty) return 0;
    return ratedRooms.length.toDouble();
  }
} 