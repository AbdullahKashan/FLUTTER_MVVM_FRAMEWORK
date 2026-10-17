import 'package:flutter_mvvm_framework/flutter_mvvm_framework.dart';
import '../models/user.dart';
import '../repositories/user_repository.dart';

/// Presentation ViewModel for the user list and creation screen.
class UserViewModel extends MvvmViewModel {
  final UserRepository repository;

  /// Observable request state holding the team member list.
  late final Property<RequestState<List<User>>> usersState;

  /// Observable search / filter query.
  late final Property<String> searchQuery;

  /// Command to fetch users from the repository.
  late final AsyncCommand<void, List<User>> fetchUsersCommand;

  /// Command to create a new user.
  late final AsyncCommand<Map<String, dynamic>, User> createUserCommand;

  UserViewModel({required this.repository}) {
    usersState = registerDisposable(Property<RequestState<List<User>>>(const RequestState.idle()));
    searchQuery = registerDisposable(Property<String>(''));

    fetchUsersCommand = registerDisposable(
      AsyncCommand<void, List<User>>(
        action: (_) async {
          return await execute<List<User>>(
            action: () => repository.getAll(),
            stateProperty: usersState,
          ) ?? [];
        },
      ),
    );

    createUserCommand = registerDisposable(
      AsyncCommand<Map<String, dynamic>, User>(
        action: (body) async {
          final newUser = await repository.create(body ?? {});
          final current = usersState.value.dataOrNull ?? [];
          usersState.value = RequestState.success([newUser, ...current]);
          return newUser;
        },
      ),
    );
  }

  @override
  void onInit() {
    super.onInit();
    fetchUsersCommand.execute();
  }

  /// Filtered list of users matching the search query.
  List<User> get filteredUsers {
    final list = usersState.value.dataOrNull ?? [];
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return list;
    return list.where((u) => u.name.toLowerCase().contains(q) || u.role.toLowerCase().contains(q)).toList();
  }
}
