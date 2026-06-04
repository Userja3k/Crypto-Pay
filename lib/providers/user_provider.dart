import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

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
  AuthNotifier() : super(AuthState());

  void login(Map<String, dynamic> user) {
    state = AuthState(user: user, isAuthenticated: true);
  }

  void logout() {
    state = AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());

final userBalanceProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, userId) async {
  final service = ref.watch(supabaseServiceProvider);
  return service.getBalance(userId);
});
