import 'package:flutter/widgets.dart';

import '../models/finance_models.dart';

extension AppLocale on BuildContext {
  bool get isArabic => Localizations.localeOf(this).languageCode == 'ar';
}

extension LocalizedText on String {
  String tr(BuildContext context, String english) =>
      context.isArabic ? this : english;

  String localizedError(BuildContext context) {
    if (context.isArabic) return this;
    return _englishErrors[this] ?? this;
  }
}

extension LocalizedExpenseCategory on ExpenseCategory {
  String labelFor(BuildContext context) => label.tr(context, switch (this) {
    ExpenseCategory.food => 'Food & drinks',
    ExpenseCategory.transport => 'Transport',
    ExpenseCategory.bills => 'Bills',
    ExpenseCategory.shopping => 'Shopping',
    ExpenseCategory.entertainment => 'Entertainment',
    ExpenseCategory.health => 'Health',
    ExpenseCategory.home => 'Home',
    ExpenseCategory.education => 'Education',
    ExpenseCategory.transfers => 'Transfers',
    ExpenseCategory.other => 'Other',
  });
}

extension LocalizedExpense on Expense {
  String categoryLabelFor(BuildContext context) =>
      customCategoryName ?? category.labelFor(context);
}

extension LocalizedPaymentMethod on PaymentMethod {
  String labelFor(BuildContext context) => switch (this) {
    PaymentMethod.cash => 'كاش'.tr(context, 'Cash'),
    PaymentMethod.credit => 'كريديت'.tr(context, 'Credit'),
  };
}

const _englishErrors = {
  'تعذر حفظ المصروف. حاول مرة أخرى.': 'Could not save the expense. Try again.',
  'تعذر حفظ التعديلات. حاول مرة أخرى.':
      'Could not save the changes. Try again.',
  'تعذر حفظ التصنيف. حاول مرة أخرى.': 'Could not save the category. Try again.',
  'اسم التصنيف مطلوب': 'Category name is required',
  'اسم التصنيف طويل جداً': 'Category name is too long',
  'هذا التصنيف موجود بالفعل': 'This category already exists',
  'تعذر حذف المصروف. حاول مرة أخرى.':
      'Could not delete the expense. Try again.',
  'تعذر حفظ البطاقة. حاول مرة أخرى.': 'Could not save the card. Try again.',
  'تعذر تسجيل السداد. حاول مرة أخرى.':
      'Could not record the payment. Try again.',
  'تعذر حفظ الإعدادات. حاول مرة أخرى.':
      'Could not save the settings. Try again.',
  'تعذر حفظ إعداد التذكيرات. حاول مرة أخرى.':
      'Could not save the reminder setting. Try again.',
  'تعذر حفظ اللغة. حاول مرة أخرى.': 'Could not save the language. Try again.',
  'تعذر حفظ الرصيد. حاول مرة أخرى.': 'Could not save the balance. Try again.',
  'تعذر حفظ إعداد قفل التطبيق. حاول مرة أخرى.':
      'Could not save the app lock setting. Try again.',
  'تعذر استيراد النسخة الاحتياطية. حاول مرة أخرى.':
      'Could not import the backup. Try again.',
  'نسخة احتياطية غير مدعومة': 'Unsupported backup',
  'بيانات النسخة الاحتياطية ناقصة': 'The backup is incomplete',
  'تحتوي النسخة على مراجع بطاقات غير صحيحة':
      'The backup contains invalid card references',
  'تحتوي النسخة على مراجع تصنيفات غير صحيحة':
      'The backup contains invalid category references',
};
