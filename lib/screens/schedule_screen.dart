// lib/screens/schedule_screen.dart
import 'package:flutter/material.dart';
import '../services/todo_service.dart';

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
    // fetch a wide range (e.g., next 30 days) and extract schedule-blocks
    final start = DateTime.now().subtract(const Duration(days: 30));
    final end = DateTime.now().add(const Duration(days: 30));
    final res = await TodoService.fetchRange(
      "${start.year}-${start.month.toString().padLeft(2,'0')}-${start.day.toString().padLeft(2,'0')}",
      "${end.year}-${end.month.toString().padLeft(2,'0')}-${end.day.toString().padLeft(2,'0')}",
    );
    setState(() => _loading = false);
    if (res['ok'] == true) {
      final body = res['body'] as Map<String, dynamic>;
      final data = body['data'] as List<dynamic>? ?? [];
      setState(() {
        _scheduleBlocks = data.where((e) => (e['type'] == 'schedule-block')).toList();
      });
    } else {
      final err = res['error'] ?? res['body']?['error'] ?? 'Failed';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err.toString())));
      setState(() => _scheduleBlocks = []);
    }
  }

  Future<void> _createScheduleBlock() async {
    // show simple dialog for creating a single schedule-block with one day entry
    final titleCtl = TextEditingController();
    String selDay = 'monday';
    final startTimeCtl = TextEditingController(text: '09:00');
    final endTimeCtl = TextEditingController(text: '10:00');

    final ok = await showDialog<bool>(
      context: context,
      builder: (c) {
        return AlertDialog(
          title: const Text('Create schedule block'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: titleCtl, decoration: const InputDecoration(labelText: 'Title')),
            DropdownButtonFormField<String>(
              value: selDay,
              items: ['monday','tuesday','wednesday','thursday','friday','saturday','sunday'].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
              onChanged: (v) => selDay = v ?? selDay,
              decoration: const InputDecoration(labelText: 'Day'),
            ),
            TextField(controller: startTimeCtl, decoration: const InputDecoration(labelText: 'Start (HH:mm)')),
            TextField(controller: endTimeCtl, decoration: const InputDecoration(labelText: 'End (HH:mm)')),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(c).pop(true), child: const Text('Create')),
          ],
        );
      },
    );

    if (ok != true) return;

    final payload = {
      'title': titleCtl.text.trim(),
      'type': 'schedule-block',
      'schedule': [
        {'day': selDay, 'start': startTimeCtl.text.trim(), 'end': endTimeCtl.text.trim()}
      ]
    };

    final res = await TodoService.createTodo(payload);
    if (res['ok'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Schedule created')));
      _loadSchedule();
    } else {
      final msg = res['error'] ?? res['body']?['error'] ?? 'Failed to create';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily / Weekly Schedule'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _scheduleBlocks.length,
              itemBuilder: (_, i) {
                final t = _scheduleBlocks[i] as Map<String, dynamic>;
                final title = t['title'] ?? 'Untitled';
                final schedule = t['schedule'] as List<dynamic>? ?? [];
                return ListTile(
                  title: Text(title),
                  subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    for (final s in schedule) Text("${s['day'] ?? ''}: ${s['start'] ?? ''} - ${s['end'] ?? ''}")
                  ]),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createScheduleBlock,
        child: const Icon(Icons.schedule),
      ),
    );
  }
}