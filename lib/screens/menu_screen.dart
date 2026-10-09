import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../app_state.dart';
import '../storage.dart';
import '../theme.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  Future<void> _confirmAndRun(
    BuildContext context, {
    required String title,
    required String message,
    required Future<void> Function() onConfirm,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await onConfirm();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(title)));
      }
    }
  }

  /// Exports [content] as [fileName].
  ///
  /// On Android/iOS the file is written to app storage first and then handed
  /// to the share sheet (Files, Drive, email...). Passing the bytes through
  /// file_picker's Save dialog is unreliable on Android: if the activity is
  /// recreated while the dialog is open, file_picker loses the bytes and
  /// leaves an empty file behind. On desktop the Save dialog writes the file.
  ///
  /// Returns a description of where the file went, or null if cancelled.
  Future<String?> _saveExport({
    required String dialogTitle,
    required String fileName,
    required String extension,
    required String content,
  }) async {
    if (Platform.isAndroid || Platform.isIOS) {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(content, flush: true);
      final result = await SharePlus.instance.share(ShareParams(
        files: [
          XFile(file.path,
              mimeType: extension == 'csv' ? 'text/csv' : 'application/json'),
        ],
        title: dialogTitle,
        subject: fileName,
      ));
      if (result.status == ShareResultStatus.dismissed) return null;
      return fileName;
    }
    return FilePicker.saveFile(
      dialogTitle: dialogTitle,
      fileName: fileName,
      bytes: Uint8List.fromList(utf8.encode(content)),
      type: FileType.custom,
      allowedExtensions: [extension],
    );
  }

  Future<void> _exportDataset(BuildContext context) async {
    final state = context.read<BudgetState>();
    final payload = state.buildExportPayload();
    final content = const JsonEncoder.withIndent('  ').convert(payload);
    try {
      final path = await _saveExport(
        dialogTitle: 'Export Budget Dataset',
        fileName: 'budget${StorageService.exportFileExt}',
        extension: 'json',
        content: content,
      );
      if (!context.mounted) return;
      if (path != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Exported dataset to $path')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  Future<void> _exportCsv(BuildContext context) async {
    final state = context.read<BudgetState>();
    final csv = StorageService.billsToCsv(state.bills);
    try {
      final path = await _saveExport(
        dialogTitle: 'Export Bills CSV',
        fileName: 'bills.csv',
        extension: 'csv',
        content: csv,
      );
      if (!context.mounted) return;
      if (path != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Exported CSV to $path')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  Future<void> _importDataset(BuildContext context) async {
    try {
      final result = await FilePicker.pickFiles(
        dialogTitle: 'Import Budget Dataset',
        type: FileType.any,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.single;
      String content;
      if (file.bytes != null) {
        content = utf8.decode(file.bytes!);
      } else if (file.path != null) {
        content = await StorageService.readFile(file.path!);
      } else {
        throw Exception('Could not read selected file.');
      }
      final decoded = json.decode(content);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('File did not contain a JSON object.');
      }
      if (!context.mounted) return;
      final state = context.read<BudgetState>();
      await state.applyImportedPayload(decoded);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            'Imported: ${state.bills.length} bills, '
            '${state.owed.length} owed items, '
            'bank balance £${state.bankBalance.toStringAsFixed(2)}.',
          ),
          duration: const Duration(seconds: 6),
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Import failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<BudgetState>();
    final (cycleStart, cycleEnd) = state.currentCycle;
    final fmt = DateFormat('d MMM yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('File & Settings')),
      body: SafeArea(
        child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _Section(title: 'Pay Day / Reset Date'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bills automatically reset to unpaid when this date is '
                    'reached each cycle. Money owed is never reset '
                    'automatically — use the manual action below.',
                    style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Text('Reset day of month',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      DropdownButton<int>(
                        value: state.payDay,
                        items: [
                          for (var d = 1; d <= 31; d++)
                            DropdownMenuItem(value: d, child: Text(d.toString())),
                        ],
                        onChanged: (v) {
                          if (v != null) state.setPayDay(v);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Current cycle: ${fmt.format(cycleStart)} → ${fmt.format(cycleEnd)}',
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                  ),
                  if (state.lastResetCycleStart != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Bills last auto-reset for cycle starting '
                        '${state.lastResetCycleStart}',
                        style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          _Section(title: 'Save / Export'),
          BigButton(
            text: 'Save',
            color: AppColors.success,
            icon: Icons.save,
            onPressed: () async {
              await state.save();
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Saved.')));
              }
            },
          ),
          const SizedBox(height: 8),
          BigButton(
            text: 'Export Bills CSV...',
            color: AppColors.neutral,
            icon: Icons.table_chart,
            onPressed: () => _exportCsv(context),
          ),
          const SizedBox(height: 8),
          BigButton(
            text: 'Export Dataset...',
            color: AppColors.neutral,
            icon: Icons.upload_file,
            onPressed: () => _exportDataset(context),
          ),
          const SizedBox(height: 18),
          _Section(title: 'Import'),
          BigButton(
            text: 'Import Dataset...',
            color: AppColors.primary,
            icon: Icons.download,
            onPressed: () => _importDataset(context),
          ),
          const SizedBox(height: 18),
          _Section(title: 'Actions'),
          BigButton(
            text: 'Untick All Bills',
            color: AppColors.amber,
            icon: Icons.refresh,
            onPressed: () => _confirmAndRun(
              context,
              title: 'Untick All Bills',
              message: 'Clear all bills back to unpaid? This cannot be undone.',
              onConfirm: () => state.untickAllBills(),
            ),
          ),
          const SizedBox(height: 8),
          BigButton(
            text: 'Reset Money Owed',
            color: AppColors.teal,
            icon: Icons.refresh,
            onPressed: () => _confirmAndRun(
              context,
              title: 'Reset Money Owed',
              message: 'Clear all money-owed items back to unpaid? '
                  'This cannot be undone.',
              onConfirm: () => state.resetAllOwed(),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  const _Section({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          const Divider(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
