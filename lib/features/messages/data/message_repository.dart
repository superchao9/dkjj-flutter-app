import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import 'models/notify_message.dart';

class MessageRepository {
  MessageRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<PageResult<NotifyMessage>> getMyMessages({
    int pageNo = 1,
    int pageSize = 20,
  }) {
    return _apiClient.get<PageResult<NotifyMessage>>(
      '/system/notify-message/my-page',
      queryParameters: {'pageNo': pageNo, 'pageSize': pageSize},
      parser: (raw) => PageResult<NotifyMessage>.fromJson(
        raw as Map<String, dynamic>,
        NotifyMessage.fromJson,
      ),
    );
  }

  Future<int> getUnreadCount() {
    return _apiClient.get<int>(
      '/system/notify-message/get-unread-count',
      parser: (raw) => (raw as num?)?.toInt() ?? 0,
    );
  }

  Future<void> markRead(int id) {
    return _apiClient.put<void>(
      '/system/notify-message/update-read',
      queryParameters: {'ids': [id]},
      parser: (_) {},
    );
  }

  Future<void> markAllRead() {
    return _apiClient.put<void>(
      '/system/notify-message/update-all-read',
      parser: (_) {},
    );
  }
}
