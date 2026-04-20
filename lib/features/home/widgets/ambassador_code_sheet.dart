import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/secure_storage.dart';

/// Checks whether the ambassador code bottom sheet should be shown, then shows
/// it if needed. Should be called once from the HomeScreen's initState via
/// addPostFrameCallback.
Future<void> checkAndShowAmbassadorCode(BuildContext context) async {
  // Read cached state first
  bool? cached = await SecureStorage().getAmbassadorCodeState();

  if (cached == null) {
    // First time — ask the profile endpoint
    try {
      final response = await ApiClient().dio.get(ApiEndpoints.profileMe);
      final data = response.data;
      final needsCode = data['ambassador_code'] as bool? ?? false;
      await SecureStorage().setAmbassadorCodeState(needsCode);
      cached = needsCode;
    } catch (_) {
      // Network error — skip for now, will retry next launch
      return;
    }
  }

  if (cached == true && context.mounted) {
    await showAmbassadorCodeSheet(context);
  }
}

/// Shows the ambassador code modal bottom sheet.
Future<void> showAmbassadorCodeSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AmbassadorCodeSheet(),
  );
}

class _AmbassadorCodeSheet extends StatefulWidget {
  const _AmbassadorCodeSheet();

  @override
  State<_AmbassadorCodeSheet> createState() => _AmbassadorCodeSheetState();
}

class _AmbassadorCodeSheetState extends State<_AmbassadorCodeSheet>
    with SingleTickerProviderStateMixin {
  final TextEditingController _codeController = TextEditingController();
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;
  bool _showForm = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _codeController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _decline() async {
    setState(() => _isLoading = true);
    try {
      await ApiClient().dio.post(
        ApiEndpoints.ambassadorCode,
        data: {'declined': true},
      );
      await SecureStorage().setAmbassadorCodeState(false);
    } catch (_) {
      // Silently fail — we still dismiss so the user isn't blocked
      await SecureStorage().setAmbassadorCodeState(false);
    } finally {
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _submit() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tafadhali weka namba ya balozi',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ApiClient().dio.post(
        ApiEndpoints.ambassadorCode,
        data: {'code': code, 'declined': false},
      );
      await SecureStorage().setAmbassadorCodeState(false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Namba ya balozi imewasilishwa kwa mafanikio',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Zoezi limeshindikana. Tafadhali jaribu tena.',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.58,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: _showForm
                      ? SlideTransition(
                          position: _slideAnimation,
                          child: _buildForm(setModalState),
                        )
                      : _buildIntro(setModalState),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildIntro(void Function(void Function()) setModalState) {
    return Column(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.people_alt_outlined,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Je, umepata usaidizi kutoka\nkwa balozi wetu?',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Tumeanzisha huduma hii ya balozi ili kuboresha huduma zetu. Tungependa kufahamu kama ulipata usaidizi kutoka kwa balozi wetu.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        setModalState(() => _showForm = true);
                        _animController.forward();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Ndiyo',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: _isLoading ? null : _decline,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : Text(
                        'Hapana',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildForm(void Function(void Function()) setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.badge_outlined,
              size: 32,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Weka Namba ya Balozi',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Weka namba uliyopewa na balozi wetu ili kusajili ushirikiano wenu.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: Colors.grey.shade600,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _codeController,
          textCapitalization: TextCapitalization.characters,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Mfano: AMB-12345',
            hintStyle: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
            prefixIcon: Icon(Icons.tag, color: AppColors.primary, size: 20),
            filled: true,
            fillColor: AppColors.primaryLight.withValues(alpha: 0.4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        const Spacer(),
        Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Wasilisha',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        setModalState(() => _showForm = false);
                        _animController.reverse();
                      },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Rudi Nyuma',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
