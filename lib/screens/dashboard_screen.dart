// lib/screens/dashboard_screen.dart
// Add this method to handle 401 errors throughout the app

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/todo_service.dart';
import '../services/auth_service.dart';
import '../widgets/todo_card.dart';
import '../utils/date_helper.dart';
import 'todo_editor_screen.dart';
import 'schedule_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final PageController _pageController = PageController(initialPage: 2);
  List<DateTime> _days = [];
  List<dynamic> _fetchedTodos = [];
  bool _loading = false;
  int _currentPage = 2;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initDays();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchForRange(showLoading: true);
    });
    _pageController.addListener(_onPageScroll);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageScroll() {
    if (_pageController.hasClients) {
      final page = _pageController.page?.round() ?? _currentPage;
      if (page != _currentPage) {
        setState(() => _currentPage = page);
      }
    }
  }

  void _initDays() {
    final today = DateTime.now();
    _days = List.generate(
      5,
      (i) => DateTime(today.year, today.month, today.day).add(Duration(days: i - 2)),
    );
  }

  /// Check if response is 401 (unauthorized) and handle auto-logout
  void _checkAuthError(Map<String, dynamic> res) {
    if (res['status'] == 401) {
      _handleUnauthorized();
    }
  }

  Future<void> _handleUnauthorized() async {
    await AuthService.logout();
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Session expired. Please login again.'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );
    
    // Navigate to login and clear all routes
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
  }

  Future<void> _fetchForRange({bool forceRefresh = false, bool showLoading = false}) async {
    if (!mounted) return;

    if (showLoading) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }

    final start = DateHelper.toIsoDateString(_days.first);
    final end = DateHelper.toIsoDateString(_days.last);

    final res = await TodoService.fetchRange(start, end, forceRefresh: forceRefresh);

    if (!mounted) return;

    // Check for auth errors
    _checkAuthError(res);

    if (res['ok'] == true) {
      final body = res['body'] as Map<String, dynamic>;
      final data = body['data'] as List<dynamic>? ?? [];
      setState(() {
        _fetchedTodos = data;
        _loading = false;
        _errorMessage = null;
      });
    } else {
      final err = res['error'] ?? res['body']?['error'] ?? 'Failed to fetch todos';
      setState(() {
        _loading = false;
        _errorMessage = err.toString();
      });
      if (res['status'] != 401) {
        _showSnackbar(err.toString(), isError: true);
      }
    }
  }

  List<Map<String, dynamic>> _occurrencesForDay(DateTime day) {
    final dayOfWeek = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"][day.weekday % 7];
    final List<Map<String, dynamic>> out = [];

    for (final item in _fetchedTodos) {
      final t = Map<String, dynamic>.from(item as Map<String, dynamic>);
      final type = t['type'];

      if (type == 'one-time') {
        if (t['date'] != null) {
          final taskDate = DateHelper.fromIsoDateString(t['date']);
          if (taskDate != null && DateHelper.isSameDay(taskDate, day)) {
            out.add(t);
          }
        } else {
          if (DateHelper.isToday(day)) {
            out.add(t);
          }
        }
      } else if (type == 'reminder') {
        if (t['date'] != null) {
          final taskDate = DateHelper.fromIsoDateString(t['date']);
          if (taskDate != null && DateHelper.isSameDay(taskDate, day)) {
            out.add(t);
          }
        } else {
          out.add(t);
        }
      } else if (type == 'recurring') {
        final rec = t['recurrence'] ?? {};
        final rtype = rec['type'] ?? 'none';
        if (rtype == 'daily') {
          out.add(t);
        } else if (rtype == 'weekly') {
          final daysArr = (rec['days'] as List<dynamic>?)
                  ?.map((e) => (e as String).toLowerCase())
                  .toList() ??
              [];
          if (daysArr.contains(dayOfWeek)) {
            out.add(t);
          }
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

  bool _isCompletedForDay(Map<String, dynamic> t, DateTime day) {
    if (t['completed'] == true) return true;
    final comps = t['completions'] as List<dynamic>?;
    if (comps == null || comps.isEmpty) return false;

    return comps.any((c) {
      final compDate = DateHelper.fromIsoDateString(c['date'].toString());
      return compDate != null && DateHelper.isSameDay(compDate, day);
    });
  }

  Future<void> _handleComplete(String id, DateTime occurrenceDate) async {
    final dateStr = DateHelper.toIsoDateString(occurrenceDate);
    final res = await TodoService.markComplete(id, date: dateStr);

    if (!mounted) return;

    // Check for auth errors
    _checkAuthError(res);

    if (res['ok'] == true) {
      await _fetchForRange(forceRefresh: true);
      if (mounted) {
        _showSnackbar('Marked complete for ${DateFormat('MMM d').format(occurrenceDate)}');
      }
    } else if (res['status'] == 409) {
      await _fetchForRange(forceRefresh: true);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Already completed for ${DateFormat('MMM d').format(occurrenceDate)}'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => _handleUncomplete(id, occurrenceDate),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } else if (res['status'] != 401) {
      final msg = res['error'] ?? 'Failed to mark complete';
      _showSnackbar(msg, isError: true);
    }
  }

  Future<void> _handleUncomplete(String id, DateTime occurrenceDate) async {
    final dateStr = DateHelper.toIsoDateString(occurrenceDate);
    final res = await TodoService.uncomplete(id, dateStr);

    if (!mounted) return;
    
    _checkAuthError(res);

    if (res['ok'] == true) {
      await _fetchForRange(forceRefresh: true);
      if (mounted) {
        _showSnackbar('Completion removed');
      }
    } else if (res['status'] != 401) {
      final msg = res['error'] ?? 'Failed to undo';
      _showSnackbar(msg, isError: true);
    }
  }

  Future<void> _deleteTodo(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
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
    
    _checkAuthError(res);

    if (res['ok'] == true) {
      await _fetchForRange(forceRefresh: true);
      if (mounted) {
        _showSnackbar('Task deleted');
      }
    } else if (res['status'] != 401) {
      final msg = res['error'] ?? 'Failed to delete';
      _showSnackbar(msg, isError: true);
    }
  }

  void _addMoreFuture() {
    final last = _days.last;
    final newDays = List.generate(5, (i) => last.add(Duration(days: i + 1)));
    setState(() => _days = [..._days, ...newDays]);
    _fetchForRange();
  }

  void _addMorePast() {
    final first = _days.first;
    final newDays = List.generate(5, (i) => first.subtract(Duration(days: i + 1))).reversed.toList();
    final currentPage = _currentPage;
    setState(() => _days = [...newDays, ..._days]);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        final newPage = (currentPage + newDays.length).clamp(0, _days.length - 1);
        _pageController.jumpToPage(newPage);
        setState(() => _currentPage = newPage);
      }
    });
    _fetchForRange();
  }

  Future<void> _openEditor({Map<String, dynamic>? todo}) async {
  final result = await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => TodoEditorScreen(todo: todo)), // Todos loaded inside editor
  );
  if (result == true && mounted) {
    await _fetchForRange(forceRefresh: true);
  }
}

  Future<void> _openSchedule() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ScheduleScreen()),
    );
    if (result == true && mounted) {
      await _fetchForRange(forceRefresh: true);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AuthService.logout();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
      }
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
    final currentDay = _days[_currentPage.clamp(0, _days.length - 1)];
    final isToday = DateHelper.isToday(currentDay);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.task_alt, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 12),
            const Text('AI Todo'),
          ],
        ),
        actions: [
          IconButton(onPressed: _openSchedule, icon: const Icon(Icons.schedule), tooltip: 'Schedule'),
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout), tooltip: 'Logout'),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchForRange(forceRefresh: true),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  DateFormat('EEEE').format(currentDay),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isToday ? Theme.of(context).colorScheme.primary : Colors.black54,
                                    fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                                if (isToday) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text('Today', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(DateFormat('d MMM yyyy').format(currentDay), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: Colors.deepPurple.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16, color: Colors.deepPurple),
                            const SizedBox(width: 8),
                            Text('${_currentPage + 1}/${_days.length}', style: const TextStyle(fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700),
                        const SizedBox(width: 12),
                        Expanded(child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade700))),
                        IconButton(icon: const Icon(Icons.refresh), onPressed: () => _fetchForRange(forceRefresh: true, showLoading: true)),
                      ],
                    ),
                  ),
                ),
              ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : PageView.builder(
                      controller: _pageController,
                      itemCount: _days.length,
                      onPageChanged: (p) => setState(() => _currentPage = p),
                      itemBuilder: (context, index) {
                        final day = _days[index];
                        final occurrences = _occurrencesForDay(day);
                        final isPast = DateHelper.isPastDate(day);

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                child: Row(
                                  children: [
                                    Text('Tasks', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(10)),
                                      child: Text('${occurrences.length}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimaryContainer)),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: occurrences.isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.hourglass_empty, size: 48, color: Colors.grey.shade400),
                                            const SizedBox(height: 8),
                                            Text(isPast ? 'No tasks for this day' : 'No tasks scheduled', style: const TextStyle(color: Colors.black54)),
                                            if (!isPast) ...[
                                              const SizedBox(height: 16),
                                              FilledButton.icon(onPressed: () => _openEditor(), icon: const Icon(Icons.add), label: const Text('Add Task')),
                                            ],
                                          ],
                                        ),
                                      )
                                    : ListView.builder(
                                        padding: const EdgeInsets.only(bottom: 16),
                                        itemCount: occurrences.length,
                                        itemBuilder: (c, i) {
                                          final t = occurrences[i];
                                          final id = t['_id'] ?? t['id'];
                                          final completedForThisDay = _isCompletedForDay(t, day);

                                          return TodoCard(
                                            todo: t,
                                            occurrenceDate: day,
                                            isCompleted: completedForThisDay,
                                            isPast: isPast,
                                            onEdit: (completedForThisDay || isPast) ? null : () => _openEditor(todo: t),
                                            onDelete: (completedForThisDay || isPast) ? null : () => _deleteTodo(id),
                                            onComplete: () => _handleComplete(id, day),
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
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
              Expanded(child: FilledButton.icon(onPressed: _addMorePast, icon: const Icon(Icons.arrow_back), label: const Text('Load earlier'))),
              const SizedBox(width: 12),
              Expanded(child: FilledButton.icon(onPressed: _addMoreFuture, icon: const Icon(Icons.arrow_forward), label: const Text('Load more'))),
            ],
          ),
        ),
      ),
    );
  }
}