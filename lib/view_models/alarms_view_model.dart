import 'package:flutter/material.dart';
import '../models/alarm.dart';
import '../services/alarms_service.dart';

class AlarmsViewModel extends ChangeNotifier {
  final AlarmsService _alarmsService = AlarmsService();
  List<Alarm> _alarms = [];
  bool _isLoading = true;

  List<Alarm> get alarms => _alarms;
  bool get isLoading => _isLoading;

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
    await _alarmsService.scheduleAlarm(alarm);
    _alarms.add(alarm);
    _sortAlarms();
    notifyListeners();
  }

  Future<void> updateAlarm(Alarm alarm) async {
    await _alarmsService.saveAlarm(alarm);
    final index = _alarms.indexWhere((a) => a.id == alarm.id);
    if (index != -1) {
      _alarms[index] = alarm;
      _sortAlarms();
      notifyListeners();
    }
  }

  Future<void> deleteAlarm(int id) async {
    // 1. Cancel
    await _alarmsService.cancelAlarm(id);
    // 2. Delete from storage
    await _alarmsService.deleteAlarm(id.toString());
    // 3. Remove locally
    _alarms.removeWhere((alarm) => alarm.id == id);
    notifyListeners();
  }

  Future<void> toggleAlarm(int id, bool value) async {
    final index = _alarms.indexWhere((a) => a.id == id);
    if (index != -1) {
      final alarm = _alarms[index];
      final updatedAlarm = alarm.copyWith(isEnabled: value);
      
      if (value) {
        await _alarmsService.scheduleAlarm(updatedAlarm);
      } else {
        await _alarmsService.cancelAlarm(updatedAlarm);
      }
      
      await updateAlarm(updatedAlarm);
    }
  }

  void _sortAlarms() {
    _alarms.sort((a, b) {
      final aTime = a.time.hour * 60 + a.time.minute;
      final bTime = b.time.hour * 60 + b.time.minute;
      return aTime.compareTo(bTime);
    });
  }
}
