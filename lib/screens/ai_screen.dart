// lib/screens/ai_screen.dart - Enhanced AI Screen with Smart Features
import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../utils/date_helper.dart';

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final TextEditingController _promptCtl = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _loading = false;
  Map<String, dynamic>? _result;
  String? _error;
  bool _committing = false;
  String _selectedMode = 'auto';

  // Quick action buttons
  final List<Map<String, dynamic>> _quickActions = [
    {'label': '📊 Daily Summary', 'prompt': 'Give me a summary of my day and what I should focus on', 'mode': 'summary'},
    {'label': '✅ What\'s Next?', 'prompt': 'What should I work on next? Prioritize my tasks', 'mode': 'prioritize'},
    {'label': '📈 Weekly Overview', 'prompt': 'Analyze my week and show productivity patterns', 'mode': 'analyze'},
    {'label': '⚠️ Check Conflicts', 'prompt': 'Check for time conflicts and overloaded days', 'mode': 'analyze'},
  ];

  @override
  void dispose() {
    _promptCtl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Validate prompt on client side
  String? _validatePrompt(String text) {
    final cleaned = text.trim();
    
    if (cleaned.length < 3) {
      return 'Please enter at least 3 characters';
    }
    
    if (cleaned.length > 2000) {
      return 'Prompt too long (max 2000 characters)';
    }

    // Check for repeated characters
    final repeatedChars = RegExp(r'(.)\1{10,}');
    if (repeatedChars.hasMatch(cleaned)) {
      return 'Invalid prompt format';
    }

    // Check for only numbers or special characters
    if (RegExp(r'^[^a-zA-Z]+$').hasMatch(cleaned)) {
      return 'Please use letters in your prompt';
    }

    return null;
  }

  Future<void> _submitPrompt({String? customPrompt, String? mode}) async {
    final prompt = (customPrompt ?? _promptCtl.text).trim();
    
    // Validate
    final validationError = _validatePrompt(prompt);
    if (validationError != null) {
      _showSnackbar(validationError, isError: true);
      return;
    }

    setState(() {
      _loading = true;
      _result = null;
      _error = null;
    });

    final payload = {'prompt': prompt};
    // Pass custom mode parameter either from argument or selected mode
    final modeToSend = mode ?? _selectedMode;
    if (modeToSend != 'auto') {
      payload['mode'] = modeToSend;
    }

    final res = await AiService.assist(payload);

    if (!mounted) return;
    setState(() => _loading = false);

    if (res['ok'] == true) {
      final body = res['body'] as Map<String, dynamic>? ?? {};
      final data = body['data'] as Map<String, dynamic>? ?? body;
      setState(() {
        _result = data;
      });

      // Auto-scroll to results
      Future.delayed(const Duration(milliseconds: 200), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } else {
      final err = res['error'] ?? res['body']?['error'] ?? 'AI request failed';
      setState(() => _error = err.toString());
      _showSnackbar(err.toString(), isError: true);
    }
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
        'categoryId': e['categoryId'],
      };
    }).toList();

    if (tasks.isEmpty) {
      _showSnackbar('No tasks to add', isError: true);
      return;
    }

    // Confirm before adding multiple tasks
    if (tasks.length > 5) {
      final confirmed = await _showConfirmDialog(
        'Add ${tasks.length} Tasks?',
        'This will create ${tasks.length} new tasks in your list.',
      );
      if (confirmed != true) return;
    }

    setState(() => _committing = true);
    final res = await AiService.commitTasks(tasks);
    
    if (!mounted) return;
    setState(() => _committing = false);

    if (res['ok'] == true) {
      final count = res['body']?['createdCount'] ?? res['body']?['created']?.length ?? 0;
      _showSnackbar('✓ Created $count tasks successfully');
      
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) Navigator.of(context).pop(true);
    } else {
      final err = res['error'] ?? res['body']?['error'] ?? 'Failed to create tasks';
      _showSnackbar(err, isError: true);
    }
  }

  Future<bool?> _showConfirmDialog(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: isError ? 4 : 2),
    ));
  }

  String _relativeToDateLabel(dynamic offsetRaw) {
    int offset = 0;
    try {
      if (offsetRaw is int) {
        offset = offsetRaw;
      } else {
        offset = int.parse(offsetRaw.toString());
      }
    } catch (_) {
      offset = 0;
    }
    
    final target = DateHelper.startOfDay(DateTime.now()).add(Duration(days: offset));
    
    if (offset == 0) return 'Today';
    if (offset == 1) return 'Tomorrow';
    if (offset == -1) return 'Yesterday';
    if (offset > 0) return 'In $offset days';
    return '${offset.abs()} days ago';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.psychology, color: theme.colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('AI Assistant'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Help',
            onPressed: () => _showHelpDialog(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  // Quick Actions
                  _buildQuickActions(),
                  const SizedBox(height: 20),

                  // Input Area
                  _buildInputArea(),
                  const SizedBox(height: 16),

                  // Loading Indicator
                  if (_loading) _buildLoadingIndicator(),

                  // Error Display
                  if (_error != null) _buildErrorCard(),

                  // Results Display
                  if (_result != null) ...[
                    const SizedBox(height: 16),
                    _buildResults(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _quickActions.map((action) {
            return ActionChip(
              avatar: const Icon(Icons.auto_awesome, size: 16),
              label: Text(action['label']),
              onPressed: _loading ? null : () {
                _submitPrompt(
                  customPrompt: action['prompt'],
                  mode: action['mode'],
                );
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildInputArea() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _promptCtl,
              minLines: 3,
              maxLines: 6,
              maxLength: 2000,
              decoration: InputDecoration(
                hintText: 'Ask me anything about your tasks...\n\nExamples:\n• "Summarize my day"\n• "Create tasks for my project"\n• "What should I focus on?"',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                counterText: '${_promptCtl.text.length}/2000',
              ),
              onChanged: (text) => setState(() {}),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DropdownButtonFormField<String>(
                initialValue: _selectedMode,
                decoration: InputDecoration(
                  labelText: 'Select AI Mode',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: const [
                  DropdownMenuItem(value: 'auto', child: Text('Auto (Detect mode)')),
                  DropdownMenuItem(value: 'summary', child: Text('Summary')),
                  DropdownMenuItem(value: 'create', child: Text('Create Tasks')),
                  DropdownMenuItem(value: 'prioritize', child: Text('Prioritize Tasks')),
                  DropdownMenuItem(value: 'analyze', child: Text('Analyze Productivity')),
                  DropdownMenuItem(value: 'general', child: Text('General Query')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedMode = value ?? 'auto';
                  });
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _loading || _promptCtl.text.trim().length < 3 
                      ? null 
                      : () => _submitPrompt(),
                    icon: _loading 
                      ? const SizedBox(
                          width: 18, 
                          height: 18, 
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send),
                    label: Text(_loading ? 'Processing...' : 'Ask AI'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _promptCtl.text.isEmpty ? null : () {
                    setState(() {
                      _promptCtl.clear();
                      _result = null;
                      _error = null;
                    });
                  },
                  icon: const Icon(Icons.clear),
                  tooltip: 'Clear',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'AI is thinking...',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'This may take a few seconds',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Error',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(_error!, style: TextStyle(color: Colors.red.shade700)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _submitPrompt(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    final responseType = _result!['responseType'] ?? 'general';
    final meta = _result!['meta'] as Map<String, dynamic>?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Meta Info Card
        if (meta != null) _buildMetaCard(meta),

        // Summary
        if ((_result!['summary'] ?? '').toString().isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildSummaryCard(),
        ],

        // Advice
        if ((_result!['advice'] ?? '').toString().isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildAdviceCard(),
        ],

        // Highlights
        if (_result!['highlights'] != null) ...[
          const SizedBox(height: 16),
          _buildHighlightsCard(),
        ],

        // Warnings
        if (_result!['warnings'] != null) ...[
          const SizedBox(height: 16),
          _buildWarningsCard(),
        ],

        // Priority Order
        if (_result!['priorityOrder'] != null) ...[
          const SizedBox(height: 16),
          _buildPriorityCard(),
        ],

        // Insights
        if (_result!['insights'] != null) ...[
          const SizedBox(height: 16),
          _buildInsightsCard(),
        ],

        // Suggested Tasks
        if ((_result!['suggestedTasks'] as List<dynamic>?)?.isNotEmpty ?? false) ...[
          const SizedBox(height: 16),
          _buildSuggestedTasksCard(),
        ],

        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildMetaCard(Map<String, dynamic> meta) {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  Text('Total: ${meta['taskCount'] ?? 0}', style: const TextStyle(fontSize: 13)),
                  if ((meta['overdueCount'] ?? 0) > 0)
                    Text(
                      'Overdue: ${meta['overdueCount']}',
                      style: const TextStyle(fontSize: 13, color: Colors.red, fontWeight: FontWeight.w600),
                    ),
                  Text('Today: ${meta['todayCount'] ?? 0}', style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.summarize, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text('Summary', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            Text(_result!['summary'], style: const TextStyle(fontSize: 15, height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildAdviceCard() {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, size: 20, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Text(
                  'Advice',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(_result!['advice'], style: const TextStyle(fontSize: 15, height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightsCard() {
    final highlights = _result!['highlights'] as List<dynamic>;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Key Points', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 12),
            ...highlights.map((h) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 18)),
                  Expanded(child: Text(h.toString(), style: const TextStyle(fontSize: 15))),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningsCard() {
    final warnings = _result!['warnings'] as List<dynamic>;
    if (warnings.isEmpty) return const SizedBox.shrink();

    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Warnings',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...warnings.map((w) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('⚠ ', style: TextStyle(fontSize: 16)),
                  Expanded(child: Text(w.toString(), style: const TextStyle(fontSize: 15))),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityCard() {
    final priorityOrder = _result!['priorityOrder'] as List<dynamic>;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recommended Priority', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 12),
            ...priorityOrder.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${idx + 1}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                          if (item['reason'] != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              item['reason'],
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsCard() {
    final insights = _result!['insights'] as List<dynamic>;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Insights', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 12),
            ...insights.map((insight) {
              final i = insight as Map<String, dynamic>;
              final type = i['type'] ?? 'insight';
              IconData icon = Icons.lightbulb_outline;
              Color color = Colors.blue;

              if (type == 'pattern') {
                icon = Icons.trending_up;
                color = Colors.purple;
              } else if (type == 'issue') {
                icon = Icons.report_problem_outlined;
                color = Colors.orange;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 20, color: color),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(i['description'] ?? '', style: const TextStyle(fontSize: 15)),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestedTasksCard() {
    final tasks = _result!['suggestedTasks'] as List<dynamic>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Suggested Tasks', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${tasks.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _committing ? null : _commitAll,
                  icon: _committing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.add, size: 18),
                  label: const Text('Add All'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...tasks.map((t) => _buildTaskItem(t as Map<String, dynamic>)),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskItem(Map<String, dynamic> task) {
    final priority = task['priority'] ?? 'medium';
    Color priorityColor = Colors.grey;
    
    switch (priority) {
      case 'critical':
        priorityColor = Colors.red;
        break;
      case 'high':
        priorityColor = Colors.orange;
        break;
      case 'medium':
        priorityColor = Colors.blue;
        break;
      case 'low':
        priorityColor = Colors.green;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: priorityColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    task['title'] ?? 'Untitled',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ],
            ),
            if ((task['description'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                task['description'],
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Chip(
                  label: Text(priority.toUpperCase()),
                  backgroundColor: priorityColor.withOpacity(0.15),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                Chip(
                  label: Text(_relativeToDateLabel(task['relativeDayOffset'])),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                if (task['time'] != null)
                  Chip(
                    avatar: const Icon(Icons.access_time, size: 16),
                    label: Text(task['time']),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI Assistant Help'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('What can I ask?', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              const Text('• Summarize my day or week\n'
                  '• Create tasks from project descriptions\n'
                  '• Prioritize my tasks\n'
                  '• Analyze productivity patterns\n'
                  '• Check for conflicts\n'
                  '• Get advice on time management'),
              const SizedBox(height: 16),
              const Text('Tips:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              const Text('• Be specific and clear\n'
                  '• Use natural language\n'
                  '• Minimum 3 characters\n'
                  '• Maximum 2000 characters\n'
                  '• Rate limit: 10 requests/minute'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}