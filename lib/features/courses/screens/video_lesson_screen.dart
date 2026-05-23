import 'package:flutter/material.dart';
import 'package:karakana_app/widgets/common/karakana_wave_loader.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

import '../../../core/network/api_client.dart';
import '../../../widgets/common/top_popup.dart';

class VideoLessonScreen extends StatefulWidget {
  final int lessonId;

  const VideoLessonScreen({
    super.key,
    required this.lessonId,
  });

  @override
  State<VideoLessonScreen> createState() => _VideoLessonScreenState();
}

class _VideoLessonScreenState extends State<VideoLessonScreen> {
  Map<String, dynamic>? _lesson;
  bool _isLoading = true;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _loadLesson();
  }

  Future<void> _loadLesson() async {
    try {
      final res =
          await ApiClient().dio.get('/api/v1/lessons/${widget.lessonId}/');
      if (!mounted) return;
      setState(() {
        _lesson = Map<String, dynamic>.from(res.data as Map);
        _isLoading = false;
        _isCompleted = res.data['is_completed'] == true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markComplete() async {
    try {
      await ApiClient()
          .dio
          .post('/api/v1/lessons/${widget.lessonId}/progress/');
      if (!mounted) return;
      setState(() => _isCompleted = true);
      showTopPopup(context, 'Somo limekamilika! ✓', isError: false);
    } catch (_) {}
  }

  String _lessonSummary() {
    final content = (_lesson?['content'] as String? ?? '').trim();
    if (content.isNotEmpty) {
      return content.length > 220 ? '${content.substring(0, 220)}...' : content;
    }
    return 'Soma somo hili kwa makini, elewa dhana kuu, kisha kamilisha ili maendeleo ya kozi yako yasasishwe.';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A0A00),
        body: SafeArea(
            child: Center(
          child: KarakanaWaveLoader(color: Color(0xFFE87722)),
        )),
      );
    }

    final signedUrl = _lesson?['signed_url'] as String?;
    final hasVideo = signedUrl != null && signedUrl.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF1A0A00),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text(
          _lesson?['title'] ?? 'Somo',
          maxLines: 1,
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          if (_isCompleted)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child:
                  Icon(Icons.check_circle, color: Color(0xFFE87722), size: 24),
            )
          else
            TextButton(
              onPressed: _markComplete,
              child: Text(
                'Kamilisha',
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFE87722),
                ),
              ),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // ── Video or placeholder ───────────────────────────────────────
          if (hasVideo)
            _MuxVideoPlayer(
              playbackUrl: signedUrl,
              onVideoEnded: _isCompleted ? null : _markComplete,
            )
          else
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                color: Colors.black,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.article_outlined,
                        color: Colors.white.withValues(alpha: 0.5),
                        size: 56,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Somo la Maandishi',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Lesson content ─────────────────────────────────────────────
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8D5C8),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _lesson?['title'] ?? '',
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF3D1800),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_lesson?['content'] != null &&
                        (_lesson!['content'] as String).isNotEmpty)
                      Text(
                        _lesson!['content'],
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: const Color(0xFF5C3D2E),
                          height: 1.6,
                        ),
                      ),
                    const SizedBox(height: 24),
                    if (!_isCompleted)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check_rounded),
                          label: Text(
                            'Kamilisha Somo',
                            style: GoogleFonts.montserrat(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE87722),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          onPressed: _markComplete,
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5E6D8),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Color(0xFFE87722),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Umekamilisha somo hili!',
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFE87722),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8F4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFF0E4DA)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.notes_rounded,
                                color: Color(0xFFE87722),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Muhtasari wa Somo',
                                style: GoogleFonts.montserrat(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF3D1800),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _lessonSummary(),
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              color: const Color(0xFF5C3D2E),
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8F4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFF0E4DA)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hatua Inayofuata',
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF3D1800),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isCompleted
                                ? 'Somo limekamilika. Rudi darasani uendelee na somo linalofuata.'
                                : 'Baada ya kujifunza, bonyeza "Kamilisha Somo" ili kufungua maendeleo yako kwenye kozi.',
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              color: const Color(0xFF5C3D2E),
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mux Video Player Widget ────────────────────────────────────────────────────

class _MuxVideoPlayer extends StatefulWidget {
  final String playbackUrl;
  final VoidCallback? onVideoEnded;

  const _MuxVideoPlayer({
    required this.playbackUrl,
    this.onVideoEnded,
  });

  @override
  State<_MuxVideoPlayer> createState() => _MuxVideoPlayerState();
}

class _MuxVideoPlayerState extends State<_MuxVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isError = false;
  bool _showControls = true;
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final url = widget.playbackUrl;
    _controller = VideoPlayerController.networkUrl(Uri.parse(url));

    _controller.addListener(_onPlayerChanged);

    try {
      await _controller.initialize();
      if (!mounted) return;
      setState(() => _isInitialized = true);
      _controller.play();
      _scheduleHideControls();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isError = true);
    }
  }

  void _onPlayerChanged() {
    if (!mounted) return;

    // Auto-mark complete when video finishes
    final pos = _controller.value.position;
    final dur = _controller.value.duration;
    if (dur.inSeconds > 0 &&
        pos.inSeconds >= dur.inSeconds - 1 &&
        !_controller.value.isPlaying &&
        widget.onVideoEnded != null) {
      widget.onVideoEnded!();
    }

    setState(() {});
  }

  void _scheduleHideControls() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _controller.value.isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  void _togglePlayPause() {
    setState(() => _showControls = true);
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
      _scheduleHideControls();
    }
  }

  void _toggleFullscreen() {
    setState(() => _isFullscreen = !_isFullscreen);
    if (_isFullscreen) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _controller.removeListener(_onPlayerChanged);
    _controller.dispose();
    // Restore orientation when leaving
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isError) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Colors.black,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.white.withValues(alpha: 0.6),
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  'Hitilafu ya kupakia video',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    setState(() => _isError = false);
                    _initPlayer();
                  },
                  child: Text(
                    'Jaribu tena',
                    style: GoogleFonts.montserrat(
                      color: const Color(0xFFE87722),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Colors.black,
          child: const Center(
            child: KarakanaWaveLoader(color: Color(0xFFE87722)),
          ),
        ),
      );
    }

    final value = _controller.value;
    final position = value.position;
    final duration = value.duration;

    final playerWidget = AspectRatio(
      aspectRatio:
          _isFullscreen ? MediaQuery.of(context).size.aspectRatio : 16 / 9,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Video ──────────────────────────────────────────────────────
          VideoPlayer(_controller),

          // ── Controls overlay ───────────────────────────────────────────
          GestureDetector(
            onTap: () {
              setState(() => _showControls = !_showControls);
              if (_showControls && _controller.value.isPlaying) {
                _scheduleHideControls();
              }
            },
            child: AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.4),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.6),
                    ],
                    stops: const [0, 0.2, 0.7, 1],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(),
                    // Play/Pause center button
                    GestureDetector(
                      onTap: _togglePlayPause,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          value.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                    // Bottom controls
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                      child: Column(
                        children: [
                          // Progress bar
                          VideoProgressIndicator(
                            _controller,
                            allowScrubbing: true,
                            colors: const VideoProgressColors(
                              playedColor: Color(0xFFE87722),
                              bufferedColor: Colors.white38,
                              backgroundColor: Colors.white12,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 6),
                          ),
                          Row(
                            children: [
                              Text(
                                _formatDuration(position),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                _formatDuration(duration),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: _toggleFullscreen,
                                child: Icon(
                                  _isFullscreen
                                      ? Icons.fullscreen_exit
                                      : Icons.fullscreen,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Buffering spinner
          if (value.isBuffering)
            const KarakanaWaveLoader(
              color: Color(0xFFE87722),
              strokeWidth: 2,
            ),
        ],
      ),
    );

    if (_isFullscreen) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: playerWidget),
      );
    }

    return playerWidget;
  }
}
