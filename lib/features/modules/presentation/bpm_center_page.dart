import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/state_views.dart';
import '../data/module_models.dart';
import '../data/module_repository.dart';
import 'process_instance_detail_page.dart';

class BpmCenterPage extends StatefulWidget {
  const BpmCenterPage({super.key});

  @override
  State<BpmCenterPage> createState() => _BpmCenterPageState();
}

class _BpmCenterPageState extends State<BpmCenterPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late Future<DynamicPageResult> _mineFuture;
  late Future<DynamicPageResult> _managerFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _mineFuture = _load(false);
    _managerFuture = _load(true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<DynamicPageResult> _load(bool manager) {
    return context.read<ModuleRepository>().fetchProcessCenterPage(
          manager: manager,
          query: const {'pageNo': 1, 'pageSize': 20},
        );
  }

  Future<void> _refresh(bool manager) async {
    setState(() {
      if (manager) {
        _managerFuture = _load(true);
      } else {
        _mineFuture = _load(false);
      }
    });
    await (manager ? _managerFuture : _mineFuture);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('流程中心'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '我发起的'),
            Tab(text: '我管理的'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ProcessTab(future: _mineFuture, onRefresh: () => _refresh(false)),
          _ProcessTab(future: _managerFuture, onRefresh: () => _refresh(true)),
        ],
      ),
    );
  }
}

class _ProcessTab extends StatelessWidget {
  const _ProcessTab({required this.future, required this.onRefresh});

  final Future<DynamicPageResult> future;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DynamicPageResult>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingView();
        }
        if (snapshot.hasError) {
          return ErrorStateView(message: snapshot.error.toString(), onRetry: onRefresh);
        }
        final page = snapshot.data ?? const DynamicPageResult(total: 0, list: []);
        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('共 ${page.total} 条流程', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF64748B))),
              const SizedBox(height: 12),
              if (page.list.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: EmptyStateView(description: '当前暂无流程记录。'),
                  ),
                )
              else
                ...page.list.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text('${item['name'] ?? '未命名流程'}', style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '实例 ID：${item['id'] ?? '--'}\n'
                            '状态：${item['status'] ?? '--'}\n'
                            '创建时间：${Formatters.dateTime(_parseDate(item['createTime']))}',
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ProcessInstanceDetailPage(processInstanceId: '${item['id']}'),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return DateTime.tryParse(value.toString());
}
