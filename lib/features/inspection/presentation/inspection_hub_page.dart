import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_response.dart';
import '../../../shared/widgets/state_views.dart';
import '../../modules/presentation/module_center_page.dart';
import '../data/inspection_repository.dart';
import '../data/models/inspection_models.dart';
import 'analysis_overview_page.dart';
import 'area_management_page.dart';
import 'collection_dashboard_page.dart';
import 'reports_page.dart';
import 'route_management_page.dart';
import 'work_orders_page.dart';

class InspectionHubPage extends StatefulWidget {
  const InspectionHubPage({super.key});

  @override
  State<InspectionHubPage> createState() => _InspectionHubPageState();
}

class _InspectionHubPageState extends State<InspectionHubPage> {
  late Future<_InspectionHubData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_InspectionHubData> _load() async {
    final repository = context.read<InspectionRepository>();
    final workOrders = await repository.getWorkOrders(pageSize: 5);
    final reports = await repository.getReports(pageSize: 5);
    final overview = await repository.getAnalysisOverview();
    return _InspectionHubData(workOrders: workOrders, reports: reports, overview: overview);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('巡检中心')),
      body: FutureBuilder<_InspectionHubData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          if (snapshot.hasError) {
            return ErrorStateView(message: snapshot.error.toString(), onRetry: _refresh);
          }
          final data = snapshot.data;
          if (data == null) {
            return const EmptyStateView(description: '暂无巡检数据');
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _InspectionHero(overview: data.overview),
                const SizedBox(height: 16),
                _InspectionActionGrid(
                  items: [
                    _InspectionActionItem(title: '巡检工单', subtitle: '工单搜索、编辑与审批查看', icon: Icons.assignment_outlined, color: const Color(0xFF0F766E), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WorkOrdersPage()))),
                    _InspectionActionItem(title: '巡检报告', subtitle: '报告维护与审批查看', icon: Icons.description_outlined, color: const Color(0xFF2563EB), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReportsPage()))),
                    _InspectionActionItem(title: '巡检采集', subtitle: '指标、轨迹与过程记录', icon: Icons.sensors_outlined, color: const Color(0xFFD97706), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CollectionDashboardPage()))),
                    _InspectionActionItem(title: '航线管理', subtitle: '天地图航线维护', icon: Icons.route_outlined, color: const Color(0xFF0E7490), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RouteManagementPage()))),
                    _InspectionActionItem(title: '区域管理', subtitle: '天地图区域维护', icon: Icons.polyline_outlined, color: const Color(0xFF7C3AED), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AreaManagementPage()))),
                    _InspectionActionItem(title: '更多功能', subtitle: '进入功能中心', icon: Icons.widgets_outlined, color: const Color(0xFF475569), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ModuleCenterPage()))),
                    _InspectionActionItem(title: '分析总览', subtitle: '风险与报告洞察', icon: Icons.analytics_outlined, color: const Color(0xFFB45309), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AnalysisOverviewPage()))),
                  ],
                ),
                const SizedBox(height: 16),
                _PreviewSection<InspectionWorkOrder>(
                  title: '待关注工单',
                  items: data.workOrders.list,
                  itemBuilder: (item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.no),
                    subtitle: Text('${item.deviceName} · ${item.routeName} · ${item.areaName}'),
                    trailing: Text(item.inspectionTypeName),
                  ),
                ),
                const SizedBox(height: 16),
                _PreviewSection<InspectionReport>(
                  title: '最新报告',
                  items: data.reports.list,
                  itemBuilder: (item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.title.isEmpty ? item.no : item.title),
                    subtitle: Text(item.workOrderNo ?? '${item.workOrderId}'),
                    trailing: Text('${item.auditStatus ?? '--'}'),
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

class _InspectionHubData {
  const _InspectionHubData({required this.workOrders, required this.reports, required this.overview});
  final PageResult<InspectionWorkOrder> workOrders;
  final PageResult<InspectionReport> reports;
  final InspectionAnalysisOverview overview;
}

class _InspectionHero extends StatelessWidget {
  const _InspectionHero({required this.overview});
  final InspectionAnalysisOverview overview;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF0E7490), Color(0xFF1D4ED8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('巡检任务总览', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Text('围绕工单、报告、采集、航线和区域，将地图能力嵌入巡检业务页面。', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white.withValues(alpha: 0.86))),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MetricChip(label: '待同步', value: '${overview.pendingSyncCount}'),
              _MetricChip(label: '已同步', value: '${overview.syncedCount}'),
              _MetricChip(label: '风险项', value: '${overview.riskItems.length}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: Colors.white70)), const SizedBox(height: 4), Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800))]),
    );
  }
}

class _InspectionActionGrid extends StatelessWidget {
  const _InspectionActionGrid({required this.items});
  final List<_InspectionActionItem> items;
  @override
  Widget build(BuildContext context) {
    final cardWidth = (MediaQuery.sizeOf(context).width - 68) / 2;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items
              .map(
                (item) => SizedBox(
                  width: cardWidth,
                  child: InkWell(
                    onTap: item.onTap,
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: item.color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(18)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(item.icon, color: item.color, size: 22),
                          const SizedBox(height: 10),
                          Text(item.title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text(item.subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF64748B), height: 1.25), maxLines: 2, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}

class _InspectionActionItem {
  const _InspectionActionItem({required this.title, required this.subtitle, required this.icon, required this.color, required this.onTap});
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class _PreviewSection<T> extends StatelessWidget {
  const _PreviewSection({required this.title, required this.items, required this.itemBuilder});
  final String title;
  final List<T> items;
  final Widget Function(T item) itemBuilder;
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (items.isEmpty) const Text('暂无数据') else ...items.map(itemBuilder),
        ]),
      ),
    );
  }
}
