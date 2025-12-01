import 'package:flutter/material.dart';
import '../models/alarm.dart';
import '../services/alarms_service.dart';

class AlarmsViewModel extends ChangeNotifier {
  final AlarmsService _alarmsService = AlarmsService();
  List<Alarm> _alarms = [];
  bool _isLoading = true;

  // Mock sleep data to prevent UI errors
  final DateTime _sleepTime = DateTime(2024, 1, 1, 23, 0);
  final Map<String, bool> _sleepDays = {'M':true,'T':true,'W':true,'T ':true,'F':true,'S':false,'S ':false};
  bool _isSleepEnabled = true;

  List<Alarm> get alarms => _alarms;
  bool get isLoading => _isLoading;
  
  // Sleep getters
  DateTime get sleepTime => _sleepTime;
  Map<String, bool> get sleepDays => _sleepDays;
  bool get isSleepEnabled => _isSleepEnabled;

  AlarmsViewModel() {
    loadAlarms();
  }

  Future<void> loadAlarms() async {
    _isLoading = true;
    notifyListeners();
    _alarms = await _alarmsService.getAlarms();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addAlarm(Alarm alarm) async {
    await _alarmsService.saveAlarm(alarm);
    if (alarm.isEnabled) {
      await _alarmsService.scheduleAlarm(alarm);
    }
    _alarms.add(alarm);
    _sortAlarms();
    notifyListeners();
  }

  Future<void> updateAlarm(Alarm alarm) async {
    await _alarmsService.saveAlarm(alarm);
    // Reschedule if enabled, otherwise just save
    if (alarm.isEnabled) {
      await _alarmsService.scheduleAlarm(alarm);
    } else {
      await _alarmsService.cancelAlarm(alarm.id);
    }

    final index = _alarms.indexWhere((a) => a.id == alarm.id);
    if (index != -1) {
      _alarms[index] = alarm;
      _sortAlarms();
      notifyListeners();
    }
  }

  Future<void> deleteAlarm(int id) async {
    await _alarmsService.cancelAlarm(id);
    await _alarmsService.deleteAlarm(id);
    _alarms.removeWhere((alarm) => alarm.id == id);
    notifyListeners();
  }

  // Alias for UI compatibility
  Future<void> toggleAlarmState(int id, bool value) => toggleAlarm(id, value);

  Future<void> toggleAlarm(int id, bool value) async {
    final index = _alarms.indexWhere((a) => a.id == id);
    if (index != -1) {
      final alarm = _alarms[index];
      final updatedAlarm = alarm.copyWith(isEnabled: value);
      
      if (value) {
        await _alarmsService.scheduleAlarm(updatedAlarm);
      } else {
        await _alarmsService.cancelAlarm(id);
      }
      
      await updateAlarm(updatedAlarm);
    }
  }

  void toggleSleepEnabled(bool value) {
    _isSleepEnabled = value;
    notifyListeners();
  }

  void _sortAlarms() {
    _alarms.sort((a, b) {
      final aTime = a.time.hour * 60 + a.time.minute;
      final bTime = b.time.hour * 60 + b.time.minute;
      return aTime.compareTo(bTime);
    });
  }
}