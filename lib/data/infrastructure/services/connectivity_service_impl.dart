import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../domain/services/i_connectivity_service.dart';

class ConnectivityServiceImpl implements IConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<ConnectivityState> _ctrl = StreamController.broadcast();
  ConnectivityState _current = ConnectivityState(online: true, type: ConnectivityType.other);

  ConnectivityServiceImpl() {
    _connectivity.onConnectivityChanged.listen((results) async {
      final online = await ping();
      final state = ConnectivityState(online: online, type: _mapList(results));
      _current = state;
      _ctrl.add(state);
    });
    // Seed inicial
    _init();
  }

  Future<void> _init() async {
    final results = await _connectivity.checkConnectivity();
    final online = await ping();
    _current = ConnectivityState(online: online, type: _mapList(results));
    _ctrl.add(_current);
  }

  ConnectivityType _map(ConnectivityResult r) {
    switch (r) {
      case ConnectivityResult.mobile:
        return ConnectivityType.mobile;
      case ConnectivityResult.wifi:
        return ConnectivityType.wifi;
      case ConnectivityResult.ethernet:
        return ConnectivityType.ethernet;
      case ConnectivityResult.none:
        return ConnectivityType.none;
      default:
        return ConnectivityType.other;
    }
  }

  ConnectivityType _mapList(List<ConnectivityResult> results) {
    if (results.isEmpty) return ConnectivityType.none;
    if (results.contains(ConnectivityResult.wifi)) return ConnectivityType.wifi;
    if (results.contains(ConnectivityResult.mobile)) return ConnectivityType.mobile;
    if (results.contains(ConnectivityResult.ethernet)) return ConnectivityType.ethernet;
    if (results.every((r) => r == ConnectivityResult.none)) return ConnectivityType.none;
    return ConnectivityType.other;
  }

  @override
  ConnectivityState get current => _current;

  @override
  Stream<ConnectivityState> get changes => _ctrl.stream;

  @override
  Future<bool> ping({Duration timeout = const Duration(seconds: 2)}) async {
    try {
      final socket = await Socket.connect('8.8.8.8', 53, timeout: timeout);
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }
}


