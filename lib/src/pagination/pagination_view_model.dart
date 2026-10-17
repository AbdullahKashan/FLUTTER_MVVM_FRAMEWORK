import 'dart:async';
import '../core/bindable_property.dart';
import '../core/command.dart';
import '../core/request_state.dart';
import '../core/view_model.dart';

/// Standard wrapper returned by paginated API endpoints.
class PaginatedResponse<T> {
  final List<T> items;
  final int currentPage;
  final int totalPages;
  final int totalItems;

  const PaginatedResponse({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
  });

  bool get hasMore => currentPage < totalPages;
}

/// A specialized [MvvmViewModel] for managing paginated data collections, infinite scrolling,
/// and pull-to-refresh flows using reactive properties and commands.
abstract class PaginationViewModel<T> extends MvvmViewModel {
  final int initialPage;
  final int pageSize;

  /// Reactive list of loaded items.
  final BindableList<T> items = BindableList<T>();

  /// Overall loading/success/error state.
  late final Property<RequestState<List<T>>> state;

  /// Current active page index.
  late final Property<int> currentPage;

  /// Whether additional pages can be fetched.
  late final Property<bool> hasMore;

  /// Whether an additional page is currently being fetched in the background.
  late final Property<bool> isLoadingMore;

  /// Command to refresh the dataset from page 1.
  late final AsyncCommand<void, void> refreshCommand;

  /// Command to load the next page of items.
  late final AsyncCommand<void, void> loadMoreCommand;

  PaginationViewModel({
    this.initialPage = 1,
    this.pageSize = 20,
  }) {
    state = registerDisposable(Property<RequestState<List<T>>>(const RequestState.idle()));
    currentPage = registerDisposable(Property<int>(initialPage));
    hasMore = registerDisposable(Property<bool>(true));
    isLoadingMore = registerDisposable(Property<bool>(false));
    registerDisposable(items);

    refreshCommand = registerDisposable(AsyncCommand<void, void>(
      action: (_) => refresh(),
    ));

    loadMoreCommand = registerDisposable(AsyncCommand<void, void>(
      action: (_) => loadMore(),
      canExecute: (_) => hasMore.value && !isLoadingMore.value && !state.value.isLoading,
    ));
  }

  @override
  void onInit() {
    super.onInit();
    unawaited(loadInitial());
  }

  /// Abstract method to fetch a paginated response for the given [page].
  Future<PaginatedResponse<T>> fetchPage(int page, int pageSize);

  /// Loads the initial page of data.
  Future<void> loadInitial() async {
    currentPage.value = initialPage;
    hasMore.value = true;
    items.clear();

    await execute<List<T>>(
      action: () async {
        final response = await fetchPage(currentPage.value, pageSize);
        items.assignAll(response.items);
        hasMore.value = response.hasMore;
        return items.items;
      },
      stateProperty: state,
    );
  }

  /// Refreshes the list by resetting pagination and fetching the first page.
  Future<void> refresh() async {
    currentPage.value = initialPage;
    hasMore.value = true;

    try {
      final response = await fetchPage(currentPage.value, pageSize);
      items.assignAll(response.items);
      hasMore.value = response.hasMore;
      state.value = RequestState<List<T>>.success(items.items);
    } catch (e, stack) {
      state.value = RequestState<List<T>>.error(e, stackTrace: stack, previousData: items.items);
    }
  }

  /// Fetches the subsequent page of items and appends them to [items].
  Future<void> loadMore() async {
    if (!hasMore.value || isLoadingMore.value) return;

    isLoadingMore.value = true;
    final nextPage = currentPage.value + 1;

    try {
      final response = await fetchPage(nextPage, pageSize);
      currentPage.value = nextPage;
      items.addAll(response.items);
      hasMore.value = response.hasMore;
      state.value = RequestState<List<T>>.success(items.items);
    } catch (_) {
      // Background load failures keep current items intact
    } finally {
      isLoadingMore.value = false;
      loadMoreCommand.notifyCanExecuteChanged();
    }
  }
}
