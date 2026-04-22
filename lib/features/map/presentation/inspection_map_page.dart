import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/state_views.dart';
import '../../inspection/data/inspection_repository.dart';
import '../../inspection/data/models/inspection_models.dart';

class InspectionMapPage extends StatefulWidget {
  const InspectionMapPage({super.key});

  @override
  State<InspectionMapPage> createState() => _InspectionMapPageState();
}

class _InspectionMapPageState extends State<InspectionMapPage> {
  late Future<InspectionCollectionDashboard> _future;
  String _mapType = 'satellite';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<InspectionCollectionDashboard> _load() {
    return context.read<InspectionRepository>().getCollectionDashboard();
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('巡检地图')),
      body: FutureBuilder<InspectionCollectionDashboard>(
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
            return const EmptyStateView(description: '暂无轨迹地图数据');
          }
          final trackPoints = data.trackPoints
              .where((item) => item.lng != null && item.lat != null)
              .map((item) => LatLng(item.lat!.toDouble(), item.lng!.toDouble()))
              .toList(growable: false);
          final center = trackPoints.isEmpty
              ? const LatLng(39.9042, 116.4074)
              : trackPoints.first;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: SizedBox(
                    height: 360,
                    child: Stack(
                      children: [
                        FlutterMap(
                          options: MapOptions(
                            initialCenter: center,
                            initialZoom: trackPoints.isEmpty ? 5 : 12,
                          ),
                          children: [
                            TileLayer(urlTemplate: _tileUrl(_mapType, false)),
                            TileLayer(urlTemplate: _tileUrl(_mapType, true)),
                            if (trackPoints.isNotEmpty)
                              PolylineLayer(
                                polylines: [
                                  Polyline(
                                    points: trackPoints,
                                    strokeWidth: 4,
                                    color: const Color(0xFF2563EB),
                                  ),
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
                                          color: i == 0
                                              ? const Color(0xFF16A34A)
                                              : const Color(0xFFDC2626),
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
                            onSelectionChanged: (value) {
                              setState(() => _mapType = value.first);
                            },
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
                          '轨迹点位',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 12),
                        if (data.trackPoints.isEmpty)
                          const Text('采集看板暂无返回轨迹点。')
                        else
                          ...data.trackPoints.take(8).map(
                                (item) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.place_outlined),
                                  title: Text('${item.lng ?? '--'}, ${item.lat ?? '--'}'),
                                  subtitle: Text(
                                    '时间：${Formatters.dateTime(item.pointTime)}',
                                  ),
                                  trailing: Text('速度 ${item.speed ?? '--'}'),
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
