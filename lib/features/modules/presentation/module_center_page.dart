import 'package:flutter/material.dart';

import '../../inspection/presentation/analysis_overview_page.dart';
import '../../inspection/presentation/area_management_page.dart';
import '../../inspection/presentation/collection_dashboard_page.dart';
import '../../inspection/presentation/route_management_page.dart';
import '../data/module_catalog.dart';
import '../data/module_models.dart';
import 'bpm_center_page.dart';
import 'module_management_page.dart';

class ModuleCenterPage extends StatelessWidget {
  const ModuleCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width >= 900 ? 4 : width >= 640 ? 3 : 2;
    final groups = <String, List<ModuleDefinition>>{};
    for (final module in allModuleDefinitions) {
      groups.putIfAbsent(module.category, () => []).add(module);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('功能中心')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0B132B), Color(0xFF0E7490), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '低空基础设施管理系统',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  '按业务模块汇聚项目、巡检、运维、故障、采购与流程协同能力，移动端可直接进入搜索、维护、审批与地图场景。',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.88),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          for (final entry in groups.entries) ...[
            Text(
              entry.key,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: entry.value.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.18,
              ),
              itemBuilder: (context, index) {
                final module = entry.value[index];
                return InkWell(
                  onTap: () => _openModule(context, module),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: module.color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 38,
                          width: 38,
                          decoration: BoxDecoration(
                            color: module.color.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(module.icon, color: module.color, size: 20),
                        ),
                        const Spacer(),
                        Text(
                          module.title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          module.subtitle,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF64748B),
                                height: 1.2,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  void _openModule(BuildContext context, ModuleDefinition module) {
    Widget page;
    switch (module.pageKind) {
      case ModulePageKind.inspectionCollection:
        page = const CollectionDashboardPage();
      case ModulePageKind.inspectionAnalysis:
        page = const AnalysisOverviewPage();
      case ModulePageKind.inspectionRoute:
        page = const RouteManagementPage();
      case ModulePageKind.inspectionArea:
        page = const AreaManagementPage();
      case ModulePageKind.bpmCenter:
        page = const BpmCenterPage();
      case ModulePageKind.generic:
        page = ModuleManagementPage(module: module);
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }
}
