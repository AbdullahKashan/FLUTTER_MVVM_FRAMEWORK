import 'package:flutter/material.dart';
import '../core/command.dart';

/// Builder widget that reacts to state changes in an [MvvmCommand].
class CommandBuilder<TParam, TResult> extends StatefulWidget {
  final MvvmCommand<TParam, TResult> command;
  final Widget Function(
    BuildContext context,
    bool isExecuting,
    bool canExecute,
    Future<TResult?> Function([TParam?]) execute,
  ) builder;

  const CommandBuilder({
    super.key,
    required this.command,
    required this.builder,
  });

  @override
  State<CommandBuilder<TParam, TResult>> createState() => _CommandBuilderState<TParam, TResult>();
}

class _CommandBuilderState<TParam, TResult> extends State<CommandBuilder<TParam, TResult>> {
  @override
  void initState() {
    super.initState();
    widget.command.addListener(_onCommandChanged);
  }

  @override
  void didUpdateWidget(CommandBuilder<TParam, TResult> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.command != oldWidget.command) {
      oldWidget.command.removeListener(_onCommandChanged);
      widget.command.addListener(_onCommandChanged);
    }
  }

  @override
  void dispose() {
    widget.command.removeListener(_onCommandChanged);
    super.dispose();
  }

  void _onCommandChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      context,
      widget.command.isExecuting,
      widget.command.canExecute,
      widget.command.execute,
    );
  }
}

/// A ready-to-use Material button that automatically binds to an [MvvmCommand].
///
/// It auto-disables when [command.canExecute] is false and displays a loading
/// indicator when [command.isExecuting] is true.
class CommandButton<TParam, TResult> extends StatelessWidget {
  final MvvmCommand<TParam, TResult> command;
  final TParam? parameter;
  final Widget child;
  final Widget? loadingWidget;
  final ButtonStyle? style;

  const CommandButton({
    super.key,
    required this.command,
    required this.child,
    this.parameter,
    this.loadingWidget,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return CommandBuilder<TParam, TResult>(
      command: command,
      builder: (context, isExecuting, canExecute, execute) {
        final VoidCallback? onPressed = canExecute
            ? () {
                execute(parameter);
              }
            : null;

        return ElevatedButton(
          style: style,
          onPressed: onPressed,
          child: isExecuting
              ? (loadingWidget ??
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  ))
              : child,
        );
      },
    );
  }
}
