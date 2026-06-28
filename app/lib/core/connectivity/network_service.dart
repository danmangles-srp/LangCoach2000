// Connectivity seam (NFR-2.1.3). Abstract so the drain logic is unit-testable
// against a fake stream; the connectivity_plus impl lives in platform/.

import 'dart:async';

/// Reports whether the device currently has a usable network connection.
abstract class NetworkService {
  /// A stream of online/offline edges. Emits the current state on listen.
  Stream<bool> get online;

  /// A one-shot read of the current connectivity state.
  Future<bool> get isOnline;
}

/// Test double: drives the online stream from the test, optionally seeded.
///
/// Emits the seed on listen, then each value passed to [emit].
class FakeNetworkService implements NetworkService {
  FakeNetworkService({this._online = true});

  final _controller = StreamController<bool>.broadcast();
  bool _online;

  @override
  Stream<bool> get online => _seeded();

  @override
  Future<bool> get isOnline async => _online;

  /// Test helper: emit a new state.
  void emit({required bool online}) {
    _online = online;
    _controller.add(online);
  }

  /// Tear down the broadcast controller.
  void dispose() => _controller.close();

  Stream<bool> _seeded() async* {
    yield _online;
    yield* _controller.stream;
  }
}
