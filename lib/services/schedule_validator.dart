// lib/services/schedule_validator.dart
class ScheduleValidator {
  static int? _timeToMinutes(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return null;
    try {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return hour * 60 + minute;
    } catch (e) {
      return null;
    }
  }

  /// Check if task conflicts with schedule blocks or other tasks
  static Map<String, dynamic> checkTaskConflicts({
    required DateTime taskDate,
    required String? taskTime,
    required List<dynamic> allTodos,
    String? excludeTodoId,
  }) {
    if (taskTime == null || taskTime.isEmpty) {
      return {'hasConflict': false};
    }

    final taskMinutes = _timeToMinutes(taskTime);
    if (taskMinutes == null) return {'hasConflict': false};

    final dayOfWeek = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"][taskDate.weekday % 7];

    for (final todo in allTodos) {
      final t = todo as Map<String, dynamic>;
      final todoId = t['_id'] ?? t['id'];
      
      if (excludeTodoId != null && todoId == excludeTodoId) continue;

      // Check schedule blocks
      if (t['type'] == 'schedule-block') {
        final schedule = t['schedule'] as List<dynamic>? ?? [];
        for (final block in schedule) {
          final blockDay = (block['day'] as String?)?.toLowerCase();
          if (blockDay == dayOfWeek) {
            final startMin = _timeToMinutes(block['start']);
            final endMin = _timeToMinutes(block['end']);
            
            if (startMin != null && endMin != null) {
              if (taskMinutes >= startMin && taskMinutes <= endMin) {
                return {
                  'hasConflict': true,
                  'type': 'schedule-block',
                  'conflictWith': t['title'] ?? 'Schedule block',
                  'blockTime': '${block['start']} - ${block['end']}',
                  'message': '⚠️ This time conflicts with "${t['title']}" (${block['start']} - ${block['end']})',
                };
              }
            }
          }
        }
      }

      // Check other tasks with same time
      if (t['time'] != null) {
        final todoTime = _timeToMinutes(t['time']);
        if (todoTime == taskMinutes) {
          // Check if it's on the same date
          bool sameDate = false;
          if (t['type'] == 'one-time' && t['date'] != null) {
            try {
              final todoDate = DateTime.parse(t['date'].toString().split('T')[0]);
              sameDate = todoDate.year == taskDate.year && 
                        todoDate.month == taskDate.month && 
                        todoDate.day == taskDate.day;
            } catch (_) {}
          } else if (t['type'] == 'recurring') {
            final rec = t['recurrence'] ?? {};
            if (rec['type'] == 'daily') {
              sameDate = true;
            } else if (rec['type'] == 'weekly') {
              final days = (rec['days'] as List<dynamic>?)?.map((e) => e.toString().toLowerCase()).toList() ?? [];
              sameDate = days.contains(dayOfWeek);
            }
          }

          if (sameDate) {
            return {
              'hasConflict': true,
              'type': 'task',
              'conflictWith': t['title'] ?? 'Another task',
              'taskTime': t['time'],
              'message': '⚠️ Another task "${t['title']}" is already scheduled at ${t['time']}',
            };
          }
        }
      }
    }

    return {'hasConflict': false};
  }

  /// Validate schedule block doesn't overlap
  static Map<String, dynamic> validateScheduleBlock({
    required String day,
    required String startTime,
    required String endTime,
    required List<dynamic> existingSchedules,
    String? excludeScheduleId,
  }) {
    final startMin = _timeToMinutes(startTime);
    final endMin = _timeToMinutes(endTime);

    if (startMin == null || endMin == null) {
      return {'valid': false, 'error': 'Invalid time format'};
    }

    if (startMin >= endMin) {
      return {'valid': false, 'error': 'Start time must be before end time'};
    }

    final dayLower = day.toLowerCase();

    for (final schedule in existingSchedules) {
      final s = schedule as Map<String, dynamic>;
      final schedId = s['_id'] ?? s['id'];
      
      if (excludeScheduleId != null && schedId == excludeScheduleId) continue;

      if (s['type'] == 'schedule-block') {
        final blocks = s['schedule'] as List<dynamic>? ?? [];
        for (final block in blocks) {
          final blockDay = (block['day'] as String?)?.toLowerCase();
          if (blockDay == dayLower) {
            final blockStartMin = _timeToMinutes(block['start']);
            final blockEndMin = _timeToMinutes(block['end']);

            if (blockStartMin != null && blockEndMin != null) {
              final hasOverlap = (startMin < blockEndMin && endMin > blockStartMin);
              
              if (hasOverlap) {
                return {
                  'valid': false,
                  'error': 'Overlaps with "${s['title']}" (${block['start']} - ${block['end']})',
                  'conflictWith': s['title'],
                };
              }
            }
          }
        }
      }
    }

    return {'valid': true};
  }
}