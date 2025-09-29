// lib/widgets/todo_card.dart
import 'package:flutter/material.dart';

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

  Color _categoryColor() {
    final cat = todo['category'];
    if (cat is Map && (cat['color'] ?? '').toString().isNotEmpty) {
      try {
        final hex = cat['color'].toString();
        if (hex.startsWith('#')) {
          final value = int.parse(hex.substring(1), radix: 16);
          return Color(0xFF000000 | value);
        }
      } catch (_) {}
    }
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
    final color = _categoryColor();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isCompleted ? 0 : 1,
      child: Opacity(
        opacity: isCompleted ? 0.6 : 1.0,
        child: Row(
          children: [
            Container(
              width: 6,
              height: 96,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  decoration: isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                  fontWeight: FontWeight.w700,
                                  color: isCompleted ? Colors.grey : Colors.black,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  if (time != null) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.access_time,
                                              size: 12, color: Colors.black54),
                                          const SizedBox(width: 6),
                                          Text(time,
                                              style: const TextStyle(fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  if (categoryLabel.isNotEmpty)
                                    Flexible(
                                      child: Chip(
                                        label: Text(categoryLabel),
                                        backgroundColor: color.withOpacity(0.12),
                                        visualDensity: VisualDensity.compact,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                ],
                              ),
                              if (desc.toString().isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  desc,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: isCompleted ? Colors.grey : Colors.black87,
                                      ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (!isPast && !isCompleted)
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'edit' && onEdit != null) onEdit!();
                  if (v == 'delete' && onDelete != null) onDelete!();
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
            const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }
}