import 'package:image_picker/image_picker.dart';
import 'server_upload_service.dart';

/// Keçid adapteri: Bütün köhnə Cloudinary çağırışlarını birbaşa İdrak serverinə yönləndirir.
/// Cloudinary və üçüncü tərəf servislər ləğv edilmişdir.
class CloudinaryService {
  static Future<String?> pickAndUploadFromCamera({
    String folder = 'idrak/profiles',
    int imageQuality = 85,
    double? maxWidth = 1200,
    double? maxHeight = 1200,
  }) async {
    return ServerUploadService.pickAndUploadFromCamera(
      imageQuality: imageQuality,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );
  }

  static Future<String?> pickAndUploadFromGallery({
    String folder = 'idrak/profiles',
    int imageQuality = 85,
    double? maxWidth = 1200,
    double? maxHeight = 1200,
  }) async {
    return ServerUploadService.pickAndUploadFromGallery(
      imageQuality: imageQuality,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );
  }

  static Future<List<String>> pickMultipleAndUpload({
    String folder = 'idrak/homework',
    int imageQuality = 80,
    double? maxWidth = 1600,
  }) async {
    return ServerUploadService.pickMultipleAndUpload(
      imageQuality: imageQuality,
      maxWidth: maxWidth,
    );
  }

  static Future<String?> uploadImage(XFile file) async {
    return ServerUploadService.uploadImage(file);
  }
}
