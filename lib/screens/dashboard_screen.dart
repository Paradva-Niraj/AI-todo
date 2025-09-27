// lib/screens/dashboard_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/todo_service.dart';
import '../widgets/todo_card.dart';
import 'todo_editor_screen.dart';
import 'schedule_screen.dart';
import '../services/auth_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final PageController _pageController = PageController(initialPage: 2);
  List<DateTime> days = [];
  List<dynamic> _fetchedTodos = [];
  bool _loading = false;
  int _currentPage = 2;

  @override
  void initState() {
    super.initState();
    _initDays();
    _fetchForRange();
    _pageController.addListener(() {
      final page = _pageController.page?.round() ?? _currentPage;
      if (page != _currentPage) setState(() => _currentPage = page);
    });
  }

  void _initDays() {
    final today = DateTime.now();
    days = List.generate(5, (i) => DateTime(today.year, today.month, today.day).add(Duration(days: i - 2)));
  }

  String _isoDate(DateTime d) => "${d.year.toString().padLeft(4,'0')}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}";

  Future<void> _fetchForRange() async {
    setState(() => _loading = true);
    final start = _isoDate(days.first);
    final end = _isoDate(days.last);
    final res = await TodoService.fetchRange(start, end);
    setState(() => _loading = false);
    if (res['ok'] == true) {
      final body = res['body'] as Map<String, dynamic>;
      final data = body['data'] as List<dynamic>? ?? [];
      setState(() => _fetchedTodos = data);
    } else {
      final err = res['error'] ?? (res['body']?['error'] ?? 'Failed to fetch todos');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err.toString())));
    }
  }

  List<Map<String, dynamic>> _occurrencesForDay(DateTime day) {
    final weekday = ["sunday","monday","tuesday","wednesday","thursday","friday","saturday"][day.weekday % 7];
    final List<Map<String, dynamic>> out = [];

    for (final item in _fetchedTodos) {
      final t = Map<String, dynamic>.from(item as Map<String, dynamic>);
      final type = t['type'];
      if (type == 'one-time') {
        if (t['date'] != null) {
          final d = DateTime.parse(t['date']);
          if (d.year == day.year && d.month == day.month && d.day == day.day) out.add(t);
        } else {
          final today = DateTime.now();
          if (day.year == today.year && day.month == today.month && day.day == today.day) out.add(t);
        }
      } else if (type == 'reminder') {
        if (t['date'] != null) {
          final d = DateTime.parse(t['date']);
          if (d.year == day.year && d.month == day.month && d.day == day.day) out.add(t);
        } else {
          out.add(t);
        }
      } else if (type == 'recurring') {
        final rec = t['recurrence'] ?? {};
        final rtype = rec['type'] ?? 'none';
        if (rtype == 'daily') out.add(t);
        else if (rtype == 'weekly') {
          final daysArr = (rec['days'] as List<dynamic>?)?.map((e) => (e as String).toLowerCase()).toList() ?? [];
          if (daysArr.contains(weekday)) out.add(t);
        }
      } else if (type == 'schedule-block') {
        out.add(t);
      } else {
        out.add(t);
      }
    }

    out.sort((a, b) {
      final tA = (a['time'] ?? a['recurrence']?['time']) as String?;
      final tB = (b['time'] ?? b['recurrence']?['time']) as String?;
      if (tA == null && tB == null) return 0;
      if (tA == null) return 1;
      if (tB == null) return -1;
      return tA.compareTo(tB);
    });

    return out;
  }

  // returns true if todo is completed for the provided day (either global or per-date)
  bool _isCompletedForDay(Map<String, dynamic> t, DateTime day) {
    if (t['completed'] == true) return true; // global
    final comps = t['completions'] as List<dynamic>?;
    if (comps == null) return false;
    return comps.any((c) {
      final cd = DateTime.parse(c['date'].toString());
      return cd.year == day.year && cd.month == day.month && cd.day == day.day;
    });
  }

  Future<void> _markCompleteFor(String id, String? dateStr) async {
    final res = await TodoService.markComplete(id, date: dateStr);
    if (res['ok'] == true) {
      await _fetchForRange();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked complete for the day')));
    } else if (res['status'] == 409 || (res['body']?['error']?.toString().toLowerCase().contains('already') ?? false)) {
      await _fetchForRange();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Already marked complete for this date')));
    } else {
      final msg = res['error'] ?? res['body']?['error'] ?? 'Failed';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg.toString())));
    }
  }

  Future<void> _deleteTodo(String id) async {
    final res = await TodoService.deleteTodo(id);
    if (res['ok'] == true) {
      await _fetchForRange();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));
    } else {
      final msg = res['error'] ?? res['body']?['error'] ?? 'Failed to delete';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg.toString())));
    }
  }

  void _addMoreFuture() {
    final last = days.last;
    final newDays = List.generate(5, (i) => last.add(Duration(days: i + 1)));
    setState(() => days = [...days, ...newDays]);
    _fetchForRange();
  }

  void _addMorePast() {
    final first = days.first;
    final newDays = List.generate(5, (i) => first.subtract(Duration(days: i + 1))).reversed.toList();
    final currentPage = _pageController.hasClients ? _pageController.page?.round() ?? _currentPage : _currentPage;
    setState(() => days = [...newDays, ...days]);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final newPage = (currentPage + newDays.length).clamp(0, days.length - 1);
      _pageController.jumpToPage(newPage);
      setState(() => _currentPage = newPage);
    });
    _fetchForRange();
  }

  Future<void> _openEditor({Map<String, dynamic>? todo}) async {
    final res = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => TodoEditorScreen(todo: todo)));
    if (res == true) await _fetchForRange();
  }

  Future<void> _openSchedule() async {
    final res = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ScheduleScreen()));
    if (res == true) await _fetchForRange();
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Do you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Logout')),
        ],
      ),
    );
    if (ok == true) {
      await AuthService.logout();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentDay = days[_currentPage.clamp(0, days.length - 1)];
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.12), shape: BoxShape.circle), child: Icon(Icons.task_alt, color: Theme.of(context).colorScheme.primary)),
          const SizedBox(width: 12),
          const Text('AI Todo'),
        ]),
        actions: [
          IconButton(onPressed: _openSchedule, icon: const Icon(Icons.schedule)),
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
        elevation: 0,
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              await _fetchForRange();
              return;
            },
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(DateFormat('EEEE').format(currentDay), style: const TextStyle(fontSize: 14, color: Colors.black54)),
                          const SizedBox(height: 6),
                          Text(DateFormat('d MMM yyyy').format(currentDay), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        ]),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: Colors.deepPurple.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                        child: Row(children: [const Icon(Icons.calendar_today, size: 16, color: Colors.deepPurple), const SizedBox(width: 8), Text('${_currentPage + 1}/${days.length}', style: const TextStyle(fontWeight: FontWeight.w700))]),
                      ),
                    ]),
                  ),
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : PageView.builder(
                        controller: _pageController,
                        itemCount: days.length,
                        itemBuilder: (context, index) {
                          final day = days[index];
                          final occurrences = _occurrencesForDay(day);
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Tasks', style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 8),
                              Expanded(
                                child: occurrences.isEmpty
                                    ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.hourglass_empty, size: 48, color: Colors.grey.shade400), const SizedBox(height: 8), const Text('No tasks for this day', style: TextStyle(color: Colors.black54))]))
                                    : ListView.builder(
                                        itemCount: occurrences.length,
                                        itemBuilder: (c, i) {
                                          final t = occurrences[i] as Map<String, dynamic>;
                                          final id = t['_id'] ?? t['id'];
                                          final isPast = t['date'] != null
                                              ? DateTime.parse(t['date']).isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day))
                                              : false;
                                          final completedForThisDay = _isCompletedForDay(t, day);

                                          return TodoCard(
                                            todo: t,
                                            occurrenceDate: day,
                                            onEdit: (completedForThisDay || isPast) ? null : () => _openEditor(todo: t),
                                            onDelete: (completedForThisDay || isPast) ? null : () => _deleteTodo(id),
                                            onCompleteForDate: (dateStr) async {
                                              final res = await TodoService.markComplete(id, date: dateStr);
                                              if (res['ok'] == true) {
                                                await _fetchForRange();
                                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked complete for the day')));
                                              } else if (res['status'] == 409 || (res['body']?['error']?.toString().toLowerCase().contains('already') ?? false)) {
                                                await _fetchForRange();
                                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Already marked complete for this date')));
                                              } else {
                                                final msg = res['error'] ?? res['body']?['error'] ?? 'Failed';
                                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg.toString())));
                                              }
                                            },
                                          );
                                        },
                                      ),
                              ),
                            ]),
                          );
                        },
                        onPageChanged: (p) => setState(() => _currentPage = p),
                      ),
              ),
            ]),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _addMorePast,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Load earlier'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _addMoreFuture,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Load more'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}