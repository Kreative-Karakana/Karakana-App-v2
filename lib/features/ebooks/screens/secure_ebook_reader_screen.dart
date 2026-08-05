import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/screenshot_prevention.dart';
import '../../../widgets/common/karakana_wave_loader.dart';
import '../providers/ebook_provider.dart';

class SecureEbookReaderScreen extends StatefulWidget {
  final int ebookId;
  final String ebookTitle;

  const SecureEbookReaderScreen({
    super.key,
    required this.ebookId,
    required this.ebookTitle,
  });

  @override
  State<SecureEbookReaderScreen> createState() =>
      _SecureEbookReaderScreenState();
}

class _SecureEbookReaderScreenState extends State<SecureEbookReaderScreen> {
  Uint8List? _currentBytes;
  bool _loading = true;
  String? _error;
  bool _showHud = true;
  Timer? _hudTimer;
  Timer? _captureTimer;
  final List<Timer> _prefetchTimers = [];
  bool _screenCaptured = false;
  bool _protectionReady = false;
  bool _protectionFailed = false;
  int _displayedPage = 1;

  // Saved in didChangeDependencies so dispose() can call it without context.
  late EbookProvider _ebookProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ebookProvider = context.read<EbookProvider>();
  }

  @override
  void initState() {
    super.initState();
    unawaited(_initializeSecureReader());
    _startHudTimer();
  }

  Future<void> _initializeSecureReader() async {
    if (mounted) {
      setState(() {
        _protectionReady = false;
        _protectionFailed = false;
      });
    }

    final enabled = await ScreenshotPrevention.enable();
    if (!mounted) {
      if (enabled) await ScreenshotPrevention.disable();
      return;
    }
    if (!enabled) {
      setState(() {
        _protectionFailed = true;
        _loading = false;
      });
      return;
    }

    setState(() => _protectionReady = true);
    _startCapturePolling();
    await _loadPage(_displayedPage);
  }

  void _startCapturePolling() {
    _captureTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      final captured = await ScreenshotPrevention.isScreenCaptured();
      if (mounted) {
        setState(() => _screenCaptured = captured);
      }
    });
  }

  void _startHudTimer() {
    _hudTimer?.cancel();
    _hudTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showHud = false);
    });
  }

  Future<void> _loadPage(int page) async {
    setState(() {
      _loading = true;
      _error = null;
      _showHud = true;
    });
    _startHudTimer();

    final provider = context.read<EbookProvider>();
    final bytes = await provider.fetchReaderPage(
        ebookId: widget.ebookId, pageNumber: page);
    if (!mounted) return;

    if (bytes == null) {
      setState(() {
        _loading = false;
        _error = 'Imeshindikana kupakia ukurasa. Tafadhali jaribu tena.';
      });
      return;
    }

    setState(() {
      _currentBytes = bytes;
      _loading = false;
      _displayedPage = page;
    });

    // Stagger prefetch so we never fire two render requests simultaneously.
    // 600 ms gap between each gives the server time to finish the previous.
    _scheduleStaggeredPrefetch(page, provider.totalPages);
  }

  void _scheduleStaggeredPrefetch(int currentPage, int total) {
    for (final timer in _prefetchTimers) {
      timer.cancel();
    }
    _prefetchTimers.clear();

    final targets = <int>[];
    if (currentPage + 1 <= total) targets.add(currentPage + 1);
    if (currentPage - 1 >= 1) targets.add(currentPage - 1);
    if (currentPage + 2 <= total) targets.add(currentPage + 2);

    for (var i = 0; i < targets.length; i++) {
      final p = targets[i];
      final timer = Timer(Duration(milliseconds: 600 + i * 600), () {
        if (!mounted) return;
        final provider = context.read<EbookProvider>();
        if (!provider.hasCachedReaderPage(
          ebookId: widget.ebookId,
          pageNumber: p,
        )) {
          unawaited(
              provider.fetchReaderPage(ebookId: widget.ebookId, pageNumber: p));
        }
      });
      _prefetchTimers.add(timer);
    }
  }

  void _next() {
    final p = context.read<EbookProvider>();
    if (p.currentEbookPage < p.totalPages) {
      _loadPage(p.currentEbookPage + 1);
    }
  }

  void _prev() {
    final p = context.read<EbookProvider>();
    if (p.currentEbookPage > 1) {
      _loadPage(p.currentEbookPage - 1);
    }
  }

  @override
  void dispose() {
    _hudTimer?.cancel();
    _captureTimer?.cancel();
    for (final timer in _prefetchTimers) {
      timer.cancel();
    }
    _prefetchTimers.clear();
    _ebookProvider.clearReaderCache();
    unawaited(ScreenshotPrevention.disable());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          setState(() => _showHud = !_showHud);
          _startHudTimer();
        },
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity == null) return;
          if (details.primaryVelocity! < 0) {
            _next();
          } else if (details.primaryVelocity! > 0) {
            _prev();
          }
        },
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(child: _buildCanvas()),
              if (_showHud)
                Positioned(left: 0, right: 0, bottom: 0, child: _buildHud()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCanvas() {
    if (_protectionFailed) {
      return Container(
        color: Colors.black,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.gpp_bad_outlined, color: Colors.white54, size: 48),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Imeshindikana kuwasha ulinzi wa eBook kwenye kifaa hiki.',
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: () => unawaited(_initializeSecureReader()),
              child: const Text('Jaribu Tena'),
            ),
          ],
        ),
      );
    }

    if (!_protectionReady) {
      return const Center(child: KarakanaWaveLoader(color: Colors.white));
    }

    if (_screenCaptured) {
      // Full opaque black-out — same behaviour as WhatsApp view-once.
      // On iOS the UITextField secure layer already blacks out the content
      // in screenshots; this overlay fires for live screen-recording detection.
      return Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock, color: Colors.white54, size: 48),
            const SizedBox(height: 16),
            Text(
              'Screen capture is not allowed\nwhile reading this ebook.',
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_loading) {
      return const Center(child: KarakanaWaveLoader(color: Colors.white));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!,
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
            const SizedBox(height: AppSpacing.sm + AppSpacing.xs / 2),
            OutlinedButton(
              onPressed: () =>
                  _loadPage(context.read<EbookProvider>().currentEbookPage),
              child: const Text('Jaribu Tena'),
            ),
          ],
        ),
      );
    }
    if (_currentBytes == null) return const SizedBox.shrink();

    return Center(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: InteractiveViewer(
          key: ValueKey(_displayedPage),
          minScale: 1,
          maxScale: 3,
          child: Image.memory(
            _currentBytes!,
            fit: BoxFit.contain,
            gaplessPlayback: true,
          ),
        ),
      ),
    );
  }

  Widget _buildHud() {
    return Consumer<EbookProvider>(
      builder: (_, p, __) {
        return Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md - AppSpacing.xs / 2,
            AppSpacing.sm + AppSpacing.xs / 2,
            AppSpacing.md - AppSpacing.xs / 2,
            AppSpacing.md + AppSpacing.xs / 2,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.72),
            border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.2))),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: p.currentEbookPage > 1 ? _prev : null,
                icon: const Icon(Icons.chevron_left, color: Colors.white),
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(widget.ebookTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.h4.copyWith(color: Colors.white)),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${p.currentEbookPage} / ${p.totalPages}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: p.currentEbookPage < p.totalPages ? _next : null,
                icon: const Icon(Icons.chevron_right, color: Colors.white),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ],
          ),
        );
      },
    );
  }
}
