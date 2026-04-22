import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/state_views.dart';
import '../data/module_models.dart';
import '../data/module_repository.dart';
import 'process_instance_detail_page.dart';

class ModuleManagementPage extends StatefulWidget {
  const ModuleManagementPage({
    super.key,
    required this.module,
  });

  final ModuleDefinition module;

  @override
  State<ModuleManagementPage> createState() => _ModuleManagementPageState();
}

class _ModuleManagementPageState extends State<ModuleManagementPage> {
  late Future<DynamicPageResult> _future;
  late final Map<String, TextEditingController> _searchControllers;

  @override
  void initState() {
    super.initState();
    _searchControllers = {
      for (final field in widget.module.searchFields) field.key: TextEditingController(),
    };
    _future = _load();
  }

  @override
  void dispose() {
    for (final controller in _searchControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<DynamicPageResult> _load() {
    final query = <String, dynamic>{'pageNo': 1, 'pageSize': 20};
    for (final field in widget.module.searchFields) {
      final value = _searchControllers[field.key]?.text.trim() ?? '';
      if (value.isNotEmpty) {
        query[field.key] = value;
      }
    }
    return context.read<ModuleRepository>().fetchPage(widget.module, query: query);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _openForm([Map<String, dynamic>? row]) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ModuleFormSheet(module: widget.module, initialValue: row),
    );
    if (result == true) {
      await _refresh();
    }
  }

  Future<void> _delete(Map<String, dynamic> row) async {
    await context.read<ModuleRepository>().delete(widget.module, row['id']);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('删除成功')));
    await _refresh();
  }

  Future<void> _submit(Map<String, dynamic> row) async {
    await context.read<ModuleRepository>().submit(widget.module, row['id']);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已提交审批')));
    await _refresh();
  }

  Future<void> _openDetail(Map<String, dynamic> row) async {
    final detail = await context.read<ModuleRepository>().fetchDetail(widget.module, row['id']);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _DetailSheet(module: widget.module, detail: detail),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.module.title)),
      floatingActionButton: widget.module.createPath == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _openForm,
              icon: const Icon(Icons.add),
              label: const Text('新增'),
            ),
      body: FutureBuilder<DynamicPageResult>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          if (snapshot.hasError) {
            return ErrorStateView(message: snapshot.error.toString(), onRetry: _refresh);
          }
          final page = snapshot.data ?? const DynamicPageResult(total: 0, list: []);
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        for (final field in widget.module.searchFields) ...[
                          TextField(
                            controller: _searchControllers[field.key],
                            decoration: InputDecoration(
                              labelText: field.label,
                              prefixIcon: const Icon(Icons.search),
                            ),
                            onSubmitted: (_) => _refresh(),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Row(
                          children: [
                            Expanded(child: FilledButton.tonal(onPressed: _refresh, child: const Text('搜索'))),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  for (final controller in _searchControllers.values) {
                                    controller.clear();
                                  }
                                  _refresh();
                                },
                                child: const Text('重置'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('共 ${page.total} 条记录', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF64748B))),
                const SizedBox(height: 12),
                if (page.list.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: EmptyStateView(description: '当前模块暂未返回记录。'),
                    ),
                  )
                else
                  ...page.list.map(_buildRecordCard),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecordCard(Map<String, dynamic> row) {
    final title = _resolveTitle(row, widget.module.titleFields);
    final processInstanceId = (row['processInstanceId'] ?? '').toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
                  if (row.containsKey('auditStatus'))
                    _TagChip(text: '审批 ${row['auditStatus'] ?? '--'}', color: widget.module.color)
                  else if (row.containsKey('status'))
                    _TagChip(text: '状态 ${row['status'] ?? '--'}', color: widget.module.color),
                ],
              ),
              const SizedBox(height: 10),
              ...widget.module.displayFields.map(
                (field) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('${field.label}：${_displayValue(row[field.key])}'),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (widget.module.detailPath != null)
                    OutlinedButton(onPressed: () => _openDetail(row), child: const Text('详情')),
                  if (widget.module.updatePath != null)
                    OutlinedButton(onPressed: () => _openForm(row), child: const Text('编辑')),
                  if (widget.module.submitPath != null)
                    OutlinedButton(onPressed: () => _submit(row), child: const Text('提交审批')),
                  if (widget.module.supportsApproval && processInstanceId.isNotEmpty)
                    FilledButton.tonal(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ProcessInstanceDetailPage(processInstanceId: processInstanceId),
                          ),
                        );
                      },
                      child: const Text('查看审批'),
                    ),
                  if (widget.module.deletePath != null)
                    OutlinedButton(onPressed: () => _delete(row), child: const Text('删除')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuleFormSheet extends StatefulWidget {
  const _ModuleFormSheet({required this.module, this.initialValue});

  final ModuleDefinition module;
  final Map<String, dynamic>? initialValue;

  @override
  State<_ModuleFormSheet> createState() => _ModuleFormSheetState();
}

class _ModuleFormSheetState extends State<_ModuleFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _controllers;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final field in widget.module.editableFields)
        field.key: TextEditingController(text: '${widget.initialValue?[field.key] ?? ''}'),
    };
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final payload = <String, dynamic>{};
      if (widget.initialValue?['id'] != null) {
        payload['id'] = widget.initialValue!['id'];
      }
      for (final field in widget.module.editableFields) {
        final text = _controllers[field.key]!.text.trim();
        if (text.isEmpty) continue;
        payload[field.key] = switch (field.type) {
          ModuleValueType.number => num.tryParse(text),
          _ => text,
        };
      }
      final repository = context.read<ModuleRepository>();
      if (widget.initialValue == null) {
        await repository.create(widget.module, payload);
      } else {
        await repository.update(widget.module, payload);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.initialValue == null ? '新增${widget.module.title}' : '编辑${widget.module.title}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                for (final field in widget.module.editableFields) ...[
                  TextFormField(
                    controller: _controllers[field.key],
                    keyboardType: field.type == ModuleValueType.number ? TextInputType.number : TextInputType.text,
                    maxLines: field.type == ModuleValueType.multiline ? 4 : 1,
                    decoration: InputDecoration(labelText: field.label),
                    validator: (value) {
                      if (field.required && (value == null || value.trim().isEmpty)) {
                        return '请输入${field.label}';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: Text(_submitting ? '提交中...' : '保存'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailSheet extends StatelessWidget {
  const _DetailSheet({required this.module, required this.detail});

  final ModuleDefinition module;
  final Map<String, dynamic> detail;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(16),
        children: [
          Text(module.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          ...detail.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 120, child: Text(entry.key, style: TextStyle(color: Colors.grey.shade600))),
                  Expanded(child: Text(_displayValue(entry.value))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
    );
  }
}

String _resolveTitle(Map<String, dynamic> row, List<String> keys) {
  for (final key in keys) {
    final value = row[key];
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString();
    }
  }
  return '${row['id'] ?? '未命名记录'}';
}

String _displayValue(dynamic value) {
  if (value == null) return '--';
  if (value is List) return value.join(', ');
  if (value is Map) return value.toString();
  final text = value.toString();
  final date = DateTime.tryParse(text);
  if (date != null) {
    return Formatters.dateTime(date);
  }
  return text;
}
