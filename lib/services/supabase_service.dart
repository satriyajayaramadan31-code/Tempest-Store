// supabase_service.dart 
import 'dart:developer' as developer;
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  // ----------------------------------------------------------
  // SINGLETON
  // ----------------------------------------------------------
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  static String _supabaseUrl = 'https://eyyzpjjeqfetwaqnicbi.supabase.co';
  static String _supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV5eXpwamplcWZldHdhcW5pY2JpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAzMDIwNDUsImV4cCI6MjA3NTg3ODA0NX0.3wvrhuBHlU_jgfy5tiibKamhqEw1qArNGv3-NXWeyIw';

  static String get supabaseUrl => _supabaseUrl;
  static String get supabaseAnonKey => _supabaseAnonKey;

  // ----------------------------------------------------------
  // INIT
  // ----------------------------------------------------------
  static Future<void> init({String? url, String? anonKey}) async {
    if (url != null) _supabaseUrl = url;
    if (anonKey != null) _supabaseAnonKey = anonKey;

    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;

  // ----------------------------------------------------------
  // AUTH
  // ----------------------------------------------------------
  User? get currentUser => client.auth.currentUser;
  Session? get currentSession => client.auth.currentSession;
  Stream<AuthState> get onAuthStateChange => client.auth.onAuthStateChange;

  Future<AuthResponse?> signIn(String email, String password) async {
    try {
      final res = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return res.user != null ? res : null;
    } on AuthApiException catch (_) {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<AuthResponse> signUp(String email, String password) {
    return client.auth.signUp(email: email, password: password);
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  // ----------------------------------------------------------
  // UNIVERSAL PARSER
  // ----------------------------------------------------------
  List<Map<String, dynamic>> _parseListResponse(dynamic res) {
    try {
      if (res == null) return [];

      if (res is List) {
        return List<Map<String, dynamic>>.from(
          res.map((e) => Map<String, dynamic>.from(e as Map)),
        );
      }

      if (res is Map && res['data'] != null) {
        return List<Map<String, dynamic>>.from(
          (res['data'] as List).map(
            (e) => Map<String, dynamic>.from(e),
          ),
        );
      }

      try {
        final dynData = (res as dynamic).data;
        if (dynData is List) {
          return List<Map<String, dynamic>>.from(
            dynData.map((e) => Map<String, dynamic>.from(e)),
          );
        }
      } catch (_) {}
    } catch (e, st) {
      developer.log('parseListResponse error: $e\n$st');
    }

    return [];
  }

  // ----------------------------------------------------------
  // ROLE
  // ----------------------------------------------------------
  Future<String?> getUserRole() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final res =
          await client.from('users').select('role').eq('auth_uid', user.id);
      final data = _parseListResponse(res);
      return data.isNotEmpty ? data.first['role']?.toString() : null;
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

  // ----------------------------------------------------------
  // PRODUK — GET only active (not soft deleted)
  // ----------------------------------------------------------
  Future<List<Map<String, dynamic>>> getProduk() async {
    try {
      final res = await client
          .from('kasir_produk')
          .select()
          .eq('is_deleted', false)
          .order('produkid', ascending: false);

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

  // ❌ Hard delete (tidak dipakai lagi)
  Future<void> deleteProduk(int id) async {
    try {
      await client.from('kasir_produk').delete().eq('produkid', id);
    } catch (e, st) {
      developer.log('deleteProduk error: $e\n$st');
      rethrow;
    }
  }

  // ----------------------------------------------------------
  // SOFT DELETE PRODUK BY SKU
  // ----------------------------------------------------------
  Future<void> deleteProdukBySKU(String sku) async {
    try {
      await client
          .from('kasir_produk')
          .update({'is_deleted': true})
          .eq('SKU', sku);
    } catch (e, st) {
      developer.log('deleteProdukBySKU error: $e\n$st');
      rethrow;
    }
  }

  // ----------------------------------------------------------
  // IMAGE UPLOAD + DELETE
  // ----------------------------------------------------------
  Future<String?> uploadProductImage(File imageFile, String sku) async {
    try {
      final ext = imageFile.path.split('.').last;
      const bucket = 'produk_image';

      final filePath = '$sku.$ext';

      await client.storage.from(bucket).upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );

      return client.storage.from(bucket).getPublicUrl(filePath);
    } catch (e, st) {
      developer.log('uploadProductImage error: $e\n$st');
      rethrow;
    }
  }

  Future<void> deleteFile(String path) async {
    try {
      final parts = path.split('/');
      final bucket = parts.first;
      final file = parts.sublist(1).join('/');

      await client.storage.from(bucket).remove([file]);
    } catch (e, st) {
      developer.log('deleteFile error: $e\n$st');
      rethrow;
    }
  }

  // ----------------------------------------------------------
  // STOK
  // ----------------------------------------------------------
  Future<void> tambahStok(int id, int jumlahTambah) async {
    try {
      final res =
          await client.from('kasir_produk').select('stok').eq('produkid', id).single();

      final currentStock = res['stok'] ?? 0;

      await client
          .from('kasir_produk')
          .update({'stok': currentStock + jumlahTambah}).eq('produkid', id);
    } catch (e, st) {
      developer.log('tambahStok error: $e\n$st');
      rethrow;
    }
  }

  Future<void> addProduk(Map<String, dynamic> data) async {
    try {
      data['is_deleted'] = data['is_deleted'] ?? false;
      await insertProduk(data);
    } catch (e, st) {
      developer.log('addProduk error: $e\n$st');
      rethrow;
    }
  }

  // ----------------------------------------------------------
  // PELANGGAN
  // ----------------------------------------------------------
  Future<List<Map<String, dynamic>>> getPelanggan() async {
    try {
      final res = await client.from('kasir_pelanggan').select();
      return _parseListResponse(res);
    } catch (e, st) {
      developer.log('getPelanggan error: $e\n$st');
      return [];
    }
  }

  Future<Map<String, dynamic>> addPelanggan({
    required String name,
    String? alamat,
    String? nomortelepon,
    String? email,
  }) async {
    try {
      final response = await client
          .from('kasir_pelanggan')
          .insert({
            'namapelanggan': name,
            'alamat': alamat,
            'nomortelepon': nomortelepon,
            'email': email,
          })
          .select()
          .single();

      return response;
    } catch (e, st) {
      developer.log('addPelanggan error: $e\n$st');
      rethrow;
    }
  }

  Future<void> updatePelanggan(int pelangganId, Map<String, dynamic> data) async {
    try {
      await client
          .from('kasir_pelanggan')
          .update(data)
          .eq('pelangganid', pelangganId);
    } catch (e, st) {
      developer.log('updatePelanggan error: $e\n$st');
      rethrow;
    }
  }

  Future<void> deletePelanggan(int pelangganId) async {
    try {
      await client
          .from('kasir_pelanggan')
          .delete()
          .eq('pelangganid', pelangganId);
    } catch (e, st) {
      developer.log('deletePelanggan error: $e\n$st');
      rethrow;
    }
  }

  // ----------------------------------------------------------
  // PENJUALAN
  // ----------------------------------------------------------
  Future<List<Map<String, dynamic>>> getPenjualan() async {
    try {
      final res = await client
          .from('kasir_penjualan')
          .select('*, kasir_pelanggan(namapelanggan)');

      return _parseListResponse(res);
    } catch (e, st) {
      developer.log('getPenjualan error: $e\n$st');
      return [];
    }
  }

  Future<void> insertPenjualan(Map<String, dynamic> data) async {
    try {
      await client.from('kasir_penjualan').insert(data);
    } catch (e, st) {
      developer.log('insertPenjualan error: $e\n$st');
      rethrow;
    }
  }

  Future<void> updatePenjualan(int id, Map<String, dynamic> data) async {
    try {
      await client
          .from('kasir_penjualan')
          .update(data)
          .eq('penjualanid', id);
    } catch (e, st) {
      developer.log('updatePenjualan error: $e\n$st');
      rethrow;
    }
  }

  Future<void> deletePenjualan(int id) async {
    try {
      await client.from('kasir_penjualan').delete().eq('penjualanid', id);
    } catch (e, st) {
      developer.log('deletePenjualan error: $e\n$st');
      rethrow;
    }
  }

  // ----------------------------------------------------------
  // STRUK
  // ----------------------------------------------------------
  Future<List<Map<String, dynamic>>> getStruk() async {
    try {
      final res = await client
          .from('kasir_struk')
          .select('*, kasir_penjualan(totalharga, pelangganid)');

      return _parseListResponse(res);
    } catch (e, st) {
      developer.log('getStruk error: $e\n$st');
      return [];
    }
  }

  Future<void> insertStruk(Map<String, dynamic> data) async {
    try {
      await client.from('kasir_struk').insert(data);
    } catch (e, st) {
      developer.log('insertStruk error: $e\n$st');
      rethrow;
    }
  }

  Future<void> deleteStruk(int strukId) async {
    try {
      await client.from('kasir_struk').delete().eq('strukid', strukId);
    } catch (e, st) {
      developer.log('deleteStruk error: $e\n$st');
      rethrow;
    }
  }

  // ----------------------------------------------------------
  // DETAIL PENJUALAN
  // ----------------------------------------------------------
  Future<List<Map<String, dynamic>>> getDetailPenjualan(int penjualanId) async {
    try {
      final res = await client
          .from('kasir_detailpenjualan')
          .select('*, kasir_produk(namaproduk, harga)')
          .eq('penjualanid', penjualanId);

      return _parseListResponse(res);
    } catch (e, st) {
      developer.log('getDetailPenjualan error: $e\n$st');
      return [];
    }
  }

  Future<void> insertDetailPenjualan(Map<String, dynamic> data) async {
    try {
      await client.from('kasir_detailpenjualan').insert(data);
    } catch (e, st) {
      developer.log('insertDetailPenjualan error: $e\n$st');
      rethrow;
    }
  }

  Future<void> deleteDetailPenjualan(int detailId) async {
    try {
      await client
          .from('kasir_detailpenjualan')
          .delete()
          .eq('detailid', detailId);
    } catch (e, st) {
      developer.log('deleteDetailPenjualan error: $e\n$st');
      rethrow;
    }
  }
}
