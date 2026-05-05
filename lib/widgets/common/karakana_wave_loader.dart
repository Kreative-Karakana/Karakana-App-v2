import 'package:flutter/material.dart';

class KarakanaWaveLoader extends StatefulWidget {
  final Color? color;
  final Color? backgroundColor;
  final Animation<Color?>? valueColor;
  final double strokeWidth;
  final double? value;
  final String? semanticsLabel;
  final String? semanticsValue;
  final StrokeCap? strokeCap;
  final double? size;

  const KarakanaWaveLoader({
    super.key,
    this.color,
    this.backgroundColor,
    this.valueColor,
    this.strokeWidth = 4.0,
    this.value,
    this.semanticsLabel,
    this.semanticsValue,
    this.strokeCap,
    this.size,
  });

  @override
  State<KarakanaWaveLoader> createState() => _KarakanaWaveLoaderState();
}

class _KarakanaWaveLoaderState extends State<KarakanaWaveLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bars = 5;
    final base = widget.color ?? const Color(0xFF3D1800);
    const accent = Color(0xFFE87722);
    return LayoutBuilder(
      builder: (context, constraints) {
        var effectiveSize = widget.size ?? 24.0;
        if (widget.size == null &&
            constraints.maxWidth.isFinite &&
            constraints.maxHeight.isFinite) {
          effectiveSize =
              ((constraints.maxWidth / 1.8) + (constraints.maxHeight / 1.2)) /
                  2;
        }
        if (effectiveSize < 10) effectiveSize = 10;

        return SizedBox(
          width: effectiveSize * 1.8,
          height: effectiveSize * 1.2,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (_, __) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(bars, (i) {
                  final phase = (_controller.value + (i * 0.13)) % 1.0;
                  final wave = (0.5 - (phase - 0.5).abs()) * 2;
                  final h = (effectiveSize * 0.32) + (wave * effectiveSize * 0.88);
                  return Container(
                    width: effectiveSize * 0.22,
                    height: h,
                    decoration: BoxDecoration(
                      color: Color.lerp(base, accent, wave),
                      borderRadius: BorderRadius.circular(effectiveSize * 0.2),
                    ),
                  );
                }),
              );
            },
          ),
        );
      },
    );
  }
}
