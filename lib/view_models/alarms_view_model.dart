import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/alarm.dart';
import '../services/alarms_service.dart';

class AlarmsViewModel extends ChangeNotifier {
  final AlarmsService _alarmsService = AlarmsService();
  List<Alarm> _alarms = [];
  bool _isLoading = true;

  List<Alarm> get alarms => _alarms;
  bool get isLoading => _isLoading;

  AlarmsViewModel() {
    _loadAlarms();
  }

  Future<void> _loadAlarms() async {
    _isLoading = true;
    notifyListeners();
    _alarms = await _alarmsService.getAlarms();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addAlarm(Alarm alarm) async {
    await _alarmsService.saveAlarm(alarm);
    _alarms.add(alarm);
    // Sort alarms by time
    _alarms.sort((a, b) {
      final aTime = a.time.hour * 60 + a.time.minute;
      final bTime = b.time.hour * 60 + b.time.minute;
      return aTime.compareTo(bTime);
    });
    notifyListeners();
  }

  Future<void> updateAlarm(Alarm alarm) async {
    await _alarmsService.saveAlarm(alarm); // This handles update if ID exists
    final index = _alarms.indexWhere((a) => a.id == alarm.id);
    if (index != -1) {
      _alarms[index] = alarm;
      notifyListeners();
    }
  }

  Future<void> deleteAlarm(String id) async {
    // 1. Cancel the notification/schedule
    await _alarmsService.cancelAlarm(id);
    
    // 2. Remove from local storage
    await _alarmsService.deleteAlarm(id);
    
    // 3. Remove from local list and update UI
    _alarms.removeWhere((alarm) => alarm.id == id);
    notifyListeners();
  }

  Future<void> toggleAlarm(String id, bool value) async {
    final index = _alarms.indexWhere((a) => a.id == id);
    if (index != -1) {
      final alarm = _alarms[index];
      final updatedAlarm = alarm.copyWith(isEnabled: value);
      
      if (value) {
        await _alarmsService.scheduleAlarm(updatedAlarm);
      } else {
        await _alarmsService.cancelAlarm(updatedAlarm.id);
      }
      
      await updateAlarm(updatedAlarm);
    }
  }
}
