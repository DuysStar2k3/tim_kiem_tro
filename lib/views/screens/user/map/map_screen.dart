import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as google_maps;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../../../controllers/room_controller.dart';
import '../../../../models/room_model.dart';
import '../../../../theme/app_colors.dart';
import '../../../../utils/currency_format.dart';
import '../../../widgets/room_detail_screen.dart';
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

class _MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin {
  // Constants
  static const double _collapsedSheetSize = 0.02; // 2% khi ẩn
  static const double _initialSheetSize = 0.25; // 25% khi mới vào
  static const double _expandedSheetSize = 0.8; // 80% khi mở rộng
  static const double _defaultRadius = 1000.0;
  static const LatLng _defaultLocation = LatLng(21.0285, 105.8542);

  // Controllers
  late final DraggableScrollableController _sheetController;
  GoogleMapController? _mapController;

  // State variables
  Position? _currentPosition;
  BitmapDescriptor? _roomMarkerIcon;
  Circle? _radiusCircle;

  // Flags
  bool _isLoading = true;
  bool _mapCreated = false;
  bool _showRadius = false;
  bool _isExpanded = false;

  // Map settings
  CustomMapType _currentMapType = CustomMapType.normal;
  PriceRange _selectedPriceRange = PriceRange.all;
  double _currentRadius = _defaultRadius;

  // Thêm các biến mới cho tìm kiếm
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;
  List<RoomModel> _searchResults = [];
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _sheetController = DraggableScrollableController();
    _initializeMap();
    _createMarkerIcon();

    // Thêm listener cho search
    _searchController.addListener(_onSearchChanged);
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
        throw Exception('Dịch vụ vị trí đã bị tắt.');
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
          throw Exception('Quyền truy cập vị trí bị từ chối');
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
            'Quyền truy cập vị trí bị từ chối vĩnh viễn, không thể yêu cầu quyền.');
      }
    } catch (e) {
      debugPrint('Lỗi kiểm tra quyền truy cập vị trí: $e');
      rethrow;
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          14,
        ),
      );

      if (_showRadius) {
        _updateRadiusCircle();
      }
    } catch (e) {
      debugPrint('Lỗi lấy vị trí: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateRadiusCircle() {
    if (_currentPosition == null) return;

    setState(() {
      _radiusCircle = Circle(
        circleId: const CircleId('searchRadius'),
        center: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        radius: _currentRadius,
        fillColor: AppColors.primary.withOpacity(0.1),
        strokeColor: AppColors.primary.withOpacity(0.5),
        strokeWidth: 2,
      );
    });
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

          // Thanh tìm kiếm
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: _buildSearchBar(),
          ),

          // Filter chips - Thêm điều kiện hiển thị
          if (!_isSearching)
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

          // Kết quả tìm kiếm - Điều chỉnh vị trí và thêm Container bọc ngoài
          if (_isSearching && _searchResults.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top +
                  70, // Đặt ngay dưới thanh tìm kiếm
              left: 16,
              right: 16,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height *
                      0.5, // Giới hn chiều cao tối đa
                ),
                child: _buildSearchResults(),
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
                    // Nút tăng bán kính
                    IconButton(
                      onPressed: () {
                        if (_currentRadius < 5000) {
                          setState(() {
                            _currentRadius = _currentRadius + 500;
                            _updateRadiusCircle();
                            // Cập nhật độ zoom của bản đồ
                            if (_currentPosition != null &&
                                _mapController != null) {
                              _mapController!.animateCamera(
                                CameraUpdate.newLatLngZoom(
                                  LatLng(_currentPosition!.latitude,
                                      _currentPosition!.longitude),
                                  _getZoomLevel(_currentRadius),
                                ),
                              );
                            }
                          });
                        }
                      },
                      icon: const Icon(Icons.add_circle_outline),
                      color: _currentRadius < 5000
                          ? AppColors.primary
                          : Colors.grey,
                    ),

                    // Hiển thị bán kính
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        '${(_currentRadius / 1000).toStringAsFixed(1)} km',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    // Slider vẫn giữ nguyên
                    SizedBox(
                      height: 130,
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
                              // Cập nhật độ zoom của bản đồ
                              if (_currentPosition != null &&
                                  _mapController != null) {
                                _mapController!.animateCamera(
                                  CameraUpdate.newLatLngZoom(
                                    LatLng(_currentPosition!.latitude,
                                        _currentPosition!.longitude),
                                    _getZoomLevel(_currentRadius),
                                  ),
                                );
                              }
                            });
                          },
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        if (_currentRadius > 500) {
                          setState(() {
                            _currentRadius = _currentRadius - 500;
                            _updateRadiusCircle();
                            // Cập nhật độ zoom của bản đồ
                            if (_currentPosition != null &&
                                _mapController != null) {
                              _mapController!.animateCamera(
                                CameraUpdate.newLatLngZoom(
                                  LatLng(_currentPosition!.latitude,
                                      _currentPosition!.longitude),
                                  _getZoomLevel(_currentRadius),
                                ),
                              );
                            }
                          });
                        }
                      },
                      icon: const Icon(Icons.remove_circle_outline),
                      color: _currentRadius > 500
                          ? AppColors.primary
                          : Colors.grey,
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
                  onPressed: _toggleScanMode,
                ),
                const SizedBox(height: 16),
                _buildActionButton(
                  icon: Icons.my_location,
                  onPressed: _getCurrentLocation,
                ),
                const SizedBox(height: 10),
                _buildActionButton(
                  icon: Icons.layers,
                  onPressed: _onMapTypeButtonPressed,
                  isActive: _currentMapType != CustomMapType.normal,
                  label: _getMapTypeLabel(_currentMapType),
                ),
              ],
            ),
          ),

          // Bottom sheet hiển thị danh sách phòng
          DraggableScrollableSheet(
            initialChildSize: _initialSheetSize,
            minChildSize: _collapsedSheetSize,
            maxChildSize: _expandedSheetSize,
            snap: true,
            snapSizes: const [
              _collapsedSheetSize,
              _initialSheetSize,
              _expandedSheetSize
            ],
            controller: _sheetController,
            builder: (context, scrollController) {
              return Consumer<RoomController>(
                builder: (context, roomController, child) {
                  final List<RoomModel> approvedRooms = roomController.rooms
                      .where((room) => room.isApproved)
                      .toList();

                  List<RoomModel> displayedRooms =
                      _showRadius ? _filterRoomsByRadius(approvedRooms) : [];
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Thanh kéo
                        GestureDetector(
                          onTap: _toggleBottomSheet,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 2, bottom: 8),
                            child: Container(
                              width: 50,
                              height: 5,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(2.5),
                              ),
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
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Danh sách phòng
                          Expanded(
                            child: displayedRooms.isEmpty
                                ? Center(
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
                                          'Thử tăng bán kính tìm kiếm hoặc di chuyển đến khu vực khác',
                                          style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 14,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
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
                          // Nội dung hướng dẫn khi chưa quét
                          Expanded(
                            child: SingleChildScrollView(
                              controller: scrollController,
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.radar,
                                    size: 70,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 20),
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
                                  const SizedBox(height: 20),
                                  ElevatedButton.icon(
                                    onPressed: _toggleScanMode,
                                    icon: const Icon(Icons.radar),
                                    label: const Text('Bắt đầu quét'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ],
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

          // Sửa lại phần nút điều khiển bên phải
          Positioned(
            bottom: MediaQuery.of(context).viewInsets.bottom + 250,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildActionButton(
                  icon: !_showRadius
                      ? (_sheetController.isAttached &&
                              _sheetController.size <= _collapsedSheetSize + 0.1
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down)
                      : (_isExpanded
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_up),
                  onPressed: _toggleBottomSheet,
                  label: !_showRadius
                      ? (_sheetController.isAttached &&
                              _sheetController.size <= _collapsedSheetSize + 0.1
                          ? 'Mở rộng'
                          : 'Thu gọn')
                      : (_isExpanded ? 'Thu gọn' : 'Mở rộng'),
                ),
              ],
            ),
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
        if (label != null) ...[
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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
      'assets/icons/hostel.png', // Đảm bảo thm file này vào assets
    );
  }

  // Cập nhật phương thức _buildMarkers
  Set<Marker> _buildMarkers(List<RoomModel> rooms) {
    if (!_showRadius) return {};

    return rooms
        .map((room) => Marker(
              markerId: MarkerId(room.id),
              position: LatLng(room.latitude, room.longitude),
              icon: _roomMarkerIcon ??
                  BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueRed),
              infoWindow: InfoWindow(
                title: room.title,
                onTap: () => _showRoomDetails(room),
              ),
            ))
        .toSet();
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
                      '${CurrencyFormat.formatVNDCurrency(room.price)}/tháng',
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
    _sheetController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
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

  // Sửa phương thức điều khiển bottom sheet
  void _toggleBottomSheet() {
    if (!_sheetController.isAttached) return;

    double currentSize = _sheetController.size;
    double targetSize;

    // Chỉ cho phép thu gọn về 5% khi không bật quét
    if (currentSize > _collapsedSheetSize + 0.1 && !_showRadius) {
      targetSize = _collapsedSheetSize;
    } else if (currentSize <= _collapsedSheetSize + 0.1) {
      targetSize = _initialSheetSize;
    } else if (currentSize <= _initialSheetSize + 0.1) {
      targetSize = _expandedSheetSize;
    } else {
      targetSize = _initialSheetSize;
    }

    setState(() => _isExpanded = targetSize == _expandedSheetSize);

    _sheetController.animateTo(
      targetSize,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // Sửa lại phương thức xử lý nút quét
  void _toggleScanMode() {
    if (!_sheetController.isAttached) return;

    bool wasOff = !_showRadius; // Lưu trạng thái trước khi thay đổi

    if (wasOff) {
      // Nếu đang chuyển từ tắt sang bật
      // Đẩy bottom sheet lên trước
      _sheetController
          .animateTo(
        _initialSheetSize,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      )
          .then((_) {
        // Sau khi đẩy lên xong mới cập nhật state để hiển thị nội dung
        setState(() {
          _showRadius = true;
          _updateRadiusCircle();
        });
      });
    } else {
      // Nếu đang tắt quét thì cập nhật state ngay
      setState(() {
        _showRadius = false;
      });
    }
  }

  // Thêm phương thức xử lý tìm kiếm
  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (_searchController.text.isEmpty) {
        setState(() {
          _isSearching = false;
          _searchResults = [];
        });
        return;
      }

      setState(() {
        _isSearching = true;
        final searchTerm = _searchController.text.toLowerCase();

        // Tạo danh sách kết quả với điểm số tương đồng
        final scoredResults =
            context.read<RoomController>().rooms.where((room) {
          if (!room.isApproved) return false;

          // Tính điểm tương đồng cho title và address
          double titleScore = _calculateSimilarity(room.title, searchTerm);
          double addressScore = _calculateSimilarity(room.address, searchTerm);

          // Kiểm tra từng từ trong searchTerm
          final searchWords =
              searchTerm.split(' ').where((word) => word.isNotEmpty).toList();
          for (final word in searchWords) {
            // Tăng điểm nếu title hoặc address chứa từ khóa tìm kiếm
            if (room.title.toLowerCase().contains(word)) {
              titleScore += 0.2;
            }
            if (room.address.toLowerCase().contains(word)) {
              addressScore += 0.2;
            }
          }

          // Lấy điểm cao nhất giữa title và address
          double maxScore =
              titleScore > addressScore ? titleScore : addressScore;

          // Thêm vào kết quả nếu điểm đủ cao
          return maxScore > 0.3; // Có thể điều chỉnh ngưỡng này
        }).map((room) {
          // Tính điểm tổng hợp cho mỗi phòng
          double titleScore = _calculateSimilarity(room.title, searchTerm);
          double addressScore = _calculateSimilarity(room.address, searchTerm);

          for (final word
              in searchTerm.split(' ').where((word) => word.isNotEmpty)) {
            if (room.title.toLowerCase().contains(word)) titleScore += 0.2;
            if (room.address.toLowerCase().contains(word)) addressScore += 0.2;
          }

          return MapEntry(
              room, titleScore > addressScore ? titleScore : addressScore);
        }).toList();

        // Sắp xếp kết quả theo điểm số từ cao xuống thấp
        scoredResults.sort((a, b) => b.value.compareTo(a.value));

        // Lấy danh sách phòng đã sắp xếp
        _searchResults = scoredResults.map((entry) => entry.key).toList();
      });
    });
  }

  // Sửa lại widget hiển thị kết quả tìm kiếm
  Widget _buildSearchResults() {
    return Material(
      color: Colors.transparent,
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _searchResults.length > 5 ? 5 : _searchResults.length,
              itemBuilder: (context, index) {
                final room = _searchResults[index];
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
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
                        ? const Icon(Icons.home, color: Colors.grey)
                        : null,
                  ),
                  title: Text(
                    room.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    room.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    '${(room.price / 1000000).toStringAsFixed(1)}tr/tháng',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLngZoom(
                        LatLng(room.latitude, room.longitude),
                        16,
                      ),
                    );

                    FocusScope.of(context).unfocus();
                    setState(() {
                      _isSearching = false;
                      _searchController.clear();
                    });

                    _showRoomDetails(room);
                  },
                );
              },
            ),
            if (_searchResults.length > 5)
              TextButton(
                onPressed: () {
                  //  Hiển thị tất cả kết quả trong một modal bottom sheet
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => DraggableScrollableSheet(
                      initialChildSize: 0.7,
                      minChildSize: 0.5,
                      maxChildSize: 0.9,
                      builder: (context, scrollController) => Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 40,
                              height: 5,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(2.5),
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                controller: scrollController,
                                itemCount: _searchResults.length,
                                itemBuilder: (context, index) {
                                  final room = _searchResults[index];
                                  return ListTile(
                                    leading: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        image: room.images.isNotEmpty
                                            ? DecorationImage(
                                                image: NetworkImage(
                                                    room.images.first),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                      ),
                                      child: room.images.isEmpty
                                          ? const Icon(Icons.home,
                                              color: Colors.grey)
                                          : null,
                                    ),
                                    title: Text(room.title),
                                    subtitle: Text(room.address),
                                    trailing: Text(
                                      '${(room.price / 1000000).toStringAsFixed(1)}tr/tháng',
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _mapController?.animateCamera(
                                        CameraUpdate.newLatLngZoom(
                                          LatLng(room.latitude, room.longitude),
                                          16,
                                        ),
                                      );
                                      _showRoomDetails(room);
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                child: Text(
                  'Xem tất cả ${_searchResults.length} kết quả',
                  style: const TextStyle(color: AppColors.primary),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Cập nhật widget thanh tìm kiếm
  Widget _buildSearchBar() {
    return Container(
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
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        decoration: InputDecoration(
          hintText: 'Tìm kiếm địa điểm, khu vực...',
          hintStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: const Icon(Icons.search, color: AppColors.primary),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _isSearching = false;
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  // Thêm hàm tính độ tương đồng giữa hai chuỗi
  double _calculateSimilarity(String str1, String str2) {
    str1 = str1.toLowerCase();
    str2 = str2.toLowerCase();

    if (str1.isEmpty || str2.isEmpty) return 0;
    if (str1 == str2) return 1;

    // Tính số ký tự giống nhau
    int matchingChars = 0;
    for (int i = 0; i < str1.length && i < str2.length; i++) {
      if (str1[i] == str2[i]) matchingChars++;
    }

    // Kiểm tra nếu một chuỗi chứa chuỗi còn lại
    if (str1.contains(str2) || str2.contains(str1)) {
      return 0.8;
    }

    // Tính độ tương đồng dựa trên số ký tự giống nhau
    return matchingChars / (str1.length + str2.length) * 2;
  }

  // Thêm phương thức để tính độ zoom dựa trên bán kính
  double _getZoomLevel(double radius) {
    double zoomLevel = 11;
    if (radius <= 500) {
      zoomLevel = 15;
    } else if (radius <= 1000) {
      zoomLevel = 14.5;
    } else if (radius <= 2000) {
      zoomLevel = 14;
    } else if (radius <= 3000) {
      zoomLevel = 13.5;
    } else if (radius <= 4000) {
      zoomLevel = 13;
    } else if (radius <= 5000) {
      zoomLevel = 12.5;
    } else {
      zoomLevel = 12;
    }
    return zoomLevel;
  }
}
