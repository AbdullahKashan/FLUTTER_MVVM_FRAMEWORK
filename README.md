# flutter_mvvm_framework

[![pub package](https://img.shields.io/pub/v/flutter_mvvm_framework.svg)](https://pub.dev/packages/flutter_mvvm_framework)
[![license](https://img.shields.io/badge/license-MIT-green.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.13+-02569B?logo=flutter)](https://flutter.dev)
[![style: effective dart](https://img.shields.io/badge/style-effective_dart-40c4ff.svg)](https://dart.dev/guides/language/effective-dart)

A battle-tested, modular, and batteries-included **Model-View-ViewModel (MVVM)** framework for Flutter applications. Designed for enterprise production apps, it provides reactive data-binding with `Property<T>`, asynchronous `MvvmCommand`, automatic lifecycle binding, an industrial-strength REST API client, concurrency-safe token refresh, repository abstractions, and infinite pagination with zero code-generation.

---

## 💡 Why flutter_mvvm_framework? (Benefits & Rationale)

In typical Flutter state management setups, widgets often handle business logic, trigger API calls, parse raw JSON, and hold mutable session tokens. This creates tightly-coupled, brittle codebases.

`flutter_mvvm_framework` provides a clean separation of concerns:

```
┌────────────────────────────────────────────────────────┐
│                         VIEW                           │
│     (MvvmView, PropertyBuilder / Bind, CommandButton)  │
└──────────────────────────┬─────────────────────────────┘
                           │ Data-Binding & Command Triggers
                           ▼
┌────────────────────────────────────────────────────────┐
│                      VIEWMODEL                         │
│     (MvvmViewModel, Property<T>, AsyncCommand)         │
└──────────────────────────┬─────────────────────────────┘
                           │ Calls Business & Data Operations
                           ▼
┌────────────────────────────────────────────────────────┐
│                      REPOSITORY                        │
│           (BaseRepository / MvvmRepository)            │
└──────────────────────────┬─────────────────────────────┘
                           │ Dispatches REST Calls & Parses JSON
                           ▼
┌────────────────────────────────────────────────────────┐
│                      API CLIENT                        │
│         (Interceptors, AuthManager, Storage)           │
└────────────────────────────────────────────────────────┘
```

### Key Highlights

1. **Reactive Properties (`Property<T>`)**:
   Enables surgical, granular widget rebuilds using `PropertyBuilder` (alias `Bind`). You never have to rebuild entire screens just because a single counter or text input changed.
2. **First-Class Commands (`MvvmCommand` / `AsyncCommand`)**:
   Encapsulates actions, parameters, loading flags, and execution conditions (`canExecute`). Buttons automatically disable themselves when tasks are in flight or prerequisites are unmet.
3. **Concurrency-Safe Token Refreshing**:
   Features a built-in mutex that merges concurrent HTTP 401 Unauthorized errors into a single refresh request, preventing race conditions and duplicate token renewals.
4. **Type-Safe Sealed Request States**:
   Eliminates manual boolean flags (`bool isLoading = false;`). [RequestState<T>] provides exhaustive pattern matching (`when`, `maybeWhen`, `mapData`) across `idle`, `loading`, `success`, and `error`.
5. **Zero Code-Generation**:
   No `build_runner`, no `.g.dart` generated files, and fast compilation times.

---

## 📦 Installation

Add `flutter_mvvm_framework` to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_mvvm_framework: ^1.0.0
```

Install via terminal:

```bash
flutter pub get
```

---

## 🚀 Quick Start Guide

### 1. Initialize the Framework

```dart
import 'package:flutter/material.dart';
import 'package:flutter_mvvm_framework/flutter_mvvm_framework.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await MVVM.initialize(
    baseUrl: 'https://api.example.com/v1',
    logging: true,
  );

  runApp(const MyApp());
}
```

---

### 2. Define the Model

```dart
import 'package:flutter_mvvm_framework/flutter_mvvm_framework.dart';

class User extends MvvmModel {
  final int id;
  final String name;
  final String email;

  const User({required this.id, required this.name, required this.email});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }

  @override
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'email': email};
}
```

---

### 3. Create the Repository

```dart
import 'package:flutter_mvvm_framework/flutter_mvvm_framework.dart';
import 'user.dart';

class UserRepository extends BaseRepository<User> {
  UserRepository()
      : super(
          apiClient: MVVM.apiClient,
          endpoint: '/users',
          fromJson: User.fromJson,
        );
}
```

---

### 4. Create the ViewModel

```dart
import 'package:flutter_mvvm_framework/flutter_mvvm_framework.dart';
import 'user.dart';
import 'user_repository.dart';

class UserViewModel extends MvvmViewModel {
  final UserRepository repository;

  late final Property<RequestState<List<User>>> usersState;
  late final AsyncCommand<void, List<User>> fetchUsersCommand;

  UserViewModel({required this.repository}) {
    usersState = registerDisposable(Property<RequestState<List<User>>>(const RequestState.idle()));

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
  }

  @override
  void onInit() {
    super.onInit();
    fetchUsersCommand.execute();
  }
}
```

---

### 5. Build the View with Data Bindings

```dart
import 'package:flutter/material.dart';
import 'package:flutter_mvvm_framework/flutter_mvvm_framework.dart';
import 'user.dart';
import 'user_repository.dart';
import 'user_view_model.dart';

class UserPage extends MvvmView<UserViewModel> {
  const UserPage({super.key});

  @override
  UserViewModel createViewModel(BuildContext context) {
    return UserViewModel(repository: UserRepository());
  }

  @override
  Widget buildView(BuildContext context, UserViewModel viewModel) {
    return Scaffold(
      appBar: AppBar(title: const Text('Team Members')),
      body: PropertyBuilder<RequestState<List<User>>>(
        property: viewModel.usersState,
        builder: (context, state, child) {
          return state.when(
            idle: () => const Center(child: Text('Idle')),
            loading: (_) => const LoadingView(message: 'Loading team...'),
            error: (err, _, __) => ErrorView(
              message: err.toString(),
              onRetry: () => viewModel.fetchUsersCommand.execute(),
            ),
            success: (users) => ListView.builder(
              itemCount: users.length,
              itemBuilder: (ctx, i) => ListTile(
                title: Text(users[i].name),
                subtitle: Text(users[i].email),
              ),
            ),
          );
        },
      ),
    );
  }
}
```

---

## 🧪 Testing

`flutter_mvvm_framework` is designed for 100% deterministic unit and widget testing without dependencies on real device environments:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:flutter_mvvm_framework/flutter_mvvm_framework.dart';

void main() {
  test('Fetches team members', () async {
    final mock = MockClient((req) async {
      return http.Response('[{"id": 1, "name": "Demo User", "email": "demo@example.com"}]', 200);
    });

    await MVVM.initialize(
      baseUrl: 'https://api.example.com',
      httpClient: mock,
    );

    final repo = UserRepository();
    final users = await repo.getAll();

    expect(users.length, equals(1));
    expect(users.first.name, equals('Demo User'));
  });
}
```

---

## 📄 License

This package is open source and released under the [MIT License](LICENSE).
