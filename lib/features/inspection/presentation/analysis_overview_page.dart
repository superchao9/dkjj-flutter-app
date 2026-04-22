import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/state_views.dart';
import '../data/inspection_repository.dart';
import '../data/models/inspection_models.dart';

class AnalysisOverviewPage extends StatefulWidget {
  const AnalysisOverviewPage({super.key});

  @override
  State<AnalysisOverviewPage> createState() => _AnalysisOverviewPageState();
}

class _AnalysisOverviewPageState extends State<AnalysisOverviewPage> {
  late Future<InspectionAnalysisOverview> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<InspectionAnalysisOverview> _load() {
    return context.read<InspectionRepository>().getAnalysisOverview();
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('分析总览')),
      body: FutureBuilder<InspectionAnalysisOverview>(
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
          final overview = snapshot.data;
          if (overview == null) {
            return const EmptyStateView(description: '分析总览暂无数据');
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: overview.summaryCards
                          .map(
                            (item) => Container(
                              width: MediaQuery.sizeOf(context).width / 2 - 30,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7FAFC),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.title),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${item.value}${item.unit ?? ''}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  if ((item.description ?? '').isNotEmpty)
                                    Text(item.description!),
                                ],
                              ),
                            ),
                          )
                          .toList(growable: false),
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
                        Text(
                          '最新风险项',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 12),
                        if (overview.riskItems.isEmpty)
                          const Text('暂无风险项')
                        else
                          ...overview.riskItems.take(8).map(
                                (item) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text('${item.deviceName} · ${item.metricName}'),
                                  subtitle: Text(
                                    '${item.workOrderNo} · ${Formatters.dateTime(item.collectedTime)}',
                                  ),
                                  trailing: Text(
                                    '${item.metricValue ?? '--'}${item.metricUnit ?? ''}',
                                  ),
                                ),
                              ),
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
                        Text(
                          '最新报告',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 12),
                        if (overview.latestReports.isEmpty)
                          const Text('暂无报告洞察')
                        else
                          ...overview.latestReports.take(6).map(
                                (item) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(item.title),
                                  subtitle: Text(
                                    '${item.workOrderNo ?? '--'} · ${Formatters.dateTime(item.reportTime)}',
                                  ),
                                  trailing: Text(item.auditStatusName ?? '--'),
                                ),
                              ),
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
