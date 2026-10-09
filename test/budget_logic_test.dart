import 'package:budget_checklist/budget_logic.dart';
import 'package:budget_checklist/models.dart';
import 'package:budget_checklist/storage.dart';
import 'package:flutter_test/flutter_test.dart';

BillItem bill(String name,
        {String due = '', double amount = 0, bool paid = false}) =>
    BillItem(id: name, name: name, due: due, amount: amount, paid: paid);

void main() {
  group('parseMoney', () {
    test('strips currency symbols and commas', () {
      expect(BudgetLogic.parseMoney('£1,234.56'), 1234.56);
      expect(BudgetLogic.parseMoney('-20'), -20);
    });

    test('returns 0 for empty or unparseable input', () {
      expect(BudgetLogic.parseMoney(''), 0);
      expect(BudgetLogic.parseMoney('abc'), 0);
    });
  });

  group('cycleBounds', () {
    test('runs from pay day to the day before next pay day', () {
      final (start, end) = BudgetLogic.cycleBounds(25, DateTime(2026, 3, 27));
      expect(start, DateTime(2026, 3, 25));
      expect(end, DateTime(2026, 4, 24));
    });

    test('uses the previous month before pay day', () {
      final (start, end) = BudgetLogic.cycleBounds(25, DateTime(2026, 3, 10));
      expect(start, DateTime(2026, 2, 25));
      expect(end, DateTime(2026, 3, 24));
    });

    test('clamps pay day 31 to short months', () {
      final (start, end) = BudgetLogic.cycleBounds(31, DateTime(2026, 3, 5));
      expect(start, DateTime(2026, 2, 28));
      expect(end, DateTime(2026, 3, 30));
    });

    test('wraps across the year end', () {
      final (start, end) = BudgetLogic.cycleBounds(25, DateTime(2026, 1, 3));
      expect(start, DateTime(2025, 12, 25));
      expect(end, DateTime(2026, 1, 24));
    });
  });

  group('parseDate', () {
    test('reads dd/mm/yyyy, dd-mm-yy and yyyy-mm-dd', () {
      expect(BudgetLogic.parseDate('05/04/2026'), DateTime(2026, 4, 5));
      expect(BudgetLogic.parseDate('05-04-26'), DateTime(2026, 4, 5));
      expect(BudgetLogic.parseDate('2026-04-05'), DateTime(2026, 4, 5));
    });

    test('returns null for blanks and junk', () {
      expect(BudgetLogic.parseDate(''), isNull);
      expect(BudgetLogic.parseDate('none'), isNull);
      expect(BudgetLogic.parseDate('soon'), isNull);
    });
  });

  group('dueToCycleDate', () {
    final today = DateTime(2026, 3, 27); // cycle 25 Mar - 24 Apr

    test('day on or after pay day falls in the cycle start month', () {
      expect(BudgetLogic.dueToCycleDate('28', 25, today), DateTime(2026, 3, 28));
    });

    test('day before pay day falls in the following month', () {
      expect(BudgetLogic.dueToCycleDate('1', 25, today), DateTime(2026, 4, 1));
    });

    test('full dates are used as-is', () {
      expect(BudgetLogic.dueToCycleDate('2026-04-10', 25, today),
          DateTime(2026, 4, 10));
    });
  });

  group('isOverdue', () {
    final today = DateTime(2026, 4, 2); // cycle 25 Mar - 24 Apr

    test('unpaid bill due earlier in the cycle is overdue', () {
      expect(BudgetLogic.isOverdue(bill('Rent', due: '1'), 25, today), isTrue);
    });

    test('paid bills and future bills are not overdue', () {
      expect(BudgetLogic.isOverdue(bill('Rent', due: '1', paid: true), 25, today),
          isFalse);
      expect(BudgetLogic.isOverdue(bill('Phone', due: '10'), 25, today), isFalse);
    });

    test('bills without a due date are never overdue', () {
      expect(BudgetLogic.isOverdue(bill('Misc'), 25, today), isFalse);
    });
  });

  test('sortBills keeps unpaid before paid, each block sorted', () {
    final sorted = BudgetLogic.sortBills([
      bill('Water', amount: 30, paid: true),
      bill('Council tax', amount: 150),
      bill('Broadband', amount: 25, paid: true),
      bill('Energy', amount: 90),
    ], 'amount', true, 25);
    expect(sorted.map((b) => b.name),
        ['Energy', 'Council tax', 'Broadband', 'Water']);
  });

  test('BillItem survives a JSON round trip', () {
    final original = BillItem(
        id: 'x1',
        name: 'Gym',
        due: '15',
        amount: 32.5,
        paid: true,
        paidAmount: 30,
        notes: 'discount');
    final copy = BillItem.fromJson(original.toJson());
    expect(copy.toJson(), original.toJson());
  });

  test('billsToCsv writes a header and one row per bill', () {
    final csv = StorageService.billsToCsv([
      bill('Gym', due: '15', amount: 32.5),
      bill('Rent', due: '1', amount: 700, paid: true),
    ]);
    final lines = csv.trim().split(RegExp(r'\r?\n'));
    expect(lines, hasLength(3));
    expect(lines.first, 'paid,name,due,amount,paid_amount,notes');
    expect(lines[1], contains('Gym'));
  });
}
