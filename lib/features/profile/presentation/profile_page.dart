import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/state_views.dart';
import '../../auth/application/auth_controller.dart';
import '../data/models/user_profile.dart';
import '../data/profile_repository.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<UserProfile> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<UserProfile> _load() {
    return context.read<ProfileRepository>().getProfile();
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: FutureBuilder<UserProfile>(
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
          final profile = snapshot.data;
          if (profile == null) {
            return const EmptyStateView(description: '用户资料接口暂无返回数据。');
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          child: Text(
                            profile.nickname.isNotEmpty
                                ? profile.nickname.characters.first
                                : profile.username.characters.first,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.nickname.isNotEmpty
                                    ? profile.nickname
                                    : profile.username,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 6),
                              Text(profile.deptName ?? '暂无部门信息'),
                              const SizedBox(height: 4),
                              Text(
                                '角色：${profile.roles.isEmpty ? '暂无' : profile.roles.join(' / ')}',
                              ),
                            ],
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
                      children: [
                        _InfoRow(label: '用户名', value: profile.username),
                        _InfoRow(label: '手机号', value: profile.mobile ?? '--'),
                        _InfoRow(label: '邮箱', value: profile.email ?? '--'),
                        _InfoRow(label: '登录 IP', value: profile.loginIp ?? '--'),
                        _InfoRow(
                          label: '最近登录',
                          value: Formatters.dateTime(profile.loginDate),
                        ),
                        _InfoRow(
                          label: '权限数量',
                          value: '${authController.session?.permissions.length ?? 0}',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.tonalIcon(
                  onPressed: () async {
                    await authController.logout();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('退出登录'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
