import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../controllers/room_controller.dart';
import '../../../../models/room_model.dart';
import '../../../../theme/app_colors.dart';
import '../../../widgets/room_card.dart';

class SearchScreen extends StatefulWidget {
  final String? initialRoomType;

  const SearchScreen({
    super.key,
    this.initialRoomType,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  RangeValues _priceRange = const RangeValues(0, 10000000);
  String _selectedArea = 'Tất cả';
  String? _selectedRoomType;
  bool _hasParking = false;
  bool _hasWifi = false;
  bool _hasAC = false;

  final List<String> _areas = [
    'Tất cả',
    'Cầu Giấy',
    'Đống Đa',
    'Hai Bà Trưng',
    'Hoàn Kiếm',
    'Tây Hồ',
  ];

  @override
  void initState() {
    super.initState();
    _selectedRoomType = widget.initialRoomType;
    if (_selectedRoomType != null) {
      // Tự động tìm kiếm khi có loại phòng được chọn
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Tìm kiếm phòng trọ...',
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                });
              },
            ),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildRoomTypeChip(), // Thêm chip hiển thị loại phòng
          Expanded(
            child: Consumer<RoomController>(
              builder: (context, controller, child) {
                final allRooms = controller.rooms.where((room) => room.isApproved).toList();
                final filteredRooms = _filterRooms(allRooms);

                if (filteredRooms.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Không tìm thấy phòng trọ phù hợp',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredRooms.length,
                  itemBuilder: (context, index) {
                    return RoomCard(room: filteredRooms[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<RoomModel> _filterRooms(List<RoomModel> rooms) {
    return rooms.where((room) {
      // Lọc theo loại phòng
      if (_selectedRoomType != null && room.roomType != _selectedRoomType) {
        return false;
      }

      // Tìm kiếm gần đúng theo từ khóa
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase().trim();
        final keywords = query.split(' ').where((k) => k.isNotEmpty).toList();
        
        final titleWords = room.title.toLowerCase().split(' ');
        final addressWords = room.address.toLowerCase().split(' ');
        
        bool matchFound = false;
        for (final keyword in keywords) {
          final titleMatch = titleWords.any((word) => word.contains(keyword));
          final addressMatch = addressWords.any((word) => word.contains(keyword));
          
          if (titleMatch || addressMatch) {
            matchFound = true;
          } else {
            return false;
          }
        }
        
        if (!matchFound) return false;
      }

      // Lọc theo khoảng giá
      if (room.price < _priceRange.start || room.price > _priceRange.end) {
        return false;
      }

      // Lọc theo khu vực
      if (_selectedArea != 'Tất cả') {
        final areaWords = _selectedArea.toLowerCase().split(' ');
        final addressWords = room.address.toLowerCase().split(' ');
        bool areaMatch = false;
        
        // Kiểm tra từng từ của khu vực trong địa chỉ
        for (final areaWord in areaWords) {
          if (addressWords.any((word) => word.contains(areaWord))) {
            areaMatch = true;
            break;
          }
        }
        
        if (!areaMatch) return false;
      }

      // Lọc theo tiện ích
      if (_hasParking && !room.hasParking) return false;
      if (_hasWifi && !room.hasWifi) return false;
      if (_hasAC && !room.hasAC) return false;

      return true;
    }).toList();
  }

  Widget _buildRoomTypeChip() {
    if (_selectedRoomType == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Chip(
        label: Text(_selectedRoomType!),
        onDeleted: () {
          setState(() {
            _selectedRoomType = null;
          });
        },
        backgroundColor: AppColors.primary.withOpacity(0.1),
        labelStyle: const TextStyle(color: AppColors.primary),
        deleteIconColor: AppColors.primary,
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bộ lọc tìm kiếm',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Khoảng giá
                  const Text(
                    'Khoảng giá (VNĐ)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  RangeSlider(
                    values: _priceRange,
                    min: 0,
                    max: 10000000,
                    divisions: 20,
                    labels: RangeLabels(
                      '${(_priceRange.start / 1000000).toStringAsFixed(1)}tr',
                      '${(_priceRange.end / 1000000).toStringAsFixed(1)}tr',
                    ),
                    onChanged: (values) {
                      setState(() {
                        _priceRange = values;
                      });
                    },
                  ),

                  // Khu vực
                  const Text(
                    'Khu vực',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _areas.map((area) {
                      return ChoiceChip(
                        label: Text(area),
                        selected: _selectedArea == area,
                        onSelected: (selected) {
                          setState(() {
                            _selectedArea = area;
                          });
                        },
                      );
                    }).toList(),
                  ),

                  // Tiện ích
                  const SizedBox(height: 16),
                  const Text(
                    'Tiện ích',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Chỗ để xe'),
                        selected: _hasParking,
                        onSelected: (selected) {
                          setState(() {
                            _hasParking = selected;
                          });
                        },
                      ),
                      FilterChip(
                        label: const Text('Wifi'),
                        selected: _hasWifi,
                        onSelected: (selected) {
                          setState(() {
                            _hasWifi = selected;
                          });
                        },
                      ),
                      FilterChip(
                        label: const Text('Điều hòa'),
                        selected: _hasAC,
                        onSelected: (selected) {
                          setState(() {
                            _hasAC = selected;
                          });
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {}); // Cập nhật lại danh sách phòng
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Áp dụng',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
} 