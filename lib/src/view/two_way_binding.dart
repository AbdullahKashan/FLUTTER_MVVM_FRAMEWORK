import 'package:flutter/widgets.dart';
import '../core/bindable_property.dart';

/// Extension methods for binding Flutter controllers two-way with [Property].
extension TextEditingControllerBinding on TextEditingController {
  /// Binds this [TextEditingController] two-way to a [Property<String>].
  ///
  /// Returns a [VoidCallback] to cancel the two-way synchronization.
  VoidCallback bindTo(Property<String> property) {
    bool updating = false;

    void textListener() {
      if (updating) return;
      if (property.value != text) {
        updating = true;
        property.value = text;
        updating = false;
      }
    }

    void propListener() {
      if (updating) return;
      if (text != property.value) {
        updating = true;
        text = property.value;
        updating = false;
      }
    }

    // Initialize with property value if non-empty
    if (property.value.isNotEmpty && text.isEmpty) {
      text = property.value;
    }

    addListener(textListener);
    property.addListener(propListener);

    return () {
      removeListener(textListener);
      property.removeListener(propListener);
    };
  }
}
