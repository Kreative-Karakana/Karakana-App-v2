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
    final mark = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.34),
        gradient: const LinearGradient(
          colors: [Color(0xFF7A360C), Color(0xFF2A1005)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: size * 0.14,
            right: size * 0.12,
            child: Container(
              width: size * 0.2,
              height: size * 0.2,
              decoration: BoxDecoration(
                color: AppColors.primaryMid.withValues(alpha: 0.28),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Container(
            width: size * 0.64,
            height: size * 0.64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(size * 0.24),
            ),
            child: Center(child: _buildLogo()),
          ),
        ],
      ),
    );

    if (!showBackground) return mark;

    return Container(
      padding: EdgeInsets.all(size * 0.08),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(size * 0.42),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: mark,
    );
  }

  Widget _buildLogo() {
    try {
      return Image.asset(
        'assets/images/Kreative_Karakana_-_Official_Logo_Icon.png',
        width: size * 0.34,
        height: size * 0.34,
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
