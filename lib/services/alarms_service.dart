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

  // Alias for loadAlarms to match ViewModel
  Future<List<Alarm>> getAlarms() => loadAlarms();

  // Alias for saveAlarmData to match ViewModel
  Future<void> saveAlarm(Alarm alarm) => saveAlarmData(alarm);

  // Alias for scheduleAlarmAt
  Future<void> scheduleAlarm(Alarm alarm) => scheduleAlarmAt(alarm);

  Future<void> saveAlarmData(Alarm alarm) async {
    final box = await Hive.openBox<Alarm>('alarms');
    // If alarm is already in box (it has a key), Hive updates it automatically.
    // If it's new, we add it.
    if (alarm.isInBox) {
      await alarm.save();
    } else {
      await box.add(alarm);
    }
    
    // Update cache
    if (_cachedAlarms == null) {
      await loadAlarms();
    } else {
      if (!_cachedAlarms!.contains(alarm)) {
        _cachedAlarms!.add(alarm);
      }
    }
  }

  Future<List<Alarm>> loadAlarms() async {
    final box = await Hive.openBox<Alarm>('alarms');
    _cachedAlarms = box.values.toList();
    return _cachedAlarms!;
  }

  Future<void> deleteAlarm(String idStr) async {
    // Convert string ID back to int if necessary, or find by ID field
    final int id = int.tryParse(idStr) ?? 0;
    final box = await Hive.openBox<Alarm>('alarms');
    
    final alarmToDelete = box.values.firstWhere(
      (a) => a.id == id, 
      orElse: () => Alarm(time: DateTime.now(), days: {}),
    );

    if (alarmToDelete.isInBox) {
      await alarmToDelete.delete();
    }
    
    _cachedAlarms?.removeWhere((a) => a.id == id);
  }

  Future<void> cancelAlarm(dynamic idOrAlarm) async {
    if (idOrAlarm is Alarm) {
      await _cancelAlarmInternal(idOrAlarm);
    } else if (idOrAlarm is String || idOrAlarm is int) {
      // If passed an ID, try to find it in cache
      int id = idOrAlarm is String ? int.parse(idOrAlarm) : idOrAlarm;
      final alarm = _cachedAlarms?.firstWhere((a) => a.id == id, orElse: () => Alarm(time: DateTime.now(), days: {}));
      if (alarm != null && alarm.isInBox) {
        await _cancelAlarmInternal(alarm);
      }
    }
  }

  Future<void> _cancelAlarmInternal(Alarm alarm) async {
    alarm.days.forEach((dayKey, isActive) async {
      if(isActive) {
        final targetWeekday = dayStringToWeekday[dayKey];
        if(targetWeekday != null) {
          final int truncatedAlarmId = alarm.id & ((1 << 28) - 1);
          final int id = (((truncatedAlarmId << 3) | (targetWeekday & 0x7)) & 0xFFFFFFFF);
          await AndroidAlarmManager.cancel(id);
        }
      }
    });
  }

  Future<void> scheduleAlarmAt(Alarm alarm) async {
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
