// The drain engine (NFR-2.1.3). Subscribes to [NetworkService]; on each
// online edge, processes all pending queue items by dispatching to the
// handler registered for the item's type. Pure logic — no platform deps — so
// the enqueue → reconnect → drain contract is unit-testable.
//
// While started + online with items still pending, it reschedules another
// drain with exponential backoff. This recovers transient failures (a DNS
// lookup that misses during a network handover, a half-open socket) in-app —
// without waiting for a fresh connectivity edge that may never come during a
// foreground session. Backoff resets the moment a drain makes progress or a
// new online edge fires (real connectivity returned).

import 'dart:async';

import 'package:rivendell/core/connectivity/network_service.dart';
import 'package:rivendell/core/logging/app_logger.dart';
import 'package:rivendell/core/queue/queue_repository.dart';

/// A per-type handler for a queued item's payload. Throwing marks the item
/// failed (not done); the worker retries it (backoff while online, or the next
/// connectivity edge). Handlers MUST be idempotent: a markDone DB failure
/// leaves the item pending and the handler re-runs on the next drain.
typedef QueueHandler = Future<void> Function(String payload);

class QueueWorker {
  QueueWorker({
    required QueueRepository repository,
    required this._network,
    required this._logger,
    this.baseBackoff = const Duration(seconds: 3),
    this.maxBackoff = const Duration(seconds: 60),
    this.reactiveDebounce = const Duration(milliseconds: 50),
  }) : _repo = repository;

  final QueueRepository _repo;
  final NetworkService _network;
  final AppLogger _logger;
  final Map<String, QueueHandler> _handlers = {};

  /// Starting backoff between autonomous retries (doubles each no-progress
  /// round, capped at [maxBackoff]). Injectable so tests run in milliseconds.
  final Duration baseBackoff;
  final Duration maxBackoff;

  /// Coalesce window for reactive drains (T19.2). A burst of pending-row writes
  /// (e.g. a drain that markDone's several items) fires one drain after the
  /// window, not one per write. Injectable so tests run in milliseconds.
  final Duration reactiveDebounce;

  StreamSubscription<bool>? _sub;
  StreamSubscription<void>? _pendingSub;
  Timer? _reactiveTimer;
  Timer? _retryTimer;
  bool _draining = false;
  bool _started = false;
  int _noProgressRounds = 0;

  /// Fires after every drain completes (success or failure). Observers
  /// (aiImageQueueSnapshotProvider, pending-count badges) re-fetch on this so
  /// the UI reflects items clearing without a manual refresh. Broadcast so any
  /// number of providers can watch; closed in [stop].
  final StreamController<void> _drainedController =
      StreamController<void>.broadcast();

  Stream<void> get onDrained => _drainedController.stream;

  /// Map a queue `type` to the handler that processes it.
  void registerHandler(String type, QueueHandler handler) {
    _handlers[type] = handler;
  }

  /// Begin draining on each reconnect (and retrying while online). Emits an
  /// initial drain if online now.
  void start() {
    _started = true;
    _sub ??= _network.online.listen(_onEdge);
    // T19.2: also drain the moment the pending set changes — an enqueue during
    // an already-online foreground session otherwise sits until a network edge
    // or app resume. The pending-row stream is the source of truth for "there
    // is work to do"; the online stream stays the gate for whether a drain can
    // actually reach the network.
    _pendingSub ??= _repo.pendingChanges().listen(_onPendingChange);
  }

  /// Stop listening + cancel any pending retry. Idempotent.
  Future<void> stop() async {
    _started = false;
    _retryTimer?.cancel();
    _retryTimer = null;
    _reactiveTimer?.cancel();
    _reactiveTimer = null;
    _noProgressRounds = 0;
    await _sub?.cancel();
    _sub = null;
    await _pendingSub?.cancel();
    _pendingSub = null;
    await _drainedController.close();
  }

  void _onEdge(bool online) {
    if (!online) return;
    // A fresh online edge: real connectivity (probably) returned — drop any
    // in-flight backoff timer and drain now so recovery isn't delayed.
    _noProgressRounds = 0;
    _retryTimer?.cancel();
    _retryTimer = null;
    _drain();
  }

  /// A pending row appeared/changed/removed (T18.1 dedup insert, a markDone, a
  /// markFailed, a cancel). Coalesce a burst into one drain so a batch doesn't
  /// fire N overlapping attempts; the `_draining` re-entry guard is the final
  /// safety. Offline: skip — the next online edge drives it, matching the
  /// offline-retry contract (no wasted attempts while the radio is down).
  void _onPendingChange(void _) {
    _maybeDrainReactively();
  }

  Future<void> _maybeDrainReactively() async {
    if (!await _network.isOnline) return;
    _reactiveTimer?.cancel();
    _reactiveTimer = Timer(reactiveDebounce, _drain);
  }

  /// Process every pending item once, in order. Re-entry guarded so a fast
  /// connectivity flap can't start two overlapping drains.
  Future<void> drain() => _drain();

  Future<void> _drain() async {
    if (_draining) return;
    _draining = true;
    var successes = 0;
    try {
      final items = await _repo.pending();
      for (final item in items) {
        if (await _process(item)) successes++;
      }
    } on Object catch (e) {
      // Drain is fire-and-forget from _onEdge; never let an error escape as an
      // unhandled async error. A repo-level failure (DB locked/closed) bails
      // the current drain — the next connectivity edge retries.
      _logger.e(LogTag.task, 'queue drain aborted: $e');
    } finally {
      _draining = false;
    }
    try {
      await _scheduleNextDrain(madeProgress: successes > 0);
      // Notify observers: the queue shape may have changed (an item cleared,
      // an attempt was recorded). Re-fetching on this signal is what keeps the
      // queue-review UI + pending badges live without a manual refresh.
      _drainedController.add(null);
    } on Object catch (e) {
      _logger.e(LogTag.task, 'queue schedule-next failed: $e');
    }
  }

  /// After a drain, if we're started + online + items remain, arm a retried
  /// drain. Backoff grows on consecutive no-progress rounds and resets the
  /// moment a round clears anything or a new online edge fires.
  Future<void> _scheduleNextDrain({required bool madeProgress}) async {
    _retryTimer?.cancel();
    _retryTimer = null;
    if (!_started) return; // one-shot drain() — no autonomous retry.
    final remaining = await _repo.pendingCount();
    if (remaining == 0) {
      _noProgressRounds = 0;
      return;
    }
    if (!await _network.isOnline) {
      // Offline: let the next online edge drive it.
      _noProgressRounds = 0;
      return;
    }
    _noProgressRounds = madeProgress ? 0 : _noProgressRounds + 1;
    _retryTimer = Timer(_backoffFor(_noProgressRounds), _drain);
  }

  Duration _backoffFor(int noProgressRounds) {
    if (noProgressRounds <= 0) return baseBackoff;
    final doubled = baseBackoff * (1 << noProgressRounds);
    return doubled > maxBackoff ? maxBackoff : doubled;
  }

  /// Run [item]'s handler. Returns true iff the item was cleared from the
  /// pending set (handler succeeded + markDone persisted).
  Future<bool> _process(QueueItem item) async {
    final handler = _handlers[item.type];
    if (handler == null) {
      _logger.w(
        LogTag.task,
        'no handler for queue type "${item.type}" (id ${item.id}); '
        'leaving pending',
      );
      return false;
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
      return false; // Leave pending; retried by the scheduler / next edge.
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
      return false;
    }
    return true;
  }
}
