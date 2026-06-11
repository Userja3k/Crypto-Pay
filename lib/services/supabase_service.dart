import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _client;

  SupabaseService(this._client);

  Future<Map<String, dynamic>> registerUser({
    required String email,
    required String phone,
    required String fullName,
    required DateTime birthDate,
    required String pinHash,
    required String pinSalt,
    String? referralCode,
  }) async {
    final response = await _client.rpc('register_user', params: {
      'p_email': email,
      'p_phone': phone,
      'p_full_name': fullName,
      'p_birth_date': birthDate.toIso8601String(),
      'p_pin_hash': pinHash,
      'p_pin_salt': pinSalt,
      'p_referral_code': referralCode,
    });
    
    if (response is List && response.isNotEmpty) {
      return response.first as Map<String, dynamic>;
    }
    return response is Map ? response as Map<String, dynamic> : {};
  }

  Future<Map<String, dynamic>> createChildAccount({
    required String parentUserId,
    required String childFullName,
    required DateTime childBirthDate,
    required double maxPerTransaction,
    required double maxPerDay,
    required double maxPerMonth,
  }) async {
    final response = await _client.rpc('create_child_account', params: {
      'p_parent_user_id': parentUserId,
      'p_child_full_name': childFullName,
      'p_child_birth_date': childBirthDate.toIso8601String(),
      'p_max_per_transaction_usd': maxPerTransaction,
      'p_max_per_day_usd': maxPerDay,
      'p_max_per_month_usd': maxPerMonth,
    });
    
    if (response is List && response.isNotEmpty) {
      return response.first as Map<String, dynamic>;
    }
    return response is Map ? response as Map<String, dynamic> : {};
  }

  Future<String?> getUserSalt(String identifier) async {
    final response = await _client.rpc('get_user_salt', params: {
      'p_identifier': identifier,
    });
    return response as String?;
  }

  Future<Map<String, dynamic>> verifyLogin({
    required String identifier,
    required String pinHash,
  }) async {
    final response = await _client.rpc('verify_login', params: {
      'p_identifier': identifier,
      'p_pin_hash': pinHash,
    });
    
    if (response is List && response.isNotEmpty) {
      return response.first as Map<String, dynamic>;
    }
    return response is Map ? response as Map<String, dynamic> : {};
  }

  Future<Map<String, dynamic>> getBalance(String userId) async {
    final response = await _client.rpc('get_balance', params: {
      'p_user_id': userId,
    });
    if (response is List && response.isNotEmpty) {
      return response.first as Map<String, dynamic>;
    }
    return {};
  }

  Future<List<Map<String, dynamic>>> searchUsers(String searchTerm) async {
    final response = await _client.rpc('search_users', params: {
      'p_search_term': searchTerm,
      'p_limit': 10,
    });
    return List<Map<String, dynamic>>.from(response as List);
  }

  Future<Map<String, dynamic>> sendPayment({
    required String senderUserId,
    required double amountUsd,
    required String destinationType,
    required String destinationIdentifier,
    String? note,
  }) async {
    final response = await _client.rpc('send_payment', params: {
      'p_sender_user_id': senderUserId,
      'p_amount_usd': amountUsd,
      'p_destination_type': destinationType,
      'p_destination_identifier': destinationIdentifier,
      'p_note': note,
    });
    
    if (response is List && response.isNotEmpty) {
      return response.first as Map<String, dynamic>;
    }
    return response is Map ? response as Map<String, dynamic> : {};
  }

  Future<Map<String, dynamic>> createLightningInvoice({
    required String userId,
    required double amountUsd,
    String? memo,
  }) async {
    final response = await _client.rpc('create_lightning_invoice', params: {
      'p_user_id': userId,
      'p_amount_usd': amountUsd,
      'p_memo': memo,
    });
    
    if (response is List && response.isNotEmpty) {
      return response.first as Map<String, dynamic>;
    }
    return response is Map ? response as Map<String, dynamic> : {};
  }

  Future<List<Map<String, dynamic>>> getTransactionHistory(String userId) async {
    final response = await _client.rpc('get_transaction_history', params: {
      'p_user_id': userId,
      'p_limit': 50,
    });
    return List<Map<String, dynamic>>.from(response as List);
  }

  Future<List<Map<String, dynamic>>> getPendingApprovals(String parentUserId) async {
    final response = await _client.rpc('get_pending_approvals', params: {
      'p_parent_user_id': parentUserId,
    });
    return List<Map<String, dynamic>>.from(response as List);
  }

  Future<void> approveTransaction(String parentUserId, String approvalId, bool approve) async {
    await _client.rpc('approve_child_transaction', params: {
      'p_parent_user_id': parentUserId,
      'p_pending_approval_id': approvalId,
      'p_approve': approve,
    });
  }
}
