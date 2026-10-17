import 'package:flutter/material.dart';
import 'package:flutter_mvvm_framework/flutter_mvvm_framework.dart';
import '../models/user.dart';
import '../repositories/user_repository.dart';
import '../view_models/user_view_model.dart';

/// Presentation View displaying users, reactive search, and user creation dialog.
class UserPage extends MvvmView<UserViewModel> {
  const UserPage({super.key});

  @override
  UserViewModel createViewModel(BuildContext context) {
    return UserViewModel(repository: UserRepository());
  }

  @override
  Widget buildView(BuildContext context, UserViewModel viewModel) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MVVM Team Directory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => viewModel.fetchUsersCommand.execute(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddUserDialog(context, viewModel),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Member'),
      ),
      body: Column(
        children: [
          _buildSearchBar(viewModel),
          Expanded(
            child: PropertyBuilder<RequestState<List<User>>>(
              property: viewModel.usersState,
              builder: (context, state, _) {
                return state.when(
                  idle: () => const Center(child: Text('Ready')),
                  loading: (_) => const LoadingView(message: 'Fetching team members...'),
                  error: (err, _, _) => ErrorView(
                    message: err.toString(),
                    onRetry: () => viewModel.fetchUsersCommand.execute(),
                  ),
                  success: (_) {
                    final users = viewModel.filteredUsers;
                    if (users.isEmpty) {
                      return const Center(
                        child: Text(
                          'No matching members found.',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () => viewModel.fetchUsersCommand.execute(),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: users.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final user = users[index];
                          return _buildUserCard(user, theme);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(UserViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search by name or role...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (val) {
          viewModel.searchQuery.value = val;
          viewModel.usersState.forceNotify();
        },
      ),
    );
  }

  Widget _buildUserCard(User user, ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        title: Text(
          user.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(user.email),
        trailing: Chip(
          label: Text(
            user.role,
            style: const TextStyle(fontSize: 12),
          ),
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
        ),
      ),
    );
  }

  void _showAddUserDialog(BuildContext context, UserViewModel viewModel) {
    final nameController = TextEditingController();
    final roleController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Team Member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: roleController,
              decoration: const InputDecoration(labelText: 'Role (e.g. Engineer)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          CommandButton<Map<String, dynamic>, User>(
            command: viewModel.createUserCommand,
            parameter: {
              'name': nameController.text.trim(),
              'email': '${nameController.text.trim().toLowerCase().replaceAll(' ', '.')}@example.com',
              'role': roleController.text.trim(),
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
