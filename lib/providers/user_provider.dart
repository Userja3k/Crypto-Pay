// lib/providers/user_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../services/breez_service.dart';
import '../services/nfc_service.dart';
import '../services/bluetooth_service.dart';
import '../services/payment_service.dart';
import '../services/lightning_address_service.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

final supabaseClientProvider = Provider((ref) => Supabase.instance.client);

final supabaseServiceProvider = Provider((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseService(client);
});

// ✅ BreezService - UNIQUE
final breezServiceProvider = Provider((ref) => BreezService());

final breezInitializedProvider = StateProvider<bool>((ref) => false);

final breezBalanceProvider = FutureProvider<Balance>((ref) async {
  final breez = ref.watch(breezServiceProvider);
  if (!breez.isConnected) throw Exception('Breez SDK non connecté');
  return breez.getBalance();
});

// ════════════════════════════════════════════════════════
// NFC & BLUETOOTH
// ════════════════════════════════════════════════════════

final nfcServiceProvider = Provider((ref) => NfcService());
final bluetoothServiceProvider = Provider((ref) => BluetoothService());
final lightningAddressServiceProvider = Provider((ref) => LightningAddressService());

final paymentServiceProvider = Provider((ref) {
  final nfc = ref.watch(nfcServiceProvider);
  final bluetooth = ref.watch(bluetoothServiceProvider);
  final breez = ref.watch(breezServiceProvider);
  final supabase = ref.watch(supabaseServiceProvider);
  return PaymentService(
    nfcService: nfc,
    bluetoothService: bluetooth,
    breezService: breez,
    supabaseService: supabase,
  );
});

// ════════════════════════════════════════════════════════
// AUTH
// ════════════════════════════════════════════════════════

class AuthState {
  final Map<String, dynamic>? user;
  final bool isAuthenticated;

  AuthState({this.user, this.isAuthenticated = false});
  
  String? get userId => user?['user_id'] as String?;
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

class NotificationsNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  final Ref _ref;

  NotificationsNotifier(this._ref) : super([]) {
    _init();
  }

  Future<void> _init() async {
    final auth = _ref.read(authProvider);
    final userId = auth.userId;
    if (userId == null) return;

    final service = _ref.read(supabaseServiceProvider);
    final initial = await service.getNotifications(userId);
    state = initial;
  }
}

final notificationsProvider = StateNotifierProvider<NotificationsNotifier, List<Map<String, dynamic>>>((ref) {
  return NotificationsNotifier(ref);
});