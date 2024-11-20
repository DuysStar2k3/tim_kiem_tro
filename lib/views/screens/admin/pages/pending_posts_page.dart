import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../controllers/room_controller.dart';
import '../../../../models/room_model.dart';
import '../../../../theme/app_colors.dart';
import '../../../../models/user_model.dart';
import '../../../../controllers/auth_controller.dart';

class PendingPostsPage extends StatefulWidget {
  const PendingPostsPage({super.key});

  @override
  State<PendingPostsPage> createState() => _PendingPostsPageState();
}

class _PendingPostsPageState extends State<PendingPostsPage> {
  String _filterOption = 'all'; // 'all', 'today', 'week', 'month'

  @override
  void initState() {
    super.initState();
    // Tải danh sách phòng khi vào màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoomController>().fetchRooms();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Duyệt bài đăng'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _filterOption = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('Tất cả'),
              ),
              const PopupMenuItem(
                value: 'today',
                child: Text('Hôm nay'),
              ),
              const PopupMenuItem(
                value: 'week',
                child: Text('Tuần này'),
              ),
              const PopupMenuItem(
                value: 'month',
                child: Text('Tháng này'),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<RoomController>(
        builder: (context, controller, child) {
          // Debug: In ra số lượng phòng
          print('Tổng số phòng: ${controller.rooms.length}');
          
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final allPendingRooms = controller.rooms
              .where((room) => !room.isApproved)
              .toList();
              
          // Debug: In ra số lượng phòng chờ duyệt
          print('Số phòng chờ duyệt: ${allPendingRooms.length}');

          final filteredRooms = _filterRooms(allPendingRooms);
          
          // Debug: In ra số lượng phòng sau khi lọc
          print('Số phòng sau khi lọc: ${filteredRooms.length}');

          if (filteredRooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, 
                    size: 64, 
                    color: Colors.grey[400]
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Không có bài đăng nào cần duyệt',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey[100],
                child: Row(
                  children: [
                    Icon(Icons.pending_actions, 
                      color: Colors.orange[800],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Có ${filteredRooms.length} bài đăng cần duyệt',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredRooms.length,
                  itemBuilder: (context, index) {
                    final room = filteredRooms[index];
                    return _buildRoomCard(context, room, controller);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<RoomModel> _filterRooms(List<RoomModel> rooms) {
    final now = DateTime.now();
    switch (_filterOption) {
      case 'today':
        return rooms.where((room) {
          return room.createdAt.year == now.year &&
              room.createdAt.month == now.month &&
              room.createdAt.day == now.day;
        }).toList();
      case 'week':
        final weekAgo = now.subtract(const Duration(days: 7));
        return rooms.where((room) => room.createdAt.isAfter(weekAgo)).toList();
      case 'month':
        return rooms.where((room) {
          return room.createdAt.year == now.year &&
              room.createdAt.month == now.month;
        }).toList();
      default:
        return rooms;
    }
  }

  Widget _buildRoomCard(
    BuildContext context, 
    RoomModel room, 
    RoomController controller
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header với thời gian đăng
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Đăng ngày: ${_formatDate(room.createdAt)}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.pending, size: 16, color: Colors.orange[800]),
                      const SizedBox(width: 4),
                      Text(
                        'Chờ duyệt',
                        style: TextStyle(color: Colors.orange[800]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Phần ảnh và thông tin
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Ảnh phòng
                SizedBox(
                  width: 120,
                  child: room.images.isNotEmpty
                      ? Image.network(
                          room.images.first,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.image, size: 40),
                        ),
                ),
                
                // Thông tin phòng
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
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
                            Icon(Icons.location_on, 
                              size: 16, 
                              color: Colors.grey[600]
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                room.address,
                                style: TextStyle(color: Colors.grey[600]),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.attach_money, 
                              size: 16, 
                              color: Colors.grey[600]
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${room.price.toStringAsFixed(0)} VNĐ/tháng',
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.square_foot, 
                              size: 16, 
                              color: Colors.grey[600]
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Diện tích: ${room.area} m²',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Phần nút tác vụ
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRoomDetails(context, room),
                    icon: const Icon(Icons.visibility),
                    label: const Text('Xem chi tiết'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showApprovalDialog(context, room, controller),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Duyệt bài'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showRoomDetails(BuildContext context, RoomModel room) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              height: 4,
              width: 40,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thông tin người đăng
                    _buildLandlordInfo(room.landlordId),
                    const Divider(height: 24),

                    // Ảnh phòng
                    if (room.images.isNotEmpty)
                      SizedBox(
                        height: 200,
                        child: PageView.builder(
                          itemCount: room.images.length,
                          itemBuilder: (context, index) => Image.network(
                            room.images[index],
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Thông tin phòng
                    Text(
                      room.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.home, 'Loại phòng:', room.roomType),
                    _buildInfoRow(Icons.location_on, 'Địa chỉ:', room.address),
                    _buildInfoRow(Icons.attach_money, 'Giá thuê:', 
                      '${room.price.toStringAsFixed(0)} VNĐ/tháng'),
                    _buildInfoRow(Icons.money, 'Tiền cọc:', 
                      '${room.deposit.toStringAsFixed(0)} VNĐ'),
                    _buildInfoRow(Icons.square_foot, 'Diện tích:', 
                      '${room.area} m²'),
                    _buildInfoRow(Icons.person, 'Giới tính:', room.gender),
                    _buildInfoRow(Icons.group, 'Số người ở tối đa:', 
                      '${room.maxTenants} người'),
                    _buildInfoRow(Icons.phone, 'Liên hệ:', room.phone),
                    const SizedBox(height: 16),

                    // Mô tả
                    const Text(
                      'Mô tả:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(room.description),
                    const SizedBox(height: 16),

                    // Tiện ích
                    _buildAmenities(room),
                    const SizedBox(height: 24),

                    // Nút duyệt/từ chối
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _showRejectDialog(context, room, 
                                context.read<RoomController>());
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Từ chối'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _showApprovalDialog(context, room, 
                                context.read<RoomController>());
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                            ),
                            child: const Text('Duyệt bài'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 4),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildAmenities(RoomModel room) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tiện ích:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (room.hasParking) _buildAmenityChip('Chỗ để xe'),
            if (room.hasWifi) _buildAmenityChip('Wifi'),
            if (room.hasAC) _buildAmenityChip('Điều hòa'),
            if (room.hasFridge) _buildAmenityChip('Tủ lạnh'),
            if (room.hasWasher) _buildAmenityChip('Máy giặt'),
            if (room.hasPrivateBathroom) _buildAmenityChip('WC riêng'),
            if (room.hasKitchen) _buildAmenityChip('Nhà bếp'),
            if (room.hasFreedom) _buildAmenityChip('Tự do'),
          ],
        ),
      ],
    );
  }

  Widget _buildAmenityChip(String label) {
    return Chip(
      label: Text(label),
      backgroundColor: Colors.grey[100],
      labelStyle: TextStyle(color: Colors.grey[800]),
    );
  }

  void _showApprovalDialog(
    BuildContext context, 
    RoomModel room,
    RoomController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận duyệt bài'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bạn có chắc chắn muốn duyệt bài đăng này không?'),
            const SizedBox(height: 8),
            Text(
              'Tiêu đề: ${room.title}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Địa chỉ: ${room.address}'),
            Text('Giá: ${room.price.toStringAsFixed(0)} VNĐ/tháng'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showRejectDialog(context, room, controller);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Từ chối'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              controller.approveRoom(room.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã duyệt bài đăng thành công'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Duyệt'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(
    BuildContext context, 
    RoomModel room,
    RoomController controller,
  ) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Từ chối bài đăng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Vui lòng nhập lý do từ chối:'),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Nhập lý do...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng nhập lý do từ chối'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(context);
              // TODO: Thêm logic từ chối bài đăng với lý do
              controller.rejectRoom(room.id, reasonController.text);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã từ chối bài đăng'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );
  }

  Widget _buildLandlordInfo(String landlordId) {
    return FutureBuilder<UserModel?>(
      future: context.read<AuthController>().getUserById(landlordId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final landlord = snapshot.data;
        if (landlord == null) {
          return const Text('Không tìm thấy thông tin người đăng');
        }

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundImage: landlord.avatar != null && landlord.avatar!.isNotEmpty
                    ? NetworkImage(landlord.avatar!)
                    : null,
                child: landlord.avatar == null || landlord.avatar!.isEmpty
                    ? const Icon(Icons.person)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      landlord.fullName ?? 'Chưa cập nhật',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'SĐT: ${landlord.phone ?? 'Chưa cập nhật'}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    Text(
                      'Email: ${landlord.email}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
} 