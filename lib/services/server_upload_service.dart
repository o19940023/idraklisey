import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'network/api_client.dart';

/// İdrak liseyinin öz serverinə (/api/mobile/v1/upload və /api/mobile/upload-photo)
/// foto, PDF və sənədlərin birbaşa yüklənməsi servisi.
/// Cloudinary və üçüncü tərəf servislər qətiyyən istifadə olunmur.
class ServerUploadService {
  static const String _uploadUrl = 'https://new.idrak.edu.az/api/mobile/v1/upload';
  static const String _fallbackUploadUrl = 'https://new.idrak.edu.az/api/mobile/upload-photo';
  static final ImagePicker _picker = ImagePicker();

  static Future<Map<String, String>> _buildHeaders() async {
    final headers = <String, String>{
      'Accept': 'application/json',
    };
    final token = await ApiClient.instance.getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Kameradan foto çəkir və İdrak serverinə yükləyir
  static Future<String?> pickAndUploadFromCamera({
    int imageQuality = 85,
    double? maxWidth = 1600,
    double? maxHeight = 1600,
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
    double? maxWidth = 1600,
    double? maxHeight = 1600,
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
        final url = await uploadImage(image, modelType: 'assignment_submission');
        if (url != null) urls.add(url);
      }
      return urls;
    } catch (e) {
      debugPrint('ServerUploadService: Çoxlu foto yükləmə xətası: $e');
      return [];
    }
  }

  /// Fayl seçici (PDF, Word, Excel, PPTX, Şəkillər) vasitəsilə sənəd seçib serverə yükləyir
  static Future<List<Map<String, dynamic>>> pickDocumentsAndUpload({
    String? modelType = 'assignment_submission',
    int? modelId,
  }) async {
    try {
      final List<PlatformFile> files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'doc',
          'docx',
          'xls',
          'xlsx',
          'ppt',
          'pptx',
          'txt',
          'zip',
          'jpg',
          'jpeg',
          'png'
        ],
      );

      if (files.isEmpty) return [];

      final List<Map<String, dynamic>> uploadedList = [];
      for (final pFile in files) {
        final uploaded = await uploadPlatformFile(pFile, modelType: modelType, modelId: modelId);
        if (uploaded != null) {
          uploadedList.add(uploaded);
        }
      }
      return uploadedList;
    } catch (e) {
      debugPrint('ServerUploadService: Sənəd seçmə/yükləmə xətası: $e');
      return [];
    }
  }

  /// PlatformFile (sənəd/fayl) İdrak serverinə POST multipart kimi göndərir
  static Future<Map<String, dynamic>?> uploadPlatformFile(
    PlatformFile file, {
    String? modelType,
    int? modelId,
  }) async {
    final headers = await _buildHeaders();
    final bytes = await file.readAsBytes();
    final fileName = file.name;
    final fileExt = file.extension ?? 'file';

    for (final endpoint in [_uploadUrl, _fallbackUploadUrl]) {
      try {
        final uri = Uri.parse(endpoint);
        final request = http.MultipartRequest('POST', uri);
        request.headers.addAll(headers);

        if (modelType != null) {
          request.fields['model_type'] = modelType;
          request.fields['folder'] = modelType;
        }
        if (modelId != null) request.fields['model_id'] = modelId.toString();

        request.files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
        ));

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final data = jsonDecode(response.body);
          if (data is Map && data['success'] == true && data['url'] != null) {
            final url = data['url'].toString();
            debugPrint('ServerUploadService: Fayl yükləndi → $url');
            return {
              'url': url,
              'name': data['name'] ?? fileName,
              'size': data['size'] ?? bytes.length,
              'ext': data['ext'] ?? fileExt,
              'is_image': (data['mime']?.toString().startsWith('image/') == true) ||
                  ['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(fileExt.toLowerCase()),
            };
          }
        }
      } catch (e) {
        debugPrint('ServerUploadService endpoint $endpoint xətası: $e');
      }
    }
    return null;
  }

  /// XFile faylını İdrak serverinə POST multipart kimi göndərir
  static Future<String?> uploadImage(
    XFile file, {
    String? modelType,
    int? modelId,
  }) async {
    final headers = await _buildHeaders();
    for (final endpoint in [_uploadUrl, _fallbackUploadUrl]) {
      try {
        final uri = Uri.parse(endpoint);
        final request = http.MultipartRequest('POST', uri);
        request.headers.addAll(headers);

        if (modelType != null) {
          request.fields['model_type'] = modelType;
          request.fields['folder'] = modelType;
        }
        if (modelId != null) request.fields['model_id'] = modelId.toString();

        if (kIsWeb) {
          final bytes = await file.readAsBytes();
          request.files.add(http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: file.name.isNotEmpty ? file.name : 'upload_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ));
        } else {
          request.files.add(await http.MultipartFile.fromPath(
            'file',
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
      } catch (e) {
        debugPrint('ServerUploadService: $endpoint xətası: $e');
      }
    }
    return null;
  }
}
