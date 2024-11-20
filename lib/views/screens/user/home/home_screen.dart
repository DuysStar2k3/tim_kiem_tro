import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../widgets/room_list_view.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  String _selectedCity = 'Hà Nội';

  // Danh sách các tính năng
  final List<Map<String, dynamic>> _features = [
    {
      'icon': Icons.local_offer,
      'label': 'Săn\nphòng giảm giá',
      'onTap': () {/* TODO */},
    },
    {
      'icon': Icons.location_searching,
      'label': 'Tìm phòng\nquanh đây',
      'onTap': () {/* TODO */},
    },
    {
      'icon': Icons.people,
      'label': 'Tìm ở\nghép',
      'onTap': () {/* TODO */},
    },
    {
      'icon': Icons.chair,
      'label': 'Nội thất\ngiá rẻ',
      'onTap': () {/* TODO */},
    },
    {
      'icon': Icons.local_shipping,
      'label': 'Vận\nchuyển',
      'onTap': () {/* TODO */},
    },
  ];

  // Danh sách các quận theo thành phố
  final Map<String, List<Map<String, dynamic>>> _districts = {
    'Hà Nội': [
      {
        'name': 'Đống Đa',
        'count': '234',
        'image': '',
      },
      {
        'name': 'Cầu Giấy',
        'count': '186',
        'image': '',
      },
      {
        'name': 'Ba Đình',
        'count': '132',
        'image': '',
      },
      {'name': 'Hoàn Kiếm', 'count': '145', 'image': ''},
      {'name': 'Tây Hồ', 'count': '128', 'image': ''},
      {'name': 'Long Biên', 'count': '167', 'image': ''},
      {'name': 'Nam Từ Liêm', 'count': '145', 'image': ''},
      {'name': 'Bắc Từ Liêm', 'count': '134', 'image': ''},
      {'name': 'Hà Đông', 'count': '167', 'image': ''},
    ],
    'Hồ Chí Minh': [
      {'name': 'Quận 1', 'count': '312', 'image': ''},
      {'name': 'Quận 3', 'count': '245', 'image': ''},
      {'name': 'Quận 4', 'count': '198', 'image': ''},
      {'name': 'Quận 5', 'count': '167', 'image': ''},
      {'name': 'Quận 6', 'count': '145', 'image': ''},
      {'name': 'Quận 7', 'count': '267', 'image': ''},
      {'name': 'Quận 8', 'count': '189', 'image': ''},
      {'name': 'Quận 10', 'count': '234', 'image': ''},
      {'name': 'Quận 11', 'count': '156', 'image': ''},
      {'name': 'Quận 12', 'count': '178', 'image': ''},
      {'name': 'Bình Thạnh', 'count': '289', 'image': ''},
      {'name': 'Gò Vấp', 'count': '245', 'image': ''},
      {'name': 'Phú Nhuận', 'count': '176', 'image': ''},
      {'name': 'Tân Bình', 'count': '198', 'image': ''},
      {'name': 'Tân Phú', 'count': '167', 'image': ''},
    ],
    'Đà Nẵng': [
      {'name': 'Hải Châu', 'count': '167', 'image': ''},
      {'name': 'Thanh Khê', 'count': '143', 'image': ''},
      {'name': 'Sơn Trà', 'count': '132', 'image': ''},
      {'name': 'Ngũ Hành Sơn', 'count': '121', 'image': ''},
      {'name': 'Liên Chiểu', 'count': '98', 'image': ''},
      {'name': 'Cẩm Lệ', 'count': '87', 'image': ''},
      {'name': 'Hòa Vang', 'count': '45', 'image': ''},
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Custom App Bar với thanh tìm kiếm
          SliverAppBar(
            floating: true,
            elevation: 0,
            backgroundColor: Colors.white,
            title: Container(
              height: 45,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 15),
                  Icon(Icons.search, color: Colors.grey[600]),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm phòng trọ...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.grey[500]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Chọn thành phố
                Container(
                  height: 50,
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildCityChip('Hà Nội'),
                      _buildCityChip('Hồ Chí Minh'),
                      _buildCityChip('Đà Nẵng'),
                    ],
                  ),
                ),

                // Banner quảng cáo
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, Colors.orange],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    image: DecorationImage(
                      image: NetworkImage(
                          'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=1000'),
                      fit: BoxFit.cover,
                      opacity: 0.2,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Tìm phòng trọ tại $_selectedCity\nDễ dàng & Nhanh chóng',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          child: const Text('Đăng tin ngay'),
                        ),
                      ],
                    ),
                  ),
                ),

                // Menu tính năng
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: _features.map((feature) {
                          return Expanded(
                            child: GestureDetector(
                              onTap: feature['onTap'] as VoidCallback,
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      feature['icon'] as IconData,
                                      color: Colors.orange,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    feature['label'] as String,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                // Khu vực phổ biến
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Khám phá',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 180,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _districts[_selectedCity]!.length,
                          itemBuilder: (context, index) {
                            final district = _districts[_selectedCity]![index];
                            return Container(
                              width: 160,
                              margin: const EdgeInsets.only(right: 16),
                              child: InkWell(
                                onTap: () {
                                  // TODO: Navigate to district rooms
                                },
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        district['image'] ?? '',
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          // Fallback khi không load được ảnh
                                          return Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              gradient: LinearGradient(
                                                colors: [
                                                  AppColors.primary
                                                      .withOpacity(0.7),
                                                  Colors.orange.withOpacity(0.7)
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                            ),
                                            child: Center(
                                              child: Icon(
                                                Icons.location_city,
                                                size: 40,
                                                color: Colors.white
                                                    .withOpacity(0.3),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withOpacity(0.7),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 12,
                                      left: 12,
                                      right: 12,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            district['name']!,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${district['count']} phòng',
                                            style: TextStyle(
                                              color:
                                                  Colors.white.withOpacity(0.8),
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Phòng trọ mới nhất
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    'Phòng trọ mới nhất',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const RoomListView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCityChip(String cityName) {
    final isSelected = _selectedCity == cityName;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(cityName),
        onSelected: (bool selected) {
          setState(() {
            _selectedCity = cityName;
          });
        },
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
