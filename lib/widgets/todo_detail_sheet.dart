import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TodoDetailSheet extends StatelessWidget {
  final Map<String, dynamic> todo;
  final DateTime? occurrenceDate;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TodoDetailSheet({
    super.key,
    required this.todo,
    this.occurrenceDate,
    this.onEdit,
    this.onDelete,
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
    final formattedDate = occurrenceDate != null
        ? DateFormat('EEEE, d MMM yyyy').format(occurrenceDate!)
        : (todo['date'] != null ? DateFormat('EEEE, d MMM yyyy').format(DateTime.parse(todo['date'])) : 'No Date');

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (formattedDate.isNotEmpty || (time ?? '').isNotEmpty)
                Row(
                  children: [
                    if (formattedDate.isNotEmpty)
                      Text(formattedDate, style: const TextStyle(fontSize: 14, color: Colors.black54)),
                    if (formattedDate.isNotEmpty && (time ?? '').isNotEmpty)
                      const SizedBox(width: 12),
                    if ((time ?? '').isNotEmpty)
                      Text(time!, style: const TextStyle(fontSize: 14, color: Colors.black54)),
                  ],
                ),
              const SizedBox(height: 16),
              if (desc.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Description', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    const SizedBox(height: 6),
                    Text(desc, style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 16),
                  ],
                ),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (categoryLabel.isNotEmpty)
                    Chip(
                      label: Text(categoryLabel),
                      backgroundColor: color.withOpacity(0.12),
                      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
                    ),
                  for (final tag in tags)
                    Chip(
                      label: Text(tag),
                      backgroundColor: Colors.blueGrey.withOpacity(0.12),
                      labelStyle: const TextStyle(color: Colors.blueGrey),
                    ),
                ],
              ),
              const SizedBox(height: 24),
            //   Row(
            //     children: [
            //       Expanded(
            //         child: FilledButton.icon(
            //           onPressed: () async {
            //             if (onEdit != null) onEdit!();
            //             Navigator.of(context).pop(); // close sheet after edit
            //           },
            //           icon: const Icon(Icons.edit),
            //           label: const Text('Edit'),
            //           style: FilledButton.styleFrom(backgroundColor: Colors.deepPurple),
            //         ),
            //       ),
            //       const SizedBox(width: 12),
            //       Expanded(
            //         child: FilledButton.icon(
            //           onPressed: () async {
            //             if (onDelete != null) onDelete!();
            //             Navigator.of(context).pop(); // close sheet after delete
            //           },
            //           icon: const Icon(Icons.delete),
            //           label: const Text('Delete'),
            //           style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            //         ),
            //       ),
            //     ],
            //   ),
            ],
          ),
        ),
      ),
    );
  }
}
