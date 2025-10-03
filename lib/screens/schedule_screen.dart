// lib/screens/schedule_screen.dart
import 'package:flutter/material.dart';
import '../services/todo_service.dart';
import '../utils/date_helper.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});
  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  bool _loading = false;
  List<dynamic> _scheduleBlocks = [];

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    setState(() => _loading = true);
    
    final start = DateTime.now().subtract(const Duration(days: 30));
    final end = DateTime.now().add(const Duration(days: 30));
    
    final res = await TodoService.fetchRange(
      DateHelper.toIsoDateString(start),
      DateHelper.toIsoDateString(end),
    );
    
    setState(() => _loading = false);

    if (!mounted) return;

    if (res['ok'] == true) {
      final body = res['body'] as Map<String, dynamic>;
      final data = body['data'] as List<dynamic>? ?? [];
      setState(() {
        _scheduleBlocks = data.where((e) => (e['type'] == 'schedule-block')).toList();
      });
    } else {
      final err = res['error'] ?? res['body']?['error'] ?? 'Failed to load schedule';
      _showSnackbar(err, isError: true);
      setState(() => _scheduleBlocks = []);
    }
  }

 Future<void> _createScheduleBlock() async {
  final titleCtl = TextEditingController();
  String selDay = 'monday';
  TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay endTime = const TimeOfDay(hour: 17, minute: 0);

  final ok = await showDialog<bool>(
    context: context,
    builder: (c) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          // Helper to format TimeOfDay to HH:mm (24-hour)
          String formatTime(TimeOfDay time) {
            return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
          }

          return AlertDialog(
            title: const Text('Create Schedule Block'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtl,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'e.g., School, Work',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selDay,
                    decoration: const InputDecoration(labelText: 'Day'),
                    items: ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']
                        .map((d) => DropdownMenuItem(
                              value: d,
                              child: Text(d[0].toUpperCase() + d.substring(1)),
                            ))
                        .toList(),
                    onChanged: (v) => setDialogState(() => selDay = v ?? selDay),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    title: Text('Start: ${formatTime(startTime)}'),
                    leading: const Icon(Icons.access_time),
                    shape: RoundedRectangleBorder(
  side: BorderSide(color: Colors.grey.shade300),
  borderRadius: BorderRadius.circular(8),
),

                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: startTime,
                        builder: (context, child) {
                          return MediaQuery(
                            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setDialogState(() => startTime = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    title: Text('End: ${formatTime(endTime)}'),
                    leading: const Icon(Icons.access_time),
                    shape: RoundedRectangleBorder(
  side: BorderSide(color: Colors.grey.shade300),
  borderRadius: BorderRadius.circular(8),
),

                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: endTime,
                        builder: (context, child) {
                          return MediaQuery(
                            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setDialogState(() => endTime = picked);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(c).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(c).pop(true),
                child: const Text('Create'),
              ),
            ],
          );
        },
      );
    },
  );

  if (ok != true) return;

  // Format times to HH:mm (24-hour format)
  final startTimeStr = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
  final endTimeStr = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';

  final payload = {
    'title': titleCtl.text.trim(),
    'type': 'schedule-block',
    'schedule': [
      {
        'day': selDay,
        'start': startTimeStr,
        'end': endTimeStr,
      }
    ]
  };

  final res = await TodoService.createTodo(payload);
  
  if (!mounted) return;

  if (res['ok'] == true) {
    _showSnackbar('Schedule block created');
    _loadSchedule();
  } else {
    final msg = res['error'] ?? res['body']?['error'] ?? 'Failed to create';
    _showSnackbar(msg, isError: true);
  }
}

  Future<void> _deleteSchedule(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Schedule'),
        content: const Text('Are you sure you want to delete this schedule block?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final res = await TodoService.deleteTodo(id);
    
    if (!mounted) return;

    if (res['ok'] == true) {
      _showSnackbar('Schedule deleted');
      _loadSchedule();
    } else {
      final msg = res['error'] ?? 'Failed to delete';
      _showSnackbar(msg, isError: true);
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Blocks'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _scheduleBlocks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      const Text(
                        'No schedule blocks',
                        style: TextStyle(fontSize: 18, color: Colors.black54),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Create blocks like school, work hours, etc.',
                        style: TextStyle(color: Colors.black45),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _createScheduleBlock,
                        icon: const Icon(Icons.add),
                        label: const Text('Create Schedule Block'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _scheduleBlocks.length,
                  itemBuilder: (_, i) {
                    final t = _scheduleBlocks[i] as Map<String, dynamic>;
                    final id = t['_id'] ?? t['id'];
                    final title = t['title'] ?? 'Untitled';
                    final schedule = t['schedule'] as List<dynamic>? ?? [];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.schedule, color: Colors.deepPurple),
                        ),
                        title: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            for (final s in schedule)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        (s['day'] ?? '')[0].toUpperCase() +
                                            (s['day'] ?? '').substring(1),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${s['start'] ?? ''} - ${s['end'] ?? ''}',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteSchedule(id),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createScheduleBlock,
        child: const Icon(Icons.add),
      ),
    );
  }
}