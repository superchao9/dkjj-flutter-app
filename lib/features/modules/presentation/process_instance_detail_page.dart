import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/state_views.dart';
import '../data/module_repository.dart';

class ProcessInstanceDetailPage extends StatefulWidget {
  const ProcessInstanceDetailPage({
    super.key,
    required this.processInstanceId,
  });

  final String processInstanceId;

  @override
  State<ProcessInstanceDetailPage> createState() => _ProcessInstanceDetailPageState();
}

class _ProcessInstanceDetailPageState extends State<ProcessInstanceDetailPage> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() {
    return context.read<ModuleRepository>().fetchApprovalDetail(widget.processInstanceId);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('审批详情')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          if (snapshot.hasError) {
            return ErrorStateView(message: snapshot.error.toString(), onRetry: _refresh);
          }
          final data = snapshot.data ?? const <String, dynamic>{};
          final processInstance = (data['processInstance'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
          final processDefinition = (data['processDefinition'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
          final activityNodes = (data['activityNodes'] as List<dynamic>? ?? const []).whereType<Map<String, dynamic>>().toList(growable: false);

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (processInstance['name'] ?? '审批流程') as String,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        _InfoRow(label: '流程实例 ID', value: '${processInstance['id'] ?? widget.processInstanceId}'),
                        _InfoRow(label: '流程定义', value: '${processDefinition['name'] ?? processDefinition['id'] ?? '--'}'),
                        _InfoRow(label: '业务主键', value: '${processInstance['businessKey'] ?? '--'}'),
                        _InfoRow(label: '流程状态', value: _processStatusText(processInstance['status'])),
                        _InfoRow(label: '发起时间', value: Formatters.dateTime(_parseDate(processInstance['startTime']))),
                        _InfoRow(label: '结束时间', value: Formatters.dateTime(_parseDate(processInstance['endTime']))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('审批时间线', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        if (activityNodes.isEmpty)
                          const Text('暂无审批节点')
                        else
                          ...activityNodes.map((node) => _NodeCard(node: node)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NodeCard extends StatelessWidget {
  const _NodeCard({required this.node});

  final Map<String, dynamic> node;

  @override
  Widget build(BuildContext context) {
    final tasks = (node['tasks'] as List<dynamic>? ?? const []).whereType<Map<String, dynamic>>().toList(growable: false);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${node['name'] ?? '审批节点'}', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('状态：${_processStatusText(node['status'])}'),
          Text('开始时间：${Formatters.dateTime(_parseDate(node['startTime']))}'),
          Text('结束时间：${Formatters.dateTime(_parseDate(node['endTime']))}'),
          if (tasks.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...tasks.map(
              (task) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${task['assigneeUser'] is Map<String, dynamic> ? (task['assigneeUser'] as Map<String, dynamic>)['nickname'] ?? '待分配' : '待分配'}'
                  ' - ${_processStatusText(task['status'])}'
                  '${(task['reason'] ?? '').toString().isEmpty ? '' : ' - ${task['reason']}'}',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 96, child: Text(label, style: TextStyle(color: Colors.grey.shade600))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

String _processStatusText(dynamic status) {
  return switch ((status as num?)?.toInt()) {
    1 => '进行中',
    2 => '已通过',
    3 => '已驳回',
    4 => '已取消',
    _ => '${status ?? '--'}',
  };
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return DateTime.tryParse(value.toString());
}
