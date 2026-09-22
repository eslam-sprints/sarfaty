import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../l10n/app_strings.dart';
import '../notifications/expense_reminder_service.dart';
import '../security/biometric_auth.dart';
import '../state/finance_store.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.store,
    required this.biometricAuthenticator,
    required this.reminderService,
  });
  final FinanceStore store;
  final BiometricAuthenticator biometricAuthenticator;
  final ExpenseReminderService reminderService;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
    children: [
      Text(
        'الإعدادات'.tr(context, 'Settings'),
        style: Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 6),
      Text(
        'المظهر واللغة ونسخة احتياطية ونقل البيانات'.tr(
          context,
          'Appearance, language, backup and data transfer',
        ),
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      const SizedBox(height: 20),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'مظهر التطبيق'.tr(context, 'App appearance'),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'system',
                    label: Text('تلقائي'.tr(context, 'System')),
                    icon: const Icon(Icons.brightness_auto_rounded),
                  ),
                  ButtonSegment(
                    value: 'light',
                    label: Text('فاتح'.tr(context, 'Light')),
                    icon: const Icon(Icons.light_mode_outlined),
                  ),
                  ButtonSegment(
                    value: 'dark',
                    label: Text('داكن'.tr(context, 'Dark')),
                    icon: const Icon(Icons.dark_mode_outlined),
                  ),
                ],
                selected: {store.themePreference},
                onSelectionChanged: (value) async {
                  try {
                    await store.setThemePreference(value.first);
                  } on PersistenceException catch (error) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(error.message)));
                  }
                },
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'لغة التطبيق'.tr(context, 'App language'),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'ar', label: Text('العربية')),
                  ButtonSegment(value: 'en', label: Text('English')),
                ],
                selected: {store.languagePreference},
                onSelectionChanged: (value) =>
                    _setLanguagePreference(context, value.first),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      Card(
        child: SwitchListTile(
          secondary: const CircleAvatar(
            child: Icon(Icons.notifications_active_outlined),
          ),
          title: Text(
            'تذكيرات تسجيل المصروفات'.tr(context, 'Expense entry reminders'),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            'تذكيران في وقتين عشوائيين مختلفين يومياً بين ٣ مساءً و١٢ منتصف الليل'.tr(
              context,
              'Two reminders at different random times each day between 3 PM and midnight',
            ),
          ),
          value: store.expenseRemindersEnabled,
          onChanged: (enabled) => _setExpenseReminders(context, enabled),
        ),
      ),
      const SizedBox(height: 12),
      Card(
        child: SwitchListTile(
          secondary: const CircleAvatar(child: Icon(Icons.fingerprint_rounded)),
          title: Text(
            'قفل التطبيق بالبصمة'.tr(context, 'Biometric app lock'),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            'استخدام البصمة أو PIN الجهاز عند فتح صرفتي'.tr(
              context,
              'Use biometrics or the device PIN when opening Sarfaty',
            ),
          ),
          value: store.biometricLockEnabled,
          onChanged: (enabled) => _setBiometricLock(context, enabled),
        ),
      ),
      const SizedBox(height: 12),
      Card(
        child: Column(
          children: [
            ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.upload_file_rounded),
              ),
              title: Text(
                'تصدير البيانات'.tr(context, 'Export data'),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                'إنشاء ملف JSON ومشاركته أو حفظه'.tr(
                  context,
                  'Create, share or save a JSON file',
                ),
              ),
              trailing: const Icon(Icons.chevron_left_rounded),
              onTap: () => _export(context),
            ),
            const Divider(height: 1, indent: 72),
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.download_rounded)),
              title: Text(
                'استيراد نسخة احتياطية'.tr(context, 'Import backup'),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                'اختيار ملف JSON من هاتف آخر'.tr(
                  context,
                  'Choose a JSON file from another phone',
                ),
              ),
              trailing: const Icon(Icons.chevron_left_rounded),
              onTap: () => _import(context),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Card(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lock_outline_rounded, color: Color(0xFF0D9488)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'بياناتك محفوظة محلياً على الجهاز. احتفظ بملف النسخة الاحتياطية في مكان آمن؛ الاستيراد يستبدل البيانات الحالية بعد تأكيدك.'.tr(
                    context,
                    'Your data is stored locally. Keep backups safe; importing replaces current data after confirmation.',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );

  Future<void> _setLanguagePreference(
    BuildContext context,
    String languageCode,
  ) async {
    try {
      await store.setLanguagePreference(languageCode);
    } on PersistenceException catch (error) {
      if (!context.mounted) return;
      _showMessage(context, error.message.localizedError(context));
      return;
    }
    if (!store.expenseRemindersEnabled) return;
    try {
      await reminderService.replaceSchedule(languageCode: languageCode);
    } on ReminderSchedulingException {
      if (!context.mounted) return;
      _showReminderError(context);
    }
  }

  Future<void> _setExpenseReminders(BuildContext context, bool enabled) async {
    try {
      if (enabled) {
        final granted = await reminderService.requestPermission();
        if (!granted) {
          if (!context.mounted) return;
          _showMessage(
            context,
            'لن تعمل التذكيرات بدون السماح بالإشعارات من إعدادات الجهاز.'.tr(
              context,
              'Reminders need notification permission in device settings.',
            ),
          );
          return;
        }
        await reminderService.replaceSchedule(
          languageCode: store.languagePreference,
        );
        try {
          await store.setExpenseRemindersEnabled(true);
        } on PersistenceException {
          await _rollbackReminderChange(reminderService.cancelScheduled);
          rethrow;
        }
      } else {
        await reminderService.cancelScheduled();
        try {
          await store.setExpenseRemindersEnabled(false);
        } on PersistenceException {
          await _rollbackReminderChange(
            () => reminderService.replaceSchedule(
              languageCode: store.languagePreference,
            ),
          );
          rethrow;
        }
      }
    } on PersistenceException catch (error) {
      if (!context.mounted) return;
      _showMessage(context, error.message.localizedError(context));
    } on ReminderSchedulingException {
      if (!context.mounted) return;
      _showReminderError(context);
    }
  }

  Future<void> _rollbackReminderChange(Future<void> Function() action) async {
    try {
      await action();
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          context: ErrorDescription('while rolling back reminder settings'),
        ),
      );
    }
  }

  void _showReminderError(BuildContext context) => _showMessage(
    context,
    'تعذر إعداد التذكيرات. حاول مرة أخرى.'.tr(
      context,
      'Could not schedule reminders. Try again.',
    ),
  );

  void _showMessage(BuildContext context, String message) =>
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));

  Future<void> _setBiometricLock(BuildContext context, bool enabled) async {
    if (enabled && !await biometricAuthenticator.isAvailable()) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'فعّل بصمة على الجهاز أولاً، ثم حاول تشغيل قفل صرفتي مرة أخرى.'.tr(
              context,
              'Set up biometrics on your device first, then try enabling the app lock again.',
            ),
          ),
        ),
      );
      return;
    }
    try {
      await store.setBiometricLockEnabled(enabled);
      if (!context.mounted || enabled) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم إيقاف قفل التطبيق'.tr(context, 'App lock disabled'),
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

  Future<void> _export(BuildContext context) async {
    final shareTitle = 'نسخة صرفتي الاحتياطية'.tr(context, 'Sarfaty backup');
    final shareText = 'ملف نسخة احتياطية من تطبيق صرفتي'.tr(
      context,
      'A backup file from Sarfaty',
    );
    try {
      final directory = await getTemporaryDirectory();
      final file = File(
        '${directory.path}/sarfaty-backup-${DateTime.now().millisecondsSinceEpoch}.json',
      );
      await file.writeAsString(await store.exportJson(), flush: true);
      await SharePlus.instance.share(
        ShareParams(
          title: shareTitle,
          text: shareText,
          files: [XFile(file.path, mimeType: 'application/json')],
        ),
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${'تعذر تصدير البيانات'.tr(context, 'Could not export data')}: $error',
            ),
          ),
        );
      }
    }
  }

  Future<void> _import(BuildContext context) async {
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );
      if (picked == null) return;
      final selected = picked.files.single;
      final source = selected.bytes != null
          ? String.fromCharCodes(selected.bytes!)
          : await File(selected.path!).readAsString();
      FinanceStore.fromBackupJson(source);
      if (!context.mounted) return;
      final confirmed =
          await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: Text(
                'استبدال البيانات الحالية؟'.tr(
                  context,
                  'Replace current data?',
                ),
              ),
              content: Text(
                'سيتم حذف البيانات الحالية واستبدالها بالكامل بمحتوى النسخة الاحتياطية. لا يمكن التراجع عن ذلك.'.tr(
                  context,
                  'Current data will be deleted and replaced by this backup. This cannot be undone.',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text('إلغاء'.tr(context, 'Cancel')),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: Text(
                    'استيراد واستبدال'.tr(context, 'Import and replace'),
                  ),
                ),
              ],
            ),
          ) ??
          false;
      if (!confirmed) return;
      await store.importJson(source);
      if (!context.mounted) return;
      await _syncImportedReminders(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم استيراد النسخة الاحتياطية بنجاح'.tr(
                context,
                'Backup imported successfully',
              ),
            ),
          ),
        );
      }
    } on PersistenceException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message.localizedError(context))),
        );
      }
    } on FormatException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${'ملف غير صالح'.tr(context, 'Invalid file')}: ${error.message.localizedError(context)}',
            ),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تعذر قراءة الملف. تأكد أنه نسخة JSON صالحة من صرفتي.'.tr(
                context,
                'Could not read the file. Make sure it is a valid Sarfaty JSON backup.',
              ),
            ),
          ),
        );
      }
    }
  }

  Future<void> _syncImportedReminders(BuildContext context) async {
    try {
      if (!store.expenseRemindersEnabled) {
        await reminderService.cancelScheduled();
        return;
      }
      final granted = await reminderService.requestPermission();
      if (!granted) {
        if (!context.mounted) return;
        _showMessage(
          context,
          'تم استيراد إعداد التذكيرات، لكنه يحتاج صلاحية الإشعارات ليعمل.'.tr(
            context,
            'The reminder setting was imported, but it needs notification permission to work.',
          ),
        );
        return;
      }
      await reminderService.replaceSchedule(
        languageCode: store.languagePreference,
      );
    } on ReminderSchedulingException {
      if (!context.mounted) return;
      _showReminderError(context);
    }
  }
}
