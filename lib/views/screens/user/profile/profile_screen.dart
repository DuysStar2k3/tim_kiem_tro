import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../controllers/auth_controller.dart';
import '../../../../theme/app_colors.dart';
import '../../auth/login_screen.dart';
import '../../../../controllers/room_controller.dart';
import '../favorite/favorite_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, auth, _) {
        if (!auth.isLoggedIn) {
          return _buildLoginPrompt(context);
        }
        return _buildUserProfile(context, auth);
      },
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_circle,
                  size: 100,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Đăng nhập để trải nghiệm',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Đăng nhập để sử dụng đầy đủ các tính năng của ứng dụng',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
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
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Đăng nhập ngay',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfile(BuildContext context, AuthController auth) {
    final user = auth.currentUser!;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Custom AppBar với gradient và avatar
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Pattern dots
                    Positioned.fill(
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 8,
                          mainAxisSpacing: 15,
                          crossAxisSpacing: 15,
                        ),
                        itemBuilder: (context, index) {
                          return Center(
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Avatar và tên người dùng
                    Align(
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Avatar với ảnh hoặc chữ cái đầu
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              image: user.avatar != null
                                  ? DecorationImage(
                                      image: NetworkImage(user.avatar!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: user.avatar == null
                                ? Center(
                                    child: Text(
                                      user.fullName?[0].toUpperCase() ?? 'U',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 12),
                          // Tên người dùng
                          Text(
                            user.fullName ?? 'Người dùng',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // Email
                          Text(
                            user.email,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Nội dung
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Thống kê
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Consumer<RoomController>(
                    builder: (context, roomController, child) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            icon: Icons.favorite,
                            value: roomController
                                .getUserFavoriteCount(user.id)
                                .toString(),
                            label: 'Đã thích',
                          ),
                          _buildVerticalDivider(),
                          _buildStatItem(
                            icon: Icons.remove_red_eye,
                            value: roomController
                                .getUserViewCount(user.id)
                                .toString(),
                            label: 'Đã xem',
                          ),
                          _buildVerticalDivider(),
                          _buildStatItem(
                            icon: Icons.star,
                            value: roomController
                                .getUserAverageRating(user.id)
                                .toString(),
                            label: 'Đánh giá',
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // Menu items
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        icon: Icons.person_outline,
                        title: 'Thông tin cá nhân',
                        subtitle: 'Cập nhật thông tin của bạn',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EditProfileScreen(),
                            ),
                          );
                        },
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.favorite_outline,
                        title: 'Phòng đã thích',
                        subtitle: 'Xem danh sách phòng yêu thích',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FavoriteScreen(),
                            ),
                          );
                        },
                      ),
                      if (!user.isLandlord) ...[
                        _buildDivider(),
                        _buildMenuItem(
                          icon: Icons.home_work,
                          title: 'Trở thành chủ trọ',
                          subtitle: 'Đăng và quản lý phòng cho thuê',
                          onTap: () {
                            context.read<AuthController>().setLandlordRole(
                                  userId: user.id,
                                  isLandlord: true,
                                  context: context,
                                );
                          },
                        ),
                      ] else ...[
                        _buildDivider(),
                        _buildMenuItem(
                          icon: Icons.person,
                          title: 'Trở về người dùng',
                          subtitle: 'Quay lại giao diện người thuê',
                          onTap: () {
                            context.read<AuthController>().setLandlordRole(
                                  userId: user.id,
                                  isLandlord: false,
                                  context: context,
                                );
                          },
                        ),
                      ],
                      _buildDivider(),
                      _buildMenuItem(
                        color: Colors.red,
                        icon: Icons.logout,
                        title: 'Đăng xuất',
                        subtitle: 'Đăng xuất khỏi tài khoản',
                        onTap: () {
                          auth.logout(context: context);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Phiên bản
                Text(
                  'Phiên bản 1.0.0',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
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

  Widget _buildVerticalDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.grey[200],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.all(16),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color?.withOpacity(0.1) ?? AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color ?? AppColors.primary),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey[200],
    );
  }
}
