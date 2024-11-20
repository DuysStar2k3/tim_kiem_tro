import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../controllers/auth_controller.dart';
import '../../auth/login_screen.dart';

class FavouriteScreen extends StatelessWidget {
  const FavouriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, auth, _) {
        if (!auth.isLoggedIn) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Tin nhắn'),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Vui lòng đăng nhập để sử dụng tính năng này'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    child: const Text('Đăng nhập'),
                  ),
                ],
              ),
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('Yêu thích'),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  // Thêm chức năng tìm kiếm sau
                },
              ),
            ],
          ),
          body: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: 10, // Số lượng bài đăng yêu thích
            itemBuilder: (context, index) {
              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hình ảnh bài đăng
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Icon(
                                Icons.image,
                                size: 50,
                                color: Colors.grey[400],
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.favorite,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  // Xử lý bỏ yêu thích
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Thông tin bài đăng
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tiêu đề bài đăng ${index + 1}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.location_on,
                                  size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                'Địa chỉ phòng trọ',
                                style: TextStyle(
                                  color: Colors.grey[600],
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
                                '2.000.000 đ/tháng',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                ),
                              ),
                              const Spacer(),
                              Icon(Icons.access_time,
                                  size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                '2 ngày trước',
                                style: TextStyle(
                                  color: Colors.grey[600],
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
      },
    );
  }
}
