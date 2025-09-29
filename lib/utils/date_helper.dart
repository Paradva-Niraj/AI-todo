// lib/utils/date_helper.dart
class DateHelper {
  /// Converts DateTime to ISO date string (YYYY-MM-DD) - ALWAYS use this for API calls
  static String toIsoDateString(DateTime date) {
    return "${date.year.toString().padLeft(4, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.day.toString().padLeft(2, '0')}";
  }

  /// Parses ISO date string to local DateTime at midnight
  static DateTime? fromIsoDateString(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      final parts = dateStr.split('T')[0].split('-');
      if (parts.length != 3) return null;
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);
      return DateTime(year, month, day);
    } catch (e) {
      return null;
    }
  }

  /// Check if two dates are the same day (ignoring time)
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Get midnight of a date
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Get end of day (23:59:59.999)
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  /// Check if a date is in the past (before today)
  static bool isPastDate(DateTime date) {
    final today = startOfDay(DateTime.now());
    final checkDate = startOfDay(date);
    return checkDate.isBefore(today);
  }

  /// Check if a date is today
  static bool isToday(DateTime date) {
    final today = DateTime.now();
    return isSameDay(date, today);
  }
}