import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// First Flutter surface displayed while application services boot.
///
/// The static image matches the native launch asset until the player is ready.
/// The video is muted, plays once, and is disposed with this screen.
class StartupVideoSplash extends StatefulWidget {
  const StartupVideoSplash({super.key});

  @override
  State<StartupVideoSplash> createState() => _StartupVideoSplashState();
}

class _StartupVideoSplashState extends State<StartupVideoSplash>
    with WidgetsBindingObserver {
  late final VideoPlayerController _controller;
  bool _videoReady = false;
  bool _videoFinished = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = VideoPlayerController.asset('assets/videos/bldr_splash.mp4')
      ..addListener(_onVideoChanged);
    _prepareVideo();
  }

  Future<void> _prepareVideo() async {
    try {
      await _controller.initialize();
      await _controller.setVolume(0);
      await _controller.setLooping(false);
      if (!mounted) return;
      setState(() => _videoReady = true);
      await _controller.play();
    } catch (_) {
      // The matching static asset remains visible if the platform cannot
      // prepare the video. Startup is never blocked by this visual layer.
    }
  }

  void _onVideoChanged() {
    if (!_controller.value.isInitialized || _videoFinished) return;
    if (_controller.value.position >= _controller.value.duration) {
      if (mounted) setState(() => _videoFinished = true);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_controller.value.isInitialized) return;
    if (state == AppLifecycleState.resumed && !_videoFinished) {
      _controller.play();
    } else if (state != AppLifecycleState.resumed) {
      _controller.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller
      ..removeListener(_onVideoChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/launch/bldr_launch.png',
            fit: BoxFit.cover,
          ),
          if (_videoReady && !_videoFinished)
            FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            ),
          if (_videoFinished) const ColoredBox(color: Colors.black),
        ],
      ),
    );
  }
}
