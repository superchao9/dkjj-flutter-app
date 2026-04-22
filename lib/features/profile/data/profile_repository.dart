import '../../../core/network/api_client.dart';
import 'models/user_profile.dart';

class ProfileRepository {
  ProfileRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<UserProfile> getProfile() {
    return _apiClient.get<UserProfile>(
      '/system/user/profile/get',
      parser: (raw) => UserProfile.fromJson(raw as Map<String, dynamic>),
    );
  }
}
