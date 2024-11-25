import 'package:intl/intl.dart';

class CurrencyFormat {
  /// Format số thành tiền VND (có ký hiệu ₫)
  /// Ví dụ: 1000000 -> 1.000.000 ₫
  static String formatVNDCurrency(num amount) {
    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'VNĐ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }
}
