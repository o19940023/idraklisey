import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/rich_html_view.dart';
import '../../../providers/app_state.dart';
import '../../../data/models/assignment_model.dart';
import '../../../services/server_upload_service.dart';
import '../../../l10n/app_localizations.dart';

class HomeworkSubmissionScreen extends StatefulWidget {
  final HomeworkAssignment assignment;

  const HomeworkSubmissionScreen({super.key, required this.assignment});

  @override
  State<HomeworkSubmissionScreen> createState() => _HomeworkSubmissionScreenState();
}

class _HomeworkSubmissionScreenState extends State<HomeworkSubmissionScreen> {
  final TextEditingController _noteController = TextEditingController();
  final List<String> _capturedPages = [];
  bool _isSubmitting = false;
  bool _isCapturing = false;
  bool _isEditingSubmission = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _showImageDialog(BuildContext context, String url, String title) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: InteractiveViewer(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    padding: const EdgeInsets.all(24),
                    color: Colors.white,
                    child: Text('Şəkil yüklənə bilmədi', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAttachment(String rawUrl, {String? fileName}) async {
    if (rawUrl.isEmpty) return;
    final fullUrl = rawUrl.startsWith('http')
        ? rawUrl
        : 'https://new.idrak.edu.az/${rawUrl.startsWith('/') ? rawUrl.substring(1) : rawUrl}';
    try {
      final uri = Uri.parse(fullUrl);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${fileName ?? "Fayl"} açıla bilmədi ($fullUrl)')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fayl açıla bilmədi: $e')),
        );
      }
    }
  }

  Future<void> _captureFromCamera() async {
    setState(() => _isCapturing = true);
    final url = await ServerUploadService.pickAndUploadFromCamera(
      imageQuality: 85,
      maxWidth: 1600,
      maxHeight: 1600,
      modelType: 'assignment_submission',
    );
    if (mounted) {
      setState(() => _isCapturing = false);
      if (url != null) {
        setState(() => _capturedPages.add(url));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_capturedPages.length}-ci dəftər səhifəsi serverə yükləndi!'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    setState(() => _isCapturing = true);
    final urls = await ServerUploadService.pickMultipleAndUpload(
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (mounted) {
      setState(() {
        _isCapturing = false;
        _capturedPages.addAll(urls);
      });
      if (urls.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${urls.length} fayl serverə yükləndi!'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final appState = Provider.of<AppState>(context);
    final currentStudent = appState.student;
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    final mySubmission = widget.assignment.getSubmissionForStudent(currentStudent.id);
    final isAlreadySubmitted = mySubmission != null;
    final isGraded = mySubmission?.score != null;
    final isPastDue = widget.assignment.isOverdueForStudent(currentStudent.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          isAlreadySubmitted ? (isGraded ? 'Tapşırıq Qiymətləndirməsi' : 'Tapşırıq Təfərrüatları') : loc.submitHomework,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Assignment Header Info Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppShadows.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      StatusBadge(
                        label: widget.assignment.subject,
                        color: AppColors.primaryAccent,
                        backgroundColor: Colors.white12,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: isPastDue
                              ? Colors.red.withValues(alpha: 0.8)
                              : Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Son: ${dateFormat.format(widget.assignment.dueDate)}',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.assignment.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person_outline_rounded, color: AppColors.primaryAccent, size: 15),
                          const SizedBox(width: 5),
                          Text(
                            'Müəllim: ${widget.assignment.teacherName}',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                      Text(
                        'Şagird: ${currentStudent.fullName}',
                        style: const TextStyle(color: AppColors.primaryAccent, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Teacher Instructions Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
                boxShadow: AppShadows.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.assignment_outlined, color: AppColors.primaryAccent, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        loc.assignmentDescription,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  RichHtmlView(
                    html: widget.assignment.instructions,
                  ),

                  // Multiple Teacher Attachments Support
                  if (widget.assignment.attachments.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.attach_file_rounded, size: 16, color: AppColors.primaryAccent),
                        const SizedBox(width: 6),
                        Text(
                          'Müəllim Resursları və Faylları (${widget.assignment.attachments.length}):',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...widget.assignment.attachments.map((att) {
                      final name = att['name']?.toString() ?? 'Fayl';
                      final url = att['url']?.toString() ?? '';
                      final isImage = att['is_image'] == true ||
                          name.endsWith('.png') ||
                          name.endsWith('.jpg') ||
                          name.endsWith('.jpeg') ||
                          name.endsWith('.webp');
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryAccent.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primaryAccent.withValues(alpha: 0.18)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isImage ? Icons.image_rounded : Icons.picture_as_pdf_rounded,
                              color: isImage ? AppColors.primaryAccent : Colors.red,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                  ),
                                  Text(
                                    isImage ? 'Dərs tapşırığı şəkli' : 'Dərs materialı və vəsait',
                                    style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                if (isImage && url.isNotEmpty) {
                                  _showImageDialog(context, url, name);
                                } else {
                                  _openAttachment(url, fileName: name);
                                }
                              },
                              icon: Icon(isImage ? Icons.fullscreen_rounded : Icons.open_in_new_rounded, size: 15),
                              label: Text(isImage ? 'Bax' : 'Aç / Endir', style: const TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      );
                    }),
                  ] else if (widget.assignment.attachmentDocUrl != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryAccent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.primaryAccent.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.picture_as_pdf_rounded, color: Colors.red, size: 24),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.assignment.attachmentDocUrl!,
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                ),
                                Text('Dərs vəsaiti & Təlimat', style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _openAttachment(widget.assignment.attachmentDocUrl!, fileName: 'Dərs vəsaiti'),
                            icon: const Icon(Icons.open_in_new_rounded, size: 15),
                            label: const Text('Aç / Endir', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Submission or Review Area (Personal to this Student)
            if (isAlreadySubmitted && !_isEditingSubmission) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isGraded ? const Color(0xFF1A73E8) : AppColors.success.withValues(alpha: 0.5),
                    width: isGraded ? 2 : 1.5,
                  ),
                  boxShadow: AppShadows.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isGraded) ...[
                      // High-end Teacher Evaluation Banner (Google Classroom style)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE8F0FE), Colors.white],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF1A73E8).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: const BoxDecoration(
                                color: Color(0xFF1A73E8),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.star_rounded, color: Colors.white, size: 26),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'MÜƏLLİM QİYMƏTLƏNDİRMƏSİ',
                                    style: const TextStyle(
                                      color: Color(0xFF1A73E8),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${mySubmission.score?.toStringAsFixed(mySubmission.score! % 1 == 0 ? 0 : 1) ?? "100"} / ${widget.assignment.maxScore.toInt()}',
                                    style: const TextStyle(
                                      color: Color(0xFF1A73E8),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 22,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (mySubmission.teacherComment != null && mySubmission.teacherComment!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text('Müəllim Rəyi:', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
                        const SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE8EAED)),
                          ),
                          child: Text(
                            mySubmission.teacherComment!,
                            style: const TextStyle(fontSize: 13, height: 1.45, fontStyle: FontStyle.italic, color: Color(0xFF3C4043)),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                    ],

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isGraded ? Icons.verified_rounded : Icons.check_circle_rounded,
                              color: isGraded ? const Color(0xFF1A73E8) : AppColors.success,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isGraded ? 'Yoxlanıldı' : loc.submitted,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: isGraded ? const Color(0xFF1A73E8) : AppColors.success,
                              ),
                            ),
                          ],
                        ),
                        if (!isGraded && !isPastDue)
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _isEditingSubmission = true;
                                _noteController.text = mySubmission.studentNote ?? '';
                                _capturedPages.clear();
                                _capturedPages.addAll(mySubmission.scannedImages);
                              });
                            },
                            icon: const Icon(Icons.edit_rounded, size: 14),
                            label: const Text('Yenilə', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Təhvil tarixi: ${dateFormat.format(mySubmission.submittedAt)}',
                      style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                    ),

                    if (mySubmission.studentNote != null && mySubmission.studentNote!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Sizin cavabınız: "${mySubmission.studentNote}"',
                        style: TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.4),
                      ),
                    ],

                    if (mySubmission.scannedImages.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text('Təhvil verilmiş fayllar / səhifələr (${mySubmission.scannedImages.length}):',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 90,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: mySubmission.scannedImages.length,
                          itemBuilder: (context, idx) {
                            final imgUrl = mySubmission.scannedImages[idx];
                            return GestureDetector(
                              onTap: () => _showImageDialog(context, imgUrl, 'Səhifə ${idx + 1}'),
                              child: Container(
                                width: 75,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.cardBorder),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(9),
                                  child: Image.network(
                                    imgUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Center(
                                      child: Icon(Icons.insert_drive_file_rounded, color: AppColors.primaryAccent),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],

                    if (!isGraded) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.hourglass_empty_rounded, color: AppColors.warning, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Tapşırığınız qəbul edildi. Müəllim yoxladıqdan sonra qiymət və rəy burada görünəcək.',
                                style: TextStyle(fontSize: 11.5, color: AppColors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ] else if (!isAlreadySubmitted && isPastDue) ...[
              // Past Due Notice
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF7E0),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF9AB00)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFB85E00), size: 26),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Son təhvil vermə tarixi bitib',
                            style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFB85E00), fontSize: 13.5),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Bu tapşırığın son təhvil tarixi (${dateFormat.format(widget.assignment.dueDate)}) keçdiyi üçün yeni cavab qəbul olunmur.',
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF5F6368)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Submission Section (Camera, Gallery, Written answer)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                  boxShadow: AppShadows.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.send_rounded, color: AppColors.primaryAccent, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _isEditingSubmission ? 'Tapşırığı Yenilə' : 'Tapşırığı Yerinə Yetir',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cavabınızı mətn şəklində yaza və ya dəftərinizin şəkillərini əlavə edərək təhvil verə bilərsiniz.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 14),

                    // Student Written Answer Input
                    TextField(
                      controller: _noteController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Cavabınız / Həll yolu',
                        hintText: 'Cavabınızı buraya yazın (məsələn: 1-ci sualın həlli: ...)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Scanned Pages Gallery
                    if (_capturedPages.isNotEmpty) ...[
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _capturedPages.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                Container(
                                  width: 80,
                                  margin: const EdgeInsets.only(right: 10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.primaryAccent, width: 1.5),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10.5),
                                    child: Image.network(_capturedPages[index], fit: BoxFit.cover),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  left: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.black87,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Səh ${index + 1}',
                                      style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 2,
                                  right: 12,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _capturedPages.removeAt(index);
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, color: Colors.white, size: 12),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Camera & Gallery Buttons
                    if (_isCapturing)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Center(
                          child: Column(
                            children: [
                              const CircularProgressIndicator(color: AppColors.primaryAccent, strokeWidth: 2),
                              const SizedBox(height: 8),
                              Text(loc.loading, style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              onPressed: _captureFromCamera,
                              icon: const Icon(Icons.photo_camera_outlined, size: 16),
                              label: Text(_capturedPages.isEmpty ? 'Kamera ilə Çək' : '+ Səhifə Çək', style: const TextStyle(fontSize: 11.5)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              onPressed: _pickFromGallery,
                              icon: const Icon(Icons.photo_library_outlined, size: 16),
                              label: const Text('Qalereyadan Seç', style: TextStyle(fontSize: 11.5)),
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 18),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: (_capturedPages.isEmpty && _noteController.text.trim().isEmpty) || _isSubmitting
                            ? null
                            : () async {
                                setState(() => _isSubmitting = true);
                                final ok = await appState.submitHomework(
                                  assignmentId: widget.assignment.id,
                                  studentId: currentStudent.id,
                                  studentName: currentStudent.fullName,
                                  images: _capturedPages,
                                  note: _noteController.text.trim(),
                                );
                                if (!mounted) return;
                                setState(() => _isSubmitting = false);
                                if (ok) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(loc.successfullySaved),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                  Navigator.pop(context);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(loc.error),
                                      backgroundColor: AppColors.danger,
                                    ),
                                  );
                                }
                              },
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.send_rounded, size: 18),
                        label: Text(
                          _isSubmitting
                              ? loc.loading
                              : (_isEditingSubmission ? 'Yenilənmiş Cavabı Göndər' : 'Tapşırığı Təhvil Ver'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
