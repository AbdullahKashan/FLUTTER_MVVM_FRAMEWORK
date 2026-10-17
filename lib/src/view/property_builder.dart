import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../core/bindable_property.dart';

/// A reactive widget that listens to a [Property] and rebuilds only itself when the property changes.
///
/// This delivers surgical UI updates, preventing expensive parent or screen-wide rebuilds.
class PropertyBuilder<T> extends StatelessWidget {
  final ValueListenable<T> property;
  final Widget Function(BuildContext context, T value, Widget? child) builder;
  final Widget? child;

  const PropertyBuilder({
    super.key,
    required this.property,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<T>(
      valueListenable: property,
      builder: builder,
      child: child,
    );
  }
}

/// Shorthand alias for [PropertyBuilder].
typedef Bind<T> = PropertyBuilder<T>;

/// Listens to two properties simultaneously and rebuilds when either emits an update.
class DualPropertyBuilder<A, B> extends StatefulWidget {
  final ValueListenable<A> first;
  final ValueListenable<B> second;
  final Widget Function(BuildContext context, A firstValue, B secondValue, Widget? child) builder;
  final Widget? child;

  const DualPropertyBuilder({
    super.key,
    required this.first,
    required this.second,
    required this.builder,
    this.child,
  });

  @override
  State<DualPropertyBuilder<A, B>> createState() => _DualPropertyBuilderState<A, B>();
}

class _DualPropertyBuilderState<A, B> extends State<DualPropertyBuilder<A, B>> {
  @override
  void initState() {
    super.initState();
    widget.first.addListener(_handleChange);
    widget.second.addListener(_handleChange);
  }

  @override
  void didUpdateWidget(DualPropertyBuilder<A, B> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.first != oldWidget.first) {
      oldWidget.first.removeListener(_handleChange);
      widget.first.addListener(_handleChange);
    }
    if (widget.second != oldWidget.second) {
      oldWidget.second.removeListener(_handleChange);
      widget.second.addListener(_handleChange);
    }
  }

  @override
  void dispose() {
    widget.first.removeListener(_handleChange);
    widget.second.removeListener(_handleChange);
    super.dispose();
  }

  void _handleChange() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, widget.first.value, widget.second.value, widget.child);
  }
}
