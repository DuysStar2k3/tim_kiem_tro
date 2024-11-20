import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import 'admin/admin_main_screen.dart';
import 'user/landlord/landlord_main_screen.dart';
import 'user/home/home_screen.dart';
import 'user/favourite/favourite_screen.dart';
import 'user/map/map_screen.dart';
import 'user/chat/chat_screen.dart';
import 'user/profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const UserDashboard(),
    const FavouriteScreen(),
    const MapScreen(),
    const ChatScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, auth, child) {
        // Kiểm tra vai trò và điều hướng
        if (auth.isLoggedIn) {
          if (auth.isAdmin) {
            return const AdminMainScreen();
          } else if (auth.isLandlord) {
            return const LandlordMainScreen();
          }
        }

        // Màn hình mặc định cho người dùng thường
        return Scaffold(
          body: _screens[_selectedIndex],
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
            ),
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              selectedItemColor: Colors.red,
              unselectedItemColor: Colors.grey,
              showUnselectedLabels: true,
              currentIndex: _selectedIndex,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              items: [
                BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: const Icon(Icons.home_outlined),
                  ),
                  activeIcon: Container(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: const Icon(Icons.home, color: Colors.red),
                  ),
                  label: 'Trang chủ',
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: const Icon(Icons.favorite_border),
                  ),
                  activeIcon: Container(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: const Icon(Icons.favorite, color: Colors.red),
                  ),
                  label: 'Yêu thích',
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.map,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  label: 'Bản đồ',
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: const Icon(Icons.chat_bubble_outline),
                  ),
                  activeIcon: Container(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: const Icon(Icons.chat_bubble, color: Colors.red),
                  ),
                  label: 'Tin nhắn',
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: const Icon(Icons.person_outline),
                  ),
                  activeIcon: Container(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: const Icon(Icons.person, color: Colors.red),
                  ),
                  label: 'Cá nhân',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
