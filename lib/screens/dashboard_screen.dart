import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../theme.dart';
import '../widgets/stat_card.dart';
import 'bills_screen.dart';
import 'owed_screen.dart';
import 'menu_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late TextEditingController _bankController;
  final _bankFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    final state = context.read<BudgetState>();
    _bankController =
        TextEditingController(text: state.bankBalance.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _bankController.dispose();
    _bankFocus.dispose();
    super.dispose();
  }

  void _showAutoResetNoticeIfNeeded(BudgetState state) {
    if (state.justAutoReset) {
      state.acknowledgeAutoReset();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New billing cycle started — bills reset to unpaid.'),
            backgroundColor: AppColors.headerBg,
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<BudgetState>();
    _showAutoResetNoticeIfNeeded(state);

    // Keep the bank balance field in sync if the value changed elsewhere
    // (e.g. dataset import), but don't clobber text the user is editing.
    final formatted = state.bankBalance.toStringAsFixed(2);
    if (!_bankFocus.hasFocus && _bankController.text != formatted) {
      _bankController.text = formatted;
    }

    final (cycleStart, cycleEnd) = state.currentCycle;
    final fmt = DateFormat('d MMM');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Checklist'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MenuScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          StatCard(
            label: 'Bank Balance',
            value: state.bankBalance.toStringAsFixed(2),
            accent: AppColors.primary,
            editable: true,
            controller: _bankController,
            focusNode: _bankFocus,
            onSubmitted: (text) async {
              final value = double.tryParse(
                      text.replaceAll(RegExp(r'[^0-9\-\.]'), '')) ??
                  state.bankBalance;
              await state.setBankBalance(value);
              _bankController.text = value.toStringAsFixed(2);
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Outstanding',
                  value: state.outstanding.toStringAsFixed(2),
                  accent: AppColors.danger,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatCard(
                  label: 'Money Left',
                  value: state.moneyLeft.toStringAsFixed(2),
                  accent: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Owed to Me',
                  value: state.owedUnpaid.toStringAsFixed(2),
                  accent: AppColors.teal,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatCard(
                  label: 'Future Balance',
                  value: state.futureBalance.toStringAsFixed(2),
                  accent: const Color(0xFF8E6FB0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              'Current cycle: ${fmt.format(cycleStart)} – ${fmt.format(cycleEnd)}'
              '  •  resets on day ${state.payDay}',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 18),
          BigButton(
            text: 'Bills Checklist',
            color: AppColors.primary,
            icon: Icons.receipt_long,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BillsScreen()),
            ),
          ),
          const SizedBox(height: 10),
          BigButton(
            text: 'Money Owed',
            color: AppColors.teal,
            icon: Icons.account_balance_wallet,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const OwedScreen()),
            ),
          ),
          const SizedBox(height: 10),
          BigButton(
            text: 'Save Now',
            color: AppColors.neutral,
            icon: Icons.save,
            onPressed: () async {
              await state.save();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Saved.')),
                );
              }
            },
          ),
        ],
      ),
      ),
    );
  }
}
