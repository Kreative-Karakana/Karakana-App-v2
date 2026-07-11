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
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

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
    final targetSize = widget.size ?? 24.0;
    final containerWidth = targetSize * 1.8;
    final containerHeight = targetSize * 1.2;
    final barWidth = containerWidth / (bars * 1.9);
    final totalBarsWidth = bars * barWidth;
    final gap = bars > 1 ? (containerWidth - totalBarsWidth) / (bars - 1) : 0.0;
    final constrainedGap = gap.isFinite && gap > 0 ? gap : 0.0;
    final minBarHeight = containerHeight * 0.32;
    final maxExtraHeight = containerHeight * 0.68;

    return SizedBox(
      width: containerWidth,
      height: containerHeight,
      child: ClipRect(
        child: FittedBox(
          fit: BoxFit.contain,
          alignment: Alignment.centerLeft,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (_, __) {
              return SizedBox(
                width: containerWidth,
                height: containerHeight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: List.generate(bars, (i) {
                    final phase = (_controller.value + (i * 0.13)) % 1.0;
                    final wave = (0.5 - (phase - 0.5).abs()) * 2;
                    final h = minBarHeight + (wave * maxExtraHeight);
                    return Padding(
                      padding: EdgeInsets.only(
                          right: i == bars - 1 ? 0 : constrainedGap),
                      child: Container(
                        width: barWidth,
                        height: h,
                        decoration: BoxDecoration(
                          color: Color.lerp(base, accent, wave),
                          borderRadius: BorderRadius.circular(barWidth),
                        ),
                      ),
                    );
                  }),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
