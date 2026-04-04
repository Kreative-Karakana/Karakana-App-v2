import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class ZanaScreen extends StatelessWidget {
  const ZanaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.construction_outlined,
              size: 64,
              color: AppColors.zanaPrimary,
            ),
            const SizedBox(height: 16),
            Text(
              'Zana',
              style: AppTextStyles.h2.copyWith(color: AppColors.zanaPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Inakuja Hivi Karibuni',
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
