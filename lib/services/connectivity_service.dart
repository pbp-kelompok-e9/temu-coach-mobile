import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// Service untuk menangani konektivitas internet
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  
  bool _isConnected = true;
  bool get isConnected => _isConnected;

  final _connectivityController = StreamController<bool>.broadcast();
  Stream<bool> get connectivityStream => _connectivityController.stream;

  /// Inisialisasi service dan mulai mendengarkan perubahan konektivitas
  Future<void> initialize() async {
    // Cek status awal
    final result = await _connectivity.checkConnectivity();
    _updateConnectionStatus(result);

    // Dengarkan perubahan
    _subscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final hasConnection = results.isNotEmpty && 
        !results.every((r) => r == ConnectivityResult.none);
    
    if (_isConnected != hasConnection) {
      _isConnected = hasConnection;
      _connectivityController.add(_isConnected);
    }
  }

  /// Cek konektivitas saat ini
  Future<bool> checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _updateConnectionStatus(result);
    return _isConnected;
  }

  /// Dispose subscription
  void dispose() {
    _subscription?.cancel();
    _connectivityController.close();
  }
}

/// Mixin untuk menambahkan event handling ke StatefulWidget
mixin ConnectivityMixin<T extends StatefulWidget> on State<T> {
  StreamSubscription<bool>? _connectivitySubscription;
  bool _isOnline = true;
  
  bool get isOnline => _isOnline;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
  }

  void _initConnectivity() {
    final service = ConnectivityService();
    _isOnline = service.isConnected;
    
    _connectivitySubscription = service.connectivityStream.listen((isConnected) {
      if (mounted) {
        setState(() => _isOnline = isConnected);
        onConnectivityChanged(isConnected);
      }
    });
  }

  /// Override method ini untuk menangani perubahan konektivitas
  void onConnectivityChanged(bool isConnected) {
    if (!isConnected) {
      showOfflineSnackBar();
    } else {
      showOnlineSnackBar();
    }
  }

  void showOfflineSnackBar() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text('Tidak ada koneksi internet'),
              ),
            ],
          ),
          backgroundColor: Colors.red[700],
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Tutup',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  void showOnlineSnackBar() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.wifi, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text('Terhubung kembali'),
              ),
            ],
          ),
          backgroundColor: Colors.green[700],
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}

/// Widget untuk menampilkan banner offline
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.red[700],
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Text(
            'Tidak ada koneksi internet',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
