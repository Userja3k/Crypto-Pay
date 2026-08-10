// lib/services/lightning_address_service.dart
// Version complète avec LNURL

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class LightningAddressService {
  LightningAddressService._internal();
  static final LightningAddressService _instance =
      LightningAddressService._internal();
  factory LightningAddressService() => _instance;

  final _supabase = Supabase.instance.client;

  // ════════════════════════════════════════════════════════
  // ADRESSE LIGHTNING
  // ════════════════════════════════════════════════════════

  Future<Map<String, String?>> getUserAddresses(String userId) async {
    try {
      final response = await _supabase
          .from('accounts')
          .select('lightning_address, btc_onchain_address')
          .eq('user_id', userId)
          .maybeSingle();
      
      if (response == null) return {'ln': null, 'btc': null};
      
      return {
        'ln': response['lightning_address'] as String?,
        'btc': response['btc_onchain_address'] as String?,
      };
    } catch (e) {
      return {'ln': null, 'btc': null};
    }
  }

  Future<void> saveAddresses({
    required String userId,
    String? lightningAddress,
    String? btcAddress,
  }) async {
    try {
      final Map<String, dynamic> data = {};
      if (lightningAddress != null) data['lightning_address'] = lightningAddress;
      if (btcAddress != null) data['btc_onchain_address'] = btcAddress;
      
      if (data.isEmpty) return;

      await _supabase
          .from('accounts')
          .update(data)
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('Erreur sauvegarde adresses: $e');
      rethrow;
    }
  }

  Future<String> createLightningAddress({
    required String userId,
    required String username,
  }) async {
    try {
      final existing = await _supabase
          .from('accounts')
          .select('lightning_address')
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null && existing['lightning_address'] != null) {
        return existing['lightning_address'] as String;
      }

      final address = '$username@crypto-pay.com';

      await _supabase
          .from('accounts')
          .update({'lightning_address': address})
          .eq('user_id', userId);

      return address;
    } catch (e) {
      debugPrint('Erreur création adresse Lightning: $e');
      rethrow;
    }
  }

  Future<bool> addressExists(String address) async {
    try {
      final response = await _supabase
          .from('accounts')
          .select('user_id')
          .eq('lightning_address', address)
          .maybeSingle();
      return response != null;
    } catch (e) {
      return false;
    }
  }

  Future<String?> getUserIdFromAddress(String address) async {
    try {
      final response = await _supabase
          .from('accounts')
          .select('user_id')
          .eq('lightning_address', address)
          .maybeSingle();
      return response?['user_id'] as String?;
    } catch (e) {
      return null;
    }
  }

  // ════════════════════════════════════════════════════════
  // LNURL-PAY (Commerçants / Réception)
  // ════════════════════════════════════════════════════════

  /// Crée un LNURL-Pay pour un utilisateur
  Future<Map<String, dynamic>> createLnurlPay({
    required String userId,
    int? fixedAmountSats,
    String? description,
    bool requiresComment = false,
    int expiresInDays = 365,
  }) async {
    try {
      final response = await _supabase.rpc(
        'create_lnurl_pay',
        params: {
          'p_user_id': userId,
          'p_fixed_amount_sats': fixedAmountSats,
          'p_description': description ?? 'Paiement Crypto-Pay',
          'p_requires_comment': requiresComment,
          'p_expires_in_days': expiresInDays,
        },
      );

      if (response is List && response.isNotEmpty) {
        return response.first as Map<String, dynamic>;
      }
      return response is Map ? response as Map<String, dynamic> : {};
    } catch (e) {
      debugPrint('Erreur création LNURL-Pay: $e');
      rethrow;
    }
  }

  /// Récupère le LNURL-Pay d'un utilisateur
  Future<Map<String, dynamic>?> getLnurlPay(String userId) async {
    try {
      final response = await _supabase
          .from('lnurl_pay')
          .select('lnurl_secret, lnurl_url, description, fixed_amount_sats')
          .eq('user_id', userId)
          .gt('expires_at', DateTime.now().toIso8601String())
          .maybeSingle();

      return response;
    } catch (e) {
      return null;
    }
  }

  /// Récupère les infos d'un LNURL-Pay par son secret
  Future<Map<String, dynamic>?> getLnurlPayInfo(String secret) async {
    try {
      final response = await _supabase.rpc(
        'get_lnurl_pay_info',
        params: {'p_lnurl_secret': secret},
      );

      if (response is List && response.isNotEmpty) {
        return response.first as Map<String, dynamic>;
      }
      return response is Map ? response as Map<String, dynamic> : null;
    } catch (e) {
      return null;
    }
  }

  // ════════════════════════════════════════════════════════
  // LNURL-WITHDRAW (Dépôts)
  // ════════════════════════════════════════════════════════

  /// Crée un LNURL-Withdraw pour un utilisateur
  Future<Map<String, dynamic>> createLnurlWithdraw({
    required String userId,
    int? amountSats,
    String? description,
    int expiresInHours = 24,
  }) async {
    try {
      final response = await _supabase.rpc(
        'create_lnurl_withdraw',
        params: {
          'p_user_id': userId,
          'p_amount_sats': amountSats,
          'p_description': description ?? 'Dépôt Crypto-Pay',
          'p_expires_in_hours': expiresInHours,
        },
      );

      if (response is List && response.isNotEmpty) {
        return response.first as Map<String, dynamic>;
      }
      return response is Map ? response as Map<String, dynamic> : {};
    } catch (e) {
      debugPrint('Erreur création LNURL-Withdraw: $e');
      rethrow;
    }
  }

  /// Récupère le LNURL-Withdraw d'un utilisateur
  Future<Map<String, dynamic>?> getLnurlWithdraw(String userId) async {
    try {
      final response = await _supabase
          .from('lnurl_withdraw')
          .select('lnurl_secret, lnurl_url, description, amount_sats')
          .eq('user_id', userId)
          .eq('status', 'pending')
          .gt('expires_at', DateTime.now().toIso8601String())
          .maybeSingle();

      return response;
    } catch (e) {
      return null;
    }
  }

  // ════════════════════════════════════════════════════════
  // UTILITAIRES
  // ════════════════════════════════════════════════════════

  /// Génère un username à partir d'un nom
  String generateUsername(String fullName) {
    final clean = fullName
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
    
    final usernameBase = clean.length > 10 ? clean.substring(0, 10) : clean;
    
    final millis = DateTime.now().millisecondsSinceEpoch.toString();
    final suffix = millis.length > 4 
        ? millis.substring(millis.length - 4) 
        : millis;
        
    return '$usernameBase$suffix';
  }

  /// Vérifie si un username est disponible
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final response = await _supabase
          .from('accounts')
          .select('id')
          .eq('lightning_address', '$username@crypto-pay.com')
          .maybeSingle();
      return response == null;
    } catch (e) {
      return false;
    }
  }
}
