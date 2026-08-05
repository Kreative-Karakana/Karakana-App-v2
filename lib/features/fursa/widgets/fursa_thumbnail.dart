import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../widgets/common/karakana_wave_loader.dart';

/// Shared 16:9 opportunity thumbnail used wherever Fursa content is shown.
/// The fixed ratio keeps card geometry stable while the cached image loads.
class FursaThumbnail extends StatelessWidget {
  static const missingPlaceholderKey = Key('fursa-thumbnail-missing');
  static const loadingPlaceholderKey = Key('fursa-thumbnail-loading');
  static const errorPlaceholderKey = Key('fursa-thumbnail-error');

  final String? imageUrl;
  final String semanticLabel;
  final BorderRadius borderRadius;

  const FursaThumbnail({
    super.key,
    required this.imageUrl,
    required this.semanticLabel,
    this.borderRadius = const BorderRadius.all(Radius.circular(14)),
  });

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    final hasImage = url != null && url.isNotEmpty;

    return Semantics(
      image: true,
      label: hasImage
          ? 'Picha ya fursa: $semanticLabel'
          : 'Picha ya fursa haipatikani: $semanticLabel',
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: ClipRRect(
          borderRadius: borderRadius,
          child: ColoredBox(
            color: _placeholderColor(context),
            child: hasImage
                ? LayoutBuilder(
                    builder: (context, constraints) {
                      final pixelRatio = MediaQuery.devicePixelRatioOf(context);
                      final cacheWidth = constraints.maxWidth.isFinite
                          ? (constraints.maxWidth * pixelRatio).round()
                          : null;
                      return ExcludeSemantics(
                        child: CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          memCacheWidth: cacheWidth,
                          fadeInDuration: const Duration(milliseconds: 180),
                          fadeOutDuration: const Duration(milliseconds: 100),
                          placeholder: (_, __) => const _FursaImagePlaceholder(
                            key: loadingPlaceholderKey,
                            showLoader: true,
                          ),
                          errorWidget: (_, __, ___) =>
                              const _FursaImagePlaceholder(
                            key: errorPlaceholderKey,
                          ),
                        ),
                      );
                    },
                  )
                : const _FursaImagePlaceholder(
                    key: missingPlaceholderKey,
                  ),
          ),
        ),
      ),
    );
  }
}

class _FursaImagePlaceholder extends StatelessWidget {
  final bool showLoader;

  const _FursaImagePlaceholder({
    super.key,
    this.showLoader = false,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _placeholderColor(context),
      child: Center(
        child: showLoader
            ? KarakanaWaveLoader(
                size: 24,
                strokeWidth: 2,
                color: AppColors.primary,
              )
            : Icon(
                Icons.work_outline_rounded,
                size: 28,
                color: AppColors.primary,
              ),
      ),
    );
  }
}

Color _placeholderColor(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark
      ? AppColors.primary.withValues(alpha: 0.16)
      : AppColors.primaryLight;
}
