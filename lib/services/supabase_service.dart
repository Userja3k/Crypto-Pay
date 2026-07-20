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
    String? userRole,
    String? parentId,
  }) async {
    final response = await _client.rpc(
      'register_user',
      params: {
        'p_email': email,
        'p_phone': phone,
        'p_full_name': fullName,
        'p_birth_date': birthDate.toIso8601String(),
        'p_pin_hash': pinHash,
        'p_pin_salt': pinSalt,
        'p_referral_code': referralCode,
        'p_user_role': userRole,
        'p_parent_id': parentId,
      },
    );

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
    final response = await _client.rpc(
      'create_child_account',
      params: {
        'p_parent_user_id': parentUserId,
        'p_child_full_name': childFullName,
        'p_child_birth_date': childBirthDate.toIso8601String(),
        'p_max_per_transaction_usd': maxPerTransaction,
        'p_max_per_day_usd': maxPerDay,
        'p_max_per_month_usd': maxPerMonth,
      },
    );

    if (response is List && response.isNotEmpty) {
      return response.first as Map<String, dynamic>;
    }
    return response is Map ? response as Map<String, dynamic> : {};
  }

  Future<String?> getUserSalt(String identifier) async {
    final response = await _client.rpc(
      'get_user_salt',
      params: {'p_identifier': identifier},
    );
    return response as String?;
  }

  Future<Map<String, dynamic>> verifyLogin({
    required String identifier,
    required String pinHash,
  }) async {
    final response = await _client.rpc(
      'verify_login',
      params: {'p_identifier': identifier, 'p_pin_hash': pinHash},
    );

    if (response is List && response.isNotEmpty) {
      return response.first as Map<String, dynamic>;
    }
    return response is Map ? response as Map<String, dynamic> : {};
  }

  Future<Map<String, dynamic>> getBalance(String userId) async {
    final response = await _client.rpc(
      'get_balance',
      params: {'p_user_id': userId},
    );
    if (response is List && response.isNotEmpty) {
      return response.first as Map<String, dynamic>;
    }
    return {};
  }

  Future<List<Map<String, dynamic>>> searchUsers(String searchTerm) async {
    final response = await _client.rpc(
      'search_users',
      params: {'p_search_term': searchTerm, 'p_limit': 10},
    );
    return List<Map<String, dynamic>>.from(response as List);
  }

  Future<Map<String, dynamic>> sendPayment({
    required String senderUserId,
    required double amountUsd,
    required String destinationType,
    required String destinationIdentifier,
    String? note,
  }) async {
    final response = await _client.rpc(
      'send_payment',
      params: {
        'p_sender_user_id': senderUserId,
        'p_amount_usd': amountUsd,
        'p_destination_type': destinationType,
        'p_destination_identifier': destinationIdentifier,
        'p_note': note,
      },
    );

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
    final response = await _client.rpc(
      'create_lightning_invoice',
      params: {'p_user_id': userId, 'p_amount_usd': amountUsd, 'p_memo': memo},
    );

    if (response is List && response.isNotEmpty) {
      return response.first as Map<String, dynamic>;
    }
    return response is Map ? response as Map<String, dynamic> : {};
  }

  Future<Map<String, dynamic>> recordPendingInvoice({
    required String userId,
    required double amountUsd,
    required int amountSats,
    required String bolt11,
    String? paymentHash,
    String? note,
  }) async {
    // Find account id
    final accountResp = await _client
        .from('accounts')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();
    final accountId = accountResp == null
        ? null
        : (accountResp as Map)['id'] as String?;
    if (accountId == null) {
      return {'status': 'failed', 'message': 'Account not found'};
    }

    final insertResp = await _client
        .from('transactions')
        .insert({
          'account_id': accountId,
          'transaction_type': 'receive',
          'amount_usd': amountUsd,
          'amount_sats': amountSats,
          'lightning_bolt11': bolt11,
          'lightning_payment_hash': paymentHash,
          'note': note,
          'status': 'pending',
        })
        .select()
        .maybeSingle();

    if (insertResp == null) {
      return {'status': 'failed', 'message': 'Insert failed'};
    }
    return {'status': 'ok', 'transaction': insertResp};
  }

  Future<List<Map<String, dynamic>>> getNotifications(String userId) async {
    final response = await _client.rpc(
      'get_notifications',
      params: {'p_user_id': userId, 'p_limit': 50},
    );
    return List<Map<String, dynamic>>.from(response as List? ?? []);
  }

  Future<Map<String, dynamic>> recordNfcPayment({
    required String userId,
    required int amountSats,
    required String bolt11,
    String? paymentHash,
    String? counterpartyId,
    String? note,
  }) async {
    final response = await _client.rpc(
      'record_nfc_payment',
      params: {
        'p_user_id': userId,
        'p_amount_sats': amountSats,
        'p_bolt11': bolt11,
        'p_payment_hash': paymentHash,
        'p_counterparty_id': counterpartyId,
        'p_note': note,
      },
    );
    if (response is List && response.isNotEmpty) {
      return response.first as Map<String, dynamic>;
    }
    return response is Map ? response as Map<String, dynamic> : {};
  }

  Future<Map<String, dynamic>> recordBluetoothPayment({
    required String userId,
    required int amountSats,
    required String bolt11,
    String? paymentHash,
    String? counterpartyId,
    String? note,
  }) async {
    final response = await _client.rpc(
      'record_bluetooth_payment',
      params: {
        'p_user_id': userId,
        'p_amount_sats': amountSats,
        'p_bolt11': bolt11,
        'p_payment_hash': paymentHash,
        'p_counterparty_id': counterpartyId,
        'p_note': note,
      },
    );
    if (response is List && response.isNotEmpty) {
      return response.first as Map<String, dynamic>;
    }
    return response is Map ? response as Map<String, dynamic> : {};
  }

  Future<Map<String, dynamic>> depositFunds({
    required String userId,
    required double amountUsd,
    String? note,
  }) async {
    final response = await _client.rpc(
      'deposit_funds',
      params: {'p_user_id': userId, 'p_amount_usd': amountUsd, 'p_note': note},
    );

    if (response is List && response.isNotEmpty) {
      return response.first as Map<String, dynamic>;
    }
    return response is Map ? response as Map<String, dynamic> : {};
  }

  Future<List<Map<String, dynamic>>> getTransactionHistory(
    String userId,
  ) async {
    final response = await _client.rpc(
      'get_transaction_history',
      params: {'p_user_id': userId, 'p_limit': 50},
    );
    return List<Map<String, dynamic>>.from(response as List);
  }

  Future<List<Map<String, dynamic>>> getPendingApprovals(
    String parentUserId,
  ) async {
    final response = await _client.rpc(
      'get_pending_approvals',
      params: {'p_parent_user_id': parentUserId},
    );
    return List<Map<String, dynamic>>.from(response as List);
  }

  Future<void> approveTransaction(
    String parentUserId,
    String approvalId,
    bool approve,
  ) async {
    await _client.rpc(
      'approve_child_transaction',
      params: {
        'p_parent_user_id': parentUserId,
        'p_pending_approval_id': approvalId,
        'p_approve': approve,
      },
    );
  }

  Future<Map<String, dynamic>> getReferralInfo(String userId) async {
    final response = await _client.rpc(
      'get_referral_info',
      params: {'p_user_id': userId},
    );

    if (response is List && response.isNotEmpty) {
      return response.first as Map<String, dynamic>;
    }
    return response is Map ? response as Map<String, dynamic> : {};
  }

  Future<List<Map<String, dynamic>>> listReferredUsers(String userId) async {
    final response = await _client.rpc(
      'list_referred_users',
      params: {'p_user_id': userId},
    );
    return List<Map<String, dynamic>>.from(response as List);
  }

  Future<bool> claimReferralBonus(String referredUserId) async {
    final response = await _client.rpc(
      'claim_referral_bonus',
      params: {'p_referred_user_id': referredUserId},
    );
    return response as bool? ?? false;
  }

  Future<Map<String, dynamic>> createLnurlPay({
    required String userId,
    int? fixedAmountSats,
    String? description,
    bool requiresComment = false,
    int expiresInDays = 365,
  }) async {
    final response = await _client.rpc(
      'create_lnurl_pay',
      params: {
        'p_user_id': userId,
        'p_fixed_amount_sats': fixedAmountSats,
        'p_description': description,
        'p_requires_comment': requiresComment,
        'p_expires_in_days': expiresInDays,
      },
    );

    if (response is List && response.isNotEmpty) {
      return response.first as Map<String, dynamic>;
    }
    return response is Map ? response as Map<String, dynamic> : {};
  }

  Future<Map<String, dynamic>> redeemLnurlWithdraw({
    required String lnurlSecret,
    required int amountSats,
  }) async {
    final response = await _client.rpc(
      'redeem_lnurl_withdraw',
      params: {'p_lnurl_secret': lnurlSecret, 'p_amount_sats': amountSats},
    );

    if (response is List && response.isNotEmpty) {
      return response.first as Map<String, dynamic>;
    }
    return response is Map ? response as Map<String, dynamic> : {};
  }

  Future<bool> sendChildInvitation({
    required String parentUserId,
    required String childUserId,
    required String invitationCode,
  }) async {
    final response = await _client.rpc(
      'send_child_invitation',
      params: {
        'p_parent_user_id': parentUserId,
        'p_child_user_id': childUserId,
        'p_invitation_code': invitationCode,
      },
    );
    return response as bool? ?? false;
  }

  Future<Map<String, dynamic>> activateChildWithCode({
    required String childUserId,
    required String invitationCode,
    required String email,
    required String phone,
    required String pinHash,
    required String pinSalt,
  }) async {
    final response = await _client.rpc(
      'activate_child_with_code',
      params: {
        'p_child_user_id': childUserId,
        'p_invitation_code': invitationCode,
        'p_email': email,
        'p_phone': phone,
        'p_pin_hash': pinHash,
        'p_pin_salt': pinSalt,
      },
    );

    if (response is List && response.isNotEmpty) {
      return response.first as Map<String, dynamic>;
    }
    return response is Map ? response as Map<String, dynamic> : {};
  }

  Future<Map<String, dynamic>> getUser(String userId) async {
    final response = await _client
        .from('users')
        .select('full_name, email, phone')
        .eq('id', userId)
        .single();
    return response;
  }

  Future<bool> changePin({
    required String userId,
    required String oldPinHash,
    required String newPinHash,
  }) async {
    final response = await _client.rpc(
      'change_pin',
      params: {
        'p_user_id': userId,
        'p_old_pin_hash': oldPinHash,
        'p_new_pin_hash': newPinHash,
      },
    );
    return response as bool? ?? false;
  }

  // ════════════════════════════════════════════════════════════
  // LNURL
  // ════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> createLnurlWithdraw({
    required String userId,
    int? amountSats,
    String? description,
    int expiresInHours = 24,
  }) async {
    final response = await _client.rpc(
      'create_lnurl_withdraw',
      params: {
        'p_user_id': userId,
        'p_amount_sats': amountSats,
        'p_description': description,
        'p_expires_in_hours': expiresInHours,
      },
    );

    if (response is List && response.isNotEmpty) {
      return response.first as Map<String, dynamic>;
    }
    return response is Map ? response as Map<String, dynamic> : {};
  }
}
