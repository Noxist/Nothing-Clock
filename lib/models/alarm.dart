import 'package:hive/hive.dart';

part 'alarm.g.dart';

@HiveType(typeId: 0)
class Alarm extends HiveObject {
  @HiveField(0)
  DateTime time;

  @HiveField(1)
  Map<String, bool> days;

  @HiveField(2, defaultValue: false)
  bool isEnabled;

  @HiveField(3)
  int id;

  @HiveField(4, defaultValue: 'Alarm')
  String label;

  Alarm({
    int? id, 
    required this.time, 
    required this.days, 
    this.isEnabled = false,
    this.label = 'Alarm',
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch % (1 << 31);

  Alarm copyWith({
    DateTime? time,
    Map<String, bool>? days,
    bool? isEnabled,
    int? id,
    String? label,
  }) {
    return Alarm(
      time: time ?? this.time,
      days: days ?? this.days,
      isEnabled: isEnabled ?? this.isEnabled,
      id: id ?? this.id,
      label: label ?? this.label,
    );
  }
}