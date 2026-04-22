import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_response.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/state_views.dart';
import '../data/models/project_models.dart';
import '../data/project_repository.dart';

class ProjectWarningsPage extends StatefulWidget {
  const ProjectWarningsPage({super.key});

  @override
  State<ProjectWarningsPage> createState() => _ProjectWarningsPageState();
}

class _ProjectWarningsPageState extends State<ProjectWarningsPage> {
  late Future<_WarningPageData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_WarningPageData> _load() async {
    final repository = context.read<ProjectRepository>();
    final summary = await repository.getWarningSummary();
    final page = await repository.getWarnings();
    return _WarningPageData(summary: summary, page: page);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设备告警')),
      body: FutureBuilder<_WarningPageData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          if (snapshot.hasError) {
            return ErrorStateView(
              message: snapshot.error.toString(),
              onRetry: _refresh,
            );
          }
          final data = snapshot.data;
          if (data == null) {
            return const EmptyStateView(description: '暂无告警数据');
          }
          final records = data.page.list;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _SummaryTile(
                      label: '总告警',
                      value: '${data.summary.total}',
                      color: const Color(0xFF0F766E),
                    ),
                    _SummaryTile(
                      label: '待处理',
                      value: '${data.summary.pending}',
                      color: const Color(0xFFB45309),
                    ),
                    _SummaryTile(
                      label: '一级',
                      value: '${data.summary.level1}',
                      color: const Color(0xFF2563EB),
                    ),
                    _SummaryTile(
                      label: '三级',
                      value: '${data.summary.level3}',
                      color: const Color(0xFFB91C1C),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (records.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: EmptyStateView(
                        title: '暂无告警记录',
                        description: '设备告警接口暂未返回记录。',
                      ),
                    ),
                  )
                else
                  ...records.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.deviceName,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                  _WarningLevelChip(level: item.warningLevel),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('监测项：${item.monitorType}'),
                              Text('告警类型：${item.warningType}'),
                              Text('告警值：${item.dataValue ?? '--'}${item.dataUnit ?? ''}'),
                              Text('处理状态：${item.handleStatus == 1 ? '已处理' : '待处理'}'),
                              Text('告警时间：${Formatters.dateTime(item.warningTime)}'),
                              if ((item.abnormalReason ?? '').isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    item.abnormalReason!,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: const Color(0xFF64748B),
                                        ),
                                  ),
                                ),
                            ],
                          ),
                        ),
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

class _WarningPageData {
  const _WarningPageData({
    required this.summary,
    required this.page,
  });

  final ProjectDeviceWarningSummary summary;
  final PageResult<ProjectDeviceWarningRecord> page;
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.sizeOf(context).width - 44) / 2;
    return Container(
      width: width.clamp(140, 240),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}

class _WarningLevelChip extends StatelessWidget {
  const _WarningLevelChip({required this.level});

  final int? level;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (level) {
      1 => ('提示', const Color(0xFF2563EB)),
      2 => ('预警', const Color(0xFFD97706)),
      3 => ('严重', const Color(0xFFB91C1C)),
      _ => ('未知', const Color(0xFF64748B)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
