import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/finance_models.dart';
import '../state/finance_store.dart';
import '../widgets/common.dart';

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
      const Text(
        'تابع الاستخدام والمبالغ المستحقة',
        style: TextStyle(color: Colors.black54),
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
    if (result != null) {
      store.addCard(
        name: result.name,
        limit: result.limit,
        statementDay: result.statementDay,
        dueDay: result.dueDay,
      );
    }
  }
}

class _CardPanel extends StatelessWidget {
  const _CardPanel({required this.store, required this.card});
  final FinanceStore store;
  final CreditCardAccount card;
  @override
  Widget build(BuildContext context) {
    final usage = store.cardUsage(card);
    final due = store.cardDue(card);
    final alertColor = usage >= .9
        ? Colors.red
        : usage >= .7
        ? Colors.orange
        : const Color(0xFF0D9488);
    final days = store.nextDueDate(card).difference(DateTime.now()).inDays + 1;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.credit_card_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    card.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: _LabelValue('المستخدم', money(due))),
                Expanded(
                  child: _LabelValue(
                    'المتبقي',
                    money((card.limit - due).clamp(0, double.infinity)),
                  ),
                ),
                Expanded(child: _LabelValue('الحد', money(card.limit))),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: usage,
              minHeight: 9,
              borderRadius: BorderRadius.circular(10),
              color: alertColor,
              backgroundColor: alertColor.withValues(alpha: .12),
            ),
            const SizedBox(height: 8),
            Text(
              'استخدام ${(usage * 100).round()}% من الحد',
              style: TextStyle(color: alertColor, fontWeight: FontWeight.w700),
            ),
            const Divider(height: 28),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'المطلوب سداده: ${money(due)}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'موعد السداد ${shortDate(store.nextDueDate(card))} • بعد $days يوم',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                FilledButton.tonal(
                  onPressed: due <= 0
                      ? null
                      : () {
                          final ok = store.payCard(card);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ok
                                    ? 'تم تسجيل سداد البطاقة'
                                    : 'الرصيد المتاح لا يكفي للسداد',
                              ),
                            ),
                          );
                        },
                  child: const Text('سددت البطاقة'),
                ),
              ],
            ),
            if (days <= 7 || usage >= .7) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: alertColor.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.notifications_active_outlined,
                      color: alertColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        usage >= .9
                            ? 'تنبيه: تجاوز استخدام البطاقة 90%'
                            : usage >= .7
                            ? 'تنبيه: تجاوز استخدام البطاقة 70%'
                            : 'تذكير: موعد السداد خلال 7 أيام',
                        style: TextStyle(
                          color: alertColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LabelValue extends StatelessWidget {
  const _LabelValue(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      const SizedBox(height: 3),
      Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
      ),
    ],
  );
}

class _CardInput {
  const _CardInput(this.name, this.limit, this.statementDay, this.dueDay);
  final String name;
  final double limit;
  final int statementDay, dueDay;
}

class _AddCardSheet extends StatefulWidget {
  const _AddCardSheet();
  @override
  State<_AddCardSheet> createState() => _AddCardSheetState();
}

class _AddCardSheetState extends State<_AddCardSheet> {
  final key = GlobalKey<FormState>();
  final name = TextEditingController();
  final limit = TextEditingController();
  int statementDay = 20, dueDay = 8;
  @override
  void dispose() {
    name.dispose();
    limit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      20,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 24,
    ),
    child: Form(
      key: key,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'إضافة بطاقة',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: name,
              decoration: const InputDecoration(
                labelText: 'اسم البطاقة أو البنك',
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'أدخل اسم البطاقة' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: limit,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'الحد الائتماني',
                suffixText: 'ج.م',
              ),
              validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0
                  ? 'أدخل حداً صحيحاً'
                  : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: statementDay,
                    decoration: const InputDecoration(
                      labelText: 'يوم قفل الكشف',
                    ),
                    items: List.generate(
                      28,
                      (i) => DropdownMenuItem(
                        value: i + 1,
                        child: Text('${i + 1}'),
                      ),
                    ),
                    onChanged: (v) => statementDay = v!,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: dueDay,
                    decoration: const InputDecoration(labelText: 'يوم السداد'),
                    items: List.generate(
                      28,
                      (i) => DropdownMenuItem(
                        value: i + 1,
                        child: Text('${i + 1}'),
                      ),
                    ),
                    onChanged: (v) => dueDay = v!,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () {
                if (key.currentState!.validate()) {
                  Navigator.pop(
                    context,
                    _CardInput(
                      name.text.trim(),
                      double.parse(limit.text),
                      statementDay,
                      dueDay,
                    ),
                  );
                }
              },
              child: const Text('حفظ البطاقة'),
            ),
          ],
        ),
      ),
    ),
  );
}
