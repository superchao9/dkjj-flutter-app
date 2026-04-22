import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/state_views.dart';
import '../data/inspection_repository.dart';
import '../data/models/inspection_models.dart';

class CollectionDashboardPage extends StatefulWidget {
  const CollectionDashboardPage({super.key});

  @override
  State<CollectionDashboardPage> createState() => _CollectionDashboardPageState();
}

class _CollectionDashboardPageState extends State<CollectionDashboardPage> {
  int? _selectedWorkOrderId;
  String _mapType = 'satellite';
  late Future<_CollectionDashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_CollectionDashboardData> _load() async {
    final repository = context.read<InspectionRepository>();
    final dashboard = await repository.getCollectionDashboard(workOrderId: _selectedWorkOrderId);
    final traces = _selectedWorkOrderId == null ? const <InspectionProcessTrace>[] : await repository.getProcessTraces(_selectedWorkOrderId!);
    return _CollectionDashboardData(dashboard: dashboard, traces: traces);
  }

  Future<void> _reloadFor(int? workOrderId) async {
    setState(() {
      _selectedWorkOrderId = workOrderId;
      _future = _load();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('巡检数据采集')),
      body: FutureBuilder<_CollectionDashboardData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          if (snapshot.hasError) {
            return ErrorStateView(message: snapshot.error.toString(), onRetry: () => _reloadFor(_selectedWorkOrderId));
          }
          final data = snapshot.data;
          if (data == null) {
            return const EmptyStateView(description: '采集看板暂无数据');
          }
          final dashboard = data.dashboard;
          final selectedTask = dashboard.workOrders.where((item) => item.workOrderId == _selectedWorkOrderId).cast<InspectionCollectionTask?>().firstWhere((item) => item != null, orElse: () => dashboard.workOrders.isEmpty ? null : dashboard.workOrders.first);
          final trackPoints = dashboard.trackPoints
              .where((item) => item.lng != null && item.lat != null)
              .map((item) => LatLng(item.lat!.toDouble(), item.lng!.toDouble()))
              .toList(growable: false);
          final center = trackPoints.isEmpty ? const LatLng(31.31154, 120.61296) : trackPoints.first;

          return RefreshIndicator(
            onRefresh: () => _reloadFor(_selectedWorkOrderId),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('工单选择', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          value: _selectedWorkOrderId,
                          decoration: const InputDecoration(hintText: '选择一个工单查看采集数据'),
                          items: dashboard.workOrders
                              .map((item) => DropdownMenuItem<int>(value: item.workOrderId, child: Text('${item.no} · ${item.deviceName}')))
                              .toList(growable: false),
                          onChanged: (value) => _reloadFor(value),
                        ),
                        if (selectedTask != null) ...[
                          const SizedBox(height: 12),
                          Text('区域：${selectedTask.areaName}'),
                          Text('航线：${selectedTask.routeName}'),
                          Text('计划时间：${Formatters.dateTime(selectedTask.plannedTime)}'),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: SizedBox(
                    height: 320,
                    child: Stack(
                      children: [
                        FlutterMap(
                          options: MapOptions(initialCenter: center, initialZoom: trackPoints.isEmpty ? 11 : 14),
                          children: [
                            TileLayer(urlTemplate: _tileUrl(_mapType, false)),
                            TileLayer(urlTemplate: _tileUrl(_mapType, true)),
                            if (trackPoints.isNotEmpty)
                              PolylineLayer(
                                polylines: [
                                  Polyline(points: trackPoints, strokeWidth: 4, color: const Color(0xFF2563EB)),
                                ],
                              ),
                            if (trackPoints.isNotEmpty)
                              MarkerLayer(
                                markers: [
                                  for (var i = 0; i < trackPoints.length; i++)
                                    Marker(
                                      point: trackPoints[i],
                                      width: 18,
                                      height: 18,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: i == 0 ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                          ],
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: 'satellite', label: Text('影像')),
                              ButtonSegment(value: 'normal', label: Text('矢量')),
                            ],
                            selected: {_mapType},
                            onSelectionChanged: (value) => setState(() => _mapType = value.first),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _MetricSection(title: '设备指标', metrics: dashboard.deviceMetrics),
                const SizedBox(height: 16),
                _MetricSection(title: '作业指标', metrics: dashboard.operationMetrics),
                const SizedBox(height: 16),
                _MetricSection(title: '安全指标', metrics: dashboard.safetyMetrics),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('轨迹点位', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        if (dashboard.trackPoints.isEmpty)
                          const Text('暂无轨迹点数据')
                        else
                          ...dashboard.trackPoints.take(6).map(
                                (point) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text('经纬度：${point.lng ?? '--'}, ${point.lat ?? '--'}'),
                                  subtitle: Text('时间：${Formatters.dateTime(point.pointTime)}'),
                                  trailing: Text('速度 ${point.speed ?? '--'}'),
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
                        Text('过程追踪', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        if (data.traces.isEmpty)
                          const Text('当前工单暂无过程追踪')
                        else
                          ...data.traces.map(
                                (trace) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(trace.title),
                                  subtitle: Text('${Formatters.dateTime(trace.traceTime)}\n${trace.content}'),
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

  String _tileUrl(String mapType, bool annotation) {
    final path = switch ((mapType, annotation)) {
      ('satellite', false) => 'img_w',
      ('satellite', true) => 'cia_w',
      ('normal', false) => 'vec_w',
      ('normal', true) => 'cva_w',
      _ => 'vec_w',
    };
    return '${AppConfig.baseUrl}/infra/map/tdt/tile?layerPath=$path&tileMatrixSet=w&z={z}&x={x}&y={y}';
  }
}

class _MetricSection extends StatelessWidget {
  const _MetricSection({required this.title, required this.metrics});
  final String title;
  final List<InspectionMetric> metrics;
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (metrics.isEmpty)
            const Text('暂无指标数据')
          else
            ...metrics.take(6).map(
              (metric) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(metric.metricName),
                subtitle: Text('最近时间：${Formatters.dateTime(metric.currentTime)}'),
                trailing: Text('${metric.currentValue ?? '--'}${metric.metricUnit ?? ''}'),
              ),
            ),
        ]),
      ),
    );
  }
}

class _CollectionDashboardData {
  const _CollectionDashboardData({required this.dashboard, required this.traces});
  final InspectionCollectionDashboard dashboard;
  final List<InspectionProcessTrace> traces;
}
