import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../shared/widgets/state_views.dart';
import '../../modules/data/module_catalog.dart';
import '../../modules/data/module_models.dart';
import '../../modules/data/module_repository.dart';

class AreaManagementPage extends StatefulWidget {
  const AreaManagementPage({super.key});

  @override
  State<AreaManagementPage> createState() => _AreaManagementPageState();
}

class _AreaManagementPageState extends State<AreaManagementPage> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _module = getModuleDefinitionById('inspection_area');
  String _mapType = 'satellite';
  int? _selectedId;
  late Future<DynamicPageResult> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<DynamicPageResult> _load() {
    return context.read<ModuleRepository>().fetchPage(
          _module,
          query: {
            'pageNo': 1,
            'pageSize': 50,
            if (_nameController.text.trim().isNotEmpty) 'name': _nameController.text.trim(),
            if (_codeController.text.trim().isNotEmpty) 'code': _codeController.text.trim(),
          },
        );
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _openForm([Map<String, dynamic>? row]) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AreaFormSheet(module: _module, initialValue: row),
    );
    if (changed == true) {
      await _refresh();
    }
  }

  Future<void> _delete(Map<String, dynamic> row) async {
    await context.read<ModuleRepository>().delete(_module, row['id']);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('区域已删除')));
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('巡检区域管理')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        icon: const Icon(Icons.add),
        label: const Text('新增区域'),
      ),
      body: FutureBuilder<DynamicPageResult>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          if (snapshot.hasError) {
            return ErrorStateView(message: snapshot.error.toString(), onRetry: _refresh);
          }
          final page = snapshot.data ?? const DynamicPageResult(total: 0, list: []);
          final selected = page.list.cast<Map<String, dynamic>?>().firstWhere(
                (item) => item?['id'] == _selectedId,
                orElse: () => page.list.isEmpty ? null : page.list.first,
              );
          final areas = page.list.map(_AreaViewData.fromJson).toList(growable: false);
          final selectedArea = selected == null ? null : _AreaViewData.fromJson(selected);
          final center = selectedArea?.center ?? (areas.isEmpty ? const LatLng(31.31154, 120.61296) : areas.first.center);

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SearchCard(
                  nameController: _nameController,
                  codeController: _codeController,
                  onSearch: _refresh,
                  onReset: () {
                    _nameController.clear();
                    _codeController.clear();
                    _refresh();
                  },
                ),
                const SizedBox(height: 16),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: SizedBox(
                    height: 320,
                    child: Stack(
                      children: [
                        FlutterMap(
                          options: MapOptions(initialCenter: center, initialZoom: 13),
                          children: [
                            TileLayer(urlTemplate: _tileUrl(_mapType, false)),
                            TileLayer(urlTemplate: _tileUrl(_mapType, true)),
                            PolygonLayer(
                              polygons: [
                                for (final area in areas)
                                  if (area.shape == 1 && area.points.length >= 3)
                                    Polygon(
                                      points: area.points,
                                      color: (area.id == _selectedId ? const Color(0xFFD97706) : const Color(0xFF0F766E)).withValues(alpha: 0.18),
                                      borderStrokeWidth: 3,
                                      borderColor: area.id == _selectedId ? const Color(0xFFD97706) : const Color(0xFF0F766E),
                                    ),
                              ],
                            ),
                            CircleLayer(
                              circles: [
                                for (final area in areas)
                                  if (area.shape == 2 && area.centerPoint != null)
                                    CircleMarker(
                                      point: area.centerPoint!,
                                      radius: ((area.radiusKm ?? 0.2) * 25).clamp(16, 80),
                                      color: (area.id == _selectedId ? const Color(0xFFD97706) : const Color(0xFF2563EB)).withValues(alpha: 0.18),
                                      borderColor: area.id == _selectedId ? const Color(0xFFD97706) : const Color(0xFF2563EB),
                                      borderStrokeWidth: 3,
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
                if (selectedArea != null) _AreaSummary(area: selectedArea),
                const SizedBox(height: 16),
                Text('共 ${page.total} 个区域', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 12),
                if (page.list.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: EmptyStateView(description: '当前没有符合条件的巡检区域。'),
                    ),
                  )
                else
                  ...page.list.map(
                    (row) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _AreaCard(
                        data: _AreaViewData.fromJson(row),
                        selected: row['id'] == _selectedId,
                        onTap: () => setState(() => _selectedId = row['id'] as int?),
                        onEdit: () => _openForm(row),
                        onDelete: () => _delete(row),
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

class _AreaViewData {
  const _AreaViewData({
    required this.id,
    required this.name,
    required this.code,
    required this.shape,
    required this.status,
    required this.points,
    required this.centerPoint,
    required this.radiusKm,
  });

  final int id;
  final String name;
  final String code;
  final int shape;
  final dynamic status;
  final List<LatLng> points;
  final LatLng? centerPoint;
  final double? radiusKm;

  LatLng get center => centerPoint ?? (points.isEmpty ? const LatLng(31.31154, 120.61296) : points.first);

  factory _AreaViewData.fromJson(Map<String, dynamic> json) {
    final raw = json['points']?.toString() ?? '[]';
    final decoded = jsonDecode(raw);
    final points = decoded is List
        ? decoded.whereType<Map<String, dynamic>>().map((item) {
            final lng = (item['pointLng'] as num?)?.toDouble();
            final lat = (item['pointLat'] as num?)?.toDouble();
            if (lng == null || lat == null) return null;
            return LatLng(lat, lng);
          }).whereType<LatLng>().toList(growable: false)
        : const <LatLng>[];
    final lng = (json['lng'] as num?)?.toDouble();
    final lat = (json['lat'] as num?)?.toDouble();
    return _AreaViewData(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '--',
      code: json['code']?.toString() ?? '--',
      shape: (json['shape'] as num?)?.toInt() ?? 1,
      status: json['status'],
      points: points,
      centerPoint: lng == null || lat == null ? null : LatLng(lat, lng),
      radiusKm: (json['radius'] as num?)?.toDouble(),
    );
  }
}

class _SearchCard extends StatelessWidget {
  const _SearchCard({
    required this.nameController,
    required this.codeController,
    required this.onSearch,
    required this.onReset,
  });

  final TextEditingController nameController;
  final TextEditingController codeController;
  final Future<void> Function() onSearch;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: '区域名称', prefixIcon: Icon(Icons.search))),
            const SizedBox(height: 12),
            TextField(controller: codeController, decoration: const InputDecoration(labelText: '区域编码', prefixIcon: Icon(Icons.tag_outlined))),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: FilledButton.tonal(onPressed: onSearch, child: const Text('搜索'))),
                const SizedBox(width: 12),
                Expanded(child: OutlinedButton(onPressed: onReset, child: const Text('重置'))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AreaSummary extends StatelessWidget {
  const _AreaSummary({required this.area});

  final _AreaViewData area;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(child: _MetricItem(label: '区域编码', value: area.code)),
            Expanded(child: _MetricItem(label: '区域形状', value: area.shape == 2 ? '圆形' : '多边形')),
            Expanded(child: _MetricItem(label: '边界点数', value: '${area.points.length}')),
            Expanded(child: _MetricItem(label: '状态', value: '${area.status ?? '--'}')),
          ],
        ),
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: Theme.of(context).textTheme.bodySmall), const SizedBox(height: 6), Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))]);
  }
}

class _AreaCard extends StatelessWidget {
  const _AreaCard({required this.data, required this.selected, required this.onTap, required this.onEdit, required this.onDelete});

  final _AreaViewData data;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE0F2FE) : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(data.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('编码：${data.code}'),
            Text('形状：${data.shape == 2 ? '圆形区域' : '多边形区域'}'),
            Text('边界点：${data.points.length}'),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              FilledButton.tonal(onPressed: onTap, child: const Text('地图定位')),
              OutlinedButton(onPressed: onEdit, child: const Text('编辑')),
              OutlinedButton(onPressed: onDelete, child: const Text('删除')),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _AreaFormSheet extends StatefulWidget {
  const _AreaFormSheet({required this.module, this.initialValue});

  final ModuleDefinition module;
  final Map<String, dynamic>? initialValue;

  @override
  State<_AreaFormSheet> createState() => _AreaFormSheetState();
}

class _AreaFormSheetState extends State<_AreaFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _controllers;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final field in widget.module.editableFields)
        field.key: TextEditingController(text: widget.initialValue?[field.key]?.toString() ?? ''),
    };
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final payload = <String, dynamic>{
        if (widget.initialValue?['id'] != null) 'id': widget.initialValue!['id'],
      };
      for (final field in widget.module.editableFields) {
        final text = _controllers[field.key]!.text.trim();
        if (text.isEmpty) continue;
        payload[field.key] = field.type == ModuleValueType.number ? num.tryParse(text) : text;
      }
      final repository = context.read<ModuleRepository>();
      if (widget.initialValue == null) {
        await repository.create(widget.module, payload);
      } else {
        await repository.update(widget.module, payload);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.initialValue == null ? '新增区域' : '编辑区域', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                for (final field in widget.module.editableFields) ...[
                  TextFormField(
                    controller: _controllers[field.key],
                    keyboardType: field.type == ModuleValueType.number ? TextInputType.number : TextInputType.text,
                    maxLines: field.type == ModuleValueType.multiline ? 5 : 1,
                    decoration: InputDecoration(labelText: field.label),
                    validator: (value) => field.required && (value == null || value.trim().isEmpty) ? '请输入${field.label}' : null,
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(width: double.infinity, child: FilledButton(onPressed: _submitting ? null : _submit, child: Text(_submitting ? '保存中...' : '保存'))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
