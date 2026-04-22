import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_response.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/state_views.dart';
import '../data/models/project_models.dart';
import '../data/project_repository.dart';

class ProjectDevicesPage extends StatefulWidget {
  const ProjectDevicesPage({super.key});

  @override
  State<ProjectDevicesPage> createState() => _ProjectDevicesPageState();
}

class _ProjectDevicesPageState extends State<ProjectDevicesPage> {
  late Future<PageResult<ProjectDeviceInfo>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<PageResult<ProjectDeviceInfo>> _load() {
    return context.read<ProjectRepository>().getDevices();
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设备台账')),
      body: FutureBuilder<PageResult<ProjectDeviceInfo>>(
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
          final items = snapshot.data?.list ?? const <ProjectDeviceInfo>[];
          if (items.isEmpty) {
            return EmptyStateView(
              title: '暂无设备数据',
              description: '设备台账接口暂未返回记录。',
              onRetry: _refresh,
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
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
                                item.deviceName,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                            _StatusBadge(
                              label: _deviceStatusText(item.deviceStatus),
                              color: _deviceStatusColor(item.deviceStatus),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('编码：${item.deviceCode}'),
                        Text('分类：${item.categoryName ?? '--'}'),
                        Text('厂家：${item.manufacturer ?? '--'}'),
                        Text('型号：${item.model ?? '--'}'),
                        Text('规格：${item.specification ?? '--'}'),
                        Text('创建时间：${Formatters.dateTime(item.createTime)}'),
                      ],
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

String _deviceStatusText(int? status) {
  return switch (status) {
    0 => '待入库',
    1 => '在用',
    2 => '停用',
    20 => '已报废',
    _ => '未知状态',
  };
}

Color _deviceStatusColor(int? status) {
  return switch (status) {
    1 => const Color(0xFF0F766E),
    2 => const Color(0xFFD97706),
    20 => const Color(0xFFB91C1C),
    _ => const Color(0xFF475569),
  };
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
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
