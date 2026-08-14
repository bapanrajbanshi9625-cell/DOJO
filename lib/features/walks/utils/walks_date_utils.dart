class WalksDateUtils {
  static DateTime monday(DateTime date) {
    final clean = DateTime(
      date.year,
      date.month,
      date.day,
    );

    return clean.subtract(
      Duration(
        days: clean.weekday - DateTime.monday,
      ),
    );
  }

  static bool sameDay(
    DateTime a,
    DateTime b,
  ) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  static bool isInWeek(
    DateTime date,
    DateTime mondayDate,
  ) {
    final start = monday(mondayDate);

    final end = start.add(
      const Duration(days: 7),
    );

    return !date.isBefore(start) &&
        date.isBefore(end);
  }

  static String dayName(DateTime date) {
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return names[date.weekday - 1];
  }

  static String month(DateTime date) {
    const names = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];

    return names[date.month - 1];
  }

  static String shortDate(DateTime date) {
    return '${date.day} ${month(date)}';
  }
}
