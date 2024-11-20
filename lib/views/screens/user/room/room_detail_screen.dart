import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../models/room_model.dart';
import '../../../../theme/app_colors.dart';
import 'room_location_detail_screen.dart';

class RoomDetailScreen extends StatefulWidget {
  final RoomModel room;

  const RoomDetailScreen({super.key, required this.room});

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: widget.room.images.isNotEmpty ? widget.room.images.length : 1,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return widget.room.images.isNotEmpty
                          ? Image.network(
                              widget.room.images[index],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.home, size: 100, color: Colors.grey),
                                );
                              },
                            )
                          : Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.home, size: 100, color: Colors.grey),
                            );
                    },
                  ),
                  if (widget.room.images.length > 1)
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_currentPage + 1}/${widget.room.images.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          if (widget.room.images.length > 1)
            SliverToBoxAdapter(
              child: Container(
                height: 80,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.room.images.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Container(
                        width: 80,
                        margin: const EdgeInsets.only(left: 8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _currentPage == index 
                                ? AppColors.primary 
                                : Colors.grey[300]!,
                            width: _currentPage == index ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            widget.room.images[index],
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),

                  // Tiêu đề và loại phòng
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.room.roomType,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.room.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Giá và diện tích
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.attach_money,
                          title: 'Giá thuê',
                          value: '${widget.room.price.toStringAsFixed(0)} VNĐ/tháng',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.square_foot,
                          title: 'Diện tích',
                          value: '${widget.room.area} m²',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Đặt cọc và số người ở
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.account_balance_wallet,
                          title: 'Đặt cọc',
                          value: '${widget.room.deposit.toStringAsFixed(0)} VNĐ',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.people,
                          title: 'Số người ở',
                          value: '${widget.room.maxTenants} người',
                          subtitle: 'Giới tính: ${widget.room.gender}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Địa chỉ
                  const Text(
                    'Địa chỉ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              RoomLocationDetailScreen(room: widget.room),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.room.address,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tiện ích
                  const Text(
                    'Tiện ích',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      if (widget.room.hasParking)
                        _buildUtilityItem(Icons.motorcycle, 'Chỗ để xe'),
                      if (widget.room.hasWifi) _buildUtilityItem(Icons.wifi, 'Wifi'),
                      if (widget.room.hasAC)
                        _buildUtilityItem(Icons.ac_unit, 'Điều hòa'),
                      if (widget.room.hasFridge)
                        _buildUtilityItem(Icons.kitchen, 'Tủ lạnh'),
                      if (widget.room.hasWasher)
                        _buildUtilityItem(
                            Icons.local_laundry_service, 'Máy giặt'),
                      if (widget.room.hasPrivateBathroom)
                        _buildUtilityItem(Icons.wc, 'WC riêng'),
                      if (widget.room.hasKitchen)
                        _buildUtilityItem(Icons.restaurant, 'Bếp'),
                      if (widget.room.hasFreedom)
                        _buildUtilityItem(Icons.lock_open, 'Tự do'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Mô tả
                  const Text(
                    'Mô tả chi tiết',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.room.description,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          RoomLocationDetailScreen(room: widget.room),
                    ),
                  );
                },
                icon: const Icon(Icons.location_on),
                label: const Text('Xem vị trí'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _makePhoneCall(widget.room.phone),
                icon: const Icon(Icons.phone),
                label: const Text('Liên hệ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUtilityItem(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      throw 'Could not launch $launchUri';
    }
  }
}
