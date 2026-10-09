import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../budget_logic.dart';
import '../models.dart';
import '../theme.dart';

class EditOwedScreen extends StatefulWidget {
  final OwedItem? owed;
  const EditOwedScreen({super.key, this.owed});

  @override
  State<EditOwedScreen> createState() => _EditOwedScreenState();
}

class _EditOwedScreenState extends State<EditOwedScreen> {
  late TextEditingController _type;
  late TextEditingController _amount;
  late TextEditingController _notes;
  late bool _paid;

  bool get _isNew => widget.owed == null;

  @override
  void initState() {
    super.initState();
    final o = widget.owed;
    _type = TextEditingController(text: o?.type ?? '');
    _amount = TextEditingController(
        text: o == null ? '' : o.amount.toStringAsFixed(2));
    _notes = TextEditingController(text: o?.notes ?? '');
    _paid = o?.paid ?? false;
  }

  @override
  void dispose() {
    _type.dispose();
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final type = _type.text.trim();
    if (type.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Type / description is required.')),
      );
      return;
    }
    final amount = BudgetLogic.parseMoney(_amount.text);
    final notes = _notes.text.trim();

    final state = context.read<BudgetState>();
    if (_isNew) {
      await state.addOwed(OwedItem(
        id: '',
        type: type,
        amount: amount,
        paid: _paid,
        notes: notes,
      ));
    } else {
      final updated = widget.owed!.copy();
      updated.type = type;
      updated.amount = amount;
      updated.paid = _paid;
      updated.notes = notes;
      await state.updateOwed(updated);
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete item?'),
        content: Text("Delete '${widget.owed!.type}'? This cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await context.read<BudgetState>().deleteOwed(widget.owed!.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'Add Owed Item' : 'Edit Owed Item'),
        backgroundColor: const Color(0xFF34534D),
      ),
      body: SafeArea(
        child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _field('Type / Description *', _type),
          _field('Amount (£) *', _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true)),
          _field('Notes', _notes, maxLines: 3),
          const SizedBox(height: 8),
          const Text('Status', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _paid = !_paid),
              icon: Icon(
                _paid ? Icons.check_box : Icons.check_box_outline_blank,
                color: _paid ? AppColors.success : AppColors.textMuted,
              ),
              label: Text(_paid ? 'Received / Paid' : 'Still Owed'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                foregroundColor: _paid ? AppColors.success : AppColors.textDark,
                backgroundColor: _paid ? AppColors.cardPaid : AppColors.surface,
                side: const BorderSide(color: AppColors.cardBorder),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          BigButton(text: 'Save', color: AppColors.success, onPressed: _save),
          if (!_isNew) ...[
            const SizedBox(height: 10),
            BigButton(text: 'Delete', color: AppColors.danger, onPressed: _delete),
          ],
          const SizedBox(height: 10),
          BigButton(
            text: 'Cancel',
            color: AppColors.neutral,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller,
      {int maxLines = 1, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
          ),
        ],
      ),
    );
  }
}
