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
            child: _TopPopupAnimatedBanner(
              message: message,
              style: style,
              duration: duration,
              onFinished: () {
                _activeTopPopup?.remove();
                _activeTopPopup = null;
              },
            ),
          ),
        ),
      ),
    ),
  );

  overlay.insert(_activeTopPopup!);
}

class _TopPopupAnimatedBanner extends StatefulWidget {
  final String message;
  final _PopupStyle style;
  final Duration duration;
  final VoidCallback onFinished;

  const _TopPopupAnimatedBanner({
    required this.message,
    required this.style,
    required this.duration,
    required this.onFinished,
  });

  @override
  State<_TopPopupAnimatedBanner> createState() => _TopPopupAnimatedBannerState();
}

class _TopPopupAnimatedBannerState extends State<_TopPopupAnimatedBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
    reverseDuration: const Duration(milliseconds: 240),
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0.24, -0.22),
    end: Offset.zero,
  ).animate(CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  ));
  late final Animation<double> _scale = Tween<double>(
    begin: 0.97,
    end: 1.0,
  ).animate(CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutBack,
    reverseCurve: Curves.easeInCubic,
  ));

  @override
  void initState() {
    super.initState();
    _runAnimation();
  }

  Future<void> _runAnimation() async {
    await _controller.forward();
    final hold = widget.duration - const Duration(milliseconds: 540);
    if (hold > Duration.zero) {
      await Future.delayed(hold);
    }
    if (mounted) {
      await _controller.reverse();
    }
    if (mounted) {
      widget.onFinished();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: ScaleTransition(
          scale: _scale,
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 560),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.style.gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: widget.style.accentColor.withValues(alpha: 0.35)),
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
                      color: widget.style.accentColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(widget.style.icon,
                        size: 16,
                        color: widget.style.accentColor.withValues(alpha: 0.95)),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      widget.message,
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
    );
  }
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
