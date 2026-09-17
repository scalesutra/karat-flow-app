import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/api_models.dart';

/// Offline & In-Memory Persistent Local Cache Service
/// Caches Catalog Designs, Production Stages, Clients & Orders locally
/// using SharedPreferences (localStorage on Web, SQLite/Key-Value on mobile).
class AppLocalCacheService {
  AppLocalCacheService._();
  static final AppLocalCacheService instance = AppLocalCacheService._();

  static const String _keyCachedThreeD = 'kf_cache_threed_v1';
  static const String _keyCachedStages = 'kf_cache_stages_v1';
  static const String _keyCachedCustomers = 'kf_cache_customers_v1';
  static const String _keyCachedOrders = 'kf_cache_orders_v1';
  static const String _keyCachedSketches = 'kf_cache_sketches_v1';

  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ── 1. 3D Designs Cache ────────────────────────────────────────────
  Future<void> saveThreeDDesigns(List<ApiThreeDDesign> designs) async {
    try {
      final prefs = await _getPrefs();
      final jsonList = designs.map((d) => d.toJson()).toList();
      await prefs.setString(_keyCachedThreeD, jsonEncode(jsonList));
    } catch (_) {
      // Cache failures must not interrupt live data loading.
    }
  }

  Future<List<ApiThreeDDesign>> getCachedThreeDDesigns() async {
    try {
      final prefs = await _getPrefs();
      final str = prefs.getString(_keyCachedThreeD);
      if (str == null || str.isEmpty) return const [];
      final decoded = jsonDecode(str);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(ApiThreeDDesign.fromJson)
            .toList();
      }
    } catch (_) {
      // Cache failures must not interrupt live data loading.
    }
    return const [];
  }

  // ── 2. Raw Sketches Cache ──────────────────────────────────────────
  Future<void> saveSketches(List<ApiSketch> sketches) async {
    try {
      final prefs = await _getPrefs();
      final jsonList = sketches.map((s) => s.toJson()).toList();
      await prefs.setString(_keyCachedSketches, jsonEncode(jsonList));
    } catch (_) {
      // Cache failures must not interrupt live data loading.
    }
  }

  Future<List<ApiSketch>> getCachedSketches() async {
    try {
      final prefs = await _getPrefs();
      final str = prefs.getString(_keyCachedSketches);
      if (str == null || str.isEmpty) return const [];
      final decoded = jsonDecode(str);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(ApiSketch.fromJson)
            .toList();
      }
    } catch (_) {
      // Cache failures must not interrupt live data loading.
    }
    return const [];
  }

  // ── 3. Production Stages Cache ─────────────────────────────────────
  Future<void> saveStages(List<ApiStage> stages) async {
    try {
      final prefs = await _getPrefs();
      final jsonList = stages.map((s) => s.toJson()).toList();
      await prefs.setString(_keyCachedStages, jsonEncode(jsonList));
    } catch (_) {
      // Cache failures must not interrupt live data loading.
    }
  }

  Future<List<ApiStage>> getCachedStages() async {
    try {
      final prefs = await _getPrefs();
      final str = prefs.getString(_keyCachedStages);
      if (str == null || str.isEmpty) return const [];
      final decoded = jsonDecode(str);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(ApiStage.fromJson)
            .toList();
      }
    } catch (_) {
      // Cache failures must not interrupt live data loading.
    }
    return const [];
  }

  // ── 4. Customers / Clients Cache ───────────────────────────────────
  Future<void> saveCustomers(List<ApiCustomer> customers) async {
    try {
      final prefs = await _getPrefs();
      final jsonList = customers.map((c) => c.toJson()).toList();
      await prefs.setString(_keyCachedCustomers, jsonEncode(jsonList));
    } catch (_) {
      // Cache failures must not interrupt live data loading.
    }
  }

  Future<List<ApiCustomer>> getCachedCustomers() async {
    try {
      final prefs = await _getPrefs();
      final str = prefs.getString(_keyCachedCustomers);
      if (str == null || str.isEmpty) return const [];
      final decoded = jsonDecode(str);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(ApiCustomer.fromJson)
            .toList();
      }
    } catch (_) {
      // Cache failures must not interrupt live data loading.
    }
    return const [];
  }

  // ── 5. Orders Cache ────────────────────────────────────────────────
  Future<void> saveOrders(List<ApiOrder> orders) async {
    try {
      final prefs = await _getPrefs();
      final jsonList = orders.map((o) => o.toJson()).toList();
      await prefs.setString(_keyCachedOrders, jsonEncode(jsonList));
    } catch (_) {
      // Cache failures must not interrupt live data loading.
    }
  }

  Future<List<ApiOrder>> getCachedOrders() async {
    try {
      final prefs = await _getPrefs();
      final str = prefs.getString(_keyCachedOrders);
      if (str == null || str.isEmpty) return const [];
      final decoded = jsonDecode(str);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(ApiOrder.fromJson)
            .toList();
      }
    } catch (_) {
      // Cache failures must not interrupt live data loading.
    }
    return const [];
  }
}
