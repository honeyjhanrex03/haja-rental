import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../models/coupon_model.dart';

class AdminStats {
  final int totalUsers;
  final int totalSellers;
  final double totalIncome;

  AdminStats({
    this.totalUsers = 0,
    this.totalSellers = 0,
    this.totalIncome = 0.0,
  });
}

class AdminProvider extends Notifier<AsyncValue<AdminStats>> {
  sb.SupabaseClient get _supabase => sb.Supabase.instance.client;

  @override
  AsyncValue<AdminStats> build() {
    fetchStats();
    return const AsyncValue.loading();
  }

  Future<void> fetchStats() async {
    try {
      state = const AsyncValue.loading();
      
      final usersRes = await _supabase.from('profiles').select('id, role');
      final users = List<Map<String, dynamic>>.from(usersRes);
      
      final userCount = users.where((u) => u['role'] == 'customer').length;
      final sellerCount = users.where((u) => u['role'] == 'seller').length;
      
      final ordersRes = await _supabase.from('orders').select('total_price');
      final orders = List<Map<String, dynamic>>.from(ordersRes);
      double totalIncome = 0;
      for (var order in orders) {
        totalIncome += (order['total_price'] as num).toDouble();
      }
      
      state = AsyncValue.data(AdminStats(
        totalUsers: userCount,
        totalSellers: sellerCount,
        totalIncome: totalIncome,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // User Management
  Future<List<Map<String, dynamic>>> fetchAllUsers() async {
    final res = await _supabase.from('profiles').select().order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  Future<void> updateUser(String id, Map<String, dynamic> data) async {
    await _supabase.from('profiles').update(data).eq('id', id);
    fetchStats();
  }

  Future<void> deleteUserProfile(String id) async {
    // Note: This only deletes from public.profiles, not auth.users
    await _supabase.from('profiles').delete().eq('id', id);
    fetchStats();
  }

  // Coupon Management
  Future<List<Coupon>> fetchCoupons() async {
    final res = await _supabase.from('coupons').select().order('created_at', ascending: false);
    return (res as List).map((e) => Coupon.fromJson(e)).toList();
  }

  Future<void> addCoupon(Coupon coupon) async {
    await _supabase.from('coupons').insert(coupon.toJson());
  }

  Future<void> updateCoupon(String id, Map<String, dynamic> data) async {
    await _supabase.from('coupons').update(data).eq('id', id);
  }

  Future<void> deleteCoupon(String id) async {
    await _supabase.from('coupons').delete().eq('id', id);
  }

  Future<Coupon?> validateCoupon(String code) async {
    final res = await _supabase
        .from('coupons')
        .select()
        .eq('code', code.toUpperCase())
        .eq('is_active', true)
        .maybeSingle();
    
    if (res == null) return null;
    final coupon = Coupon.fromJson(res);
    return coupon.isValid ? coupon : null;
  }
}

// THE PROVIDER
final adminProvider = NotifierProvider<AdminProvider, AsyncValue<AdminStats>>(() {
  return AdminProvider();
});

