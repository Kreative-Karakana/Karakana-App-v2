import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

OverlayEntry? _activeTopPopup;

enum TopPopupType { error, success, warning, info }

void showTopPopup(
  BuildContext context,
  String message, {
  TopPopupType? type,
  bool isError = true,
  Duration duration = const Duration(milliseconds: 2600),
}) {
  _activeTopPopup?.remove();
  _activeTopPopup = null;

  final overlay = Overlay.of(context);
  final popupType = type ?? (isError ? TopPopupType.error : TopPopupType.success);
  final _PopupStyle style = _styleForType(popupType);

  _activeTopPopup = OverlayEntry(
    builder: (context) => IgnorePointer(
      child: SafeArea(
        child: Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
            child: Material(
              color: Colors.transparent,
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                tween: Tween(begin: 0, end: 1),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(56 * (1 - value), -24 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 560),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: style.gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: style.accentColor.withValues(alpha: 0.35)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.28),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: style.accentColor.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(style.icon,
                            size: 16,
                            color: style.accentColor.withValues(alpha: 0.95)),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          message,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  overlay.insert(_activeTopPopup!);
  Future.delayed(duration, () {
    _activeTopPopup?.remove();
    _activeTopPopup = null;
  });
}

class _PopupStyle {
  final Color accentColor;
  final List<Color> gradientColors;
  final IconData icon;

  const _PopupStyle({
    required this.accentColor,
    required this.gradientColors,
    required this.icon,
  });
}

_PopupStyle _styleForType(TopPopupType type) {
  switch (type) {
    case TopPopupType.success:
      return _PopupStyle(
        accentColor: const Color(0xFF71E59B),
        gradientColors: const [Color(0xFF1E5133), Color(0xFF2A7C4D)],
        icon: Icons.check_circle_outline,
      );
    case TopPopupType.warning:
      return _PopupStyle(
        accentColor: const Color(0xFFFFD86B),
        gradientColors: const [Color(0xFF5A4114), Color(0xFF7B5A19)],
        icon: Icons.warning_amber_rounded,
      );
    case TopPopupType.info:
      return _PopupStyle(
        accentColor: const Color(0xFF8FCCFF),
        gradientColors: const [Color(0xFF1A3B63), Color(0xFF255A93)],
        icon: Icons.info_outline,
      );
    case TopPopupType.error:
      return _PopupStyle(
        accentColor: const Color(0xFFFF8A7A),
        gradientColors: const [Color(0xFF5A2118), Color(0xFF7A2D1F)],
        icon: Icons.error_outline,
      );
  }
}
