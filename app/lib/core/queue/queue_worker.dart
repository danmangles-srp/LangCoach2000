// The drain engine (NFR-2.1.3). Subscribes to [NetworkService]; on each
// online edge, processes all pending queue items by dispatching to the
// handler registered for the item's type. Pure logic — no platform deps — so
// the enqueue → reconnect → drain contract is unit-testable.

import 'dart:async';

import 'package:rivendell/core/connectivity/network_service.dart';
import 'package:rivendell/core/logging/app_logger.dart';
import 'package:rivendell/core/queue/queue_repository.dart';

/// A per-type handler for a queued item's payload. Throwing marks the item
/// failed (not done); the next reconnect retries it. Handlers MUST be
/// idempotent: a markDone DB failure leaves the item pending and the handler
/// re-runs on the next drain.
typedef QueueHandler = Future<void> Function(String payload);

class QueueWorker {
  QueueWorker({
    required QueueRepository repository,
    required this._network,
    required this._logger,
  }) : _repo = repository;

  final QueueRepository _repo;
  final NetworkService _network;
  final AppLogger _logger;
  final Map<String, QueueHandler> _handlers = {};

  StreamSubscription<bool>? _sub;
  bool _draining = false;

  /// Map a queue `type` to the handler that processes it.
  void registerHandler(String type, QueueHandler handler) {
    _handlers[type] = handler;
  }

  /// Begin draining on each reconnect. Emits an initial drain if online now.
  void start() {
    _sub ??= _network.online.listen(_onEdge);
  }

  /// Stop listening. Idempotent.
  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  void _onEdge(bool online) {
    if (online) {
      // Fire-and-forget: drain guards re-entry and swallows its own errors.
      _drain();
    }
  }

  /// Process every pending item once, in order. Re-entry guarded so a fast
  /// connectivity flap can't start two overlapping drains.
  Future<void> drain() => _drain();

  Future<void> _drain() async {
    if (_draining) return;
    _draining = true;
    try {
      final items = await _repo.pending();
      for (final item in items) {
        await _process(item);
      }
    } on Object catch (e) {
      // Drain is fire-and-forget from _onEdge; never let an error escape as an
      // unhandled async error. A repo-level failure (DB locked/closed) bails
      // the current drain — the next connectivity edge retries.
      _logger.e(LogTag.task, 'queue drain aborted: $e');
    } finally {
      _draining = false;
    }
  }

  Future<void> _process(QueueItem item) async {
    final handler = _handlers[item.type];
    if (handler == null) {
      _logger.w(
        LogTag.task,
        'no handler for queue type "${item.type}" (id ${item.id}); '
        'leaving pending',
      );
      return;
    }
    try {
      await handler(item.payload);
    } on Object catch (e) {
      _logger.e(LogTag.task, 'queue item ${item.id} (${item.type}) failed: $e');
      try {
        await _repo.markFailed(item.id, error: e.toString());
      } on Object catch (mfErr) {
        // A DB error recording the failure likely affects the whole drain —
        // bail rather than spin through the batch unable to record any.
        _logger.e(
          LogTag.task,
          'markFailed for item ${item.id} also threw: $mfErr',
        );
        rethrow;
      }
      return; // Leave pending; next reconnect retries.
    }
    // Handler succeeded. markDone is a DB write, not a handler step: a failure
    // here must NOT be recorded as a handler failure (would mis-bump attempts
    // and re-run the already side-effected handler). Log + leave pending.
    try {
      await _repo.markDone(item.id);
    } on Object catch (e) {
      _logger.e(
        LogTag.task,
        'markDone failed for item ${item.id}: $e; leaving pending '
        '(handler already executed)',
      );
    }
  }
}
