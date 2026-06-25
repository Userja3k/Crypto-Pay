import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class KycUploadService {
  KycUploadService._internal();
  static final KycUploadService _instance = KycUploadService._internal();
  factory KycUploadService() => _instance;

  final _supabase = Supabase.instance.client;
  final _picker = ImagePicker();

  Future<File?> pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source, maxWidth: 1024, maxHeight: 1024, imageQuality: 80);
      if (image != null) return File(image.path);
      return null;
    } catch (e) {
      debugPrint('Erreur sélection image: $e');
      return null;
    }
  }

  Future<String?> uploadDocument({required String userId, required File file, required String documentType}) async {
    try {
      final filePath = '$userId/$documentType/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final res = await _supabase.storage.from('kyc-documents').upload(filePath, file);
      // Supabase client vX returns response/error differently; try to get public URL
      final url = _supabase.storage.from('kyc-documents').getPublicUrl(filePath);
      return url;
    } catch (e) {
      debugPrint('Erreur upload: $e');
      rethrow;
    }
  }

  Future<void> submitKyc({required String userId, required String documentType, required String documentUrl}) async {
    try {
      await _supabase.rpc('submit_kyc_document', params: {'p_user_id': userId, 'p_type': documentType, 'p_url': documentUrl});
    } catch (e) {
      debugPrint('Erreur soumission KYC: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getKycStatus(String userId) async {
    try {
      final response = await _supabase.rpc('get_kyc_status', params: {'p_user_id': userId});
      if (response is List && response.isNotEmpty) return response.first as Map<String, dynamic>;
      return {'level': 'none'};
    } catch (e) {
      return {'level': 'none'};
    }
  }
}
