/// Pure business-logic helpers, ported from the original Tkinter app.
///
/// The "pay day" / reset date is now configurable (1-31) instead of being
/// hard-coded to the 25th. A billing cycle runs from the pay day of one
/// month up to (but not including) the pay day of the next month.
library;

import 'models.dart';

class BudgetLogic {
  /// Parse a free-form money string (e.g. "£1,234.56") into a double.
  static double parseMoney(String s) {
    final cleaned = s.replaceAll(RegExp(r'[^0-9\-\.]'), '');
    if (cleaned.isEmpty) return 0.0;
    return double.tryParse(cleaned) ?? 0.0;
  }

  /// Clamp [day] to the number of days actually in [year]-[month]
  /// (e.g. pay day 31 in February becomes the 28th/29th).
  static DateTime _clampedDate(int year, int month, int day) {
    // Normalise month overflow/underflow (month can be 0 or 13 etc.)
    var y = year;
    var m = month;
    while (m < 1) {
      m += 12;
      y -= 1;
    }
    while (m > 12) {
      m -= 12;
      y += 1;
    }
    final daysInMonth = DateTime(y, m + 1, 0).day;
    final d = day > daysInMonth ? daysInMonth : (day < 1 ? 1 : day);
    return DateTime(y, m, d);
  }

  /// Returns the (start, end) dates of the current billing cycle.
  /// The cycle starts on [payDay] of a month and ends the day before
  /// [payDay] of the following month.
  static (DateTime start, DateTime end) cycleBounds(int payDay,
      [DateTime? today]) {
    final now = _dateOnly(today ?? DateTime.now());
    DateTime start;
    if (now.day >= payDay) {
      start = _clampedDate(now.year, now.month, payDay);
    } else {
      start = _clampedDate(now.year, now.month - 1, payDay);
    }
    final nextStart = _clampedDate(start.year, start.month + 1, payDay);
    final end = nextStart.subtract(const Duration(days: 1));
    return (start, end);
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Parse common date strings: dd/mm/yyyy, dd-mm-yyyy, yyyy-mm-dd.
  static DateTime? parseDate(String text) {
    final s = text.trim();
    if (s.isEmpty || s.toLowerCase() == 'nan' || s.toLowerCase() == 'none') {
      return null;
    }
    final dmy = RegExp(r'^(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{2,4})$');
    final ymd = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$');

    var m = dmy.firstMatch(s);
    if (m != null) {
      final day = int.parse(m.group(1)!);
      final month = int.parse(m.group(2)!);
      var year = int.parse(m.group(3)!);
      if (year < 100) year += 2000;
      try {
        return DateTime(year, month, day);
      } catch (_) {
        return null;
      }
    }

    m = ymd.firstMatch(s);
    if (m != null) {
      final year = int.parse(m.group(1)!);
      final month = int.parse(m.group(2)!);
      final day = int.parse(m.group(3)!);
      try {
        return DateTime(year, month, day);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Convert a bill's "due" field (either a day-of-month number, or a
  /// full date string) into a concrete date within the current cycle.
  static DateTime? dueToCycleDate(String due, int payDay, [DateTime? today]) {
    final now = today ?? DateTime.now();
    final s = due.trim();
    if (s.isEmpty || s.toLowerCase() == 'nan' || s.toLowerCase() == 'none') {
      return null;
    }
    if (s.contains('/') || s.contains('-')) {
      return parseDate(s);
    }
    final dayMatch = RegExp(r'^\d{1,2}(\.0)?$').firstMatch(s);
    if (dayMatch != null) {
      final day = int.parse(s.split('.').first);
      final (start, end) = cycleBounds(payDay, now);
      if (day >= payDay) {
        return _clampedDate(start.year, start.month, day);
      } else {
        return _clampedDate(end.year, end.month, day);
      }
    }
    return parseDate(s);
  }

  /// A bill is overdue if it's unpaid, has a due date within the current
  /// cycle, and that date is strictly before today.
  static bool isOverdue(BillItem b, int payDay, [DateTime? today]) {
    if (b.paid) return false;
    final now = _dateOnly(today ?? DateTime.now());
    final d = dueToCycleDate(b.due, payDay, now);
    if (d == null) return false;
    final dDate = _dateOnly(d);
    final (start, end) = cycleBounds(payDay, now);
    final inCycle = !dDate.isBefore(start) && !dDate.isAfter(end);
    return inCycle && dDate.isBefore(now);
  }

  /// Sort key for a bill given a column name: "name", "due", "amount",
  /// or "paid_amount".
  static Comparable sortKey(BillItem b, String col, int payDay) {
    switch (col) {
      case 'due':
        final d = dueToCycleDate(b.due, payDay);
        // Items with no due date sort last.
        return d == null ? '9999-99-99' : d.toIso8601String();
      case 'amount':
        return b.amount;
      case 'paid_amount':
        return b.paidAmount ?? double.infinity;
      case 'name':
      default:
        return b.name.toLowerCase();
    }
  }

  /// Sort bills: unpaid first (in their own sorted block), then paid
  /// (in their own sorted block) — matching the original app's behaviour.
  static List<BillItem> sortBills(
      List<BillItem> bills, String col, bool asc, int payDay) {
    final unpaid = bills.where((b) => !b.paid).toList();
    final paid = bills.where((b) => b.paid).toList();

    int cmp(BillItem a, BillItem b) {
      final ka = sortKey(a, col, payDay);
      final kb = sortKey(b, col, payDay);
      int result;
      if (ka is String && kb is String) {
        result = ka.compareTo(kb);
      } else {
        result = (ka as double).compareTo(kb as double);
      }
      return asc ? result : -result;
    }

    unpaid.sort(cmp);
    paid.sort(cmp);
    return [...unpaid, ...paid];
  }
}
