import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:nothing_clock/models/alarm.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

class AlarmsService {
  List<Alarm>? _cachedAlarms;
  static const MethodChannel _channel = MethodChannel('exactAlarmChannel');

  static const Map<String, int> dayStringToWeekday = {
    "SUN": DateTime.sunday,
    "MON": DateTime.monday,
    "TUE": DateTime.tuesday,
    "WED": DateTime.wednesday,
    "THU": DateTime.thursday,
    "FRI": DateTime.friday,
    "SAT": DateTime.saturday,
  };

  Future<List<Alarm>> getAlarms() => loadAlarms();
  Future<void> saveAlarm(Alarm alarm) => saveAlarmData(alarm);
  Future<void> scheduleAlarm(Alarm alarm) => scheduleAlarmAt(alarm);

  // --- Missing Methods Restored ---
  Future<bool> canScheduleExactAlarms() async {
    try {
      final bool? result = await _channel.invokeMethod("canScheduleExactAlarms");
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint("Error checking exact alarms: $e");
      return false;
    }
  }

  static Future<void> openExactAlarmSettings() async {
    try {
      await _channel.invokeMethod("openExactAlarmSettings");
    } on PlatformException catch (e) {
      debugPrint("Error opening settings: $e");
    }
  }
  // --------------------------------

  Future<void> saveAlarmData(Alarm alarm) async {
    final box = await Hive.openBox<Alarm>('alarms');
    if (alarm.isInBox) {
      await alarm.save();
    } else {
      await box.put(alarm.id, alarm);
    }
    _cachedAlarms = box.values.toList();
  }

  Future<List<Alarm>> loadAlarms() async {
    final box = await Hive.openBox<Alarm>('alarms');
    _cachedAlarms = box.values.toList();
    return _cachedAlarms!;
  }

  Future<void> deleteAlarm(int id) async {
    final box = await Hive.openBox<Alarm>('alarms');
    await box.delete(id);
    _cachedAlarms = box.values.toList();
  }

  Future<void> cancelAlarm(dynamic idOrAlarm) async {
    if (idOrAlarm is Alarm) {
      await _cancelAlarmInternal(idOrAlarm);
    } else if (idOrAlarm is int) {
      // Try to find the alarm to get its days for proper cancellation
      final box = await Hive.openBox<Alarm>('alarms');
      final alarm = box.get(idOrAlarm);
      
      if (alarm != null) {
        await _cancelAlarmInternal(alarm);
      } else {
        // Fallback: just cancel the main ID if alarm object not found
        await AndroidAlarmManager.cancel(idOrAlarm);
      }
    }
  }

  Future<void> _cancelAlarmInternal(Alarm alarm) async {
    await AndroidAlarmManager.cancel(alarm.id); // Cancel main ID
    
    // Cancel specific day IDs
    alarm.days.forEach((dayKey, isActive) async {
        final targetWeekday = dayStringToWeekday[dayKey];
        if(targetWeekday != null) {
          final int truncatedAlarmId = alarm.id & ((1 << 28) - 1);
          final int id = (((truncatedAlarmId << 3) | (targetWeekday & 0x7)) & 0xFFFFFFFF);
          await AndroidAlarmManager.cancel(id);
        }
    });
  }

  Future<void> scheduleAlarmAt(Alarm alarm) async {
    // Schedule one-shot if no days selected
    if (alarm.days.values.every((active) => !active)) {
       await AndroidAlarmManager.oneShotAt(
         alarm.time, 
         alarm.id, 
         alarmCallback, 
         exact: true, 
         wakeup: true
       );
       return;
    }

    alarm.days.forEach((dayKey, isActive) async {
      if(isActive) {
        final targetWeekday = dayStringToWeekday[dayKey];
        if(targetWeekday != null) {
          final nextOccourance = _getNextOccurrence(alarm.time, targetWeekday);
          final int truncatedAlarmId = alarm.id & ((1 << 28) - 1);
          final int id = (((truncatedAlarmId << 3) | (targetWeekday & 0x7)) & 0x7FFFFFFF);

          await AndroidAlarmManager.oneShotAt(nextOccourance, id, alarmCallback, exact: true, wakeup: true);
        }
      }
    });
  }

  DateTime _getNextOccurrence(DateTime alarmTime, int targetDay) {
    final now = DateTime.now();
    DateTime scheduled = DateTime(now.year, now.month, now.day, alarmTime.hour, alarmTime.minute);
    int daysToAdd = (targetDay - scheduled.weekday) % 7;
    if(daysToAdd == 0 && scheduled.isBefore(now)) {
      daysToAdd = 7;
    } else if(daysToAdd < 0) {
      daysToAdd += 7;
    }
    return scheduled.add(Duration(days: daysToAdd));
  }

  @pragma('vm:entry-point')
  static void alarmCallback() {
    debugPrint("Alarm triggered!");
    final SendPort? sendPort = IsolateNameServer.lookupPortByName("alarmPort");
    sendPort?.send("showNotification");
  }
}