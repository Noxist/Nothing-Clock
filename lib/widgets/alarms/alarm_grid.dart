import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/alarm.dart';
import '../../view_models/alarms_view_model.dart';

class AlarmGrid extends StatelessWidget {
  const AlarmGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AlarmsViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (viewModel.alarms.isEmpty) {
          return Center(
            child: Text(
              'No Alarms',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.85,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: viewModel.alarms.length,
          itemBuilder: (context, index) {
            final alarm = viewModel.alarms[index];
            return _buildAlarmCard(context, alarm, viewModel);
          },
        );
      },
    );
  }

  Widget _buildAlarmCard(BuildContext context, Alarm alarm, AlarmsViewModel viewModel) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final timeString = '${alarm.time.hour.toString().padLeft(2, '0')}:${alarm.time.minute.toString().padLeft(2, '0')}';

    return Dismissible(
      key: Key(alarm.id.toString()), // Fixed: Convert int ID to String
      direction: DismissDirection.up,
      onDismissed: (_) => viewModel.deleteAlarm(alarm.id),
      background: Container(
        color: theme.colorScheme.error,
        alignment: Alignment.center,
        child: const Icon(Icons.delete, color: Colors.white, size: 32),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.black12,
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    alarm.label.isEmpty ? 'Alarm' : alarm.label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () => viewModel.deleteAlarm(alarm.id),
                  child: Icon(
                    Icons.close, 
                    size: 20, 
                    color: theme.colorScheme.onSurface.withOpacity(0.4)
                  ),
                ),
              ],
            ),
            
            const Spacer(),
            
            Text(
              timeString,
              style: theme.textTheme.displayMedium?.copyWith(
                fontSize: 40,
                color: alarm.isEnabled 
                    ? theme.colorScheme.onSurface 
                    : theme.colorScheme.onSurface.withOpacity(0.3),
              ),
            ),
            
            const SizedBox(height: 8),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDays(alarm.days), // Fixed: logic helper below
                  style: theme.textTheme.bodySmall?.copyWith(
                     color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                Switch(
                  value: alarm.isEnabled,
                  onChanged: (value) => viewModel.toggleAlarm(alarm.id, value),
                  activeColor: theme.colorScheme.primary,
                  activeTrackColor: theme.colorScheme.primary.withOpacity(0.3),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDays(Map<String, bool> days) {
    if (days.values.every((e) => e == false)) return 'Once';
    if (days.values.every((e) => e == true)) return 'Daily';
    
    // Sort logic to order M, T, W, etc.
    final orderedDays = ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"];
    List<String> activeDays = [];
    
    for (var day in orderedDays) {
      if (days[day] == true) {
        // Map "MON" -> "M", "TUE" -> "T", etc.
        activeDays.add(day[0]); 
      }
    }
    return activeDays.join(' ');
  }
}
