part of 'cards_screen.dart';

class _PaymentSheet extends StatefulWidget {
  const _PaymentSheet({required this.due});

  /// Due amount in piastres.
  final int due;
  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  final key = GlobalKey<FormState>();
  final controller = TextEditingController();
  bool full = true;
  @override
  void dispose() {
    controller.dispose();
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'تسجيل سداد البطاقة'.tr(context, 'Record card payment'),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            '${'المستحق الحالي'.tr(context, 'Current due')}: ${money(context, widget.due)}',
          ),
          const SizedBox(height: 16),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(
                value: true,
                label: Text('سداد كامل'.tr(context, 'Full payment')),
              ),
              ButtonSegment(
                value: false,
                label: Text('سداد جزئي'.tr(context, 'Partial payment')),
              ),
            ],
            selected: {full},
            onSelectionChanged: (value) => setState(() => full = value.first),
          ),
          if (!full) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: InputDecoration(
                labelText: 'مبلغ السداد'.tr(context, 'Payment amount'),
                suffixText: context.isArabic ? 'ج.م' : 'EGP',
              ),
              validator: (value) {
                final pounds = double.tryParse(value ?? '');
                if (pounds == null || pounds <= 0) {
                  return 'أدخل مبلغاً موجباً'.tr(
                    context,
                    'Enter a positive amount',
                  );
                }
                if (poundsToPiastres(pounds) > widget.due) {
                  return 'لا يمكن أن يزيد المبلغ عن المستحق'.tr(
                    context,
                    'Amount cannot exceed the current due',
                  );
                }
                return null;
              },
            ),
          ],
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () {
              if (!full && !key.currentState!.validate()) return;
              Navigator.pop(
                context,
                full
                    ? piastresToPounds(widget.due)
                    : double.parse(controller.text),
              );
            },
            child: Text('تأكيد السداد'.tr(context, 'Confirm payment')),
          ),
        ],
      ),
    ),
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
              'إضافة بطاقة'.tr(context, 'Add card'),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: name,
              decoration: InputDecoration(
                labelText: 'اسم البطاقة أو البنك'.tr(
                  context,
                  'Card or bank name',
                ),
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'أدخل اسم البطاقة'.tr(context, 'Enter the card name')
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: limit,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'الحد الائتماني'.tr(context, 'Credit limit'),
                suffixText: context.isArabic ? 'ج.م' : 'EGP',
              ),
              validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0
                  ? 'أدخل حداً صحيحاً'.tr(context, 'Enter a valid limit')
                  : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: statementDay,
                    decoration: InputDecoration(
                      labelText: 'يوم قفل الكشف'.tr(context, 'Statement day'),
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
                    initialValue: dueDay,
                    decoration: InputDecoration(
                      labelText: 'يوم السداد'.tr(context, 'Due day'),
                    ),
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
              child: Text('حفظ البطاقة'.tr(context, 'Save card')),
            ),
          ],
        ),
      ),
    ),
  );
}
