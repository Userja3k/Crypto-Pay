import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

final supabaseClientProvider = Provider((ref) => Supabase.instance.client);

final supabaseServiceProvider = Provider((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseService(client);
});

// Custom Auth State Management
class AuthState {
  final Map<String, dynamic>? user;
  final bool isAuthenticated;

  AuthState({this.user, this.isAuthenticated = false});
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState()) {
    _loadAuth();
  }

  Future<void> _loadAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('auth_user');
    if (userJson != null) {
      state = AuthState(user: jsonDecode(userJson), isAuthenticated: true);
    }
  }

  Future<void> login(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_user', jsonEncode(user));
    state = AuthState(user: user, isAuthenticated: true);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_user');
    state = AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());

final userBalanceProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, userId) async {
  final service = ref.watch(supabaseServiceProvider);
  return service.getBalance(userId);
});

final transactionHistoryProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, userId) async {
  final service = ref.watch(supabaseServiceProvider);
  return service.getTransactionHistory(userId);
});

final pendingApprovalsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, parentUserId) async {
  final service = ref.watch(supabaseServiceProvider);
  return service.getPendingApprovals(parentUserId);
});
