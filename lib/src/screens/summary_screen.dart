import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../models/finance_models.dart';
import '../state/finance_store.dart';
import '../widgets/common.dart';

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key, required this.store});
  final FinanceStore store;
  @override
  Widget build(BuildContext context) {
    final total = store.monthlyTotal;
    final cashRatio = total == 0 ? 0.0 : store.cashTotal / total;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        Text(
          'ملخص الشهر'.tr(context, 'Monthly summary'),
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          'نظرة سريعة على نمط مصروفاتك'.tr(
            context,
            'A quick look at your spending pattern',
          ),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        MetricCard(
          label: 'إجمالي الصرف'.tr(context, 'Total spending'),
          value: money(context, total),
          icon: Icons.trending_down_rounded,
        ),
        MetricCard(
          label: 'أعلى تصنيف'.tr(context, 'Top category'),
          value:
              store.topCustomCategoryName ??
              store.topCategory?.labelFor(context) ??
              'لا يوجد'.tr(context, 'None'),
          icon: store.topCategory?.icon ?? Icons.category_outlined,
          tint: store.topCategory?.color ?? Colors.grey,
        ),
        MetricCard(
          label: 'سداد البطاقات هذا الشهر'.tr(
            context,
            'Card payments this month',
          ),
          value: money(context, store.monthlyPayments),
          icon: Icons.credit_score_rounded,
          tint: const Color(0xFF0369A1),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'طرق الدفع'.tr(context, 'Payment methods'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 18),
                _PaymentLine(
                  label: PaymentMethod.cash.labelFor(context),
                  value: store.cashTotal,
                  ratio: cashRatio,
                  color: const Color(0xFF0D9488),
                ),
                const SizedBox(height: 18),
                _PaymentLine(
                  label: PaymentMethod.credit.labelFor(context),
                  value: store.creditTotal,
                  ratio: 1 - cashRatio,
                  color: const Color(0xFF7C3AED),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          color: Theme.of(context).colorScheme.secondaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: Color(0xFFEA580C),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'البيانات محفوظة محلياً بشكل دائم. يمكنك تصدير نسخة احتياطية من شاشة الإعدادات.'.tr(
                      context,
                      'Your data is stored locally. Export a backup from Settings at any time.',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PaymentLine extends StatelessWidget {
  const _PaymentLine({
    required this.label,
    required this.value,
    required this.ratio,
    required this.color,
  });
  final String label;
  final int value;
  final double ratio;
  final Color color;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          Text(
            money(context, value),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
      const SizedBox(height: 8),
      LinearProgressIndicator(
        value: ratio.clamp(0, 1),
        minHeight: 10,
        color: color,
        backgroundColor: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(10),
      ),
    ],
  );
}
