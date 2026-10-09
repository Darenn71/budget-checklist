import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/bill_card.dart';
import 'edit_bill_screen.dart';

class BillsScreen extends StatelessWidget {
  const BillsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<BudgetState>();
    final unpaid = state.bills.where((b) => !b.paid).toList();
    final paid = state.bills.where((b) => b.paid).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bills Checklist'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add bill',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const EditBillScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
        children: [
          _SortBar(state: state),
          Expanded(
            child: state.bills.isEmpty
                ? const _EmptyState()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                    children: [
                      if (unpaid.isNotEmpty) ...[
                        SectionLabel(
                          text: 'Unpaid (${unpaid.length})',
                          color: AppColors.danger,
                        ),
                        for (var i = 0; i < unpaid.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: BillCard(
                              bill: unpaid[i],
                              overdue: state.isOverdue(unpaid[i]),
                              alt: i.isOdd,
                              onTogglePaid: () => state.toggleBillPaid(unpaid[i]),
                              onTap: () => _openEdit(context, unpaid[i]),
                            ),
                          ),
                      ],
                      if (paid.isNotEmpty) ...[
                        SectionLabel(
                          text: 'Paid (${paid.length})',
                          color: AppColors.success,
                        ),
                        for (var i = 0; i < paid.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: BillCard(
                              bill: paid[i],
                              overdue: false,
                              alt: i.isOdd,
                              onTogglePaid: () => state.toggleBillPaid(paid[i]),
                              onTap: () => _openEdit(context, paid[i]),
                            ),
                          ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
      ),
    );
  }

  void _openEdit(BuildContext context, BillItem bill) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EditBillScreen(bill: bill)),
    );
  }
}

class _SortBar extends StatelessWidget {
  final BudgetState state;
  const _SortBar({required this.state});

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, String col) {
      final active = state.sortCol == col;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: active,
          onSelected: (_) => state.sortBillsBy(col),
          selectedColor: AppColors.primary,
          labelStyle: TextStyle(
            color: active ? Colors.white : AppColors.textDark,
            fontWeight: FontWeight.w600,
            fontSize: 12.5,
          ),
          backgroundColor: AppColors.surface,
          side: const BorderSide(color: AppColors.cardBorder),
          avatar: active
              ? Icon(
                  state.sortAsc ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 14,
                  color: Colors.white,
                )
              : null,
        ),
      );
    }

    return Container(
      width: double.infinity,
      color: AppColors.headerBg,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Text('Sort:', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ),
            chip('Name', 'name'),
            chip('Due date', 'due'),
            chip('Amount', 'amount'),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'No bills yet.\n\nTap + to get started.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textMuted, fontSize: 15),
        ),
      ),
    );
  }
}
