import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jewellery_ops_mobile/core/widgets/common_snackbar.dart';

class ConnectivityController extends GetxController {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  final RxBool isConnected = true.obs;
  bool _isFirstCheck = true;

  @override
  void onInit() {
    super.onInit();
    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _handleStatus(results, isInitial: true);
    } catch (_) {
      isConnected.value = true;
    }

    try {
      _subscription = _connectivity.onConnectivityChanged.listen(
        _updateConnectionStatus,
        onError: (e) {
          debugPrint('Connectivity stream error: $e');
        },
      );
    } catch (e) {
      debugPrint('Failed to subscribe to connectivity stream: $e');
    }
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    _handleStatus(results, isInitial: false);
  }

  void _handleStatus(
    List<ConnectivityResult> results, {
    required bool isInitial,
  }) {
    final hasNet =
        results.isNotEmpty &&
        !results.every((r) => r == ConnectivityResult.none);
    final previousState = isConnected.value;
    isConnected.value = hasNet;

    if (isInitial) {
      _isFirstCheck = false;
      if (!hasNet) {
        _showOfflineSnackbar();
      }
      return;
    }

    if (_isFirstCheck) {
      _isFirstCheck = false;
      return;
    }

    // State transitioned from Online -> Offline
    if (previousState && !hasNet) {
      _showOfflineSnackbar();
    }
    // State transitioned from Offline -> Online
    else if (!previousState && hasNet) {
      _showOnlineSnackbar();
    }
  }

  void _showOfflineSnackbar() {
    CommonSnackbar.error(
      null,
      title: 'No Internet Connection',
      message:
          'You are currently offline. Operations will sync once connection is restored.',
      duration: const Duration(seconds: 4),
    );
  }

  void _showOnlineSnackbar() {
    CommonSnackbar.success(
      null,
      title: 'Back Online',
      message: 'Internet connection restored. Live cloud sync active.',
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
