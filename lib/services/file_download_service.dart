import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'network/api_client.dart';

/// Faylların (PDF, Word, Excel və s.) birbaşa tətbiq daxilinə endirilməsi və native açılması servisi.
/// Veb səhifəyə və ya login-ə yönləndirmədən birbaşa cihazda açır.
class FileDownloadService {
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      followRedirects: true,
      maxRedirects: 5,
    ),
  );

  /// Faylı birbaşa tətbiq daxilində endirir və native PDF/sənəd oxuyucu ilə açır
  static Future<bool> downloadAndOpen(
    String rawUrl, {
    String? fileName,
    void Function(int received, int total)? onProgress,
  }) async {
    if (rawUrl.isEmpty) return false;
    final fullUrl = rawUrl.startsWith('http')
        ? rawUrl
        : 'https://new.idrak.edu.az/${rawUrl.startsWith('/') ? rawUrl.substring(1) : rawUrl}';

    try {
      if (kIsWeb) {
        return await launchUrl(Uri.parse(fullUrl), mode: LaunchMode.platformDefault);
      }

      // Fayl adını müəyyənləşdiririk
      String cleanName = fileName ?? '';
      if (cleanName.isEmpty) {
        final uri = Uri.tryParse(fullUrl);
        cleanName = uri?.pathSegments.isNotEmpty == true ? uri!.pathSegments.last : '';
      }
      if (cleanName.isEmpty || !cleanName.contains('.')) {
        cleanName = 'idrak_material_${DateTime.now().millisecondsSinceEpoch}.pdf';
      }

      // Xüsusi simvolları təmizləyirik
      cleanName = cleanName.replaceAll(RegExp(r'[^a-zA-Z0-9._\-]'), '_');

      final dir = await getTemporaryDirectory();
      final savePath = '${dir.path}/$cleanName';
      final file = File(savePath);

      // Əgər fayl artıq mövcuddursa və ölçüsü > 0-dırsa, birbaşa aç
      if (await file.exists() && await file.length() > 0) {
        final openResult = await OpenFilex.open(savePath);
        if (openResult.type == ResultType.done) {
          return true;
        }
      }

      // Bearer token əlavə edirik (lazım olduqda avtorizasiya üçün)
      final token = await ApiClient.instance.getToken();
      final headers = <String, dynamic>{
        'Accept': '*/*',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      // Dio ilə birbaşa cihaza endiririk
      await _dio.download(
        fullUrl,
        savePath,
        onReceiveProgress: onProgress,
        options: Options(
          headers: headers,
          responseType: ResponseType.bytes,
        ),
      );

      if (await file.exists() && await file.length() > 0) {
        final openResult = await OpenFilex.open(savePath);
        if (openResult.type == ResultType.done) {
          return true;
        }
        // Native açılmadısa xarici tətbiq / brauzer ilə yoxla
        return await launchUrl(Uri.parse(fullUrl), mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Endirilmiş fayl boşdur və ya yaradılmadı.');
      }
    } catch (e) {
      debugPrint('FileDownloadService xətası: $e');
      try {
        return await launchUrl(Uri.parse(fullUrl), mode: LaunchMode.externalApplication);
      } catch (_) {
        return false;
      }
    }
  }
}
