import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class KycState {
  final bool isLoading;
  final String? documentUrl;
  final String? error;
  final KycStatus status;

  const KycState({this.isLoading = false, this.documentUrl, this.error, this.status = KycStatus.idle});

  KycState copyWith({bool? isLoading, String? documentUrl, String? error, KycStatus? status}) {
    return KycState(
      isLoading: isLoading ?? this.isLoading,
      documentUrl: documentUrl ?? this.documentUrl,
      error: error ?? this.error,
      status: status ?? this.status,
    );
  }
}

enum KycStatus { idle, uploading, submitted, verified, rejected }

class KycNotifier extends StateNotifier<KycState> {
  final SupabaseClient _supabase;
  KycNotifier(this._supabase) : super(const KycState());

  Future<void> uploadDocument({required String userId, required String documentType, required String filePath}) async {
    state = state.copyWith(isLoading: true, status: KycStatus.uploading);
    try {
      // This provider relies on services/kyc_upload_service for actual pick/upload.
      await Future.delayed(const Duration(milliseconds: 400));
      state = state.copyWith(isLoading: false, status: KycStatus.submitted, documentUrl: filePath);
    } catch (e) {
      state = state.copyWith(isLoading: false, status: KycStatus.rejected, error: e.toString());
    }
  }

  Future<void> checkStatus(String userId) async {
    try {
      final response = await _supabase.rpc('get_kyc_status', params: {'p_user_id': userId});
      if (response is List && response.isNotEmpty) {
        final data = response.first as Map<String, dynamic>;
        final level = data['level'] as String;
        if (level == 'verified') state = state.copyWith(status: KycStatus.verified);
        else if (level == 'basic') state = state.copyWith(status: KycStatus.submitted);
      }
    } catch (_) {}
  }

  void reset() => state = const KycState();
}

final kycProvider = StateNotifierProvider<KycNotifier, KycState>((ref) {
  return KycNotifier(Supabase.instance.client);
});
