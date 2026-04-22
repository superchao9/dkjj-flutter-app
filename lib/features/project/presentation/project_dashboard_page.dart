import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_response.dart';
import '../../../shared/widgets/state_views.dart';
import '../../modules/presentation/module_center_page.dart';
import '../data/models/project_models.dart';
import '../data/project_repository.dart';
import 'project_assets_page.dart';
import 'project_devices_page.dart';
import 'project_warnings_page.dart';

class ProjectDashboardPage extends StatefulWidget {
  const ProjectDashboardPage({super.key});

  @override
  State<ProjectDashboardPage> createState() => _ProjectDashboardPageState();
}

class _ProjectDashboardPageState extends State<ProjectDashboardPage> {
  late Future<_ProjectDashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_ProjectDashboardData> _load() async {
    final repository = context.read<ProjectRepository>();
    final devices = await repository.getDevices(pageSize: 6);
    final warnings = await repository.getWarnings(pageSize: 6);
    final assets = await repository.getAssets(pageSize: 6);
    final warningSummary = await repository.getWarningSummary();
    return _ProjectDashboardData(devices: devices, warnings: warnings, assets: assets, warningSummary: warningSummary);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('项目管理')),
      body: FutureBuilder<_ProjectDashboardData>(
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
            return const EmptyStateView(description: '暂无项目数据');
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _ProjectHero(summary: data.warningSummary),
                const SizedBox(height: 16),
                _ActionGrid(
                  items: [
                    _ActionItem(title: '设备台账', subtitle: '设备、分类、运行数据', icon: Icons.memory_outlined, color: const Color(0xFF0F766E), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProjectDevicesPage()))),
                    _ActionItem(title: '告警中心', subtitle: '规则与告警记录', icon: Icons.warning_amber_rounded, color: const Color(0xFFD97706), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProjectWarningsPage()))),
                    _ActionItem(title: '资产台账', subtitle: '资产入库、调拨、盘点', icon: Icons.inventory_2_outlined, color: const Color(0xFF2563EB), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProjectAssetsPage()))),
                    _ActionItem(title: '功能中心', subtitle: '规划、建设、运维、故障', icon: Icons.widgets_outlined, color: const Color(0xFF0E7490), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ModuleCenterPage()))),
                  ],
                ),
                const SizedBox(height: 16),
                _PreviewCard<ProjectDeviceInfo>(
                  title: '重点设备',
                  items: data.devices.list,
                  itemBuilder: (item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.deviceName),
                    subtitle: Text('${item.deviceCode} · ${item.categoryName ?? '--'}'),
                    trailing: Text(item.model ?? '--'),
                  ),
                ),
                const SizedBox(height: 16),
                _PreviewCard<ProjectDeviceWarningRecord>(
                  title: '最新告警',
                  items: data.warnings.list,
                  itemBuilder: (item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.deviceName),
                    subtitle: Text('${item.monitorType} · ${item.warningType}'),
                    trailing: Text(item.dataValue == null ? '--' : '${item.dataValue}${item.dataUnit ?? ''}'),
                  ),
                ),
                const SizedBox(height: 16),
                _PreviewCard<ProjectAssetLedger>(
                  title: '资产动态',
                  items: data.assets.list,
                  itemBuilder: (item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.assetName ?? item.assetCode ?? '--'),
                    subtitle: Text('${item.assetCategory ?? '--'} · ${item.businessType ?? '--'}'),
                    trailing: Text(item.assetStatus ?? '--'),
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

class _ProjectDashboardData {
  const _ProjectDashboardData({required this.devices, required this.warnings, required this.assets, required this.warningSummary});
  final PageResult<ProjectDeviceInfo> devices;
  final PageResult<ProjectDeviceWarningRecord> warnings;
  final PageResult<ProjectAssetLedger> assets;
  final ProjectDeviceWarningSummary warningSummary;
}

class _ProjectHero extends StatelessWidget {
  const _ProjectHero({required this.summary});
  final ProjectDeviceWarningSummary summary;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0F766E), Color(0xFF0E7490), Color(0xFF1D4ED8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('项目设备与资产总览', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Text('围绕设备、资产、规划、建设、运维、故障与采购备件形成移动端统一入口。', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white.withValues(alpha: 0.86))),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _HeroMetric(label: '告警总数', value: '${summary.total}'),
              _HeroMetric(label: '待处理', value: '${summary.pending}'),
              _HeroMetric(label: '已处理', value: '${summary.handled}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});
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

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({required this.items});
  final List<_ActionItem> items;
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

class _ActionItem {
  const _ActionItem({required this.title, required this.subtitle, required this.icon, required this.color, required this.onTap});
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class _PreviewCard<T> extends StatelessWidget {
  const _PreviewCard({required this.title, required this.items, required this.itemBuilder});
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
