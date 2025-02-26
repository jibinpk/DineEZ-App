import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// Network connectivity state class
class NetworkState {
  final bool isLoading;
  final String? errorMessage;
  final bool isConnected;
  final ConnectivityResult connectionType;

  const NetworkState({
    this.isLoading = false,
    this.errorMessage,
    this.isConnected = true,
    this.connectionType = ConnectivityResult.none,
  });

  NetworkState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isConnected,
    ConnectivityResult? connectionType,
  }) {
    return NetworkState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      isConnected: isConnected ?? this.isConnected,
      connectionType: connectionType ?? this.connectionType,
    );
  }
}

// Network state notifier
class NetworkNotifier extends StateNotifier<NetworkState> {
  NetworkNotifier() : super(const NetworkState()) {
    _initConnectivity();
    _setupConnectivityListener();
  }

  // Initialize connectivity
  Future<void> _initConnectivity() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      final result = await Connectivity().checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to check connectivity: $e',
        isConnected: false,
      );
    }
  }

  // Setup connectivity change listener
  void _setupConnectivityListener() {
    Connectivity().onConnectivityChanged.listen((result) {
      _updateConnectionStatus(result);
    });
  }

  // Update connection status based on connectivity result
  void _updateConnectionStatus(ConnectivityResult result) {
    state = state.copyWith(
      isLoading: false,
      connectionType: result,
      isConnected: result != ConnectivityResult.none,
    );
  }

  // Manually check connectivity
  Future<void> checkConnectivity() async {
    await _initConnectivity();
  }
}

// Network state provider
final networkProvider = StateNotifierProvider<NetworkNotifier, NetworkState>((ref) {
  return NetworkNotifier();
});

// Convenient provider to check if online
final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(networkProvider).isConnected;
});

// Provider for connection type
final connectionTypeProvider = Provider<ConnectivityResult>((ref) {
  return ref.watch(networkProvider).connectionType;
});

// Provider that indicates if we're on WiFi
final isWifiProvider = Provider<bool>((ref) {
  return ref.watch(connectionTypeProvider) == ConnectivityResult.wifi;
});

// Provider that indicates if we're on mobile data
final isMobileDataProvider = Provider<bool>((ref) {
  return ref.watch(connectionTypeProvider) == ConnectivityResult.mobile;
}); 