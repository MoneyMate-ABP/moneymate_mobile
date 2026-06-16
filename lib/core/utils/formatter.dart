/// Utility class for formatting currency and dates.
class Formatter {
  /// Format value to Rupiah, e.g. `Rp 5.000.000`.
  static String formatRupiah(num amount) {
    final isNegative = amount < 0;
    final abs = amount.abs();
    final intPart = abs.toInt();
    final str = intPart.toString();

    final buffer = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }

    return '${isNegative ? '-' : ''}Rp ${buffer.toString()}';
  }

  /// Format date string from YYYY-MM-DD to DD MMM YYYY.
  static String formatDate(String dateStr) {
    try {
      final parts = dateStr.split('-');
      if (parts.length != 3) return dateStr;
      final year = parts[0];
      final monthIndex = int.tryParse(parts[1]) ?? 1;
      final day = int.tryParse(parts[2]) ?? 1;

      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      final monthName = months[monthIndex - 1];
      return '$day $monthName $year';
    } catch (_) {
      return dateStr;
    }
  }
}
