import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/api_endpoints.dart';
import '../network/api_client.dart';
import '../theme/app_colors.dart';
import '../../widgets/common/top_popup.dart';
import 'secure_storage.dart';

/// Checks whether the user has filled out the mastercard form. If not, shows
/// a top popup prompt and navigates them to the form.
///
/// Caches the result so the check only hits the network once per install.
/// Should be called from HomeScreen's initState via addPostFrameCallback.
Future<void> checkAndPromptMastercard(BuildContext context) async {
  // Already confirmed done — skip
  final isDone = await SecureStorage().isMastercardDone();
  if (isDone) return;

  try {
    final response = await ApiClient().dio.get(
      ApiEndpoints.masterCard,
      options: Options(validateStatus: (code) => code != null && code < 500),
    );
    final statusCode = response.statusCode ?? 0;

    if (statusCode == 200) {
      await SecureStorage().setMastercardDone();
      return;
    }

    if (statusCode == 404) {
      if (!context.mounted) return;
      showTopPopup(
        context,
        'Tafadhali jaza taarifa za fomu ifuatayo.',
        type: TopPopupType.warning,
        duration: const Duration(milliseconds: 3500),
      );
      if (!context.mounted) return;
      context.push('/mastercard-form');
    }
  } catch (_) {
    // Any network/transport error — skip silently, retry next launch.
  }
}
