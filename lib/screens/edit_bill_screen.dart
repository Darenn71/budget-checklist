import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../budget_logic.dart';
import '../models.dart';
import '../theme.dart';

class EditBillScreen extends StatefulWidget {
  final BillItem? bill;
  const EditBillScreen({super.key, this.bill});

  @override
  State<EditBillScreen> createState() => _EditBillScreenState();
}

class _EditBillScreenState extends State<EditBillScreen> {
  late TextEditingController _name;
  late TextEditingController _due;
  late TextEditingController _amount;
  late TextEditingController _paidAmount;
  late TextEditingController _notes;
  late bool _paid;

  bool get _isNew => widget.bill == null;

  @override
  void initState() {
    super.initState();
    final b = widget.bill;
    _name = TextEditingController(text: b?.name ?? '');
    _due = TextEditingController(text: b?.due ?? '');
    _amount = TextEditingController(
        text: b == null ? '' : b.amount.toStringAsFixed(2));
    _paidAmount = TextEditingController(
        text: b?.paidAmount == null ? '' : b!.paidAmount!.toStringAsFixed(2));
    _notes = TextEditingController(text: b?.notes ?? '');
    _paid = b?.paid ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _due.dispose();
    _amount.dispose();
    _paidAmount.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bill name is required.')),
      );
      return;
    }
    final amount = BudgetLogic.parseMoney(_amount.text);
    final due = _due.text.trim();
    final notes = _notes.text.trim();
    double? paidAmount;
    final paidRaw = _paidAmount.text.trim();
    if (paidRaw.isNotEmpty) {
      paidAmount = BudgetLogic.parseMoney(paidRaw);
    }
    if (_paid && paidAmount == null) paidAmount = amount;
    if (!_paid) paidAmount = null;

    final state = context.read<BudgetState>();
    if (_isNew) {
      await state.addBill(BillItem(
        id: '',
        name: name,
        due: due,
        amount: amount,
        paid: _paid,
        paidAmount: paidAmount,
        notes: notes,
      ));
    } else {
      final updated = widget.bill!.copy();
      updated.name = name;
      updated.due = due;
      updated.amount = amount;
      updated.paid = _paid;
      updated.paidAmount = paidAmount;
      updated.notes = notes;
      await state.updateBill(updated);
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete bill?'),
        content: Text("Delete '${widget.bill!.name}'? This cannot be undone."),
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
      await context.read<BudgetState>().deleteBill(widget.bill!.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isNew ? 'Add Bill' : 'Edit Bill')),
      body: SafeArea(
        child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _field('Bill Name *', _name),
          _field('Due (day number or date)', _due,
              hint: 'e.g. 15 or 15/06/2026'),
          _field('Amount (£) *', _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true)),
          _field('Paid Amount (£)', _paidAmount,
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
              label: Text(_paid ? 'Marked as PAID' : 'Mark as Paid'),
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
          BigButton(text: 'Save Bill', color: AppColors.primary, onPressed: _save),
          if (!_isNew) ...[
            const SizedBox(height: 10),
            BigButton(text: 'Delete Bill', color: AppColors.danger, onPressed: _delete),
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
      {String? hint, int maxLines = 1, TextInputType? keyboardType}) {
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
            decoration: InputDecoration(hintText: hint),
          ),
        ],
      ),
    );
  }
}
