import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'controllers/auth_controller.dart';
import 'controllers/room_controller.dart';
import 'views/screens/admin/admin_main_screen.dart';
import 'views/screens/main_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase đã được khởi tạo trước đó: $e');
    Firebase.app();
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => RoomController()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ứng dụng tìm phòng trọ',
      theme: AppTheme.lightTheme,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, auth, _) {
        // Kiểm tra trạng thái đăng nhập và vai trò
        if (auth.isLoggedIn) {
          if (auth.isAdmin) {
            return const AdminMainScreen();
          }
        }
        // Nếu chưa đăng nhập hoặc không phải admin thì hiển thị MainScreen
        return const MainScreen();
      },
    );
  }
}
