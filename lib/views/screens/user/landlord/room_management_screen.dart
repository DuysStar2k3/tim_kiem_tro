import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../controllers/auth_controller.dart';
import '../../../../controllers/room_controller.dart';
import '../../../../models/room_model.dart';
import '../../../../theme/app_colors.dart';
import '../../../../utils/currency_format.dart';
import 'room/create_room_screen.dart';

class RoomManagementScreen extends StatefulWidget {
  const RoomManagementScreen({super.key});

  @override
  State<RoomManagementScreen> createState() => _RoomManagementScreenState();
}

class _RoomManagementScreenState extends State<RoomManagementScreen> {
  String? currentUserId;
  @override
  void initState() {
    super.initState();
    // Lấy ID của người dùng hiện tại và tải danh sách phòng
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthController>().currentUser;
      if (user != null) {
        setState(() {
          currentUserId = user.id;
        });
        _loadRooms();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Vui lòng đăng nhập để xem danh sách phòng')),
          );
          Navigator.pop(context);
        }
      }
    });
  }


  // Thêm phương thức tải danh sách phòng
  Future<void> _loadRooms() async {
    if (currentUserId == null) {
      return;
    }
    try {
      final roomController = context.read<RoomController>();
      roomController.getRoomsByLandlord(currentUserId!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tải danh sách phòng: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUserId == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quản lý phòng cho thuê'),
          actions: [
            // Thêm nút đăng tin mới vào AppBar
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateRoomScreen(),
                    ),
                  ).then((_) => _loadRooms());
                },
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Đăng tin',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ],
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Tất cả'),
              Tab(text: 'Chờ duyệt'),
              Tab(text: 'Đã duyệt'),
            ],
          ),
        ),
        body: Consumer<RoomController>(
          builder: (context, roomController, child) {
            if (roomController.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (roomController.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Có lỗi xảy ra: ${roomController.error}',
                      style: TextStyle(color: Colors.red[300]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadRooms,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Thử lại'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              );
            }

            final myRooms = roomController.rooms
                .where((room) => room.landlordId == currentUserId)
                .toList();

            return TabBarView(
              children: [
                _buildRoomList(myRooms),
                _buildRoomList(
                  myRooms.where((room) => !room.isApproved).toList(),
                ),
                _buildRoomList(
                  myRooms.where((room) => room.isApproved).toList(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildRoomList(List<RoomModel> rooms) {
    if (rooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home_work_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Chưa có phòng trọ nào',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRooms,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: rooms.length,
        itemBuilder: (context, index) {
          final room = rooms[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () => _showRoomDetails(context, room),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ảnh phòng
                  Stack(
                    children: [
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            image: room.images.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(room.images.first),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: room.images.isEmpty
                              ? const Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      // Trạng thái phê duyệt
                      Positioned(
                        top: 12,
                        right: 12,
                        child: _buildStatusChip(room.isApproved),
                      ),
                      // Lượt xem
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.remove_red_eye,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${room.views}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Thông tin phòng
                  Padding(
                    padding: const EdgeInsets.all(16),
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
                                size: 16, color: Colors.grey[600]),
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
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${CurrencyFormat.formatVNDCurrency(room.price)}/tháng',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${room.area} m²',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
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
    );
  }

  Widget _buildStatusChip(bool isApproved) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: isApproved ? Colors.green : Colors.orange,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isApproved ? 'Đã duyệt' : 'Chờ duyệt',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
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
            // Thanh kéo
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Nội dung chi tiết
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ảnh phòng
                    if (room.images.isNotEmpty)
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: NetworkImage(room.images.first),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Tiêu đề và trạng thái
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            room.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _buildStatusChip(room.isApproved),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Thông tin cơ bản
                    _buildInfoRow(Icons.location_on, 'Địa chỉ:', room.address),
                    _buildInfoRow(Icons.attach_money, 'Giá thuê:',
                        '${CurrencyFormat.formatVNDCurrency(room.price)}/tháng'),
                    _buildInfoRow(
                        Icons.square_foot, 'Diện tích:', '${room.area} m²'),
                    _buildInfoRow(Icons.people, 'Số người ở tối đa:',
                        '${room.maxTenants} người'),
                    _buildInfoRow(Icons.person, 'Giới tính:', room.gender),

                    const SizedBox(height: 16),

                    // Thống kê
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(Icons.remove_red_eye, '${room.views}',
                              'Lượt xem'),
                          _buildStatItem(Icons.favorite,
                              '${room.favoriteBy.length}', 'Lượt thích'),
                          _buildStatItem(Icons.star,
                              room.rating.toStringAsFixed(1), 'Đánh giá'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Mô tả
                    const Text(
                      'Mô tả chi tiết',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(room.description),

                    const SizedBox(height: 24),

                    // Nút xóa phòng
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showDeleteConfirmation(context, room),
                        icon: const Icon(Icons.delete_forever),
                        label: const Text('Xóa phòng'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context, RoomModel room) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text(
          'Bạn có chắc chắn muốn xóa phòng này? '
          'Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await context.read<RoomController>().deleteRoom(room.id);
                if (mounted) {
                  Navigator.pop(context); // Đóng dialog
                  Navigator.pop(context); // Đóng bottom sheet
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã xóa phòng thành công')),
                  );
                  _loadRooms(); // Tải lại danh sách
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi khi xóa phòng: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}
