import 'package:flutter_mvvm_framework/flutter_mvvm_framework.dart';
import '../models/user.dart';

/// Repository responsible for user network requests.
class UserRepository extends BaseRepository<User> {
  UserRepository({ApiClient? client})
      : super(
          apiClient: client ?? MVVM.apiClient,
          endpoint: '/users',
          fromJson: User.fromJson,
        );

  /// Custom endpoint helper to fetch active team members.
  Future<List<User>> getActiveUsers() => getAll(queryParameters: {'status': 'active'});
}
