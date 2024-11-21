import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../controllers/auth_controller.dart';
import '../../../../controllers/room_controller.dart';
import '../../../../models/activity_model.dart';
import '../../../../theme/app_colors.dart';
import '../room/room_detail_screen.dart';
import '../../auth/login_screen.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, auth, _) {
        if (!auth.isLoggedIn) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Hoạt động'),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Đăng nhập để xem hoạt động của bạn',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      'Đăng nhập ngay',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Hoạt động'),
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Tương tác'),
                  Tab(text: 'Phòng của tôi'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _buildInteractionsTab(context, auth.currentUser!.id),
                _buildMyRoomsTab(context, auth.currentUser!.id),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInteractionsTab(BuildContext context, String userId) {
    return StreamBuilder<List<dynamic>>(
      stream: context.read<RoomController>().getUserActivities(userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Đã có lỗi xảy ra: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final activities = snapshot.data!;
        if (activities.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Chưa có hoạt động nào',
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
          itemCount: activities.length,
          itemBuilder: (context, index) {
            final activity = activities[index];
            return _buildActivityItem(context, activity);
          },
        );
      },
    );
  }

  Widget _buildMyRoomsTab(BuildContext context, String userId) {
    return Consumer<RoomController>(
      builder: (context, controller, child) {
        final myRooms = controller.rooms
            .where((room) => room.landlordId == userId)
            .toList();

        if (myRooms.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.home_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Bạn chưa đăng phòng nào',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Chuyển đến trang đăng phòng
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Đăng phòng ngay'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: myRooms.length,
          itemBuilder: (context, index) {
            final room = myRooms[index];
            return Card(
              child: ListTile(
                leading: room.images.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          room.images.first,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.home),
                      ),
                title: Text(room.title),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${room.views} lượt xem'),
                    Text(
                      room.isApproved ? 'Đã duyệt' : 'Chờ duyệt',
                      style: TextStyle(
                        color: room.isApproved ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RoomDetailScreen(room: room),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActivityItem(BuildContext context, ActivityModel activity) {
    IconData getActivityIcon(ActivityType type) {
      switch (type) {
        case ActivityType.comment:
          return Icons.comment;
        case ActivityType.rating:
          return Icons.star;
        case ActivityType.favorite:
          return Icons.favorite;
        case ActivityType.roomStatus:
          return Icons.home_work;
      }
    }

    Color getActivityColor(ActivityType type) {
      switch (type) {
        case ActivityType.comment:
          return Colors.blue;
        case ActivityType.rating:
          return Colors.amber;
        case ActivityType.favorite:
          return Colors.red;
        case ActivityType.roomStatus:
          return Colors.green;
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          context.read<RoomController>().markActivityAsRead(activity.id);
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RoomDetailScreen(
                room: context.read<RoomController>().rooms
                    .firstWhere((room) => room.id == activity.roomId),
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: activity.isRead ? null : Colors.blue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: getActivityColor(activity.type).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  getActivityIcon(activity.type),
                  color: getActivityColor(activity.type),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (activity.roomImage != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              activity.roomImage!,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            ),
                          ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activity.roomTitle ?? 'Phòng trọ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                activity.content,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatTimeAgo(activity.createdAt),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                        if (!activity.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
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
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    
    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }
} 