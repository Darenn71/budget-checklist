/// Local persistence + dataset export/import helpers.
library;

import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'models.dart';

class StorageService {
  static const String dataFileName = 'budget_data.json';
  static const String exportFileExt = '.budget.json';

  static Future<File> _dataFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$dataFileName');
  }

  /// Load the autosaved app state, or null if none exists / unreadable.
  static Future<Map<String, dynamic>?> load() async {
    try {
      final file = await _dataFile();
      if (!await file.exists()) return null;
      final content = await file.readAsString();
      final decoded = json.decode(content);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Autosave the full app state to local app storage.
  static Future<void> save({
    required double bankBalance,
    required List<BillItem> bills,
    required List<OwedItem> owed,
    required int payDay,
    String? lastResetCycleStart,
    String sourceExcel = '',
  }) async {
    final file = await _dataFile();
    final data = {
      'version': 11,
      'saved_at': DateTime.now().toIso8601String(),
      'bank_balance': bankBalance,
      'pay_day': payDay,
      'last_reset_cycle_start': lastResetCycleStart,
      'source_excel': sourceExcel,
      'bills': bills.map((b) => b.toJson()).toList(),
      'owed': owed.map((o) => o.toJson()).toList(),
    };
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
  }

  /// Build a portable export payload (matching the original app's
  /// `.budget.json` format, plus the new pay-day / reset fields).
  static Map<String, dynamic> exportPayload({
    required double bankBalance,
    required List<BillItem> bills,
    required List<OwedItem> owed,
    required int payDay,
    String? lastResetCycleStart,
    String sourceExcel = '',
  }) {
    return {
      'format': 'budget-checklist',
      'version': 2,
      'exported_at': DateTime.now().toIso8601String(),
      'bank_balance': bankBalance,
      'pay_day': payDay,
      'last_reset_cycle_start': lastResetCycleStart,
      'source_excel': sourceExcel,
      'bills': bills.map((b) => b.toJson()).toList(),
      'owed': owed.map((o) => o.toJson()).toList(),
    };
  }

  /// Build CSV text for the bills list.
  static String billsToCsv(List<BillItem> bills) {
    final rows = <List<dynamic>>[
      ['paid', 'name', 'due', 'amount', 'paid_amount', 'notes'],
    ];
    for (final b in bills) {
      rows.add([
        b.paid,
        b.name,
        b.due,
        b.amount,
        b.paidAmount ?? '',
        b.notes,
      ]);
    }
    return const ListToCsvConverter().convert(rows);
  }

  /// Read raw bytes/text from a file path (used after file_picker selection).
  static Future<String> readFile(String path) async {
    return File(path).readAsString();
  }

  /// Write text content to an explicit file path (used after a
  /// file_picker "save" selection).
  static Future<void> writeFile(String path, String content) async {
    await File(path).writeAsString(content);
  }
}
