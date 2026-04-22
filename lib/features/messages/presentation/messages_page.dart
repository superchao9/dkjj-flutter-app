import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_response.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/state_views.dart';
import '../data/message_repository.dart';
import '../data/models/notify_message.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  late Future<PageResult<NotifyMessage>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<PageResult<NotifyMessage>> _load() {
    return context.read<MessageRepository>().getMyMessages();
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _markAllRead() async {
    await context.read<MessageRepository>().markAllRead();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已全部标记为已读')),
    );
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的消息'),
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child: const Text('全部已读'),
          ),
        ],
      ),
      body: FutureBuilder<PageResult<NotifyMessage>>(
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
          final messages = snapshot.data?.list ?? const <NotifyMessage>[];
          if (messages.isEmpty) {
            return EmptyStateView(
              title: '暂无消息',
              description: '站内信接口暂未返回消息。',
              onRetry: _refresh,
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = messages[index];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: item.readStatus
                          ? Colors.grey.shade200
                          : Theme.of(context).colorScheme.primaryContainer,
                      child: Icon(
                        item.readStatus
                            ? Icons.mark_email_read_outlined
                            : Icons.mark_email_unread_outlined,
                      ),
                    ),
                    title: Text(
                      item.templateNickname,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${item.templateContent}\n${Formatters.dateTime(item.createTime)}',
                      ),
                    ),
                    onTap: () => showDialog<void>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text(item.templateNickname),
                        content: Text(item.templateContent),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('关闭'),
                          ),
                        ],
                      ),
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
