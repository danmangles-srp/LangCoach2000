// connectivity_plus-backed NetworkService. Under platform/ so the coverage
// gate excludes it (requires the platform plugin + a real radio — verified
// on-device).

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:rivendell/core/queue/network_service.dart';

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
    _connectivity.checkConnectivity().then((results) {
      _current = results.any((r) => r != ConnectivityResult.none);
      _controller.add(_current);
    });
    _sub = _connectivity.onConnectivityChanged.listen((results) {
      _current = results.any((r) => r != ConnectivityResult.none);
      _controller.add(_current);
    }, onError: _controller.addError);
  }

  @override
  Stream<bool> get online {
    _wire();
    return _controller.stream;
  }

  @override
  Future<bool> get isOnline async {
    final results = await _connectivity.checkConnectivity();
    return _current = results.any((r) => r != ConnectivityResult.none);
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    await _controller.close();
  }
}
