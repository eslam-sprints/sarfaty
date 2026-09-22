import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sarfaty/src/notifications/daily_reminder_schedule.dart';

void main() {
  test('generates two daily reminders inside the window with a safe gap', () {
    final schedule = buildExpenseReminderSchedule(
      now: DateTime(2026, 9, 22, 14),
      random: Random(42),
      days: 30,
    );

    expect(schedule, hasLength(60));
    final byDate = <String, List<DateTime>>{};
    for (final reminder in schedule) {
      final time = reminder.localTime;
      final key = '${time.year}-${time.month}-${time.day}';
      byDate.putIfAbsent(key, () => []).add(time);
      final minute = time.hour * 60 + time.minute;
      expect(minute, greaterThanOrEqualTo(reminderWindowStartMinute));
      expect(minute, lessThan(reminderWindowEndMinute));
    }
    for (final reminders in byDate.values) {
      expect(reminders, hasLength(2));
      expect(
        reminders.last.difference(reminders.first).inMinutes,
        greaterThanOrEqualTo(reminderMinimumGapMinutes),
      );
    }
  });

  test('never schedules a reminder in the past on the activation day', () {
    final now = DateTime(2026, 9, 22, 23, 30);
    final schedule = buildExpenseReminderSchedule(
      now: now,
      random: Random(7),
      days: 2,
    );

    expect(
      schedule.every((reminder) => reminder.localTime.isAfter(now)),
      isTrue,
    );
    expect(
      schedule.where((reminder) => reminder.localTime.day == 23),
      hasLength(2),
    );
  });

  test('notification ids are stable and unique for each day and slot', () {
    final day = DateTime(2026, 9, 22);
    final first = reminderNotificationId(day, 0);
    final second = reminderNotificationId(day, 1);

    expect(first, isNot(second));
    expect(first, reminderNotificationId(day, 0));
    expect(isExpenseReminderNotificationId(first), isTrue);
    expect(isExpenseReminderNotificationId(42), isFalse);
  });
}
