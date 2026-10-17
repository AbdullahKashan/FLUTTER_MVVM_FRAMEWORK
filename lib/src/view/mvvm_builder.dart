import 'package:flutter/widgets.dart';
import '../core/view_model.dart';
import 'view_model_provider.dart';

/// Builder widget that subscribes to an ancestor [MvvmViewModel] and rebuilds whenever
/// the ViewModel calls [notifyListeners].
class MvvmBuilder<VM extends MvvmViewModel> extends StatelessWidget {
  final Widget Function(BuildContext context, VM viewModel) builder;

  const MvvmBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final viewModel = ViewModelProvider.of<VM>(context, listen: true);
    return builder(context, viewModel);
  }
}

/// Selector widget that filters rebuilds from a [MvvmViewModel] so the child only rebuilds
/// when the specific selected value changes.
class MvvmSelector<VM extends MvvmViewModel, S> extends StatefulWidget {
  final S Function(VM viewModel) selector;
  final Widget Function(BuildContext context, S selected, Widget? child) builder;
  final Widget? child;

  const MvvmSelector({
    super.key,
    required this.selector,
    required this.builder,
    this.child,
  });

  @override
  State<MvvmSelector<VM, S>> createState() => _MvvmSelectorState<VM, S>();
}

class _MvvmSelectorState<VM extends MvvmViewModel, S> extends State<MvvmSelector<VM, S>> {
  late VM _viewModel;
  late S _currentValue;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _viewModel = ViewModelProvider.of<VM>(context, listen: false);
    _viewModel.removeListener(_onViewModelUpdated);
    _viewModel.addListener(_onViewModelUpdated);
    _currentValue = widget.selector(_viewModel);
  }

  void _onViewModelUpdated() {
    final newValue = widget.selector(_viewModel);
    if (newValue != _currentValue) {
      if (mounted) {
        setState(() {
          _currentValue = newValue;
        });
      }
    }
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelUpdated);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _currentValue, widget.child);
  }
}
