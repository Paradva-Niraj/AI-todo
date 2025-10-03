import 'package:flutter/material.dart';
import 'todo_detail_sheet.dart';
import '../screens/todo_editor_screen.dart'; // your editor
import '../services/todo_service.dart';

class TodoCard extends StatelessWidget {
  final Map<String, dynamic> todo;
  final DateTime? occurrenceDate;
  final bool isCompleted;
  final bool isPast;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onComplete;

  const TodoCard({
    super.key,
    required this.todo,
    this.occurrenceDate,
    required this.isCompleted,
    required this.isPast,
    this.onEdit,
    this.onDelete,
    this.onComplete,
  });

  Color _priorityColor() {
    final p = todo['priority'] ?? 'medium';
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

  @override
  Widget build(BuildContext context) {
    final title = todo['title'] ?? 'Untitled';
    final desc = todo['description'] ?? '';
    final time = todo['time'] ?? todo['recurrence']?['time'];
    final category = todo['category'];
    final categoryLabel = (category is Map) ? (category['name'] ?? '') : '';
    final tags = (todo['tags'] as List<dynamic>? ?? []).cast<String>();
    final color = _priorityColor();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isCompleted ? 0 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Opacity(
        opacity: isCompleted ? 0.6 : 1.0,
        child: Row(
          children: [
            // Priority/Category Strip
            Container(
              width: 6,
              height: 120,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
              ),
            ),
            const SizedBox(width: 10),
            // Expanded content with tap to open detailed sheet
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (_) => TodoDetailSheet(
                      todo: todo,
                      occurrenceDate: occurrenceDate,
                      onEdit: () async {
                        Navigator.of(context).pop(); // close sheet first
                        final result = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(builder: (_) => TodoEditorScreen(todo: todo)),
                        );
                        if (result == true) {
                          onEdit?.call(); // null-aware call
                        }
                      },
                      onDelete: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Delete Task'),
                            content: const Text('Are you sure you want to delete this task?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
                              FilledButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          final id = todo['_id'] ?? todo['id'];
                          await TodoService.deleteTodo(id);
                          Navigator.of(context).pop(); // close sheet after delete
                          onDelete?.call(); // null-aware call
                        }
                      },
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Complete checkbox
                          GestureDetector(
                            onTap: isCompleted ? null : onComplete,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isCompleted ? color : Colors.transparent,
                                border: Border.all(
                                  color: isCompleted ? color : Colors.grey.shade300,
                                  width: 1.6,
                                ),
                              ),
                              child: isCompleted
                                  ? const Icon(Icons.check, size: 18, color: Colors.white)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Task info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: isCompleted ? Colors.grey : Colors.black,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                if (desc.isNotEmpty)
                                  Text(
                                    desc,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isCompleted ? Colors.grey : Colors.black87,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    if (time != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.access_time, size: 12, color: Colors.black54),
                                            const SizedBox(width: 4),
                                            Text(time, style: const TextStyle(fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                    if (categoryLabel.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: color.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          categoryLabel,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: color,
                                          ),
                                        ),
                                      ),
                                    for (final tag in tags)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.blueGrey.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(tag, style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (!isPast && !isCompleted)
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'edit') onEdit?.call();
                  if (v == 'delete') onDelete?.call();
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'edit',
                    enabled: onEdit != null,
                    child: Row(
                      children: [
                        const Icon(Icons.edit, size: 18),
                        const SizedBox(width: 12),
                        Text(onEdit == null ? 'Edit (disabled)' : 'Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    enabled: onDelete != null,
                    child: Row(
                      children: [
                        const Icon(Icons.delete, size: 18, color: Colors.red),
                        const SizedBox(width: 12),
                        Text(
                          onDelete == null ? 'Delete (disabled)' : 'Delete',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            else
              const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}
