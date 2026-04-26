import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/secure_storage.dart';
import '../../features/auth/providers/auth_provider.dart';

Future<void> showTermsDialog(BuildContext context) async {
  await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _TermsDialog(),
  );
}

class _TermsDialog extends StatefulWidget {
  const _TermsDialog();

  @override
  State<_TermsDialog> createState() => _TermsDialogState();
}

class _TermsDialogState extends State<_TermsDialog> {
  bool _hasScrolledToBottom = false;
  bool _isAccepting = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 40) {
        setState(() => _hasScrolledToBottom = true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.policy_outlined, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Masharti ya Matumizi',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Tafadhali soma kabla ya kuendelea',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Scrollable content
          Flexible(
            child: SizedBox(
              height: 280,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _section(
                      '1. Kukubali Masharti',
                      'Kwa kutumia programu ya Karakana, unakubali masharti haya ya matumizi. Tafadhali soma kwa makini.',
                    ),
                    _section(
                      '2. Matumizi Yanayoruhusiwa',
                      'Unaweza kutumia Karakana kwa madhumuni ya kujifunza na biashara halali tu. Hairuhusiwi kushiriki maudhui bila ruhusa.',
                    ),
                    _section(
                      '3. Akaunti Yako',
                      'Unawajibika kulinda neno lako la siri. Karakana haitawajibika kwa hasara inayotokana na uzembe wa mtumiaji.',
                    ),
                    _section(
                      '4. Malipo',
                      'Malipo yote yanafanywa salama kupitia AzamPay. Karakana haifanyi kuhifadhi maelezo ya kadi yako ya benki.',
                    ),
                    _section(
                      '5. Maudhui ya Kozi',
                      'Kozi na maudhui yote ni mali ya Kreative Karakana au wafunzaji husika. Hairuhusiwi kunakili au kusambaza bila ruhusa.',
                    ),
                    _section(
                      '6. Faragha Yako',
                      'Tunalinda taarifa zako binafsi kulingana na sera yetu ya faragha. Hatuuzi taarifa zako kwa mtu yeyote wa tatu.',
                    ),
                    _section(
                      '7. Mabadiliko ya Masharti',
                      'Karakana inaweza kubadilisha masharti haya wakati wowote. Utaarifiwa kuhusu mabadiliko muhimu kupitia arifa.',
                    ),
                    const SizedBox(height: 8),
                    if (!_hasScrolledToBottom)
                      Center(
                        child: Text(
                          '↓ Endelea kusoma hadi mwisho',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Divider
          const Divider(height: 1, color: AppColors.divider),

          // Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (!_hasScrolledToBottom)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Soma masharti yote ili uweze kukubali',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _hasScrolledToBottom
                          ? AppColors.primary
                          : AppColors.border,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onPressed: _hasScrolledToBottom && !_isAccepting
                        ? () async {
                            setState(() => _isAccepting = true);
                            await SecureStorage().setTermsAccepted();
                            if (context.mounted) Navigator.pop(context, true);
                          }
                        : null,
                    child: _isAccepting
                        ? const CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2)
                        : Text(
                            'Nakubali Masharti',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    context.read<AuthProvider>().logout();
                    Navigator.pop(context, false);
                    context.go('/login');
                  },
                  child: Text(
                    'Sitakubali — Toka',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
