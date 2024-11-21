class RoomModel {
  final String id;
  final String title;
  final String address;
  final double price;
  final String description;
  final List<String> images;
  final String landlordId;
  final double latitude;
  final double longitude;
  final bool isApproved;
  final DateTime createdAt;
  final bool isRejected;
  final String? rejectionReason;
  
  // Thêm các trường mới
  final String roomType;
  final double area;
  final double deposit;
  final String phone;
  final String gender;
  final int maxTenants;
  
  // Tiện ích
  final bool hasParking;
  final bool hasWifi;
  final bool hasAC;
  final bool hasFridge;
  final bool hasWasher;
  final bool hasPrivateBathroom;
  final bool hasKitchen;
  final bool hasFreedom;
  final int views;
  final List<String> viewedBy;
  final double rating;
  final int ratingCount;
  final List<String> ratedBy;
  final List<String> favoriteBy;

  RoomModel({
    required this.id,
    required this.title,
    required this.address,
    required this.price,
    required this.description,
    required this.images,
    required this.landlordId,
    required this.latitude,
    required this.longitude,
    this.isApproved = false,
    DateTime? createdAt,
    this.isRejected = false,
    this.rejectionReason,
    this.roomType = 'Phòng trọ',
    this.area = 0,
    this.deposit = 0,
    this.phone = '',
    this.gender = 'Tất cả',
    this.maxTenants = 1,
    this.hasParking = false,
    this.hasWifi = false,
    this.hasAC = false,
    this.hasFridge = false,
    this.hasWasher = false,
    this.hasPrivateBathroom = false,
    this.hasKitchen = false,
    this.hasFreedom = false,
    this.views = 0,
    this.viewedBy = const [],
    this.rating = 0,
    this.ratingCount = 0,
    this.ratedBy = const [],
    this.favoriteBy = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  factory RoomModel.fromMap(Map<String, dynamic> map, String id) {
    try {
      return RoomModel(
        id: id,
        title: map['title'] ?? '',
        address: map['address'] ?? '',
        price: (map['price'] ?? 0).toDouble(),
        description: map['description'] ?? '',
        images: List<String>.from(map['images'] ?? []),
        landlordId: map['landlordId'] ?? '',
        latitude: (map['latitude'] ?? 0).toDouble(),
        longitude: (map['longitude'] ?? 0).toDouble(),
        isApproved: map['isApproved'] ?? false,
        createdAt: map['createdAt'] != null 
            ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
            : DateTime.now(),
        isRejected: map['isRejected'] ?? false,
        rejectionReason: map['rejectionReason'],
        roomType: map['roomType'] ?? 'Phòng trọ',
        area: (map['area'] ?? 0).toDouble(),
        deposit: (map['deposit'] ?? 0).toDouble(),
        phone: map['phone'] ?? '',
        gender: map['gender'] ?? 'Tất cả',
        maxTenants: map['maxTenants'] ?? 1,
        hasParking: map['hasParking'] ?? false,
        hasWifi: map['hasWifi'] ?? false,
        hasAC: map['hasAC'] ?? false,
        hasFridge: map['hasFridge'] ?? false,
        hasWasher: map['hasWasher'] ?? false,
        hasPrivateBathroom: map['hasPrivateBathroom'] ?? false,
        hasKitchen: map['hasKitchen'] ?? false,
        hasFreedom: map['hasFreedom'] ?? false,
        views: map['views'] ?? 0,
        viewedBy: List<String>.from(map['viewedBy'] ?? []),
        rating: (map['rating'] ?? 0).toDouble(),
        ratingCount: map['ratingCount'] ?? 0,
        ratedBy: List<String>.from(map['ratedBy'] ?? []),
        favoriteBy: List<String>.from(map['favoriteBy'] ?? []),
      );
    } catch (e) {
      print('Lỗi khi chuyển đổi dữ liệu phòng: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'address': address,
      'price': price,
      'description': description,
      'images': images,
      'landlordId': landlordId,
      'latitude': latitude,
      'longitude': longitude,
      'isApproved': isApproved,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isRejected': isRejected,
      'rejectionReason': rejectionReason,
      'roomType': roomType,
      'area': area,
      'deposit': deposit,
      'phone': phone,
      'gender': gender,
      'maxTenants': maxTenants,
      'hasParking': hasParking,
      'hasWifi': hasWifi,
      'hasAC': hasAC,
      'hasFridge': hasFridge,
      'hasWasher': hasWasher,
      'hasPrivateBathroom': hasPrivateBathroom,
      'hasKitchen': hasKitchen,
      'hasFreedom': hasFreedom,
      'views': views,
      'viewedBy': viewedBy,
      'rating': rating,
      'ratingCount': ratingCount,
      'ratedBy': ratedBy,
      'favoriteBy': favoriteBy,
    };
  }

  RoomModel copyWith({
    String? id,
    String? title,
    String? address,
    double? price,
    String? description,
    List<String>? images,
    String? landlordId,
    double? latitude,
    double? longitude,
    bool? isApproved,
    DateTime? createdAt,
    bool? isRejected,
    String? rejectionReason,
    String? roomType,
    double? area,
    double? deposit,
    String? phone,
    String? gender,
    int? maxTenants,
    bool? hasParking,
    bool? hasWifi,
    bool? hasAC,
    bool? hasFridge,
    bool? hasWasher,
    bool? hasPrivateBathroom,
    bool? hasKitchen,
    bool? hasFreedom,
    int? views,
    List<String>? viewedBy,
    double? rating,
    int? ratingCount,
    List<String>? ratedBy,
    List<String>? favoriteBy,
  }) {
    return RoomModel(
      id: id ?? this.id,
      title: title ?? this.title,
      address: address ?? this.address,
      price: price ?? this.price,
      description: description ?? this.description,
      images: images ?? this.images,
      landlordId: landlordId ?? this.landlordId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isApproved: isApproved ?? this.isApproved,
      createdAt: createdAt ?? this.createdAt,
      isRejected: isRejected ?? this.isRejected,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      roomType: roomType ?? this.roomType,
      area: area ?? this.area,
      deposit: deposit ?? this.deposit,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      maxTenants: maxTenants ?? this.maxTenants,
      hasParking: hasParking ?? this.hasParking,
      hasWifi: hasWifi ?? this.hasWifi,
      hasAC: hasAC ?? this.hasAC,
      hasFridge: hasFridge ?? this.hasFridge,
      hasWasher: hasWasher ?? this.hasWasher,
      hasPrivateBathroom: hasPrivateBathroom ?? this.hasPrivateBathroom,
      hasKitchen: hasKitchen ?? this.hasKitchen,
      hasFreedom: hasFreedom ?? this.hasFreedom,
      views: views ?? this.views,
      viewedBy: viewedBy ?? this.viewedBy,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      ratedBy: ratedBy ?? this.ratedBy,
      favoriteBy: favoriteBy ?? this.favoriteBy,
    );
  }
} 