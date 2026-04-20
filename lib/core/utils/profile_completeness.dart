import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/api_endpoints.dart';
import '../network/api_client.dart';
import '../theme/app_colors.dart';
import 'secure_storage.dart';

/// Checks whether the user has filled out the mastercard form. If not, shows
/// a snackbar prompt and navigates them to the form.
///
/// Caches the result so the check only hits the network once per install.
/// Should be called from HomeScreen's initState via addPostFrameCallback.
Future<void> checkAndPromptMastercard(BuildContext context) async {
  // Already confirmed done — skip
  final isDone = await SecureStorage().isMastercardDone();
  if (isDone) return;

  try {
    await ApiClient().dio.get(ApiEndpoints.masterCard);
    // 200 means mastercard exists — mark done and skip
    await SecureStorage().setMastercardDone();
  } catch (e) {
    final parsed = ApiClient().parseError(e);
    if (parsed.contains('404') || parsed.contains('not found')) {
      // No mastercard yet — prompt the user
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tafadhali jaza taarifa za fomu ifuatayo.',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: AppColors.primary,
          duration: const Duration(milliseconds: 3500),
        ),
      );
      if (!context.mounted) return;
      context.push('/mastercard-form');
    }
    // Any other error (network, auth) — skip silently, retry next launch
  }
}
