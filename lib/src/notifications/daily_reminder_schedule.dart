import 'dart:math';

const reminderWindowStartMinute = 15 * 60;
const reminderWindowEndMinute = 24 * 60;
const reminderMinimumGapMinutes = 2 * 60;
const reminderScheduleDays = 180;
const reminderNotificationIdBase = 100000000;

class ScheduledExpenseReminder {
  const ScheduledExpenseReminder({required this.id, required this.localTime});

  final int id;
  final DateTime localTime;
}

List<int> generateDailyReminderMinutes(
  Random random, {
  int startMinute = reminderWindowStartMinute,
  int endMinute = reminderWindowEndMinute,
  int minimumGapMinutes = reminderMinimumGapMinutes,
}) {
  final windowMinutes = endMinute - startMinute;
  if (windowMinutes <= minimumGapMinutes) {
    throw ArgumentError('Reminder window must be wider than the minimum gap.');
  }

  final firstOffset = random.nextInt(windowMinutes);
  final lowerCount = max(0, firstOffset - minimumGapMinutes + 1);
  final upperStart = firstOffset + minimumGapMinutes;
  final upperCount = max(0, windowMinutes - upperStart);
  final secondChoice = random.nextInt(lowerCount + upperCount);
  final secondOffset = secondChoice < lowerCount
      ? secondChoice
      : upperStart + secondChoice - lowerCount;
  final result = [startMinute + firstOffset, startMinute + secondOffset]
    ..sort();
  return result;
}

List<ScheduledExpenseReminder> buildExpenseReminderSchedule({
  required DateTime now,
  required Random random,
  int days = reminderScheduleDays,
}) {
  if (days <= 0) return const [];

  final today = DateTime(now.year, now.month, now.day);
  final reminders = <ScheduledExpenseReminder>[];
  for (var dayOffset = 0; dayOffset < days; dayOffset++) {
    final day = DateTime(today.year, today.month, today.day + dayOffset);
    final minutes = generateDailyReminderMinutes(random);
    for (var slot = 0; slot < minutes.length; slot++) {
      final minute = minutes[slot];
      final localTime = DateTime(
        day.year,
        day.month,
        day.day,
        minute ~/ 60,
        minute % 60,
      );
      if (!localTime.isAfter(now)) continue;
      reminders.add(
        ScheduledExpenseReminder(
          id: reminderNotificationId(day, slot),
          localTime: localTime,
        ),
      );
    }
  }
  return reminders;
}

int reminderNotificationId(DateTime day, int slot) {
  final dateKey = day.year * 10000 + day.month * 100 + day.day;
  return reminderNotificationIdBase + dateKey * 2 + slot;
}

bool isExpenseReminderNotificationId(int id) =>
    id >= reminderNotificationIdBase &&
    id < reminderNotificationIdBase + 100000000;
