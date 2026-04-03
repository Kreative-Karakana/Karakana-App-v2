import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final bool isLoading;
  final double? width;
  final double height;

  const GradientButton({
    super.key,
    required this.text,
    this.onTap,
    this.isLoading = false,
    this.width,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null || isLoading;

    return Opacity(
      opacity: isDisabled ? 0.45 : 1.0,
      child: GestureDetector(
        onTap: isDisabled ? null : onTap,
        child: Container(
          width: width ?? double.infinity,
          height: height,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: AppColors.ctaGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.button),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator.adaptive(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(text, style: AppTextStyles.buttonLarge),
          ),
        ),
      ),
    );
  }
}
