import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

enum AppButtonVariant { primary, secondary, outlined, destructive }

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final bool isLoading;
  final double? width;
  final double height;
  final AppButtonVariant variant;
  final IconData? icon;

  const GradientButton({
    super.key,
    required this.text,
    this.onTap,
    this.isLoading = false,
    this.width,
    this.height = 56,
    this.variant = AppButtonVariant.primary,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null || isLoading;

    final colors = switch (variant) {
      AppButtonVariant.primary => (AppColors.primary, Colors.white),
      AppButtonVariant.secondary => (
          const Color(0xFFF0E4DA),
          AppColors.primary,
        ),
      AppButtonVariant.outlined => (Colors.transparent, AppColors.primary),
      AppButtonVariant.destructive => (Colors.red.shade700, Colors.white),
    };
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton.icon(
        onPressed: isDisabled ? null : onTap,
        icon: isLoading
            ? const SizedBox.shrink()
            : (icon == null ? const SizedBox.shrink() : Icon(icon)),
        label: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator.adaptive(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                text,
                style: AppTextStyles.buttonLarge.copyWith(color: colors.$2),
              ),
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.$1,
          foregroundColor: colors.$2,
          disabledBackgroundColor: colors.$1,
          disabledForegroundColor: colors.$2,
          elevation: variant == AppButtonVariant.primary ? 4 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
            side: variant == AppButtonVariant.outlined
                ? BorderSide(color: AppColors.primary)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
