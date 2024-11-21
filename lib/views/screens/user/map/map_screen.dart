import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as google_maps;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../../../controllers/room_controller.dart';
import '../../../../models/room_model.dart';
import '../../../../theme/app_colors.dart';
import '../room/room_detail_screen.dart';
import '../../../../controllers/auth_controller.dart';

// Đổi tên enum để tránh xung đột
enum CustomMapType {
  normal,
  satellite,
  terrain,
  hybrid,
}

// Thêm enum để định nghĩa các khoảng giá
enum PriceRange {
  all,
  under3M,
  from3Mto5M,
  from5Mto7M,
  over7M,
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isLoading = true;
  // ignore: unused_field
  bool _locationError = false;
  bool _mapCreated = false;
  double _currentRadius = 1000; // Bán kính mặc định 1km
  Circle? _radiusCircle;
  bool _showRadius = false;

  // Vị trí mặc định (Hà Nội)
  static const LatLng _defaultLocation = LatLng(21.0285, 105.8542);

  // Thêm biến để lưu trữ BitmapDescriptor ở đầu class _MapScreenState
  BitmapDescriptor? _roomMarkerIcon;

  // Thêm biến để lưu kiểu bản đồ hiện tại
  CustomMapType _currentMapType = CustomMapType.normal;

  // Thêm biến để lưu bộ lọc hiện tại
  PriceRange _selectedPriceRange = PriceRange.all;

  @override
  void initState() {
    super.initState();
    _initializeMap();
    _createMarkerIcon();
  }

  Future<void> _initializeMap() async {
    try {
      await _checkLocationPermission();
      await _getCurrentLocation();
      if (mounted) {
        context.read<RoomController>().fetchRooms();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationError = true;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      // Kiểm tra dịch vụ vị trí có được bật không
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Hiển thị dialog yêu cầu bật dịch vụ vị trí
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Dịch vụ vị trí bị tắt'),
                content: const Text(
                    'Vui lòng bật dịch vụ vị trí để sử dụng tính năng này'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Geolocator.openLocationSettings();
                    },
                    child: const Text('Mở cài đặt'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Đóng'),
                  ),
                ],
              );
            },
          );
        }
        throw Exception('Location services are disabled.');
      }

      // Kiểm tra quyền truy cập vị trí
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Quyền truy cập vị trí bị từ chối'),
              ),
            );
          }
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Hiển thị dialog hướng dẫn cấp quyền trong cài đặt
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Quyền truy cập vị trí bị từ chối'),
                content: const Text(
                  'Bạn đã từ chối quyền truy cập vị trí vĩnh viễn. '
                  'Vui lòng vào cài đặt để cấp quyền cho ứng dụng.',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Geolocator.openAppSettings();
                    },
                    child: const Text('Mở cài đặt'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Đóng'),
                  ),
                ],
              );
            },
          );
        }
        throw Exception(
            'Location permissions are permanently denied, we cannot request permissions.');
      }
    } catch (e) {
      debugPrint('Error checking location permission: $e');
      rethrow;
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        _isLoading = false;
        _locationError = false;
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          15,
        ),
      );

      if (_showRadius) {
        _updateRadiusCircle();
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      setState(() {
        _isLoading = false;
        _locationError = true;
      });
    }
  }

  void _updateRadiusCircle() {
    if (_currentPosition != null) {
      setState(() {
        _radiusCircle = Circle(
          circleId: const CircleId('searchRadius'),
          center:
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          radius: _currentRadius,
          fillColor: AppColors.primary.withOpacity(0.1),
          strokeColor: AppColors.primary.withOpacity(0.5),
          strokeWidth: 2,
        );
      });
    }
  }

  List<RoomModel> _filterRoomsByRadius(List<RoomModel> rooms) {
    if (!_showRadius || _currentPosition == null) {
      return <RoomModel>[];
    }

    return rooms.where((room) {
      double distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        room.latitude,
        room.longitude,
      );
      return distance <= _currentRadius;
    }).toList();
  }

  // Thêm phương thức để lọc phòng theo giá
  List<RoomModel> _filterRoomsByPrice(List<RoomModel> rooms) {
    switch (_selectedPriceRange) {
      case PriceRange.all:
        return rooms;
      case PriceRange.under3M:
        return rooms.where((room) => room.price < 3000000).toList();
      case PriceRange.from3Mto5M:
        return rooms
            .where((room) => room.price >= 3000000 && room.price < 5000000)
            .toList();
      case PriceRange.from5Mto7M:
        return rooms
            .where((room) => room.price >= 5000000 && room.price < 7000000)
            .toList();
      case PriceRange.over7M:
        return rooms.where((room) => room.price >= 7000000).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && !_mapCreated) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          Consumer<RoomController>(
            builder: (context, roomController, child) {
              final List<RoomModel> approvedRooms = roomController.rooms
                  .where((room) => room.isApproved)
                  .toList();

              // Áp dụng cả bộ lọc bán kính và giá
              List<RoomModel> displayedRooms =
                  _showRadius ? _filterRoomsByRadius(approvedRooms) : [];

              // Áp dụng bộ lọc giá
              displayedRooms = _filterRoomsByPrice(displayedRooms);

              return GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _currentPosition != null
                      ? LatLng(_currentPosition!.latitude,
                          _currentPosition!.longitude)
                      : _defaultLocation,
                  zoom: 15,
                ),
                mapType: _getGoogleMapType(_currentMapType),
                onMapCreated: (controller) {
                  setState(() {
                    _mapController = controller;
                    // ignore: deprecated_member_use
                    _mapController?.setMapStyle(_getMapStyle(_currentMapType));
                    _mapCreated = true;
                    _isLoading = false;
                  });
                },
                markers: _buildMarkers(displayedRooms),
                circles: _showRadius && _radiusCircle != null
                    ? {_radiusCircle!}
                    : {},
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
              );
            },
          ),

          // Search bar với thiết kế mới
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    // TODO: Implement search
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Text(
                          'Tìm kiếm khu vực...',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Filter chips
          Positioned(
            top: MediaQuery.of(context).padding.top + 70,
            left: 16,
            right: 16,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: PriceRange.values
                    .map((range) => _buildFilterChip(range))
                    .toList(),
              ),
            ),
          ),

          // Radius control với thiết kế mới
          if (_showRadius)
            Positioned(
              top: MediaQuery.of(context).padding.top + 130,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(_currentRadius / 1000).toStringAsFixed(1)} km',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 150,
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: Slider(
                          value: _currentRadius,
                          min: 500,
                          max: 5000,
                          activeColor: AppColors.primary,
                          inactiveColor: Colors.grey[300],
                          onChanged: (value) {
                            setState(() {
                              _currentRadius = value;
                              _updateRadiusCircle();
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Thay thế phần Action buttons cũ bằng 2 cột nút ở 2 bên
          // Nút bên trái
          Positioned(
            bottom: MediaQuery.of(context).viewInsets.bottom + 250,
            left: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildActionButton(
                  icon: Icons.radar,
                  isActive: _showRadius,
                  onPressed: () {
                    setState(() {
                      _showRadius = !_showRadius;
                      if (_showRadius) {
                        _updateRadiusCircle();
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildActionButton(
                  icon: Icons.my_location,
                  onPressed: _getCurrentLocation,
                ),
                const SizedBox(height: 10),
                _buildActionButton(
                  icon: Icons.layers,
                  onPressed: _showMapTypeOptions,
                  isActive: _currentMapType != CustomMapType.normal,
                  label: _getMapTypeLabel(_currentMapType),
                ),
              ],
            ),
          ),

          // Bottom sheet hiển thị danh sách phòng
          DraggableScrollableSheet(
            initialChildSize: 0.3,
            minChildSize: 0.2,
            maxChildSize: 0.7,
            snap: true,
            snapSizes: const [0.3, 0.5, 0.7],
            builder: (context, scrollController) {
              return Consumer<RoomController>(
                builder: (context, roomController, child) {
                  final List<RoomModel> approvedRooms = roomController.rooms
                      .where((room) => room.isApproved)
                      .toList();

                  // Áp dụng cả bộ lọc bán kính và giá
                  List<RoomModel> displayedRooms =
                      _showRadius ? _filterRoomsByRadius(approvedRooms) : [];

                  // Áp dụng bộ lọc giá
                  displayedRooms = _filterRoomsByPrice(displayedRooms);

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(20)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Thanh kéo được làm to hơn để dễ thao tác
                        Container(
                          width: 100,
                          height: 30,
                          alignment: Alignment.center,
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            width: 50,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2.5),
                            ),
                          ),
                        ),

                        if (_showRadius) ...[
                          // Hiển thị thông tin khi bật quét
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Tiêu đề với Wrap để tự động xuống dòng
                                Wrap(
                                  children: [
                                    Text(
                                      'Phòng${_getPriceRangeText()} trong bán kính ${(_currentRadius / 1000).toStringAsFixed(1)}km',
                                      style: const TextStyle(
                                        fontSize: 16, // Giảm kích thước chữ
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                // Số lượng phòng và nút sắp xếp
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Tìm thấy ${displayedRooms.length} phòng',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (displayedRooms.isNotEmpty)
                                      TextButton.icon(
                                        onPressed: () {
                                          // TODO: Implement sort function
                                        },
                                        icon: const Icon(Icons.sort, size: 20),
                                        label: const Text(
                                          'Sắp xếp',
                                          style: TextStyle(fontSize: 14),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Danh sách phòng
                          Expanded(
                            child: displayedRooms.isEmpty
                                ? SingleChildScrollView(
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.search_off,
                                            size: 64,
                                            color: Colors.grey[400],
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Không tìm thấy phòng trong khu vực này',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Thử tăng bán kính tm kiếm hoặc di chuyển đến khu vực khác',
                                            style: TextStyle(
                                              color: Colors.grey[500],
                                              fontSize: 14,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    controller: scrollController,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 10,
                                    ),
                                    itemCount: displayedRooms.length,
                                    itemBuilder: (context, index) {
                                      final room = displayedRooms[index];
                                      return _buildRoomListItem(room);
                                    },
                                  ),
                          ),
                        ] else ...[
                          // Hiển thị hướng dẫn khi chưa bật quét
                          Expanded(
                            child: SingleChildScrollView(
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.radar,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Bật tính năng quét để tìm phòng',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Nhấn nút "Quét khu vực" để xem các phòng\ntrong bán kính xung quanh bạn',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(PriceRange range) {
    String label;
    switch (range) {
      case PriceRange.all:
        label = 'Tất cả';
        break;
      case PriceRange.under3M:
        label = 'Dưới 3 triệu';
        break;
      case PriceRange.from3Mto5M:
        label = '3-5 triệu';
        break;
      case PriceRange.from5Mto7M:
        label = '5-7 triệu';
        break;
      case PriceRange.over7M:
        label = 'Trên 7 triệu';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color:
                _selectedPriceRange == range ? Colors.white : Colors.grey[800],
            fontWeight: _selectedPriceRange == range
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
        selected: _selectedPriceRange == range,
        onSelected: (bool selected) {
          setState(() {
            _selectedPriceRange = range;
          });
        },
        backgroundColor: Colors.white,
        selectedColor: AppColors.primary,
        checkmarkColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isActive = false,
    String? label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onPressed,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  icon,
                  color: isActive ? Colors.white : AppColors.primary,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        if (label != null)
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }

  // Thêm style cho Google Map
  final String _mapStyle = '''
    [
      {
        "featureType": "poi",
        "elementType": "labels.text",
        "stylers": [
          {
            "visibility": "off"
          }
        ]
      },
      {
        "featureType": "poi.business",
        "stylers": [
          {
            "visibility": "off"
          }
        ]
      },
      {
        "featureType": "road",
        "elementType": "labels.icon",
        "stylers": [
          {
            "visibility": "off"
          }
        ]
      },
      {
        "featureType": "transit",
        "stylers": [
          {
            "visibility": "off"
          }
        ]
      }
    ]
  ''';

  // Thêm phương thức để tạo custom marker icon
  Future<void> _createMarkerIcon() async {
    _roomMarkerIcon = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(30, 30)),
      'assets/icons/hostel.png', // Đảm bảo thêm file này vào assets
    );
  }

  // Cập nhật phương thức _buildMarkers
  Set<Marker> _buildMarkers(List<RoomModel> rooms) {
    if (!_showRadius) {
      return {};
    }

    final markers = <Marker>{};
    for (final room in rooms) {
      markers.add(
        Marker(
          markerId: MarkerId(room.id),
          position: LatLng(room.latitude, room.longitude),
          icon: _roomMarkerIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: room.title,
            onTap: () => _showRoomDetails(room),
          ),
          // onTap: () => _showRoomDetails(room),
        ),
      );
    }
    return markers;
  }

  // Cập nhật phương thức _buildRoomListItem
  Widget _buildRoomListItem(RoomModel room) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showRoomDetails(room),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: room.images.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(room.images.first),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: room.images.isEmpty
                    ? const Icon(Icons.home, color: Colors.grey, size: 40)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            room.address,
                            style: const TextStyle(color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${room.price.toStringAsFixed(0)} VNĐ/tháng',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Giữ nguyên logic tăng lượt xem trong _showRoomDetails
  void _showRoomDetails(RoomModel room) {
    // Kiểm tra người dùng đã đăng nhập chưa
    final currentUser = context.read<AuthController>().currentUser;
    if (currentUser != null) {
      // Tăng lượt xem nếu đã đăng nhập
      context.read<RoomController>().incrementViews(room.id, currentUser.id);
    }

    // Chuyển đến trang chi tiết
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoomDetailScreen(room: room),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  // Sửa phương thức chuyển đổi MapType
  google_maps.MapType _getGoogleMapType(CustomMapType type) {
    switch (type) {
      case CustomMapType.normal:
        return google_maps.MapType.normal;
      case CustomMapType.satellite:
        return google_maps.MapType.satellite;
      case CustomMapType.terrain:
        return google_maps.MapType.terrain;
      case CustomMapType.hybrid:
        return google_maps.MapType.hybrid;
    }
  }

  // Sửa phương thức chuyển đổi kiểu bản đồ
  void _onMapTypeButtonPressed() {
    setState(() {
      _currentMapType = CustomMapType
          .values[(_currentMapType.index + 1) % CustomMapType.values.length];
    });
  }

  // Sửa phương thức lấy style
  String? _getMapStyle(CustomMapType type) {
    switch (type) {
      case CustomMapType.normal:
        return _mapStyle;
      case CustomMapType.satellite:
      case CustomMapType.terrain:
      case CustomMapType.hybrid:
        return null;
    }
  }

  // Sửa phương thức lấy nhãn
  String _getMapTypeLabel(CustomMapType type) {
    switch (type) {
      case CustomMapType.normal:
        return 'Thường';
      case CustomMapType.satellite:
        return 'Vệ tinh';
      case CustomMapType.terrain:
        return 'Địa hình';
      case CustomMapType.hybrid:
        return 'Kết hợp';
    }
  }

  // Sửa phương thức lấy icon
  IconData _getMapTypeIcon(CustomMapType type) {
    switch (type) {
      case CustomMapType.normal:
        return Icons.map;
      case CustomMapType.satellite:
        return Icons.satellite;
      case CustomMapType.terrain:
        return Icons.terrain;
      case CustomMapType.hybrid:
        return Icons.layers;
    }
  }

  // Sửa phương thức hiển thị tùy chọn
  void _showMapTypeOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: CustomMapType.values.map((type) {
              return ListTile(
                leading: Icon(
                  _getMapTypeIcon(type),
                  color:
                      _currentMapType == type ? AppColors.primary : Colors.grey,
                ),
                title: Text(
                  _getMapTypeLabel(type),
                  style: TextStyle(
                    color: _currentMapType == type
                        ? AppColors.primary
                        : Colors.black,
                    fontWeight: _currentMapType == type
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                selected: _currentMapType == type,
                onTap: () {
                  setState(() {
                    _currentMapType = type;
                    // ignore: deprecated_member_use
                    _mapController?.setMapStyle(_getMapStyle(type));
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // Thêm phương thức để lấy text hiển thị khoảng giá
  String _getPriceRangeText() {
    switch (_selectedPriceRange) {
      case PriceRange.all:
        return '';
      case PriceRange.under3M:
        return ' giá dưới 3 triệu';
      case PriceRange.from3Mto5M:
        return ' giá 3-5 triệu';
      case PriceRange.from5Mto7M:
        return ' giá 5-7 triệu';
      case PriceRange.over7M:
        return ' giá trên 7 triệu';
    }
  }
}
