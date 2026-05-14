import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
  State<SecureEbookReaderScreen> createState() => _SecureEbookReaderScreenState();
}

class _SecureEbookReaderScreenState extends State<SecureEbookReaderScreen> {
  Uint8List? _currentBytes;
  bool _loading = true;
  String? _error;
  bool _showHud = true;
  Timer? _hudTimer;
  bool _screenCaptured = false;

  @override
  void initState() {
    super.initState();
    ScreenshotPrevention.enable();
    _loadPage(1);
    _startHudTimer();
    _startCapturePolling();
  }

  void _startCapturePolling() {
    Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
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
    final bytes = await provider.fetchReaderPage(ebookId: widget.ebookId, pageNumber: page);
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
    });

    // prefetch next page
    final next = provider.currentEbookPage + 1;
    if (next <= provider.totalPages) {
      unawaited(provider.fetchReaderPage(ebookId: widget.ebookId, pageNumber: next));
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
    context.read<EbookProvider>().clearReaderCache();
    ScreenshotPrevention.disable();
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
              if (_showHud) Positioned(left: 0, right: 0, bottom: 0, child: _buildHud()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCanvas() {
    if (_screenCaptured) {
      return const Center(
        child: Text(
          'Screenshot/recording is blocked while reading.',
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_loading) return const Center(child: KarakanaWaveLoader(color: Colors.white));
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 10),
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
      child: InteractiveViewer(
        minScale: 1,
        maxScale: 3,
        child: Image.memory(_currentBytes!, fit: BoxFit.contain),
      ),
    );
  }

  Widget _buildHud() {
    return Consumer<EbookProvider>(
      builder: (_, p, __) {
        return Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.72),
            border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.2))),
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
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('${p.currentEbookPage} / ${p.totalPages}', style: const TextStyle(color: Colors.white70)),
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
