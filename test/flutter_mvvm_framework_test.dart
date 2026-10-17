import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_mvvm_framework/flutter_mvvm_framework.dart';

// Sample Model
class UserModel extends MvvmModel {
  final int id;
  final String name;
  final String email;

  const UserModel({required this.id, required this.name, required this.email});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }

  @override
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'email': email};
}

// Sample ViewModel
class UserViewModel extends MvvmViewModel {
  final BaseRepository<UserModel> repository;

  late final Property<RequestState<List<UserModel>>> usersState;
  late final AsyncCommand<void, List<UserModel>> fetchUsersCommand;

  UserViewModel({required this.repository}) {
    usersState = registerDisposable(Property<RequestState<List<UserModel>>>(const RequestState.idle()));

    fetchUsersCommand = registerDisposable(AsyncCommand<void, List<UserModel>>(
      action: (_) async {
        final list = await repository.getAll();
        usersState.value = RequestState.success(list);
        return list;
      },
    ));
  }

  @override
  void onInit() {
    super.onInit();
    fetchUsersCommand.execute();
  }
}

void main() {
  setUp(() {
    MVVM.reset();
  });

  group('RequestState', () {
    test('State properties and getters', () {
      const idle = RequestState<String>.idle();
      expect(idle.isIdle, isTrue);
      expect(idle.isLoading, isFalse);
      expect(idle.isSuccess, isFalse);
      expect(idle.isError, isFalse);

      const loading = RequestState<String>.loading(previousData: 'old');
      expect(loading.isLoading, isTrue);
      expect(loading.dataOrNull, equals('old'));

      const success = RequestState<String>.success('new');
      expect(success.isSuccess, isTrue);
      expect(success.dataOrNull, equals('new'));

      const error = RequestState<String>.error('error_msg');
      expect(error.isError, isTrue);
      expect(error.errorOrNull, equals('error_msg'));
    });

    test('Pattern matching with when and maybeWhen', () {
      const state = RequestState<int>.success(42);

      final result = state.when(
        idle: () => 'idle',
        loading: (_) => 'loading',
        success: (data) => 'success: $data',
        error: (e, _, _) => 'error: $e',
      );
      expect(result, equals('success: 42'));

      final maybeResult = state.maybeWhen(
        success: (data) => 'got $data',
        orElse: () => 'fallback',
      );
      expect(maybeResult, equals('got 42'));
    });
  });

  group('Property & BindableList', () {
    test('Property notifies listeners on value change', () {
      final prop = Property<int>(10);
      int callCount = 0;
      prop.addListener(() => callCount++);

      prop.value = 20;
      expect(callCount, equals(1));
      expect(prop.value, equals(20));

      // Same value does not notify
      prop.value = 20;
      expect(callCount, equals(1));

      // Silent update
      prop.setValueSilently(30);
      expect(callCount, equals(1));
      expect(prop.value, equals(30));

      prop.dispose();
      expect(prop.isDisposed, isTrue);
    });

    test('ReadOnlyProperty and map transformation', () {
      final counter = Property<int>(5);
      final derived = counter.map((val) => 'Count: $val');

      expect(derived.value, equals('Count: 5'));
      counter.value = 10;
      expect(derived.value, equals('Count: 10'));

      derived.dispose();
      counter.dispose();
    });

    test('BindableList triggers notifications on modifications', () {
      final list = BindableList<String>(['a', 'b']);
      int notifyCount = 0;
      list.addListener(() => notifyCount++);

      list.add('c');
      expect(notifyCount, equals(1));
      expect(list.length, equals(3));

      list.remove('a');
      expect(notifyCount, equals(2));
      expect(list.length, equals(2));

      list.dispose();
    });
  });

  group('MvvmCommand', () {
    test('Sync command execution', () async {
      int count = 0;
      final cmd = MvvmCommand.sync(
        action: (int? param) => count += (param ?? 1),
      );

      expect(cmd.canExecute, isTrue);
      await cmd.execute(5);
      expect(count, equals(5));
      expect(cmd.lastResult, equals(5));

      cmd.dispose();
    });

    test('AsyncCommand execution state and concurrency guard', () async {
      final cmd = AsyncCommand<int, String>(
        action: (param) async {
          await Future.delayed(const Duration(milliseconds: 20));
          return 'Result: $param';
        },
      );

      expect(cmd.isExecuting, isFalse);
      expect(cmd.canExecute, isTrue);

      final future = cmd.execute(100);
      expect(cmd.isExecuting, isTrue);
      expect(cmd.canExecute, isFalse);

      final result = await future;
      expect(result, equals('Result: 100'));
      expect(cmd.isExecuting, isFalse);
      expect(cmd.lastResult, equals('Result: 100'));

      cmd.dispose();
    });
  });

  group('MvvmViewModel', () {
    test('Lifecycle and automatic disposal', () {
      final mock = MockClient((_) async => http.Response('[]', 200));
      final client = ApiClient(config: ApiConfig(baseUrl: 'https://example.com'), httpClient: mock);
      final repo = MvvmRepository<UserModel>(
        apiClient: client,
        endpoint: '/users',
        fromJson: UserModel.fromJson,
      );

      final vm = UserViewModel(repository: repo);
      expect(vm.isInitialized, isFalse);

      vm.onInit();
      expect(vm.isInitialized, isTrue);
      expect(vm.usersState.isDisposed, isFalse);

      vm.dispose();
      expect(vm.isDisposed, isTrue);
      expect(vm.usersState.isDisposed, isTrue);
    });

    test('execute() manages loading, success, and error states', () async {
      final vm = UserViewModel(
        repository: MvvmRepository<UserModel>(
          apiClient: ApiClient(config: ApiConfig(baseUrl: 'https://example.com')),
          endpoint: '/users',
          fromJson: UserModel.fromJson,
        ),
      );

      final prop = Property<RequestState<String>>(const RequestState.idle());
      await vm.execute<String>(
        action: () async => 'Loaded Data',
        stateProperty: prop,
      );

      expect(prop.value.isSuccess, isTrue);
      expect(prop.value.dataOrNull, equals('Loaded Data'));

      prop.dispose();
      vm.dispose();
    });
  });

  group('ServiceLocator', () {
    test('Registers and resolves instances', () {
      final sl = ServiceLocator();
      sl.registerSingleton<String>('Hello MVVM');
      expect(sl.get<String>(), equals('Hello MVVM'));

      sl.registerLazySingleton<int>(() => 42);
      expect(sl.get<int>(), equals(42));

      sl.reset();
      expect(sl.isRegistered<String>(), isFalse);
    });
  });

  group('Storage & Auth', () {
    test('MemoryStorage reads, writes, and clears data', () async {
      final storage = MemoryStorage();
      await storage.write('token', 'xyz123');
      expect(await storage.read('token'), equals('xyz123'));

      await storage.writeJson('user', {'name': 'Demo User'});
      final json = await storage.readJson('user');
      expect(json?['name'], equals('Demo User'));

      await storage.clear();
      expect(await storage.read('token'), isNull);
    });

    test('AuthManager coordinates login and refresh mutex', () async {
      final storage = MemoryStorage();
      int refreshCalls = 0;

      final authManager = AuthManager(
        storage: storage,
        refreshHandler: (token) async {
          refreshCalls++;
          await Future.delayed(const Duration(milliseconds: 30));
          return 'new_access_token';
        },
      );

      await authManager.login(
        accessToken: 'initial_token',
        refreshToken: 'valid_refresh',
      );
      expect(authManager.isAuthenticated, isTrue);

      // Concurrent refresh calls should be merged into a single execution
      final results = await Future.wait([
        authManager.refreshToken(),
        authManager.refreshToken(),
        authManager.refreshToken(),
      ]);

      expect(refreshCalls, equals(1));
      expect(results.every((token) => token == 'new_access_token'), isTrue);
      expect(authManager.tokenManager.accessToken, equals('new_access_token'));
    });
  });

  group('Widgets (PropertyBuilder, CommandButton, ErrorView)', () {
    testWidgets('PropertyBuilder rebuilds reactively on property change', (tester) async {
      final count = Property<int>(0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PropertyBuilder<int>(
              property: count,
              builder: (context, value, child) => Text('Count: $value'),
            ),
          ),
        ),
      );

      expect(find.text('Count: 0'), findsOneWidget);

      count.value = 15;
      await tester.pump();
      expect(find.text('Count: 15'), findsOneWidget);

      count.dispose();
    });

    testWidgets('CommandButton executes command and updates UI', (tester) async {
      int executedCount = 0;
      final cmd = AsyncCommand<void, void>(
        action: (_) async {
          executedCount++;
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommandButton<void, void>(
              command: cmd,
              child: const Text('Submit'),
            ),
          ),
        ),
      );

      expect(find.text('Submit'), findsOneWidget);
      await tester.tap(find.text('Submit'));
      await tester.pump();

      expect(executedCount, equals(1));
      cmd.dispose();
    });

    testWidgets('ErrorView renders title and handles retry callback', (tester) async {
      bool retried = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorView(
              message: 'Failed to connect',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      expect(find.text('Failed to connect'), findsOneWidget);
      await tester.tap(find.byType(ElevatedButton));
      expect(retried, isTrue);
    });
  });
}
