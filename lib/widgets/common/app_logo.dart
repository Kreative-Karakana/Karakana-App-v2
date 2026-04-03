import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showBackground;

  const AppLogo({
    super.key,
    this.size = 88,
    this.showBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    final logo = _buildLogo();

    if (!showBackground) return logo;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(child: logo),
    );
  }

  Widget _buildLogo() {
    try {
      return Image.asset(
        'assets/images/Kreative_Karakana_-_Official_Logo_Icon.png',
        width: showBackground ? size * 0.6 : size,
        height: showBackground ? size * 0.6 : size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    } catch (_) {
      return _fallback();
    }
  }

  Widget _fallback() {
    return Text(
      'K',
      style: TextStyle(
        fontSize: size * 0.45,
        fontWeight: FontWeight.w800,
        color: AppColors.primary,
      ),
    );
  }
}
