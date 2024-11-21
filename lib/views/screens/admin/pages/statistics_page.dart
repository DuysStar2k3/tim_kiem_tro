import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../controllers/room_controller.dart';
import '../../../../models/room_model.dart';
import '../../../../theme/app_colors.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê'),
      ),
      body: Consumer<RoomController>(
        builder: (context, controller, child) {
          final totalRooms = controller.rooms.length;
          final approvedRooms =
              controller.rooms.where((room) => room.isApproved).length;
          final pendingRooms = totalRooms - approvedRooms;
          final totalViews =
              controller.rooms.fold(0, (sum, room) => sum + room.views);

          return RefreshIndicator(
            onRefresh: () => controller.fetchRooms(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thẻ tổng quan
                  _buildOverviewCards(
                    totalRooms: totalRooms,
                    approvedRooms: approvedRooms,
                    pendingRooms: pendingRooms,
                    totalViews: totalViews,
                  ),
                  const SizedBox(height: 24),

                  // Thống kê theo giá
                  _buildPriceRangeStats(controller.rooms),
                  const SizedBox(height: 24),

                  // Thống kê theo khu vực
                  _buildLocationStats(controller.rooms),
                  const SizedBox(height: 24),

                  // Thống kê theo loại phòng
                  _buildRoomTypeStats(controller.rooms),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverviewCards({
    required int totalRooms,
    required int approvedRooms,
    required int pendingRooms,
    required int totalViews,
  }) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          title: 'Tổng số phòng',
          value: totalRooms.toString(),
          icon: Icons.home,
          color: Colors.blue,
        ),
        _buildStatCard(
          title: 'Phòng đã duyệt',
          value: approvedRooms.toString(),
          icon: Icons.check_circle,
          color: Colors.green,
        ),
        _buildStatCard(
          title: 'Phòng chờ duyệt',
          value: pendingRooms.toString(),
          icon: Icons.pending,
          color: Colors.orange,
        ),
        _buildStatCard(
          title: 'Lượt xem',
          value: totalViews.toString(),
          icon: Icons.remove_red_eye,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRangeStats(List<RoomModel> rooms) {
    final priceRanges = {
      'Dưới 3 triệu': rooms.where((r) => r.price < 3000000).length,
      '3-5 triệu':
          rooms.where((r) => r.price >= 3000000 && r.price < 5000000).length,
      '5-7 triệu':
          rooms.where((r) => r.price >= 5000000 && r.price < 7000000).length,
      'Trên 7 triệu': rooms.where((r) => r.price >= 7000000).length,
    };

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thống kê theo giá',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...priceRanges.entries
                .map((entry) => Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(entry.key),
                            ),
                            Expanded(
                              flex: 7,
                              child: Stack(
                                children: [
                                  Container(
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: rooms.isEmpty
                                        ? 0
                                        : entry.value / rooms.length,
                                    child: Container(
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 40,
                              child: Text(
                                '${entry.value}',
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ))
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationStats(List<RoomModel> rooms) {
    // Tạo map để đếm số phòng theo khu vực
    final locationCounts = <String, int>{};
    for (var room in rooms) {
      final district = _extractDistrict(room.address);
      locationCounts[district] = (locationCounts[district] ?? 0) + 1;
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thống kê theo khu vực',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...locationCounts.entries
                .where((e) => e.key.isNotEmpty)
                .map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(entry.key),
                          ),
                          Expanded(
                            flex: 7,
                            child: Stack(
                              children: [
                                Container(
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                FractionallySizedBox(
                                  widthFactor: rooms.isEmpty
                                      ? 0
                                      : entry.value / rooms.length,
                                  child: Container(
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 40,
                            child: Text(
                              '${entry.value}',
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomTypeStats(List<RoomModel> rooms) {
    final typeCounts = <String, int>{};
    for (var room in rooms) {
      typeCounts[room.roomType] = (typeCounts[room.roomType] ?? 0) + 1;
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thống kê theo loại phòng',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...typeCounts.entries
                .map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(entry.key),
                          ),
                          Expanded(
                            flex: 7,
                            child: Stack(
                              children: [
                                Container(
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                FractionallySizedBox(
                                  widthFactor: rooms.isEmpty
                                      ? 0
                                      : entry.value / rooms.length,
                                  child: Container(
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 40,
                            child: Text(
                              '${entry.value}',
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ],
        ),
      ),
    );
  }

  String _extractDistrict(String address) {
    final parts = address.split(',');
    for (var part in parts) {
      part = part.trim();
      if (part.toLowerCase().contains('quận') ||
          part.toLowerCase().contains('huyện')) {
        return part;
      }
    }
    return '';
  }
}
