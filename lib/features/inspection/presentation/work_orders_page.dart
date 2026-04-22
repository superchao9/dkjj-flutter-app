import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_response.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/state_views.dart';
import '../data/inspection_repository.dart';
import '../data/models/inspection_models.dart';

class WorkOrdersPage extends StatefulWidget {
  const WorkOrdersPage({super.key});

  @override
  State<WorkOrdersPage> createState() => _WorkOrdersPageState();
}

class _WorkOrdersPageState extends State<WorkOrdersPage> {
  late Future<PageResult<InspectionWorkOrder>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<PageResult<InspectionWorkOrder>> _load() {
    return context.read<InspectionRepository>().getWorkOrders();
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('巡检工单')),
      body: FutureBuilder<PageResult<InspectionWorkOrder>>(
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
          final orders = snapshot.data?.list ?? const <InspectionWorkOrder>[];
          if (orders.isEmpty) {
            return EmptyStateView(
              title: '暂无工单',
              description: '巡检工单接口暂未返回记录。',
              onRetry: _refresh,
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = orders[index];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      item.no.isNotEmpty ? item.no : '未命名工单',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('设备：${item.deviceName}'),
                          Text('区域：${item.areaName}'),
                          Text('路线：${item.routeName}'),
                          Text('巡检类型：${item.inspectionTypeName}'),
                          Text('服务商：${item.serviceProviderName}'),
                          Text('计划时间：${Formatters.dateTime(item.plannedTime)}'),
                        ],
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => WorkOrderDetailPage(order: item),
                        ),
                      );
                    },
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

class WorkOrderDetailPage extends StatelessWidget {
  const WorkOrderDetailPage({super.key, required this.order});

  final InspectionWorkOrder order;

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('工单编号', order.no),
      ('设备名称', order.deviceName),
      ('区域', order.areaName),
      ('路线', order.routeName),
      ('巡检类型', order.inspectionTypeName),
      ('服务商', order.serviceProviderName),
      ('巡检日期', Formatters.date(order.inspectionDate)),
      ('计划时间', Formatters.dateTime(order.plannedTime)),
      ('审核状态', '${order.auditStatus ?? '--'}'),
      ('派发状态', '${order.dispatchStatus ?? '--'}'),
      ('说明', order.description ?? '--'),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('工单详情')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: rows
                    .map(
                      (row) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 92,
                              child: Text(
                                row.$1,
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ),
                            Expanded(child: Text(row.$2)),
                          ],
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
