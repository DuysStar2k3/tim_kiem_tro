import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../controllers/room_controller.dart';
import '../../../../models/room_model.dart';

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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOverviewCard(
                  totalRooms: totalRooms,
                  approvedRooms: approvedRooms,
                  pendingRooms: pendingRooms,
                ),
                const SizedBox(height: 20),
                _buildPriceRangeStats(controller.rooms),
                const SizedBox(height: 20),
                _buildLocationStats(controller.rooms),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverviewCard({
    required int totalRooms,
    required int approvedRooms,
    required int pendingRooms,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tổng quan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatRow('Tổng số phòng', totalRooms),
            _buildStatRow('Phòng đã duyệt', approvedRooms),
            _buildStatRow('Phòng chờ duyệt', pendingRooms),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value.toString(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRangeStats(List<RoomModel> rooms) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thống kê theo giá',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            // Thêm biểu đồ thống kê giá ở đây
          ],
        ),
      ),
    );
  }

  Widget _buildLocationStats(List<RoomModel> rooms) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thống kê theo khu vực',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Thêm biểu đồ thống kê khu vực ở đây
          ],
        ),
      ),
    );
  }
}
