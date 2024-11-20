import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../controllers/auth_controller.dart';
import '../../auth/login_screen.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

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
            title: const Text('Tin nhắn'),
          ),
          body: ListView.builder(
            itemCount: 10,
            itemBuilder: (context, index) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey[300],
                  child: const Icon(Icons.person),
                ),
                title: const Text('Người dùng'),
                subtitle: const Text('Tin nhắn cuối cùng...'),
                trailing: const Text('12:00'),
              );
            },
          ),
        );
      },
    );
  }
} 