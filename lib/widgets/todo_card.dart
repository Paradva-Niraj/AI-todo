// lib/widgets/todo_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TodoCard extends StatefulWidget {
  final Map<String, dynamic> todo;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final Future<Map<String, dynamic>> Function(String? date)? onCompleteForDate;
  final DateTime? occurrenceDate;

  const TodoCard({
    super.key,
    required this.todo,
    this.onEdit,
    this.onDelete,
    this.onCompleteForDate,
    this.occurrenceDate,
  });

  @override
  State<TodoCard> createState() => _TodoCardState();
}

class _TodoCardState extends State<TodoCard> with SingleTickerProviderStateMixin {
  late bool _completed;
  late final AnimationController _anim;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _completed = _computeCompleted();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    if (_completed) _anim.value = 1.0;
  }

  @override
  void didUpdateWidget(covariant TodoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // recompute if todo changed externally
    final nowCompleted = _computeCompleted();
    if (nowCompleted != _completed) {
      setState(() => _completed = nowCompleted);
      if (_completed) _anim.forward();
      else _anim.reverse();
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  bool _computeCompleted() {
    final t = widget.todo;
    final occDate = widget.occurrenceDate;
    if (occDate != null) {
      if (t['completed'] == true) return true;
      final comps = t['completions'] as List<dynamic>?;
      if (comps == null) return false;
      return comps.any((c) {
        final cd = DateTime.parse(c['date'].toString());
        return cd.year == occDate.year && cd.month == occDate.month && cd.day == occDate.day;
      });
    } else {
      return t['completed'] == true;
    }
  }

  Color _categoryColor() {
    final cat = widget.todo['category'];
    if (cat is Map && (cat['color'] ?? '').toString().isNotEmpty) {
      try {
        final hex = cat['color'].toString();
        if (hex.startsWith('#')) {
          final value = int.parse(hex.substring(1), radix: 16);
          return Color(0xFF000000 | value);
        }
      } catch (_) {}
    }
    final p = widget.todo['priority'] ?? 'medium';
    switch (p) {
      case 'high':
        return Colors.orange;
      case 'critical':
        return Colors.redAccent;
      case 'low':
        return Colors.green;
      default:
        return Colors.deepPurple;
    }
  }

  Future<void> _onToggleComplete() async {
    if (_running) return;
    if (widget.onCompleteForDate == null) return;
    final dateStr = widget.occurrenceDate != null ? DateFormat('yyyy-MM-dd').format(widget.occurrenceDate!) : null;

    // If already completed for this date, do nothing client-side — parent will refresh if needed
    if (_completed) return;

    setState(() {
      _running = true;
      _completed = true;
    });
    await _anim.forward();

    try {
      final res = await widget.onCompleteForDate!(dateStr);
      // onCompleteForDate returns Map -> parent handles logic/refresh/snackbar
      // After parent refresh, parent will rebuild this card with new todo contents.
    } finally {
      if (mounted) {
        setState(() => _running = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.todo;
    final title = t['title'] ?? 'Untitled';
    final desc = t['description'] ?? '';
    final time = t['time'] ?? t['recurrence']?['time'];
    final occDate = widget.occurrenceDate;
    final category = t['category'];
    final categoryLabel = (category is Map) ? (category['name'] ?? '') : '';

    final color = _categoryColor();

    return Card(
      child: Row(
        children: [
          Container(
            width: 6,
            height: 96,
            decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.horizontal(left: Radius.circular(12))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  GestureDetector(
                    onTap: _onToggleComplete,
                    child: ScaleTransition(
                      scale: Tween(begin: 1.0, end: 0.92).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut)),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _completed ? color : Colors.transparent,
                          border: Border.all(color: _completed ? color : Colors.grey.shade300, width: 1.6),
                        ),
                        child: _completed ? const Icon(Icons.check, size: 18, color: Colors.white) : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(title, style: _completed ? const TextStyle(decoration: TextDecoration.lineThrough, fontWeight: FontWeight.w700) : const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Row(children: [
                        if (time != null) ...[
                          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)), child: Row(children: [const Icon(Icons.access_time, size: 12, color: Colors.black54), const SizedBox(width: 6), Text(time, style: const TextStyle(fontSize: 12))])),
                          const SizedBox(width: 8),
                        ],
                        if (categoryLabel.isNotEmpty) Chip(label: Text(categoryLabel), backgroundColor: color.withOpacity(0.12), visualDensity: VisualDensity.compact),
                      ]),
                      if (desc.toString().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(desc, style: Theme.of(context).textTheme.bodySmall),
                      ]
                    ]),
                  ),
                ]),
              ]),
            ),
          ),
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit' && widget.onEdit != null) widget.onEdit!();
                if (v == 'delete' && widget.onDelete != null) widget.onDelete!();
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'edit', child: Text(widget.onEdit == null ? 'Edit (disabled)' : 'Edit')),
                PopupMenuItem(value: 'delete', child: Text(widget.onDelete == null ? 'Delete (disabled)' : 'Delete')),
              ],
            ),
          ]),
          const SizedBox(width: 6),
        ],
      ),
    );
  }
}