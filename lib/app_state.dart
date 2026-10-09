/// Central application state.
///
/// Handles persistence, derived totals, sorting, and the pay-day based
/// auto-reset of bills (money owed is reset manually only).
library;

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'budget_logic.dart';
import 'models.dart';
import 'storage.dart';

const _uuid = Uuid();

class BudgetState extends ChangeNotifier {
  double bankBalance = 0.0;
  List<BillItem> bills = [];
  List<OwedItem> owed = [];
  String sourceExcel = '';
  String sortCol = 'due';
  bool sortAsc = true;

  /// Day of the month (1-31) on which bills automatically reset to unpaid.
  int payDay = 25;

  /// ISO date string of the cycle-start that bills were last auto-reset
  /// for. Used to detect when a new cycle has begun.
  String? lastResetCycleStart;

  bool loaded = false;

  /// Set right after an automatic reset happens, so the UI can show a
  /// one-off notice if desired.
  bool justAutoReset = false;

  // ── Derived totals ────────────────────────────────────────────────────

  double get outstanding =>
      bills.where((b) => !b.paid).fold(0.0, (s, b) => s + b.amount);

  double get moneyLeft => bankBalance - outstanding;

  double get owedUnpaid =>
      owed.where((o) => !o.paid).fold(0.0, (s, o) => s + o.amount);

  double get futureBalance => moneyLeft + owedUnpaid;

  (DateTime, DateTime) get currentCycle => BudgetLogic.cycleBounds(payDay);

  // ── Load / persistence ──────────────────────────────────────────────────

  Future<void> load() async {
    final saved = await StorageService.load();
    if (saved != null) {
      bankBalance = _asDouble(saved['bank_balance']);
      sourceExcel = saved['source_excel']?.toString() ?? '';
      payDay = _asInt(saved['pay_day']) ?? 25;
      lastResetCycleStart = saved['last_reset_cycle_start']?.toString();

      final billsRaw = (saved['bills'] as List?) ?? const [];
      bills = billsRaw
          .whereType<Map>()
          .map((e) => BillItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      final owedRaw = (saved['owed'] as List?) ?? const [];
      owed = owedRaw
          .whereType<Map>()
          .map((e) => OwedItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      sortBills();
    }
    loaded = true;
    await checkAutoReset();
    notifyListeners();
  }

  Future<void> save() async {
    await StorageService.save(
      bankBalance: bankBalance,
      bills: bills,
      owed: owed,
      payDay: payDay,
      lastResetCycleStart: lastResetCycleStart,
      sourceExcel: sourceExcel,
    );
  }

  // ── Auto-reset (pay day) ────────────────────────────────────────────────

  /// Checks whether a new billing cycle has started since the bills were
  /// last reset. If so, every bill is unticked (paid -> false,
  /// paid_amount -> null). Money-owed items are never touched here.
  ///
  /// On first run (no previous reset marker), the marker is simply
  /// initialised to the current cycle without resetting anything, so a
  /// freshly imported dataset isn't wiped.
  Future<void> checkAutoReset() async {
    final (start, _) = currentCycle;
    final startIso = _dateOnlyIso(start);

    if (lastResetCycleStart == null) {
      lastResetCycleStart = startIso;
      await save();
      return;
    }

    if (lastResetCycleStart != startIso) {
      for (final b in bills) {
        b.paid = false;
        b.paidAmount = null;
      }
      lastResetCycleStart = startIso;
      justAutoReset = true;
      sortBills();
      await save();
    }
  }

  void acknowledgeAutoReset() {
    justAutoReset = false;
  }

  // ── Settings ─────────────────────────────────────────────────────────────

  Future<void> setPayDay(int day) async {
    payDay = day.clamp(1, 31);
    sortBills();
    await save();
    notifyListeners();
  }

  Future<void> setBankBalance(double value) async {
    bankBalance = value;
    await save();
    notifyListeners();
  }

  // ── Bills ────────────────────────────────────────────────────────────────

  void sortBills([String? col, bool? asc]) {
    if (col != null) {
      if (sortCol == col) {
        sortAsc = asc ?? !sortAsc;
      } else {
        sortCol = col;
        sortAsc = asc ?? true;
      }
    }
    bills = BudgetLogic.sortBills(bills, sortCol, sortAsc, payDay);
  }

  Future<void> sortBillsBy(String col) async {
    sortBills(col);
    notifyListeners();
  }

  bool isOverdue(BillItem b) => BudgetLogic.isOverdue(b, payDay);

  Future<void> toggleBillPaid(BillItem b) async {
    b.paid = !b.paid;
    b.paidAmount = b.paid ? b.amount : null;
    sortBills();
    await save();
    notifyListeners();
  }

  Future<void> addBill(BillItem b) async {
    bills.add(BillItem(
      id: _uuid.v4(),
      name: b.name,
      due: b.due,
      amount: b.amount,
      paid: b.paid,
      paidAmount: b.paidAmount,
      notes: b.notes,
    ));
    sortBills();
    await save();
    notifyListeners();
  }

  Future<void> updateBill(BillItem updated) async {
    final idx = bills.indexWhere((b) => b.id == updated.id);
    if (idx != -1) {
      bills[idx] = updated;
      sortBills();
      await save();
      notifyListeners();
    }
  }

  Future<void> deleteBill(String id) async {
    bills.removeWhere((b) => b.id == id);
    await save();
    notifyListeners();
  }

  /// Manual "untick all bills" action (in addition to the automatic
  /// pay-day reset).
  Future<void> untickAllBills() async {
    for (final b in bills) {
      b.paid = false;
      b.paidAmount = null;
    }
    sortBills();
    await save();
    notifyListeners();
  }

  // ── Owed ─────────────────────────────────────────────────────────────────

  Future<void> toggleOwedPaid(OwedItem o) async {
    o.paid = !o.paid;
    await save();
    notifyListeners();
  }

  Future<void> addOwed(OwedItem o) async {
    owed.add(OwedItem(
      id: _uuid.v4(),
      type: o.type,
      amount: o.amount,
      paid: o.paid,
      notes: o.notes,
    ));
    await save();
    notifyListeners();
  }

  Future<void> updateOwed(OwedItem updated) async {
    final idx = owed.indexWhere((o) => o.id == updated.id);
    if (idx != -1) {
      owed[idx] = updated;
      await save();
      notifyListeners();
    }
  }

  Future<void> deleteOwed(String id) async {
    owed.removeWhere((o) => o.id == id);
    await save();
    notifyListeners();
  }

  /// Manual-only reset of money-owed items (never triggered by pay day).
  Future<void> resetAllOwed() async {
    for (final o in owed) {
      o.paid = false;
    }
    await save();
    notifyListeners();
  }

  // ── Import / Export ──────────────────────────────────────────────────────

  Map<String, dynamic> buildExportPayload() {
    return StorageService.exportPayload(
      bankBalance: bankBalance,
      bills: bills,
      owed: owed,
      payDay: payDay,
      lastResetCycleStart: lastResetCycleStart,
      sourceExcel: sourceExcel,
    );
  }

  Future<void> applyImportedPayload(Map<String, dynamic> payload) async {
    bankBalance = _asDouble(payload['bank_balance']);
    sourceExcel = payload['source_excel']?.toString() ?? sourceExcel;
    payDay = _asInt(payload['pay_day']) ?? payDay;
    lastResetCycleStart =
        payload['last_reset_cycle_start']?.toString() ?? lastResetCycleStart;

    final billsRaw =
        (payload['bills'] as List?) ?? (payload['items'] as List?) ?? const [];
    bills = billsRaw
        .whereType<Map>()
        .map((e) => BillItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    final owedRaw =
        (payload['owed'] as List?) ?? (payload['owed_items'] as List?) ?? const [];
    owed = owedRaw
        .whereType<Map>()
        .map((e) => OwedItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    sortBills();
    await checkAutoReset();
    await save();
    notifyListeners();
  }

  int get unpaidBillsCount => bills.where((b) => !b.paid).length;
  int get paidBillsCount => bills.where((b) => b.paid).length;
}

double _asDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

String _dateOnlyIso(DateTime d) {
  final dd = DateTime(d.year, d.month, d.day);
  return dd.toIso8601String().split('T').first;
}
