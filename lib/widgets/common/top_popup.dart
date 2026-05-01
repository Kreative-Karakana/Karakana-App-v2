import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

OverlayEntry? _activeTopPopup;

void showTopPopup(
  BuildContext context,
  String message, {
  bool isError = true,
  Duration duration = const Duration(milliseconds: 2600),
}) {
  _activeTopPopup?.remove();
  _activeTopPopup = null;

  final overlay = Overlay.of(context);
  final borderColor = isError ? Colors.red.shade300 : Colors.green.shade300;
  final gradientColors = isError
      ? const [Color(0xFF5A2118), Color(0xFF7A2D1F)]
      : const [Color(0xFF1E5133), Color(0xFF2A7C4D)];
  final icon = isError ? Icons.warning_amber_rounded : Icons.check_circle_outline;

  _activeTopPopup = OverlayEntry(
    builder: (context) => IgnorePointer(
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
            child: Material(
              color: Colors.transparent,
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                tween: Tween(begin: 0, end: 1),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(42 * (1 - value), -20 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 560),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor.withValues(alpha: 0.35)),
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
                      Icon(icon, size: 20, color: borderColor.withValues(alpha: 0.9)),
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

