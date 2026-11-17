import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

/// İdrak liseyinin öz serverinə (/api/mobile/upload-photo) birbaşa şəkil yükləmə servisi.
/// Cloudinary və üçüncü tərəf servislər istifadə olunmur.
class ServerUploadService {
  static const String _uploadUrl = 'https://new.idrak.edu.az/api/mobile/upload-photo';
  static final ImagePicker _picker = ImagePicker();

  /// Kameradan foto çəkir və İdrak serverinə yükləyir
  static Future<String?> pickAndUploadFromCamera({
    int imageQuality = 85,
    double? maxWidth = 1200,
    double? maxHeight = 1200,
    String? modelType,
    int? modelId,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );
      if (image == null) return null;
      return await uploadImage(image, modelType: modelType, modelId: modelId);
    } catch (e) {
      debugPrint('ServerUploadService: Kameradan foto xətası: $e');
      return null;
    }
  }

  /// Qalereyadan foto seçir və İdrak serverinə yükləyir
  static Future<String?> pickAndUploadFromGallery({
    int imageQuality = 85,
    double? maxWidth = 1200,
    double? maxHeight = 1200,
    String? modelType,
    int? modelId,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );
      if (image == null) return null;
      return await uploadImage(image, modelType: modelType, modelId: modelId);
    } catch (e) {
      debugPrint('ServerUploadService: Qalereyadan foto xətası: $e');
      return null;
    }
  }

  /// Çoxsaylı foto seçir və yükləyir (ev tapşırıqları və sənədlər üçün)
  static Future<List<String>> pickMultipleAndUpload({
    int imageQuality = 80,
    double? maxWidth = 1600,
  }) async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: imageQuality,
        maxWidth: maxWidth,
      );
      if (images.isEmpty) return [];

      final List<String> urls = [];
      for (final image in images) {
        final url = await uploadImage(image);
        if (url != null) urls.add(url);
      }
      return urls;
    } catch (e) {
      debugPrint('ServerUploadService: Çoxlu foto yükləmə xətası: $e');
      return [];
    }
  }

  /// XFile faylını İdrak serverinə POST multipart kimi göndərir
  static Future<String?> uploadImage(
    XFile file, {
    String? modelType,
    int? modelId,
  }) async {
    try {
      final uri = Uri.parse(_uploadUrl);
      final request = http.MultipartRequest('POST', uri);
      request.headers['Accept'] = 'application/json';

      if (modelType != null) request.fields['model_type'] = modelType;
      if (modelId != null) request.fields['model_id'] = modelId.toString();

      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'photo',
          bytes,
          filename: file.name.isNotEmpty ? file.name : 'upload_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath(
          'photo',
          file.path,
          filename: file.name.isNotEmpty ? file.name : 'upload_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data is Map && data['success'] == true && data['url'] != null) {
          final url = data['url'] as String;
          debugPrint('ServerUploadService: Uğurla yükləndi → $url');
          return url;
        }
      }
      debugPrint('ServerUploadService: Yükləmə uğursuz oldu: ${response.statusCode} ${response.body}');
      return null;
    } catch (e) {
      debugPrint('ServerUploadService: Xəta: $e');
      return null;
    }
  }
}
