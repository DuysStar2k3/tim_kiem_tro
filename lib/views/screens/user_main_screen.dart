import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/room_controller.dart';
import 'admin/admin_main_screen.dart';
import 'user/home/home_screen.dart';
import 'user/landlord/landlord_main_screen.dart';
import 'user/favorite/favorite_screen.dart';
import 'user/map/map_screen.dart';
import 'user/activity/activity_screen.dart';
import 'user/profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const FavoriteScreen(),
    const MapScreen(),
    const ActivityScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, auth, child) {
        if (auth.isLoggedIn) {
          if (auth.isAdmin) {
            return const AdminMainScreen();
          } else if (auth.isLandlord) {
            return const LandlordMainScreen();
          }
        }

        return Scaffold(
          body: _screens[_selectedIndex],
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
            ),
            child: StreamBuilder<int>(
              stream: auth.isLoggedIn
                  ? context
                      .read<RoomController>()
                      .getUnreadActivitiesCount(auth.currentUser!.id)
                  : Stream.value(0),
              builder: (context, snapshot) {
                final unreadCount = snapshot.data ?? 0;

                return BottomNavigationBar(
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
                      icon: Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: const Icon(Icons.history_outlined),
                          ),
                          if (unreadCount > 0)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  unreadCount > 99 ? '99+' : '$unreadCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                      activeIcon: Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: const Icon(Icons.history, color: Colors.red),
                          ),
                          if (unreadCount > 0)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  unreadCount > 99 ? '99+' : '$unreadCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                      label: 'Gần đây',
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
                );
              },
            ),
          ),
        );
      },
    );
  }
}
