import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'daily_reminder_schedule.dart';

typedef ReminderClock = DateTime Function();

class ReminderSchedulingException implements Exception {
  const ReminderSchedulingException();
}

abstract interface class ExpenseReminderService {
  Future<bool> requestPermission();

  Future<void> ensureScheduled({required String languageCode});

  Future<void> replaceSchedule({required String languageCode});

  Future<void> cancelScheduled();
}

class DisabledExpenseReminderService implements ExpenseReminderService {
  const DisabledExpenseReminderService();

  @override
  Future<void> cancelScheduled() async {}

  @override
  Future<void> ensureScheduled({required String languageCode}) async {}

  @override
  Future<void> replaceSchedule({required String languageCode}) async {}

  @override
  Future<bool> requestPermission() async => false;
}

class AndroidExpenseReminderService implements ExpenseReminderService {
  AndroidExpenseReminderService({
    FlutterLocalNotificationsPlugin? notifications,
    ReminderClock? clock,
    Random Function()? randomFactory,
  }) : _notifications = notifications ?? FlutterLocalNotificationsPlugin(),
       _clock = clock ?? DateTime.now,
       _randomFactory = randomFactory ?? Random.new;

  static const _minimumPendingBeforeRefresh = 60;
  static const _channelId = 'expense_entry_reminders';

  final FlutterLocalNotificationsPlugin _notifications;
  final ReminderClock _clock;
  final Random Function() _randomFactory;
  var _initialized = false;

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<bool> requestPermission() async {
    if (!_isAndroid) return false;
    await _initialize();
    try {
      final android = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await android?.requestNotificationsPermission() ?? false;
    } catch (_) {
      throw const ReminderSchedulingException();
    }
  }

  @override
  Future<void> ensureScheduled({required String languageCode}) async {
    if (!_isAndroid) return;
    await _initialize();
    final pending = await _reminderPendingRequests();
    if (pending.length >= _minimumPendingBeforeRefresh) return;
    await _replacePending(pending, languageCode);
  }

  @override
  Future<void> replaceSchedule({required String languageCode}) async {
    if (!_isAndroid) return;
    await _initialize();
    await _replacePending(await _reminderPendingRequests(), languageCode);
  }

  @override
  Future<void> cancelScheduled() async {
    if (!_isAndroid) return;
    await _initialize();
    await _cancel(await _reminderPendingRequests());
  }

  Future<void> _initialize() async {
    if (_initialized) return;
    try {
      tz_data.initializeTimeZones();
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimezone.identifier));
      final initialized = await _notifications.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_stat_sarfaty'),
        ),
      );
      if (initialized == false) throw const ReminderSchedulingException();
      _initialized = true;
    } catch (_) {
      throw const ReminderSchedulingException();
    }
  }

  Future<List<PendingNotificationRequest>> _reminderPendingRequests() async {
    try {
      final pending = await _notifications.pendingNotificationRequests();
      return pending
          .where((request) => isExpenseReminderNotificationId(request.id))
          .toList();
    } catch (_) {
      throw const ReminderSchedulingException();
    }
  }

  Future<void> _replacePending(
    List<PendingNotificationRequest> pending,
    String languageCode,
  ) async {
    try {
      await _cancel(pending);
      final schedule = buildExpenseReminderSchedule(
        now: _clock(),
        random: _randomFactory(),
      );
      await _scheduleAll(schedule, languageCode == 'en');
    } on ReminderSchedulingException {
      rethrow;
    } catch (error, stackTrace) {
      await _cleanUpPartialSchedule(error, stackTrace);
      throw const ReminderSchedulingException();
    }
  }

  Future<void> _scheduleAll(
    List<ScheduledExpenseReminder> schedule,
    bool isEnglish,
  ) async {
    final details = _notificationDetails(isEnglish);
    for (final reminder in schedule) {
      final time = reminder.localTime;
      await _notifications.zonedSchedule(
        id: reminder.id,
        title: isEnglish ? 'Record your expenses' : 'سجّل مصروفاتك',
        body: isEnglish
            ? 'Take a moment to add today\'s expenses in Sarfaty.'
            : 'خد دقيقة وسجّل مصروفات اليوم في صرفتي.',
        scheduledDate: tz.TZDateTime(
          tz.local,
          time.year,
          time.month,
          time.day,
          time.hour,
          time.minute,
        ),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'expense-reminder',
      );
    }
  }

  NotificationDetails _notificationDetails(bool isEnglish) =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          isEnglish ? 'Expense reminders' : 'تذكيرات المصروفات',
          channelDescription: isEnglish
              ? 'Daily reminders to record expenses'
              : 'تذكيرات يومية لتسجيل المصروفات',
          importance: Importance.high,
          priority: Priority.high,
        ),
      );

  Future<void> _cleanUpPartialSchedule(
    Object schedulingError,
    StackTrace schedulingStack,
  ) async {
    try {
      await _cancel(await _reminderPendingRequests());
    } catch (cleanupError, cleanupStack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: cleanupError,
          stack: cleanupStack,
          context: ErrorDescription('while cleaning up partial reminders'),
          informationCollector: () => [
            ErrorDescription('Original scheduling error: $schedulingError'),
            DiagnosticsStackTrace('Original stack', schedulingStack),
          ],
        ),
      );
    }
  }

  Future<void> _cancel(List<PendingNotificationRequest> pending) async {
    try {
      for (final request in pending) {
        await _notifications.cancel(id: request.id);
      }
    } catch (_) {
      throw const ReminderSchedulingException();
    }
  }
}
