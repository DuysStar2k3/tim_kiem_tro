import 'package:flutter/material.dart';

class AppColors {
  // Màu chủ đạo
  static const Color primary = Color(0xFF2196F3); // Hoặc màu chính của bạn

  // Thêm phương thức tạo MaterialColor từ Color
  static MaterialColor createMaterialColor(Color color) {
    List<double> strengths = <double>[.05];
    Map<int, Color> swatch = {};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }

  static const Color primaryDark = Color(0xFFE61E4D);
  static const Color primaryLight = Color(0xFFFF5A5F);

  // Màu thứ cấp
  static const Color secondary = Color(0xFF00A699); // Màu xanh mint
  static const Color secondaryDark = Color(0xFF00887E);
  static const Color secondaryLight = Color(0xFF00C3B5);

  // Màu nền
  static const Color background = Colors.white;
  static const Color surface = Color(0xFFF7F7F7);
  static const Color card = Colors.white;

  // Màu văn bản
  static const Color textPrimary = Color(0xFF222222);
  static const Color textSecondary = Color(0xFF717171);
  static const Color textHint = Color(0xFFB0B0B0);

  // Màu biểu tượng
  static const Color icon = Color(0xFF717171);
  static const Color iconSelected = primary;

  // Màu đường viền
  static const Color border = Color(0xFFDDDDDD);
  static const Color divider = Color(0xFFEEEEEE);

  // Màu trạng thái
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFA000);
  static const Color info = Color(0xFF2196F3);

  // Màu gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      primary,
      primaryDark,
    ],
  );

  // Màu overlay
  static Color overlay = Colors.black.withOpacity(0.5);
  static Color shimmerBase = Colors.grey[300]!;
  static Color shimmerHighlight = Colors.grey[100]!;

  // Màu cho các loại phòng
  static const Color priceDown = Color(0xFF4CAF50); // Màu cho phòng giảm giá
  static const Color hotDeal = Color(0xFFFF9800); // Màu cho phòng hot
  static const Color newRoom = Color(0xFF2196F3); // Màu cho phòng mới

  // Màu cho bottom navigation bar
  static const Color bottomNavBackground = Colors.white;
  static const Color bottomNavInactive = Color(0xFF717171);
  static const Color bottomNavActive = primary;
} 