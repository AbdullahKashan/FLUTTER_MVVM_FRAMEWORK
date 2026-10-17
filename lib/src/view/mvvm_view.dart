import 'package:flutter/widgets.dart';
import '../core/view_model.dart';
import 'view_model_provider.dart';

/// Base class for Views in the `flutter_mvvm_framework`.
///
/// Automatically creates and binds a [MvvmViewModel] of type [VM] to this widget,
/// handling all initialization and disposal lifecycles seamlessly.
abstract class MvvmView<VM extends MvvmViewModel> extends StatelessWidget {
  const MvvmView({super.key});

  /// Factory method to instantiate the [MvvmViewModel] for this View.
  VM createViewModel(BuildContext context);

  /// Builds the widget tree given the attached [viewModel].
  Widget buildView(BuildContext context, VM viewModel);

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<VM>(
      create: createViewModel,
      builder: (ctx, vm) => buildView(ctx, vm),
    );
  }
}

/// A stateful variant of [MvvmView] when local ephemeral UI state (animations, tabs, scroll)
/// is required alongside the presentation [MvvmViewModel].
abstract class MvvmStatefulView<VM extends MvvmViewModel> extends StatefulWidget {
  const MvvmStatefulView({super.key});

  /// Factory method to instantiate the [MvvmViewModel].
  VM createViewModel(BuildContext context);

  @override
  MvvmStatefulViewState<VM, MvvmStatefulView<VM>> createState();
}

/// Base State for [MvvmStatefulView].
abstract class MvvmStatefulViewState<VM extends MvvmViewModel, T extends MvvmStatefulView<VM>>
    extends State<T> {
  late VM viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = widget.createViewModel(context);
    if (!viewModel.isInitialized) {
      viewModel.onInit();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !viewModel.isDisposed) {
        viewModel.onReady();
      }
    });
  }

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  /// Builds the View's UI hierarchy with the active [viewModel].
  Widget buildView(BuildContext context, VM viewModel);

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<VM>.value(
      value: viewModel,
      builder: (ctx, vm) => buildView(ctx, vm),
    );
  }
}
