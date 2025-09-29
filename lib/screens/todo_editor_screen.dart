// lib/screens/todo_editor_screen.dart
import 'package:flutter/material.dart';
import '../services/todo_service.dart';
import '../utils/date_helper.dart';

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
  String _type = 'one-time';
  DateTime? _selectedDate;
  String _time = '';
  bool _saving = false;

  final List<String> _weekDays = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday'
  ];
  final Set<String> _selectedWeekDays = {};

  @override
  void initState() {
    super.initState();
    final t = widget.todo;
    if (t != null) {
      _title.text = t['title'] ?? '';
      _desc.text = t['description'] ?? '';

      final rec = t['recurrence'] ?? {};
      final rtype = (rec['type'] ?? t['type']) as String;
      if (rtype == 'daily') {
        _type = 'daily';
        _time = rec['time'] ?? t['time'] ?? '';
      } else if (rtype == 'weekly') {
        _type = 'weekly';
        _time = rec['time'] ?? t['time'] ?? '';
        final days = (rec['days'] as List<dynamic>?)
                ?.map((e) => e.toString().toLowerCase())
                .toList() ??
            [];
        for (final d in days) {
          if (_weekDays.contains(d)) _selectedWeekDays.add(d);
        }
      } else {
        _type = 'one-time';
        _time = t['time'] ?? '';
      }

      if (t['date'] != null) {
        _selectedDate = DateHelper.fromIsoDateString(t['date']);
      }
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    TimeOfDay? initial;
    if (_time.isNotEmpty) {
      try {
        final parts = _time.split(':');
        initial = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      } catch (_) {}
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: initial ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _time = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_type == 'weekly' && _selectedWeekDays.isEmpty) {
      _showSnackbar('Please select at least one weekday for weekly tasks', isError: true);
      return;
    }

    setState(() => _saving = true);

    final payload = <String, dynamic>{
      'title': _title.text.trim(),
      'description': _desc.text.trim(),
    };

    if (_type == 'one-time') {
      payload['type'] = 'one-time';
      
      if (_selectedDate != null) {
        payload['date'] = DateHelper.toIsoDateString(_selectedDate!);
      } else {
        payload['date'] = DateHelper.toIsoDateString(DateTime.now());
      }
      
      if (_time.isNotEmpty) {
        payload['time'] = _time;
      }
      payload['recurrence'] = {'type': 'none'};
    } else if (_type == 'daily') {
      payload['type'] = 'recurring';
      payload['recurrence'] = {
        'type': 'daily',
        'time': _time.isNotEmpty ? _time : null,
      };
      if (_selectedDate != null) {
        payload['date'] = DateHelper.toIsoDateString(_selectedDate!);
      }
    } else if (_type == 'weekly') {
      payload['type'] = 'recurring';
      payload['recurrence'] = {
        'type': 'weekly',
        'days': _selectedWeekDays.toList(),
        'time': _time.isNotEmpty ? _time : null,
      };
      if (_selectedDate != null) {
        payload['date'] = DateHelper.toIsoDateString(_selectedDate!);
      }
    }

    Map<String, dynamic> res;
    if (widget.todo != null) {
      final id = widget.todo!['_id'] ?? widget.todo!['id'];
      res = await TodoService.updateTodo(id, payload);
    } else {
      res = await TodoService.createTodo(payload);
    }

    setState(() => _saving = false);

    if (!mounted) return;

    if (res['ok'] == true) {
      Navigator.of(context).pop(true);
    } else {
      final msg = res['error'] ?? res['body']?['error'] ?? 'Failed to save';
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

  Widget _weekdayChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: _weekDays.map((d) {
        final selected = _selectedWeekDays.contains(d);
        return ChoiceChip(
          selected: selected,
          label: Text(d[0].toUpperCase() + d.substring(1)),
          onSelected: (v) {
            setState(() {
              if (v) {
                _selectedWeekDays.add(d);
              } else {
                _selectedWeekDays.remove(d);
              }
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
        title: Text(widget.todo != null ? 'Edit Task' : 'Create Task'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'What needs to be done?',
                border: OutlineInputBorder(),
              ),
              validator: (s) => (s ?? '').trim().isEmpty ? 'Title is required' : null,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _desc,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Add details (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(
                labelText: 'Task Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'one-time', child: Text('One-time Task')),
                DropdownMenuItem(value: 'daily', child: Text('Daily Recurring')),
                DropdownMenuItem(value: 'weekly', child: Text('Weekly (Mon-Sat)')),
              ],
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            const SizedBox(height: 16),
            if (_type == 'one-time') ...[
              ListTile(
                title: Text(
                  _selectedDate == null
                      ? 'Date: Today (tap to change)'
                      : 'Date: ${DateHelper.toIsoDateString(_selectedDate!)}',
                ),
                leading: const Icon(Icons.calendar_today),
                trailing: _selectedDate != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _selectedDate = null),
                      )
                    : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                onTap: _pickDate,
              ),
              const SizedBox(height: 12),
              ListTile(
                title: Text(_time.isEmpty ? 'Time (optional)' : 'Time: $_time'),
                leading: const Icon(Icons.access_time),
                trailing: _time.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _time = ''),
                      )
                    : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                onTap: _pickTime,
              ),
            ] else ...[
              ListTile(
                title: Text(_time.isEmpty ? 'Time (optional)' : 'Time: $_time'),
                subtitle: const Text('When this task occurs each day/week'),
                leading: const Icon(Icons.access_time),
                trailing: _time.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _time = ''),
                      )
                    : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                onTap: _pickTime,
              ),
              const SizedBox(height: 12),
              if (_type == 'weekly') ...[
                const Text(
                  'Select Weekdays (Monday - Saturday)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 12),
                _weekdayChips(),
              ],
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check),
              label: Text(widget.todo != null ? 'Update Task' : 'Create Task'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}