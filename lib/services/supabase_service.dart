import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  // Singleton
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  // default fallback (bisa di-override via init)
  static String _supabaseUrl = 'https://eyyzpjjeqfetwaqnicbi.supabase.co';
  static String _supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV5eXpwamplcWZldHdhcW5pY2JpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAzMDIwNDUsImV4cCI6MjA3NTg3ODA0NX0.3wvrhuBHlU_jgfy5tiibKamhqEw1qArNGv3-NXWeyIw';

  static String get supabaseUrl => _supabaseUrl;
  static String get supabaseAnonKey => _supabaseAnonKey;

  /// Init Supabase
  static Future<void> init({String? url, String? anonKey}) async {
    if (url != null) _supabaseUrl = url;
    if (anonKey != null) _supabaseAnonKey = anonKey;

    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;

  // =============== AUTH ==================

  User? get currentUser => client.auth.currentUser;
  Session? get currentSession => client.auth.currentSession;
  Stream<AuthState> get onAuthStateChange => client.auth.onAuthStateChange;

  Future<AuthResponse> signIn(String email, String password) {
    return client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp(String email, String password) {
    return client.auth.signUp(email: email, password: password);
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  // ============== PARSER ================
  List<Map<String, dynamic>> _parseListResponse(dynamic res) {
    try {
      if (res == null) return [];

      if (res is List) {
        return List<Map<String, dynamic>>.from(
            res.map((e) => Map<String, dynamic>.from(e as Map)));
      }

      if (res is Map && res['data'] != null) {
        return List<Map<String, dynamic>>.from(
            (res['data'] as List).map((e) => Map<String, dynamic>.from(e)));
      }

      try {
        final dynData = (res as dynamic).data;
        if (dynData is List) {
          return List<Map<String, dynamic>>.from(
              dynData.map((e) => Map<String, dynamic>.from(e)));
      }
      } catch (_) {}
    } catch (e, st) {
      developer.log('parseListResponse error: $e\n$st');
    }
    return [];
  }

  // ============== ROLE LOGIC ==============

  Future<String?> getUserRole() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final res = await client
          .from('users')
          .select('role')
          .eq('auth_uid', user.id);

      final data = _parseListResponse(res);
      if (data.isEmpty) return null;

      return data.first['role']?.toString();
    } catch (e, st) {
      developer.log('getUserRole error: $e\n$st');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUserWithRole() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final res = await client
          .from('users')
          .select('id, email, role, auth_uid')
          .eq('auth_uid', user.id);

      final data = _parseListResponse(res);
      if (data.isEmpty) return null;

      final map = Map<String, dynamic>.from(data.first);
      map['auth_user'] = {'id': user.id, 'email': user.email};
      return map;
    } catch (e, st) {
      developer.log('getUserWithRole error: $e\n$st');
      return null;
    }
  }

  // ======================================
  // CRUD: PRODUK, PELANGGAN, PENJUALAN, STRUK
  // (Bagian bawah milikmu tadi — sudah benar!)
  // ======================================

  Future<List<Map<String, dynamic>>> getProduk() async {
    try {
      final res = await client.from('kasir_produk').select();
      return _parseListResponse(res);
    } catch (e, st) {
      developer.log('getProduk error: $e\n$st');
      return [];
    }
  }

  Future<void> insertProduk(Map<String, dynamic> data) async {
    try {
      await client.from('kasir_produk').insert(data);
    } catch (e, st) {
      developer.log('insertProduk error: $e\n$st');
      rethrow;
    }
  }

  Future<void> updateProduk(int id, Map<String, dynamic> data) async {
    try {
      await client.from('kasir_produk').update(data).eq('produkid', id);
    } catch (e, st) {
      developer.log('updateProduk error: $e\n$st');
      rethrow;
    }
  }

  Future<void> deleteProduk(int id) async {
    try {
      await client.from('kasir_produk').delete().eq('produkid', id);
    } catch (e, st) {
      developer.log('deleteProduk error: $e\n$st');
      rethrow;
    }
  }

  // ==========================
  // CRUD: PELANGGAN
  // ==========================
  Future<List<Map<String, dynamic>>> getPelanggan() async {
    try {
      final res = await client.from('kasir_pelanggan').select();
      return _parseListResponse(res);
    } catch (e, st) {
      developer.log('getPelanggan exception: $e\n$st');
      return [];
    }
  }

  Future<void> insertPelanggan(Map<String, dynamic> data) async {
    try {
      await client.from('kasir_pelanggan').insert(data);
    } catch (e, st) {
      developer.log('insertPelanggan exception: $e\n$st');
      rethrow;
    }
  }

  Future<void> updatePelanggan(int pelangganId, Map<String, dynamic> data) async {
    try {
      await client.from('kasir_pelanggan').update(data).eq('pelangganid', pelangganId);
    } catch (e, st) {
      developer.log('updatePelanggan exception: $e\n$st');
      rethrow;
    }
  }

  Future<void> deletePelanggan(int pelangganId) async {
    try {
      await client.from('kasir_pelanggan').delete().eq('pelangganid', pelangganId);
    } catch (e, st) {
      developer.log('deletePelanggan exception: $e\n$st');
      rethrow;
    }
  }

  // ==========================
  // CRUD: PENJUALAN
  // ==========================
  Future<List<Map<String, dynamic>>> getPenjualan() async {
    try {
      final res = await client.from('kasir_penjualan').select('*, kasir_pelanggan(namapelanggan)');
      return _parseListResponse(res);
    } catch (e, st) {
      developer.log('getPenjualan exception: $e\n$st');
      return [];
    }
  }

  Future<void> insertPenjualan(Map<String, dynamic> data) async {
    try {
      await client.from('kasir_penjualan').insert(data);
    } catch (e, st) {
      developer.log('insertPenjualan exception: $e\n$st');
      rethrow;
    }
  }

  Future<void> updatePenjualan(int id, Map<String, dynamic> data) async {
    try {
      await client.from('kasir_penjualan').update(data).eq('penjualanid', id);
    } catch (e, st) {
      developer.log('updatePenjualan exception: $e\n$st');
      rethrow;
    }
  }

  Future<void> deletePenjualan(int id) async {
    try {
      await client.from('kasir_penjualan').delete().eq('penjualanid', id);
    } catch (e, st) {
      developer.log('deletePenjualan exception: $e\n$st');
      rethrow;
    }
  }

  // ==========================
  // CRUD: STRUK
  // ==========================
  Future<List<Map<String, dynamic>>> getStruk() async {
    try {
      final res = await client.from('kasir_struk').select('*, kasir_penjualan(totalharga, pelangganid)');
      return _parseListResponse(res);
    } catch (e, st) {
      developer.log('getStruk exception: $e\n$st');
      return [];
    }
  }

  Future<void> insertStruk(Map<String, dynamic> data) async {
    try {
      await client.from('kasir_struk').insert(data);
    } catch (e, st) {
      developer.log('insertStruk exception: $e\n$st');
      rethrow;
    }
  }

  Future<void> deleteStruk(int strukId) async {
    try {
      await client.from('kasir_struk').delete().eq('strukid', strukId);
    } catch (e, st) {
      developer.log('deleteStruk exception: $e\n$st');
      rethrow;
    }
  }

  // ==========================
  // DETAIL PENJUALAN
  // ==========================
  Future<List<Map<String, dynamic>>> getDetailPenjualan(int penjualanId) async {
    try {
      final res = await client
          .from('kasir_detailpenjualan')
          .select('*, kasir_produk(namaproduk, harga)')
          .eq('penjualanid', penjualanId);
      return _parseListResponse(res);
    } catch (e, st) {
      developer.log('getDetailPenjualan exception: $e\n$st');
      return [];
    }
  }

  Future<void> insertDetailPenjualan(Map<String, dynamic> data) async {
    try {
      await client.from('kasir_detailpenjualan').insert(data);
    } catch (e, st) {
      developer.log('insertDetailPenjualan exception: $e\n$st');
      rethrow;
    }
  }

  Future<void> deleteDetailPenjualan(int detailId) async {
    try {
      await client.from('kasir_detailpenjualan').delete().eq('detailid', detailId);
    } catch (e, st) {
      developer.log('deleteDetailPenjualan exception: $e\n$st');
      rethrow;
    }
  }
}
