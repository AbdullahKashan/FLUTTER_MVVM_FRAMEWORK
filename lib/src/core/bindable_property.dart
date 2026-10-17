import 'package:flutter/foundation.dart';

/// Contract for objects that need cleanup when their parent ViewModel is disposed.
abstract interface class Disposable {
  void dispose();
}

/// A reactive, observable property used in MVVM ViewModels to hold and notify state changes.
///
/// Implements [ValueListenable] so Flutter widgets (like [ValueListenableBuilder] or
/// [PropertyBuilder]) can reactively bind to updates without rebuilding the whole page.
class Property<T> extends ChangeNotifier implements ValueListenable<T>, Disposable {
  T _value;
  bool _isDisposed = false;

  /// Creates a reactive property with an initial [value].
  Property(T value) : _value = value;

  @override
  T get value => _value;

  /// Updates the value and notifies listeners if the value has changed.
  set value(T newValue) {
    if (_isDisposed) return;
    if (_value == newValue) return;
    _value = newValue;
    notifyListeners();
  }

  /// Silently updates the value without triggering notifications.
  void setValueSilently(T newValue) {
    _value = newValue;
  }

  /// Forces notification of listeners even if the value hasn't changed.
  void forceNotify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  /// Whether this property has been disposed.
  bool get isDisposed => _isDisposed;

  /// Creates a read-only projection of this property.
  ReadOnlyProperty<T> asReadOnly() => ReadOnlyProperty<T>(this);

  /// Projects this property into a new derived read-only property using [transform].
  ReadOnlyProperty<R> map<R>(R Function(T value) transform) {
    final derived = Property<R>(transform(_value));
    void listener() {
      derived.value = transform(_value);
    }

    addListener(listener);
    return ReadOnlyProperty<R>(derived, onDispose: () {
      removeListener(listener);
      derived.dispose();
    });
  }

  @override
  void dispose() {
    if (!_isDisposed) {
      _isDisposed = true;
      super.dispose();
    }
  }

  @override
  String toString() => 'Property($value)';
}

/// A read-only wrapper around a [Property] to safely expose state from a ViewModel
/// without allowing external components to mutate it directly.
class ReadOnlyProperty<T> implements ValueListenable<T>, Disposable {
  final Property<T> _property;
  final VoidCallback? onDispose;

  ReadOnlyProperty(this._property, {this.onDispose});

  @override
  T get value => _property.value;

  @override
  void addListener(VoidCallback listener) {
    _property.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _property.removeListener(listener);
  }

  @override
  void dispose() {
    onDispose?.call();
  }

  @override
  String toString() => 'ReadOnlyProperty($value)';
}

/// A reactive list that notifies listeners when items are added, removed, or updated.
class BindableList<T> extends ChangeNotifier implements Disposable {
  final List<T> _items;
  bool _isDisposed = false;

  BindableList([List<T>? initialItems]) : _items = initialItems != null ? List<T>.from(initialItems) : [];

  List<T> get items => List.unmodifiable(_items);

  int get length => _items.length;

  bool get isEmpty => _items.isEmpty;

  bool get isNotEmpty => _items.isNotEmpty;

  T operator [](int index) => _items[index];

  void operator []=(int index, T value) {
    _items[index] = value;
    notifyListeners();
  }

  void add(T item) {
    _items.add(item);
    notifyListeners();
  }

  void addAll(Iterable<T> items) {
    _items.addAll(items);
    notifyListeners();
  }

  bool remove(T item) {
    final removed = _items.remove(item);
    if (removed) notifyListeners();
    return removed;
  }

  T removeAt(int index) {
    final item = _items.removeAt(index);
    notifyListeners();
    return item;
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  void assignAll(Iterable<T> items) {
    _items.clear();
    _items.addAll(items);
    notifyListeners();
  }

  @override
  void dispose() {
    if (!_isDisposed) {
      _isDisposed = true;
      super.dispose();
    }
  }
}
