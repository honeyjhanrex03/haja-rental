import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/env.dart';

class CloudinaryService {
  final String cloudName = Env.cloudinaryCloudName; 
  final String uploadPreset = Env.cloudinaryUploadPreset; 

  Future<String?> uploadImage(Uint8List bytes, String fileName) async {
    final url = 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';
    
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: fileName),
        'upload_preset': uploadPreset,
      });

      final response = await Dio().post(url, data: formData);

      if (response.statusCode == 200) {
        return response.data['secure_url'] as String;
      }
    } catch (e) {
      debugPrint('Cloudinary Upload Error: $e');
    }
    return null;
  }
}

final cloudinaryServiceProvider = Provider((ref) => CloudinaryService());
