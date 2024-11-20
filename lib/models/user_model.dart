import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String? fullName;
  final String? phone;
  final String? avatar;
  final bool isAdmin;
  final bool isLandlord;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.email,
    this.fullName,
    this.phone,
    this.avatar,
    this.isAdmin = false,
    this.isLandlord = false,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String?,
      phone: json['phone'] as String?,
      avatar: json['avatar'] as String?,
      isAdmin: json['isAdmin'] as bool? ?? false,
      isLandlord: json['isLandlord'] as bool? ?? false,
      createdAt: json['createdAt'] != null 
          ? (json['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'avatar': avatar,
      'isAdmin': isAdmin,
      'isLandlord': isLandlord,
      'createdAt': createdAt,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phone,
    String? avatar,
    bool? isAdmin,
    bool? isLandlord,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      isAdmin: isAdmin ?? this.isAdmin,
      isLandlord: isLandlord ?? this.isLandlord,
      createdAt: createdAt ?? this.createdAt,
    );
  }
} 