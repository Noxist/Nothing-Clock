import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:nothing_clock/models/timezone_data.dart';
import 'package:nothing_clock/models/world_clock_data.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class WorldClocksProvider with ChangeNotifier {
  List<WorldClockData> _worldClocks = [];
  List<WorldClockData> get worldClocks => _worldClocks;

  WorldClocksProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadWorldClocks();
    await _fetchInitialTimeData(); 
    notifyListeners();
  }

  // Simplified: The UI should use a Clock stream to rebuild, 
  // we don't need to rebuild the entire provider on every tick.
  void forceUpdate() {
    for (var worldClock in _worldClocks) {
      worldClock.calculateTimeOffset();
    }
    notifyListeners();
  }

  Future<void> _loadWorldClocks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? worldClockStrings = prefs.getStringList('world_clocks');
      
      if (worldClockStrings != null && worldClockStrings.isNotEmpty) {
        _worldClocks = worldClockStrings.map((clockString) {
          final Map<String, dynamic> clockData = jsonDecode(clockString);
          return WorldClockData(
            currentFormattedTime: clockData['currentFormattedTime'] ?? "00:00",
            utcTime: clockData['utcTime'] ?? 0,
            longitude: clockData['longitude'] ?? 0.0,
            latitude: clockData['latitude'] ?? 0.0,
            displayName: clockData['displayName'] ?? "Unknown",
          );
        }).toList();
      }
    } catch (e) {
      debugPrint("Error loading world clocks: $e");
    }
  }

  Future<void> _saveWorldClocks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> worldClockStrings = _worldClocks.map((clock) {
        return jsonEncode({
          'currentFormattedTime': clock.currentFormattedTime,
          'utcTime': clock.utcTime,
          'longitude': clock.longitude,
          'latitude': clock.latitude,
          'displayName': clock.displayName,
        });
      }).toList();
      await prefs.setStringList('world_clocks', worldClockStrings);
    } catch (e) {
      debugPrint("Error saving world clocks: $e");
    }
  }

  Future<void> _fetchInitialTimeData() async {
    for (var worldClock in _worldClocks) {
      final response = await _fetchUtcTimezone(worldClock.latitude, worldClock.longitude);
      worldClock.utc = response.utcOffset;
      worldClock.calculateTimeOffset();
    }
    notifyListeners();
  }

  Future<TimezoneData> _fetchUtcTimezone(double latitude, double longitude) async {
    try {
      final response = await http.get(Uri.parse(
        'http://api.geonames.org/timezoneJSON?lat=$latitude&lng=$longitude&username=sashachverenko'));
      final jsonData = jsonDecode(response.body);
      final int utcOffset = jsonData['gmtOffset'];
      return TimezoneData(utcOffset: utcOffset);
    } catch(e) {
      return TimezoneData(utcOffset: 0);
    }
  }

  bool _isDuplicateLocation(double latitude, double longitude) {
    const double threshold = 0.1;
    for (var clock in _worldClocks) {
      if ((latitude - clock.latitude).abs() < threshold && 
          (longitude - clock.longitude).abs() < threshold) {
        return true;
      }
    }
    return false;
  }

  Future<bool> addWorldClock(WorldClockData worldClock) async {
    if (_isDuplicateLocation(worldClock.latitude, worldClock.longitude)) {
      return false;
    }
    TimezoneData timezoneData = await _fetchUtcTimezone(worldClock.latitude, worldClock.longitude);
    worldClock.utc = timezoneData.utcOffset;
    worldClock.calculateTimeOffset();
    _worldClocks.add(worldClock);
    _saveWorldClocks();
    notifyListeners();
    return true;
  }

  void removeWorldClock(WorldClockData worldClock) {
    _worldClocks.remove(worldClock);
    _saveWorldClocks();
    notifyListeners();
  }
}
