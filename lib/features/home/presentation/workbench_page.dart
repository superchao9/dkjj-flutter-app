import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_response.dart';
import '../../../shared/widgets/state_views.dart';
import '../../auth/application/auth_controller.dart';
import '../../inspection/data/inspection_repository.dart';
import '../../inspection/data/models/inspection_models.dart';
import '../../inspection/presentation/collection_dashboard_page.dart';
import '../../inspection/presentation/route_management_page.dart';
import '../../modules/presentation/bpm_center_page.dart';
import '../../modules/presentation/module_center_page.dart';
import '../../project/data/models/project_models.dart';
import '../../project/data/project_repository.dart';
import '../../project/presentation/project_assets_page.dart';
import '../../project/presentation/project_devices_page.dart';

class WorkbenchPage extends StatefulWidget {
  const WorkbenchPage({
    super.key,
    required this.onOpenInspection,
    required this.onOpenProject,
  });

  final VoidCallback onOpenInspection;
  final VoidCallback onOpenProject;

  @override
  State<WorkbenchPage> createState() => _WorkbenchPageState();
}

class _WorkbenchPageState extends State<WorkbenchPage> {
  late Future<_WorkbenchData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_WorkbenchData> _load() async {
    final inspectionRepository = context.read<InspectionRepository>();
    final projectRepository = context.read<ProjectRepository>();
    final inspection = await inspectionRepository.getAnalysisOverview();
    final workOrders = await inspectionRepository.getWorkOrders(pageSize: 4);
    final warningSummary = await projectRepository.getWarningSummary();
    final warnings = await projectRepository.getWarnings(pageSize: 4);
    return _WorkbenchData(
      overview: inspection,
      workOrders: workOrders,
      warningSummary: warningSummary,
      warnings: warnings,
    );
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user;
    return Scaffold(
      body: FutureBuilder<_WorkbenchData>(
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
            return const EmptyStateView(description: '暂无首页数据');
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _HomeHero(
                  userName: user?.displayName ?? user?.nickname ?? '同事',
                  overview: data.overview,
                  warningSummary: data.warningSummary,
                ),
                Transform.translate(
                  offset: const Offset(0, -24),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _QuickPanel(
                          onOpenInspection: widget.onOpenInspection,
                          onOpenProject: widget.onOpenProject,
                        ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: '主要快捷入口',
                          actionText: '更多',
                          onAction: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ModuleCenterPage(),
                            ),
                          ),
                          child: GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 1.22,
                            children: [
                              _ActionTile(
                                title: '巡检采集',
                                subtitle: '查看轨迹与采集指标',
                                icon: Icons.sensors_outlined,
                                color: const Color(0xFF0F766E),
                                tag: 'LIVE',
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const CollectionDashboardPage(),
                                  ),
                                ),
                              ),
                              _ActionTile(
                                title: '航线管理',
                                subtitle: '天地图联动航线',
                                icon: Icons.route_outlined,
                                color: const Color(0xFF2563EB),
                                tag: 'MAP',
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const RouteManagementPage(),
                                  ),
                                ),
                              ),
                              _ActionTile(
                                title: '设备台账',
                                subtitle: '核心设备资产',
                                icon: Icons.memory_outlined,
                                color: const Color(0xFF0E7490),
                                tag: 'ASSET',
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const ProjectDevicesPage(),
                                  ),
                                ),
                              ),
                              _ActionTile(
                                title: '流程中心',
                                subtitle: '审批流程查看',
                                icon: Icons.approval_outlined,
                                color: const Color(0xFFD97706),
                                tag: 'BPM',
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const BpmCenterPage(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: '巡检态势',
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _MetricTile(
                                      label: '待同步',
                                      value:
                                          '${data.overview.pendingSyncCount}',
                                      color: const Color(0xFFD97706),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _MetricTile(
                                      label: '已同步',
                                      value: '${data.overview.syncedCount}',
                                      color: const Color(0xFF0F766E),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ...data.workOrders.list.map(
                                (item) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(item.no),
                                  subtitle: Text(
                                    '${item.deviceName} · ${item.routeName} · ${item.areaName}',
                                  ),
                                  trailing: Text(item.inspectionTypeName),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: '项目告警',
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _MetricTile(
                                      label: '告警总数',
                                      value: '${data.warningSummary.total}',
                                      color: const Color(0xFF2563EB),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _MetricTile(
                                      label: '待处理',
                                      value: '${data.warningSummary.pending}',
                                      color: const Color(0xFFB91C1C),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (data.warnings.list.isEmpty)
                                const Text('暂无告警记录')
                              else
                                ...data.warnings.list.map(
                                  (item) => ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: const Icon(
                                      Icons.warning_amber_rounded,
                                    ),
                                    title: Text(item.deviceName),
                                    subtitle: Text(
                                      '${item.monitorType} · ${item.warningType}',
                                    ),
                                    trailing: Text(
                                      item.dataValue == null
                                          ? '--'
                                          : '${item.dataValue}${item.dataUnit ?? ''}',
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: '资产概览',
                          child: _BusinessTile(
                            title: '资产台账',
                            subtitle:
                                '查看资产生命周期、调拨、入库、租赁、维修与盘点业务。',
                            icon: Icons.inventory_2_outlined,
                            color: const Color(0xFF2563EB),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ProjectAssetsPage(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
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

class _WorkbenchData {
  const _WorkbenchData({
    required this.overview,
    required this.workOrders,
    required this.warningSummary,
    required this.warnings,
  });

  final InspectionAnalysisOverview overview;
  final PageResult<InspectionWorkOrder> workOrders;
  final ProjectDeviceWarningSummary warningSummary;
  final PageResult<ProjectDeviceWarningRecord> warnings;
}

class _HomeHero extends StatelessWidget {
  const _HomeHero({
    required this.userName,
    required this.overview,
    required this.warningSummary,
  });

  final String userName;
  final InspectionAnalysisOverview overview;
  final ProjectDeviceWarningSummary warningSummary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 56),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0B132B), Color(0xFF0E7490), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '你好，$userName',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              '低空基础设施管理系统',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '在移动端快速进入巡检、项目、设备、审批与地图业务场景。',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _HeroStat(label: '风险项', value: '${overview.riskItems.length}'),
                _HeroStat(
                  label: '待同步',
                  value: '${overview.pendingSyncCount}',
                ),
                _HeroStat(
                  label: '待处理告警',
                  value: '${warningSummary.pending}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickPanel extends StatelessWidget {
  const _QuickPanel({
    required this.onOpenInspection,
    required this.onOpenProject,
  });

  final VoidCallback onOpenInspection;
  final VoidCallback onOpenProject;

  @override
  Widget build(BuildContext context) {
    final cardWidth = (MediaQuery.sizeOf(context).width - 68) / 2;
    final items = [
      ('巡检中心', Icons.flight_takeoff_outlined, const Color(0xFF0F766E), onOpenInspection),
      ('项目管理', Icons.account_tree_outlined, const Color(0xFF2563EB), onOpenProject),
      (
        '功能中心',
        Icons.widgets_outlined,
        const Color(0xFF0E7490),
        () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ModuleCenterPage()),
        ),
      ),
      (
        '审批流程',
        Icons.approval_outlined,
        const Color(0xFFD97706),
        () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const BpmCenterPage()),
        ),
      ),
    ];

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
                    onTap: item.$4,
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: item.$3.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          Icon(item.$2, color: item.$3, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.$1,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.actionText,
    this.onAction,
  });

  final String title;
  final Widget child;
  final String? actionText;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                if (actionText != null && onAction != null)
                  TextButton(onPressed: onAction, child: Text(actionText!)),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.tag,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String tag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.16),
              color.withValues(alpha: 0.06),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.14)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 28,
                  width: 28,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF64748B),
                    height: 1.18,
                    fontSize: 11.5,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  height: 3,
                  width: 26,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const Spacer(),
                Icon(Icons.north_east_rounded, size: 16, color: color),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BusinessTile extends StatelessWidget {
  const _BusinessTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF64748B),
                        ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
