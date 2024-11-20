import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../controllers/auth_controller.dart';
import '../../../../controllers/room_controller.dart';
import '../../../../models/room_model.dart';
import '../../../../theme/app_colors.dart';
import 'create_room_screen.dart';

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
      print('Current user: $user'); // Debug user object
      
      if (user != null) {
        print('User ID: ${user.id}'); // Debug user ID
        setState(() {
          currentUserId = user.id;
        });
        print('Set currentUserId: $currentUserId'); // Debug currentUserId after setting
        _loadRooms();
      } else {
        print('No user logged in'); // Debug when no user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vui lòng đăng nhập để xem danh sách phòng')),
          );
          Navigator.pop(context);
        }
      }
    });
  }

  // Thêm phương thức tải danh sách phòng
  Future<void> _loadRooms() async {
    print('Loading rooms for user: $currentUserId'); // Debug loading
    if (currentUserId == null) {
      print('Cannot load rooms: currentUserId is null'); // Debug null case
      return;
    }

    try {
      final roomController = context.read<RoomController>();
      await roomController.getRoomsByLandlord(currentUserId!);
      
      // Debug thông tin sau khi tải
      print('Total rooms in controller: ${roomController.rooms.length}');
      print('Rooms for current user: ${roomController.rooms.where((room) => room.landlordId == currentUserId).length}');
      
      // In ra thông tin chi tiết của từng phòng
      for (var room in roomController.rooms) {
        print('Room ID: ${room.id}');
        print('Room Title: ${room.title}');
        print('Room LandlordId: ${room.landlordId}');
        print('Current UserId: $currentUserId');
        print('Is Match: ${room.landlordId == currentUserId}');
        print('------------------------');
      }
    } catch (e) {
      print('Error loading rooms: $e'); // Debug error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tải danh sách phòng: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Kiểm tra người dùng đã đăng nhập chưa
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
            // Thêm nút refresh
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadRooms,
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Tất cả'),
              Tab(text: 'Chờ duyệt'),
              Tab(text: 'Đã duyệt'),
            ],
          ),
        ),
        body: Consumer<RoomController>(
          builder: (context, roomController, child) {
            print('Building Consumer with:');
            print('Current User ID: $currentUserId');
            print('Total Rooms: ${roomController.rooms.length}');
            
            if (roomController.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            // Thêm xử lý khi có lỗi
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
                    ElevatedButton(
                      onPressed: _loadRooms,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              );
            }

            if (currentUserId == null) {
              return const Center(
                child: Text('Vui lòng đăng nhập để xem danh sách phòng'),
              );
            }

            // Lọc phòng theo chủ trọ hiện tại
            final myRooms = roomController.rooms
                .where((room) => room.landlordId == currentUserId)
                .toList();
            
            print('Filtered Rooms: ${myRooms.length}');
            print('Room IDs: ${myRooms.map((r) => r.id).join(', ')}');

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
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateRoomScreen(),
              ),
            ).then(
                (_) => _loadRooms()); // Tải lại danh sách sau khi tạo phòng mới
          },
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.add),
          label: const Text('Đăng tin mới'),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ảnh phòng
                Stack(
                  children: [
                    Container(
                      height: 200,
                      width: double.infinity,
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
                    // Trạng thái phê duyệt
                    Positioned(
                      top: 12,
                      right: 12,
                      child: _buildStatusChip(room.isApproved),
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
                          fontSize: 18,
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
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.attach_money,
                              size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${room.price.toStringAsFixed(0)} VNĐ/tháng',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                // TODO: Implement edit functionality
                                // Navigator.push(
                                //   context,
                                //   MaterialPageRoute(
                                //     builder: (context) => EditRoomScreen(room: room),
                                //   ),
                                // ).then((_) => _loadRooms());
                              },
                              icon: const Icon(Icons.edit),
                              label: const Text('Sửa'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showRoomDetails(context, room),
                              icon: const Icon(Icons.visibility),
                              label: const Text('Chi tiết'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              room.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('Địa chỉ: ${room.address}'),
            Text('Giá: ${room.price.toStringAsFixed(0)} VNĐ/tháng'),
            const SizedBox(height: 8),
            const Text(
              'Mô tả:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(room.description),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Đóng'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Edit room
                      Navigator.pop(context);
                    },
                    child: const Text('Sửa'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
