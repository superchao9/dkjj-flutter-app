import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_response.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/state_views.dart';
import '../data/models/project_models.dart';
import '../data/project_repository.dart';

class ProjectAssetsPage extends StatefulWidget {
  const ProjectAssetsPage({super.key});

  @override
  State<ProjectAssetsPage> createState() => _ProjectAssetsPageState();
}

class _ProjectAssetsPageState extends State<ProjectAssetsPage> {
  late Future<PageResult<ProjectAssetLedger>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<PageResult<ProjectAssetLedger>> _load() {
    return context.read<ProjectRepository>().getAssets();
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('资产台账')),
      body: FutureBuilder<PageResult<ProjectAssetLedger>>(
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
          final items = snapshot.data?.list ?? const <ProjectAssetLedger>[];
          if (items.isEmpty) {
            return EmptyStateView(
              title: '暂无资产台账',
              description: '资产台账接口暂未返回记录。',
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
                        Text(
                          item.assetName ?? item.assetCode ?? '未命名资产',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text('资产编码：${item.assetCode ?? '--'}'),
                        Text('资产分类：${item.assetCategory ?? '--'}'),
                        Text('业务类型：${item.businessType ?? '--'}'),
                        Text('生命周期节点：${item.lifecycleNode ?? '--'}'),
                        Text('使用部门：${item.useDept ?? '--'}'),
                        Text('保管人：${item.keeperUser ?? '--'}'),
                        Text('存放位置：${item.storageLocation ?? '--'}'),
                        Text('状态：${item.assetStatus ?? '--'}'),
                        Text('发生时间：${Formatters.dateTime(item.occurDate)}'),
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
