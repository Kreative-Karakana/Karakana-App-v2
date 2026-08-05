import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

import '../../../widgets/common/fullscreen_video_orientation.dart';
import '../../../widgets/common/karakana_wave_loader.dart';

class CourseIntroVideoPlayer extends StatefulWidget {
  final String playbackUrl;

  const CourseIntroVideoPlayer({
    super.key,
    required this.playbackUrl,
  });

  @override
  State<CourseIntroVideoPlayer> createState() => _CourseIntroVideoPlayerState();
}

class _CourseIntroVideoPlayerState extends State<CourseIntroVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isError = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    if (_isInitialized || _isError) {
      _controller.removeListener(_onPlayerChanged);
      await _controller.dispose();
    }
    final streamUrl = _resolvePlaybackUrl(widget.playbackUrl);
    final streamUri = Uri.parse(streamUrl);
    final isHls = streamUri.path.toLowerCase().endsWith('.m3u8');

    _controller = VideoPlayerController.networkUrl(
      streamUri,
      formatHint: isHls ? VideoFormat.hls : null,
    );
    _controller.addListener(_onPlayerChanged);

    try {
      await _controller.initialize();
      if (!mounted) return;
      setState(() => _isInitialized = true);
      _scheduleHideControls();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isError = true);
    }
  }

  String _resolvePlaybackUrl(String rawValue) {
    final trimmed = rawValue.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return 'https://stream.mux.com/$trimmed.m3u8';
  }

  void _onPlayerChanged() {
    if (!mounted) return;
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

  Future<void> _openFullscreen() async {
    setState(() => _showControls = false);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _FullscreenCourseVideoPlayer(controller: _controller),
      ),
    );
    if (!mounted) return;
    setState(() => _showControls = true);
    _scheduleHideControls();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _controller.removeListener(_onPlayerChanged);
    _controller.dispose();
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
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.white.withValues(alpha: 0.65),
                  size: 44,
                ),
                const SizedBox(height: 10),
                Text(
                  'Hitilafu ya kupakia video',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isError = false;
                      _isInitialized = false;
                    });
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
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(
            child: KarakanaWaveLoader(color: Color(0xFFE87722)),
          ),
        ),
      );
    }

    final value = _controller.value;
    final position = value.position;
    final duration = value.duration;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(child: VideoPlayer(_controller)),
            GestureDetector(
              onTap: () => setState(() => _showControls = !_showControls),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: _showControls ? 1 : 0,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.25),
                  child: Stack(
                    children: [
                      Center(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            iconSize: 42,
                            color: Colors.white,
                            onPressed: _togglePlayPause,
                            icon: Icon(
                              value.isPlaying ? Icons.pause : Icons.play_arrow,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: IconButton(
                          onPressed: _openFullscreen,
                          color: Colors.white,
                          icon: const Icon(Icons.fullscreen),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.7),
                              ],
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              VideoProgressIndicator(
                                _controller,
                                allowScrubbing: true,
                                padding: EdgeInsets.zero,
                                colors: const VideoProgressColors(
                                  playedColor: Color(0xFFE87722),
                                  bufferedColor: Colors.white30,
                                  backgroundColor: Colors.white12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    _formatDuration(position),
                                    style: GoogleFonts.montserrat(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    _formatDuration(duration),
                                    style: GoogleFonts.montserrat(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullscreenCourseVideoPlayer extends StatefulWidget {
  final VideoPlayerController controller;

  const _FullscreenCourseVideoPlayer({
    required this.controller,
  });

  @override
  State<_FullscreenCourseVideoPlayer> createState() =>
      _FullscreenCourseVideoPlayerState();
}

class _FullscreenCourseVideoPlayerState
    extends State<_FullscreenCourseVideoPlayer>
    with FullscreenVideoOrientation {
  bool _showControls = true;
  bool _isExiting = false;
  bool _canPop = false;

  @override
  void initState() {
    super.initState();
    enterFullscreenOrientation();
  }

  @override
  void dispose() {
    restorePortraitOrientation();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _exitFullscreen() async {
    if (_isExiting) return;
    _isExiting = true;

    await restorePortraitOrientation();
    if (!mounted) return;

    setState(() => _canPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.controller.value;
    final aspectRatio = value.aspectRatio == 0 ? 16 / 9 : value.aspectRatio;
    final padding = MediaQuery.paddingOf(context);

    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exitFullscreen();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _showControls = !_showControls),
          child: Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              Center(
                child: AspectRatio(
                  aspectRatio: aspectRatio,
                  child: VideoPlayer(widget.controller),
                ),
              ),
              AnimatedOpacity(
                opacity: _showControls ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                child: IgnorePointer(
                  ignoring: !_showControls,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.55),
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.65),
                        ],
                        stops: const [0, 0.24, 0.68, 1],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: padding.top + 12,
                          left: padding.left + 16,
                          child: IconButton(
                            onPressed: _exitFullscreen,
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                if (widget.controller.value.isPlaying) {
                                  widget.controller.pause();
                                } else {
                                  widget.controller.play();
                                }
                              });
                            },
                            child: Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                value.isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: padding.left + 24,
                          right: padding.right + 24,
                          bottom: padding.bottom + 16,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              VideoProgressIndicator(
                                widget.controller,
                                allowScrubbing: true,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                colors: const VideoProgressColors(
                                  playedColor: Color(0xFFE87722),
                                  bufferedColor: Colors.white38,
                                  backgroundColor: Colors.white12,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    _formatDuration(value.position),
                                    style: GoogleFonts.montserrat(
                                      fontSize: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    _formatDuration(value.duration),
                                    style: GoogleFonts.montserrat(
                                      fontSize: 12,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  GestureDetector(
                                    onTap: _exitFullscreen,
                                    child: const Icon(
                                      Icons.fullscreen_exit,
                                      color: Colors.white,
                                      size: 24,
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
            ],
          ),
        ),
      ),
    );
  }
}
