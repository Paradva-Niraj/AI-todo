// lib/screens/todo_editor_screen.dart
import 'package:flutter/material.dart';
import '../services/todo_service.dart';

class TodoEditorScreen extends StatefulWidget {
  final Map<String, dynamic>? todo;
  const TodoEditorScreen({super.key, this.todo});
  @override
  State<TodoEditorScreen> createState() => _TodoEditorScreenState();
}

class _TodoEditorScreenState extends State<TodoEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  String _type = 'one-time'; // 'one-time' | 'daily' | 'weekly'
  final _date = TextEditingController();
  final _time = TextEditingController();
  bool _saving = false;

  // weekday selection for weekly recurrence (mon..sat)
  final List<String> _weekDays = ['monday','tuesday','wednesday','thursday','friday','saturday'];
  final Set<String> _selectedWeekDays = {};

  @override
  void initState() {
    super.initState();
    final t = widget.todo;
    if (t != null) {
      _title.text = t['title'] ?? '';
      _desc.text = t['description'] ?? '';
      // Map server recurrence to our simplified types
      final rec = t['recurrence'] ?? {};
      final rtype = (rec['type'] ?? t['type']) as String;
      if (rtype == 'daily') {
        _type = 'daily';
      } else if (rtype == 'weekly') {
        _type = 'weekly';
        final days = (rec['days'] as List<dynamic>?)?.map((e) => e.toString().toLowerCase()).toList() ?? [];
        for (final d in days) {
          if (_weekDays.contains(d)) _selectedWeekDays.add(d);
        }
      } else {
        _type = 'one-time';
      }

      if (t['date'] != null) _date.text = (t['date'] as String).split('T').first;
      if (t['time'] != null) _time.text = t['time'] ?? '';
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _date.dispose();
    _time.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      _date.text =
          "${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      final hour = picked.hour.toString().padLeft(2, '0');
      final minute = picked.minute.toString().padLeft(2, '0');
      _time.text = "$hour:$minute";
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_type == 'weekly' && _selectedWeekDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one weekday for weekly tasks')));
      return;
    }

    setState(() => _saving = true);

    final payload = <String, dynamic>{
      'title': _title.text.trim(),
      'description': _desc.text.trim(),
      // type handled below
    };

    if (_type == 'one-time') {
      payload['type'] = 'one-time';
      // default to today if empty (your requested behavior)
      if (_date.text.trim().isEmpty) {
        final now = DateTime.now();
        payload['date'] =
            "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      } else {
        payload['date'] = _date.text.trim();
      }
      if (_time.text.trim().isNotEmpty) payload['time'] = _time.text.trim();
      // clear recurrence if any
      payload['recurrence'] = {'type': 'none'};
    } else if (_type == 'daily') {
      payload['type'] = 'recurring';
      payload['recurrence'] = {'type': 'daily', 'time': _time.text.trim().isNotEmpty ? _time.text.trim() : null};
      // remove date field
      if (_date.text.trim().isNotEmpty) payload['date'] = _date.text.trim(); // optional single-date reminder allowed
    } else if (_type == 'weekly') {
      payload['type'] = 'recurring';
      payload['recurrence'] = {
        'type': 'weekly',
        'days': _selectedWeekDays.toList(),
        'time': _time.text.trim().isNotEmpty ? _time.text.trim() : null
      };
      if (_date.text.trim().isNotEmpty) payload['date'] = _date.text.trim(); // optional
    }

    Map<String, dynamic> res;
    if (widget.todo != null) {
      final id = widget.todo!['_id'] ?? widget.todo!['id'];
      res = await TodoService.updateTodo(id, payload);
    } else {
      res = await TodoService.createTodo(payload);
    }

    setState(() => _saving = false);
    if (res['ok'] == true) {
      Navigator.of(context).pop(true);
    } else {
      final msg = res['error'] ?? res['body']?['error'] ?? 'Failed';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg.toString())));
    }
  }

  Widget _weekdayChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: _weekDays.map((d) {
        final label = d[0].toUpperCase() + d.substring(1, 3); // Mo, Tu...
        final selected = _selectedWeekDays.contains(d);
        return ChoiceChip(
          selected: selected,
          label: Text(d[0].toUpperCase() + d.substring(1)),
          onSelected: (v) {
            setState(() {
              if (v) _selectedWeekDays.add(d);
              else _selectedWeekDays.remove(d);
            });
          },
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.todo != null ? 'Edit task' : 'Create task'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Form(
          key: _formKey,
          child: ListView(children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (s) => (s ?? '').trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(controller: _desc, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _type,
              items: [
                DropdownMenuItem(value: 'one-time', child: Text('One-time')),
                DropdownMenuItem(value: 'daily', child: Text('Daily')),
                DropdownMenuItem(value: 'weekly', child: Text('Weekly (Mon—Sat)')),
              ],
              onChanged: (v) => setState(() => _type = v ?? _type),
              decoration: const InputDecoration(labelText: 'Task type'),
            ),
            const SizedBox(height: 12),
            if (_type == 'one-time') ...[
              TextFormField(
                controller: _date,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Date (leave empty to use today)', suffixIcon: Icon(Icons.calendar_today)),
                onTap: _pickDate,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _time,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Time (optional)', suffixIcon: Icon(Icons.access_time)),
                onTap: _pickTime,
              ),
            ] else ...[
              // daily or weekly: optional time (when the task occurs)
              TextFormField(
                controller: _time,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Time (optional) — when this occurs each day/week', suffixIcon: Icon(Icons.access_time)),
                onTap: _pickTime,
              ),
              const SizedBox(height: 10),
              if (_type == 'weekly') ...[
                const Text('Select weekdays (Mon—Sat)', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _weekdayChips(),
              ],
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator()) : const Text('Save'),
            ),
          ]),
        ),
      ),
    );
  }
}