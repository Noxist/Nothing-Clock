import 'dart:async';
import 'package:flutter/material.dart';

class TimerProvider with ChangeNotifier {
  Timer? _timer;
  int _remainingSeconds = 0;
  int _totalSeconds = 0; // The duration initially set
  bool _isRunning = false;
  bool _isPickerMode = true; // Start in picker mode
  Duration _pickerDuration = const Duration(minutes: 5); // Default 5 min

  // Getters
  int get remainingSeconds => _remainingSeconds;
  int get totalSeconds => _totalSeconds;
  int get originalTotalSeconds => _totalSeconds; // Alias for UI
  bool get isRunning => _isRunning;
  bool get isPickerMode => _isPickerMode;
  bool get isCompleted => _totalSeconds > 0 && _remainingSeconds <= 0 && !_isPickerMode;
  Duration get pickerDuration => _pickerDuration;

  void updatePickerDuration(Duration duration) {
    _pickerDuration = duration;
    notifyListeners();
  }

  void togglePickerMode() {
    if (_isPickerMode) {
      // Switching from Picker to Timer
      _totalSeconds = _pickerDuration.inSeconds;
      _remainingSeconds = _totalSeconds;
      _isPickerMode = false;
      if (_totalSeconds > 0) {
        startTimer();
      }
    } else {
      // Switching from Timer (or Completed) back to Picker
      stopTimer();
      _isPickerMode = true;
      // Reset timer state
      _remainingSeconds = 0;
      _totalSeconds = 0;
    }
    notifyListeners();
  }

  void startTimer() {
    if (_timer != null) return;
    
    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        stopTimer();
        _isRunning = false; // It's finished
        notifyListeners();
        // Here you would trigger sound/notification
      }
    });
    notifyListeners();
  }

  void stopTimer() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    notifyListeners();
  }

  void toggleTimer() {
    if (_isRunning) {
      stopTimer();
    } else {
      startTimer();
    }
  }

  void adjustTime(int seconds) {
    _remainingSeconds += seconds;
    if (_remainingSeconds < 0) _remainingSeconds = 0;
    // Optionally update total seconds if you want the progress bar to adapt
    // _totalSeconds += seconds; 
    notifyListeners();
  }

  void snoozeTimer() {
    // Add 5 minutes and restart
    _remainingSeconds += 300; 
    // If we were completed, we might need to update totalSeconds to make sense of progress
    if (_remainingSeconds > _totalSeconds) {
      _totalSeconds = _remainingSeconds;
    }
    startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}