import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_response.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/state_views.dart';
import '../data/inspection_repository.dart';
import '../data/models/inspection_models.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  late Future<PageResult<InspectionReport>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<PageResult<InspectionReport>> _load() {
    return context.read<InspectionRepository>().getReports();
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('巡检报告')),
      body: FutureBuilder<PageResult<InspectionReport>>(
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
          final reports = snapshot.data?.list ?? const <InspectionReport>[];
          if (reports.isEmpty) {
            return EmptyStateView(
              title: '暂无报告',
              description: '巡检报告接口暂未返回记录。',
              onRetry: _refresh,
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: reports.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = reports[index];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      item.title.isNotEmpty ? item.title : item.no,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('报告编号：${item.no}'),
                          Text('关联工单：${item.workOrderNo ?? item.workOrderId}'),
                          Text('报告日期：${Formatters.date(item.reportDate)}'),
                          Text('结论：${item.conclusion ?? '暂无'}'),
                        ],
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ReportDetailPage(report: item),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class ReportDetailPage extends StatelessWidget {
  const ReportDetailPage({super.key, required this.report});

  final InspectionReport report;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('报告详情')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.title.isNotEmpty ? report.title : report.no,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text('报告编号：${report.no}'),
                  Text('关联工单：${report.workOrderNo ?? report.workOrderId}'),
                  Text('报告日期：${Formatters.date(report.reportDate)}'),
                  Text('审核状态：${report.auditStatus ?? '--'}'),
                  const SizedBox(height: 12),
                  const Text('摘要'),
                  const SizedBox(height: 6),
                  Text(report.summary ?? '暂无摘要'),
                  const SizedBox(height: 12),
                  const Text('结论'),
                  const SizedBox(height: 6),
                  Text(report.conclusion ?? '暂无结论'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
