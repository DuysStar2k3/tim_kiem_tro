import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/room_model.dart';

class RoomController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<RoomModel> _rooms = [];
  bool _isLoading = false;
  String? _error;

  List<RoomModel> get rooms => _rooms;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Lấy danh sách phòng
  Future<void> fetchRooms() async {
    try {
      _isLoading = true;
      notifyListeners();

      // In ra log để debug
      print('Đang tải danh sách phòng...');

      final snapshot = await _firestore
          .collection('rooms')
          .orderBy('createdAt', descending: true)
          .get();

      print('Số lượng phòng từ Firestore: ${snapshot.docs.length}');

      _rooms = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        print('Room data: $data');
        return RoomModel.fromMap(data, doc.id);
      }).toList();

      print('Số lượng phòng sau khi chuyển đổi: ${_rooms.length}');
      print('Số phòng chờ duyệt: ${_rooms.where((room) => !room.isApproved).length}');

    } catch (e) {
      print('Lỗi khi tải danh sách phòng: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Phê duyệt phòng
  Future<void> approveRoom(String roomId) async {
    try {
      await _firestore.collection('rooms').doc(roomId).update({
        'isApproved': true,
        'approvedAt': DateTime.now().millisecondsSinceEpoch,
      });

      final index = _rooms.indexWhere((r) => r.id == roomId);
      if (index != -1) {
        _rooms[index] = _rooms[index].copyWith(isApproved: true);
        notifyListeners();
      }
    } catch (e) {
      print('Lỗi khi duyệt phòng: $e');
      _error = e.toString();
      throw Exception('Không thể phê duyệt phòng: $e');
    }
  }

  // Từ chối phòng
  Future<void> rejectRoom(String roomId, String reason) async {
    try {
      await _firestore.collection('rooms').doc(roomId).update({
        'isRejected': true,
        'rejectionReason': reason,
        'rejectedAt': DateTime.now().millisecondsSinceEpoch,
      });

      _rooms.removeWhere((room) => room.id == roomId);
      notifyListeners();
    } catch (e) {
      print('Lỗi khi từ chối phòng: $e');
      _error = e.toString();
      throw Exception('Không thể từ chối phòng: $e');
    }
  }

  // Lấy phòng theo landlordId
  Future<void> getRoomsByLandlord(String landlordId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final snapshot = await _firestore
          .collection('rooms')
          .where('landlordId', isEqualTo: landlordId)
          .get();

      _rooms = snapshot.docs
          .map((doc) => RoomModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Lỗi khi lấy danh sách phòng theo landlord: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
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
} 