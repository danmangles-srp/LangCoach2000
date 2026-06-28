// connectivity_plus-backed NetworkService. Under platform/ so the coverage
// gate excludes it (requires the platform plugin + a real radio — verified
// on-device).

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:rivendell/core/connectivity/network_service.dart';

/// Production [NetworkService] backed by connectivity_plus.
///
/// Treats any non-`none` result as online. Emits the current state on listen.
/// App-lifetime singleton: the broadcast controller lives until [dispose].
class ConnectivityNetworkService implements NetworkService {
  ConnectivityNetworkService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;
  final _controller = StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _current = true;
  bool _wired = false;

  void _wire() {
    if (_wired) return;
    _wired = true;
    _connectivity
        .checkConnectivity()
        .then((results) {
          _current = _isOnline(results);
          _controller.add(_current);
        })
        .catchError((Object e, StackTrace st) {
          _controller.addError(e, st);
        });
    _sub = _connectivity.onConnectivityChanged.listen((results) {
      _current = _isOnline(results);
      _controller.add(_current);
    }, onError: _controller.addError);
  }

  /// 'Treat any non-none result as online' — one definition, used by both the
  /// seed fetch and the change stream so the two paths can't drift.
  bool _isOnline(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  @override
  Stream<bool> get online async* {
    _wire();
    // Broadcast controllers don't replay the last event, so a subscriber that
    // attaches after the initial checkConnectivity resolves would miss the
    // seed. Yield the cached current state first, then forward the stream —
    // matching FakeNetworkService's contract.
    yield _current;
    yield* _controller.stream;
  }

  @override
  Future<bool> get isOnline async {
    final results = await _connectivity.checkConnectivity();
    return _current = _isOnline(results);
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    await _controller.close();
  }
}
