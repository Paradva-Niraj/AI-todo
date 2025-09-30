// lib/screens/ai_screen.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/ai_service.dart';
import '../services/todo_service.dart';
import '../utils/date_helper.dart';

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final TextEditingController _promptCtl = TextEditingController();
  bool _loading = false;
  Map<String, dynamic>? _result;
  String? _error;
  bool _committing = false;

  @override
  void dispose() {
    _promptCtl.dispose();
    super.dispose();
  }

  Future<void> _submitPrompt() async {
    final prompt = _promptCtl.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a prompt')));
      return;
    }

    setState(() {
      _loading = true;
      _result = null;
      _error = null;
    });

    final res = await AiService.assist(prompt);

    if (!mounted) return;
    setState(() => _loading = false);

    if (res['ok'] == true) {
      final body = res['body'] as Map<String, dynamic>? ?? {};
      // server returns { ok: true, data: { summary, suggestedTasks, importantPastTasks }, raw: ... }
      final data = body['data'] as Map<String, dynamic>? ?? body;
      setState(() {
        _result = data;
      });
    } else {
      final err = res['error'] ?? res['body']?['error'] ?? 'AI request failed';
      setState(() => _error = err.toString());
      _showSnackbar(err.toString(), isError: true);
    }
  }

  Widget _buildSummary(String summary) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(summary, style: const TextStyle(fontSize: 15)),
      ),
    );
  }

  Widget _buildSuggestedTasks(List<dynamic> tasks) {
    if (tasks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('No suggested tasks returned by AI.'),
      );
    }

    return Column(
      children: [
        for (var t in tasks)
          Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              title: Text(t['title'] ?? 'Untitled'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((t['description'] ?? '').toString().isNotEmpty) Text(t['description']),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (t['priority'] != null)
                        Chip(label: Text(t['priority'].toString().toUpperCase())),
                      const SizedBox(width: 6),
                      Text(_relativeToDateLabel(t['relativeDayOffset'])),
                      const SizedBox(width: 8),
                      if (t['time'] != null) Text('at ${t['time']}'),
                    ],
                  )
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _relativeToDateLabel(dynamic offsetRaw) {
    int offset = 0;
    try {
      if (offsetRaw is int) offset = offsetRaw;
      else offset = int.parse(offsetRaw.toString());
    } catch (_) {
      offset = 0;
    }
    final target = DateHelper.startOfDay(DateTime.now()).add(Duration(days: offset));
    return DateFormat('yyyy-MM-dd').format(target);
  }

  Widget _buildImportantPast(List<dynamic> items) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Text('Important Past Tasks', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        for (var it in items)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(it['title'] ?? 'Untitled'),
              subtitle: it['reason'] != null ? Text(it['reason']) : null,
            ),
          ),
      ],
    );
  }

  Future<void> _commitAll() async {
    if (_result == null) return;
    final tasks = (_result!['suggestedTasks'] as List<dynamic>? ?? []).map<Map<String, dynamic>>((e) {
      return {
        'title': e['title'],
        'description': e['description'],
        'priority': e['priority'],
        'relativeDayOffset': e['relativeDayOffset'] ?? 0,
        'time': e['time'],
        'tags': e['tags'] ?? [],
        'categoryId': e['categoryId'] ?? null,
      };
    }).toList();

    if (tasks.isEmpty) {
      _showSnackbar('No tasks to add', isError: true);
      return;
    }

    setState(() => _committing = true);
    final res = await AiService.commitTasks(tasks);
    if (!mounted) return;
    setState(() => _committing = false);

    if (res['ok'] == true) {
      _showSnackbar('Created ${res['body']?['createdCount'] ?? res['body']?['created']?.length ?? 0} tasks');
      // after creating, refresh todos in parent — we pop true so calling screen can refresh
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) Navigator.of(context).pop(true);
    } else {
      final err = res['error'] ?? res['body']?['error'] ?? 'Failed to commit tasks';
      _showSnackbar(err, isError: true);
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red.shade700 : null,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _commitSingle(int index) async {
    if (_result == null) return;
    final item = (_result!['suggestedTasks'] as List<dynamic>? ?? [])[index];
    final task = {
      'title': item['title'],
      'description': item['description'],
      'priority': item['priority'],
      'relativeDayOffset': item['relativeDayOffset'] ?? 0,
      'time': item['time'],
      'tags': item['tags'] ?? [],
      'categoryId': item['categoryId'] ?? null,
    };
    setState(() => _committing = true);
    final res = await AiService.commitTasks([task]);
    if (!mounted) return;
    setState(() => _committing = false);

    if (res['ok'] == true) {
      _showSnackbar('Task added');
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) Navigator.of(context).pop(true);
    } else {
      final err = res['error'] ?? res['body']?['error'] ?? 'Failed to add task';
      _showSnackbar(err, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _promptCtl,
              minLines: 2,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Ask the assistant (e.g. "Summarize my day" or "Break my todo app project into tasks")',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                suffixIcon: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _submitPrompt,
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: _loading ? null : _submitPrompt,
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Ask AI'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    _promptCtl.text =
                        'Break this project into tasks and schedule them: Build a todo app with Flutter frontend and Node.js + Mongo backend. Return JSON with summary, suggestedTasks (title, description, priority, relativeDayOffset 0=today, optional time), and importantPastTasks. Schedule: frontend today, backend after 3 days, DB design after 4 days.';
                  },
                  icon: const Icon(Icons.auto_fix_high),
                  label: const Text('Example'),
                ),
                const SizedBox(width: 8),
              ],
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_error!, style: TextStyle(color: Colors.red.shade700)),
                ),
              ),
            if (_result != null) ...[
              if ((_result!['summary'] ?? '').toString().isNotEmpty) ...[
                const Text('Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                _buildSummary(_result!['summary'] ?? ''),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Suggested Tasks', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _committing ? null : _commitAll,
                    icon: _committing ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.add),
                    label: const Text('Add all'),
                    style: ElevatedButton.styleFrom(),
                  )
                ],
              ),
              const SizedBox(height: 8),
              _buildSuggestedTasks(_result!['suggestedTasks'] as List<dynamic>? ?? []),
              const SizedBox(height: 12),
              _buildImportantPast(_result!['importantPastTasks'] as List<dynamic>? ?? []),
              const SizedBox(height: 20),
              if ((_result!['raw'] ?? '').toString().isNotEmpty)
                ExpansionTile(
                  title: const Text('Raw AI response'),
                  children: [
                    Container(
                      width: double.infinity,
                      color: Colors.grey.shade50,
                      padding: const EdgeInsets.all(12),
                      child: Text(const JsonEncoder.withIndent('  ').convert(_result!['raw'] ?? _result)),
                    ),
                  ],
                )
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}