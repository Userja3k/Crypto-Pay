import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LightningAddressService {
  LightningAddressService._internal();
  static final LightningAddressService _instance = LightningAddressService._internal();
  factory LightningAddressService() => _instance;

  final _supabase = Supabase.instance.client;

  Future<String> createLightningAddress({required String userId, required String username}) async {
    try {
      final existing = await _supabase
          .from('accounts')
          .select('lightning_address')
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null && existing['lightning_address'] != null) {
        return existing['lightning_address'] as String;
      }

      final address = '\$username@crypto-pay.com'.replaceFirst('\$username', username);

      await _supabase.from('accounts').update({'lightning_address': address}).eq('user_id', userId);
      return address;
    } catch (e) {
      debugPrint('Erreur création adresse Lightning: $e');
      rethrow;
    }
  }

  Future<bool> addressExists(String address) async {
    try {
      final response = await _supabase.from('accounts').select('user_id').eq('lightning_address', address).maybeSingle();
      return response != null;
    } catch (e) {
      return false;
    }
  }

  Future<String?> getUserIdFromAddress(String address) async {
    try {
      final response = await _supabase.from('accounts').select('user_id').eq('lightning_address', address).maybeSingle();
      return response?['user_id'] as String?;
    } catch (e) {
      return null;
    }
  }
}
