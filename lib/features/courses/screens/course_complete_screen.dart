import 'package:flutter/material.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import 'package:karakana_app/widgets/common/karakana_wave_loader.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import 'package:printing/printing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import 'package:share_plus/share_plus.dart' show Share;
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/common/top_popup.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../utils/certificate_pdf_generator.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class CourseCompleteScreen extends StatefulWidget {
  final int courseId;
  final String courseTitle;

  const CourseCompleteScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  @override
  State<CourseCompleteScreen> createState() => _CourseCompleteScreenState();
}

class _CourseCompleteScreenState extends State<CourseCompleteScreen> {
  Map<String, dynamic>? _certificate;
  bool _isRequestingCert = true;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _requestCertificate());
  }

  Future<void> _requestCertificate() async {
    try {
      final res = await ApiClient().dio.post(
        '/api/v1/certificates/',
        data: {'course_id': widget.courseId},
      );
      if (!mounted) return;
      setState(() {
        _certificate = Map<String, dynamic>.from(res.data as Map);
        _isRequestingCert = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isRequestingCert = false);
    }
  }

  Future<void> _downloadCertificate(AuthProvider auth) async {
    setState(() => _isDownloading = true);
    try {
      final cert = _certificate;
      final issuedAt = cert != null && cert['issued_at'] != null
          ? DateTime.tryParse(cert['issued_at'].toString()) ?? DateTime.now()
          : DateTime.now();
      final certNumber = cert?['certificate_number']?.toString() ?? '';
      final excerpt = cert?['course_excerpt']?.toString() ?? '';

      final doc = await CertificatePdfGenerator.generate(
        studentName: auth.userFullName,
        courseTitle: widget.courseTitle,
        courseExcerpt: excerpt,
        issuedAt: issuedAt,
        certificateNumber: certNumber.isNotEmpty ? certNumber : 'KARAKANA',
      );
      final bytes = await doc.save();

      if (!mounted) return;
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: 'Cheti — ${widget.courseTitle}',
      );
    } catch (e) {
      if (!mounted) return;
      showTopPopup(context, 'Hitilafu ya kupakua cheti: $e');
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Consumer<AuthProvider>(
            builder: (_, auth, __) => Column(
              children: [
                const SizedBox(height: AppSpacing.xl),
                // Trophy icon
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE87722),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE87722).withValues(alpha: 0.4),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.emoji_events,
                      color: Colors.white,
                      size: 52,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Hongera!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF3D1800),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Umekamilisha kozi kwa mafanikio!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3D1800),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.courseTitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: AppTextStyles.h4.fontSize,
                    color: const Color(0xFFE87722),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                // Certificate preview card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFF8F4), Color(0xFFFFF0E6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFE87722).withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1FC4620A),
                        blurRadius: 20,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE87722),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                'K',
                                style: GoogleFonts.montserrat(
                                  fontSize: AppTextStyles.bodyLarge.fontSize,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'KARAKANA',
                                style: GoogleFonts.montserrat(
                                  fontSize: AppTextStyles.bodySmall.fontSize,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF3D1800),
                                  letterSpacing: 2,
                                ),
                              ),
                              Text(
                                'Cheti cha Ukamilishaji',
                                style: GoogleFonts.montserrat(
                                  fontSize: AppTextStyles.labelSmall.fontSize,
                                  color: const Color(0xFF9E8070),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Divider(
                        color: const Color(0xFFE87722).withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Hii inathibitisha kwamba',
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          color: const Color(0xFF9E8070),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        auth.userFullName,
                        style: GoogleFonts.montserrat(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF3D1800),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'amekamilisha kwa mafanikio kozi ya',
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          color: const Color(0xFF9E8070),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        widget.courseTitle,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          fontSize: AppTextStyles.bodyLarge.fontSize,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFE87722),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Cheti hiki kinatambua kujituma, uelewa wa kina, na uwezo wa kutumia maarifa ya kozi katika vitendo vya kazi na biashara.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          fontSize: 11.5,
                          height: 1.45,
                          color: const Color(0xFF9E8070),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _certificate != null &&
                                _certificate!['issued_at'] != null
                            ? DateFormat('d MMMM yyyy').format(
                                DateTime.tryParse(
                                      _certificate!['issued_at'].toString(),
                                    )?.toLocal() ??
                                    DateTime.now(),
                              )
                            : DateFormat('d MMMM yyyy').format(DateTime.now()),
                        style: GoogleFonts.montserrat(
                          fontSize: AppTextStyles.bodySmall.fontSize,
                          color: const Color(0xFF9E8070),
                        ),
                      ),
                      if (_certificate != null &&
                          _certificate!['certificate_number'] != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          'No. ${_certificate!['certificate_number'].toString().toUpperCase().replaceAll('-', '').substring(0, 10)}',
                          style: GoogleFonts.montserrat(
                            fontSize: AppTextStyles.labelSmall.fontSize,
                            letterSpacing: 1.5,
                            color: const Color(0xFF9E8070),
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      Divider(
                        color: const Color(0xFFE87722).withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Imetolewa na Kreative Karakana',
                        style: GoogleFonts.montserrat(
                          fontSize: AppTextStyles.caption.fontSize,
                          color: const Color(0xFFBDA99C),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                // Download PDF button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: _isRequestingCert || _isDownloading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: KarakanaWaveLoader(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.download_outlined),
                    label: Text(
                      _isRequestingCert
                          ? 'Inaandaa cheti...'
                          : _isDownloading
                              ? 'Inapakua...'
                              : 'Pakua Cheti (PDF)',
                      style: GoogleFonts.montserrat(
                        fontSize: AppTextStyles.bodyLarge.fontSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE87722),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    onPressed: _isRequestingCert || _isDownloading
                        ? null
                        : () => _downloadCertificate(auth),
                  ),
                ),
                const SizedBox(height: 12),
                // Share achievement button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(
                      Icons.share_outlined,
                      color: Color(0xFFE87722),
                      size: 18,
                    ),
                    label: Text(
                      'Shiriki Mafanikio',
                      style: GoogleFonts.montserrat(
                        fontSize: AppTextStyles.bodyMedium.fontSize,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFE87722),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE87722)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      minimumSize: const Size(double.infinity, 52),
                    ),
                    onPressed: () async {
                      final date =
                          DateFormat('d MMMM yyyy').format(DateTime.now());
                      final text =
                          '🎓 Nimekamilisha kozi ya "${widget.courseTitle}" kwenye Karakana!\n\nTarehe: $date\n\n— ${auth.userFullName}\n\nPakua Karakana: https://kreativekarakana.co.tz';
                      await Share.share(
                        text,
                        subject: 'Nimekamilisha kozi kwenye Karakana!',
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextButton(
                  onPressed: () => context.go('/home'),
                  child: Text(
                    'Rudi Nyumbani',
                    style: GoogleFonts.montserrat(
                      fontSize: AppTextStyles.bodyMedium.fontSize,
                      color: const Color(0xFF9E8070),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
