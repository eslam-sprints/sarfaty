import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/money.dart';
import '../data/time_codec.dart';
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
            'بطاقاتي',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          FilledButton.tonalIcon(
            onPressed: () => _addCard(context),
            icon: const Icon(Icons.add),
            label: const Text('بطاقة'),
          ),
        ],
      ),
      const SizedBox(height: 6),
      Text(
        'تابع الاستخدام والمبالغ المستحقة',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      const SizedBox(height: 20),
      if (store.cards.isEmpty)
        const Card(
          child: Padding(
            padding: EdgeInsets.all(30),
            child: Center(child: Text('أضف بطاقتك الأولى')),
          ),
        )
      else
        ...store.cards.map((card) => _CardPanel(store: store, card: card)),
    ],
  );
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}
