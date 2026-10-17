import 'package:flutter/widgets.dart';
import '../core/mvvm_exception.dart';
import '../core/view_model.dart';

/// Provides a [MvvmViewModel] to its widget subtree and manages its lifecycle.
class ViewModelProvider<VM extends MvvmViewModel> extends StatefulWidget {
  final VM Function(BuildContext context)? create;
  final VM? value;
  final Widget Function(BuildContext context, VM viewModel)? builder;
  final Widget? child;
  final bool autoDispose;

  const ViewModelProvider({
    super.key,
    required VM Function(BuildContext context) this.create,
    this.builder,
    this.child,
    this.autoDispose = true,
  })  : value = null,
        assert(builder != null || child != null, 'Either builder or child must be provided.');

  const ViewModelProvider.value({
    super.key,
    required VM this.value,
    this.builder,
    this.child,
    this.autoDispose = false,
  })  : create = null,
        assert(builder != null || child != null, 'Either builder or child must be provided.');

  /// Retrieves the [MvvmViewModel] of type [VM] from the closest ancestor [ViewModelProvider].
  static VM of<VM extends MvvmViewModel>(BuildContext context, {bool listen = false}) {
    final _InheritedViewModel<VM>? inherited = listen
        ? context.dependOnInheritedWidgetOfExactType<_InheritedViewModel<VM>>()
        : context.getInheritedWidgetOfExactType<_InheritedViewModel<VM>>();

    if (inherited == null) {
      throw DependencyNotFoundException(VM);
    }
    return inherited.viewModel;
  }

  @override
  State<ViewModelProvider<VM>> createState() => _ViewModelProviderState<VM>();
}

class _ViewModelProviderState<VM extends MvvmViewModel> extends State<ViewModelProvider<VM>> {
  late VM _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = widget.value ?? widget.create!(context);
    if (!_viewModel.isInitialized) {
      _viewModel.onInit();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_viewModel.isDisposed) {
        _viewModel.onReady();
      }
    });
  }

  @override
  void dispose() {
    if (widget.autoDispose && widget.value == null) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedViewModel<VM>(
      viewModel: _viewModel,
      child: widget.builder != null
          ? widget.builder!(context, _viewModel)
          : widget.child!,
    );
  }
}

class _InheritedViewModel<VM extends MvvmViewModel> extends InheritedWidget {
  final VM viewModel;

  const _InheritedViewModel({
    required this.viewModel,
    required super.child,
  });

  @override
  bool updateShouldNotify(_InheritedViewModel<VM> oldWidget) {
    return viewModel != oldWidget.viewModel;
  }
}

/// Convenience extension on [BuildContext] to access ViewModels easily.
extension ViewModelContextExtension on BuildContext {
  /// Retrieves the nearest [MvvmViewModel] of type [VM].
  VM viewModel<VM extends MvvmViewModel>({bool listen = false}) {
    return ViewModelProvider.of<VM>(this, listen: listen);
  }
}
