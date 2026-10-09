import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/owed_card.dart';
import 'edit_owed_screen.dart';

class OwedScreen extends StatelessWidget {
  const OwedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<BudgetState>();
    final items = state.owed;

    return Scaffold(
      appBar: AppBar(
        title: Text('Money Owed (${items.length})'),
        backgroundColor: const Color(0xFF34534D),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add item',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const EditOwedScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: items.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No owed items yet.\n\nTap + to get started.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 15),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              children: [
                for (var i = 0; i < items.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: OwedCard(
                      item: items[i],
                      alt: i.isOdd,
                      onTogglePaid: () => state.toggleOwedPaid(items[i]),
                      onTap: () => _openEdit(context, items[i]),
                    ),
                  ),
              ],
            ),
      ),
    );
  }

  void _openEdit(BuildContext context, OwedItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EditOwedScreen(owed: item)),
    );
  }
}
