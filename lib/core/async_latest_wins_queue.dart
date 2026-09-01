import 'dart:async';

class AsyncLatestWinsQueue<T> {
  final Future<void> Function(T value) handler;
  final void Function(T value)? onDropped;

  _QueuedValue<T>? _pending;
  Future<void>? _worker;
  bool _closed = false;

  AsyncLatestWinsQueue({required this.handler, this.onDropped});

  Future<void> submit(T value) {
    if (_closed) {
      onDropped?.call(value);
      return Future.value();
    }
    final completer = Completer<void>();
    final previous = _pending;
    if (previous != null) {
      onDropped?.call(previous.value);
      previous.complete();
    }
    _pending = _QueuedValue(value, completer);
    _worker ??= _drain();
    return completer.future;
  }

  Future<void> close() async {
    _closed = true;
    final pending = _pending;
    _pending = null;
    if (pending != null) {
      onDropped?.call(pending.value);
      pending.complete();
    }
    await _worker;
  }

  void reopen() => _closed = false;

  Future<void> _drain() async {
    try {
      while (_pending != null && !_closed) {
        final current = _pending!;
        _pending = null;
        try {
          await handler(current.value);
        } finally {
          current.complete();
        }
      }
    } finally {
      _worker = null;
      if (_pending != null && !_closed) _worker = _drain();
    }
  }
}

class _QueuedValue<T> {
  final T value;
  final Completer<void> completer;

  _QueuedValue(this.value, this.completer);

  void complete() {
    if (!completer.isCompleted) completer.complete();
  }
}
