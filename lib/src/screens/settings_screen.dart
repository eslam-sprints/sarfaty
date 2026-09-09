import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../state/finance_store.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.store});
  final FinanceStore store;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
    children: [
      Text(
        'الإعدادات',
        style: Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 6),
      Text(
        'المظهر ونسخة احتياطية ونقل البيانات',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      const SizedBox(height: 20),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'مظهر التطبيق',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'system',
                    label: Text('تلقائي'),
                    icon: Icon(Icons.brightness_auto_rounded),
                  ),
                  ButtonSegment(
                    value: 'light',
                    label: Text('فاتح'),
                    icon: Icon(Icons.light_mode_outlined),
                  ),
                  ButtonSegment(
                    value: 'dark',
                    label: Text('داكن'),
                    icon: Icon(Icons.dark_mode_outlined),
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
        child: Column(
          children: [
            ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.upload_file_rounded),
              ),
              title: const Text(
                'تصدير البيانات',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: const Text('إنشاء ملف JSON ومشاركته أو حفظه'),
              trailing: const Icon(Icons.chevron_left_rounded),
              onTap: () => _export(context),
            ),
            const Divider(height: 1, indent: 72),
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.download_rounded)),
              title: const Text(
                'استيراد نسخة احتياطية',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: const Text('اختيار ملف JSON من هاتف آخر'),
              trailing: const Icon(Icons.chevron_left_rounded),
              onTap: () => _import(context),
            ),
            const Divider(height: 1, indent: 72),
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.menu_book_rounded)),
              title: const Text(
                'إعادة عرض المقدمة',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: const Text('عرض شاشات التعريف مرة أخرى'),
              trailing: const Icon(Icons.chevron_left_rounded),
              onTap: () async {
                try {
                  await store.resetOnboarding();
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
      const SizedBox(height: 12),
      Card(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock_outline_rounded, color: Color(0xFF0D9488)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'بياناتك محفوظة محلياً على الجهاز. احتفظ بملف النسخة الاحتياطية في مكان آمن؛ الاستيراد يستبدل البيانات الحالية بعد تأكيدك.',
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );

  Future<void> _export(BuildContext context) async {
    try {
      final directory = await getTemporaryDirectory();
      final file = File(
        '${directory.path}/sarfaty-backup-${DateTime.now().millisecondsSinceEpoch}.json',
      );
      await file.writeAsString(await store.exportJson(), flush: true);
      await SharePlus.instance.share(
        ShareParams(
          title: 'نسخة صرفتي الاحتياطية',
          text: 'ملف نسخة احتياطية من تطبيق صرفتي',
          files: [XFile(file.path, mimeType: 'application/json')],
        ),
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('تعذر تصدير البيانات: $error')));
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
              title: const Text('استبدال البيانات الحالية؟'),
              content: const Text(
                'سيتم حذف البيانات الحالية واستبدالها بالكامل بمحتوى النسخة الاحتياطية. لا يمكن التراجع عن ذلك.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('استيراد واستبدال'),
                ),
              ],
            ),
          ) ??
          false;
      if (!confirmed) return;
      await store.importJson(source);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم استيراد النسخة الاحتياطية بنجاح')),
        );
      }
    } on PersistenceException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } on FormatException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ملف غير صالح: ${error.message}')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تعذر قراءة الملف. تأكد أنه نسخة JSON صالحة من صرفتي.',
            ),
          ),
        );
      }
    }
  }
}
