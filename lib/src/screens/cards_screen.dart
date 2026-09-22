import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/money.dart';
import '../data/time_codec.dart';
import '../l10n/app_strings.dart';
import '../models/finance_models.dart';
import '../state/finance_store.dart';
import '../widgets/common.dart';

part 'cards_screen_panel.dart';
part 'cards_screen_sheets.dart';

class CardsScreen extends StatelessWidget {
  const CardsScreen({super.key, required this.store});
  final FinanceStore store;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'المحفظة'.tr(context, 'Wallet'),
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          FilledButton.tonalIcon(
            onPressed: () => _addCard(context),
            icon: const Icon(Icons.add),
            label: Text('بطاقة'.tr(context, 'Card')),
          ),
        ],
      ),
      const SizedBox(height: 6),
      Text(
        'أدر رصيد الكاش وبطاقات الكريديت'.tr(
          context,
          'Manage cash and credit cards',
        ),
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      const SizedBox(height: 20),
      Card(
        child: ListTile(
          leading: const CircleAvatar(
            child: Icon(Icons.account_balance_wallet_outlined),
          ),
          title: Text(
            'رصيد الكاش'.tr(context, 'Cash balance'),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            Localizations.localeOf(context).languageCode == 'ar'
                ? '${money(context, store.startingBalance)} قبل خصم المصروفات والسداد'
                : '${money(context, store.startingBalance)} before expenses and card payments',
          ),
          trailing: const Icon(Icons.edit_outlined),
          onTap: () => _editStartingBalance(context),
        ),
      ),
      const SizedBox(height: 16),
      Text(
        'بطاقات الكريديت'.tr(context, 'Credit cards'),
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 10),
      if (store.cards.isEmpty)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Center(
              child: Text(
                'أضف بطاقتك الأولى'.tr(context, 'Add your first card'),
              ),
            ),
          ),
        )
      else
        ...store.cards.map((card) => _CardPanel(store: store, card: card)),
    ],
  );

  Future<void> _editStartingBalance(BuildContext context) async {
    var input = formatPoundsForInput(store.startingBalance);
    final amount = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('تعديل رصيد الكاش'.tr(context, 'Edit cash balance')),
        content: TextFormField(
          initialValue: input,
          autofocus: true,
          onChanged: (value) => input = value,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'الرصيد بالجنيه'.tr(context, 'Balance in EGP'),
            helperText: 'يُخصم منه مصروف الكاش وسداد البطاقات'.tr(
              context,
              'Cash expenses and card payments are deducted from it',
            ),
            prefixIcon: const Icon(Icons.payments_outlined),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('إلغاء'.tr(context, 'Cancel')),
          ),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(input.trim().replaceAll(',', '.'));
              if (value == null || value < 0) return;
              Navigator.pop(dialogContext, value);
            },
            child: Text('حفظ'.tr(context, 'Save')),
          ),
        ],
      ),
    );
    if (amount == null || !context.mounted) return;
    try {
      await store.setStartingBalance(amount);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم تحديث رصيد الكاش'.tr(context, 'Cash balance updated'),
          ),
        ),
      );
    } on PersistenceException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message.localizedError(context))),
      );
    }
  }

  Future<void> _addCard(BuildContext context) async {
    final result = await showModalBottomSheet<_CardInput>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AddCardSheet(),
    );
    if (result == null) return;
    try {
      await store.addCard(
        name: result.name,
        limit: result.limit,
        statementDay: result.statementDay,
        dueDay: result.dueDay,
      );
    } on PersistenceException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message.localizedError(context))),
      );
    }
  }
}
