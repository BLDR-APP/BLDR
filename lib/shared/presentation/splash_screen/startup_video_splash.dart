import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// First Flutter surface displayed while application services boot.
///
/// The static image matches the native launch asset until the player is ready.
/// The video is muted, plays once, and is disposed with this screen.
class StartupVideoSplash extends StatefulWidget {
  const StartupVideoSplash({
    required this.bootstrapReady,
    required this.onCompleted,
    super.key,
  });

  final bool bootstrapReady;
  final VoidCallback onCompleted;

  @override
  State<StartupVideoSplash> createState() => _StartupVideoSplashState();
}

class _StartupVideoSplashState extends State<StartupVideoSplash>
    with WidgetsBindingObserver {
  // O asset contém a animação útil até ~5,0 s, seguida por preto e então por
  // frames totalmente brancos a partir de 5,667 s. Desmontamos a Texture com
  // margem segura, sem modificar ou recomprimir o vídeo.
  static const _safeVisualEnd = Duration(milliseconds: 5100);

  late final VideoPlayerController _controller;
  Timer? _visualEndTimer;
  bool _videoReady = false;
  bool _videoFinished = false;
  bool _videoFailed = false;
  bool _completionDelivered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = VideoPlayerController.asset('assets/videos/bldr_splash.mp4')
      ..addListener(_onVideoChanged);
    _prepareVideo();
  }

  @override
  void didUpdateWidget(covariant StartupVideoSplash oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.bootstrapReady && widget.bootstrapReady) {
      _continueWhenReady();
    }
  }

  Future<void> _prepareVideo() async {
    try {
      await _controller.initialize();
      await _controller.setVolume(0);
      await _controller.setLooping(false);
      if (!mounted) return;
      setState(() => _videoReady = true);
      await _controller.play();
      _visualEndTimer = Timer(_safeVisualEnd, _finishVideo);
    } catch (_) {
      if (!mounted) return;
      setState(() => _videoFailed = true);
      _continueWhenReady();
    }
  }

  void _onVideoChanged() {
    if (!_controller.value.isInitialized || _videoFinished) return;
    if (_controller.value.position >= _safeVisualEnd) {
      _finishVideo();
    }
  }

  void _finishVideo() {
    if (!mounted || _videoFinished) return;
    _visualEndTimer?.cancel();
    _controller.pause();
    setState(() => _videoFinished = true);
    _continueWhenReady();
  }

  void _continueWhenReady() {
    if (!widget.bootstrapReady || _completionDelivered) return;
    if (!_videoFinished && !_videoFailed) return;
    _completionDelivered = true;
    // bootstrapReady pode mudar enquanto o AppLoader está reconstruindo este
    // widget. Entregamos a conclusão depois do frame para nunca chamar
    // setState no ancestral durante a própria fase de build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onCompleted();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_controller.value.isInitialized || _videoFinished) return;
    if (state == AppLifecycleState.resumed) {
      _controller.play();
    } else if (state != AppLifecycleState.resumed) {
      _controller.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _visualEndTimer?.cancel();
    _controller
      ..removeListener(_onVideoChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Estado seguro antes do primeiro frame e depois do fim visual.
            // A Texture nunca permanece montada durante a cauda branca.
            if (!_videoReady || _videoFinished || _videoFailed)
              const _StaticBldrFrame(),
            if (_videoReady && !_videoFinished && !_videoFailed)
              Center(
                child: FittedBox(
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: _controller.value.size.width,
                    height: _controller.value.size.height,
                    child: VideoPlayer(_controller),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StaticBldrFrame extends StatelessWidget {
  const _StaticBldrFrame();

  @override
  Widget build(BuildContext context) => const Center(
        child: FractionallySizedBox(
          widthFactor: 0.6,
          child: AspectRatio(
            aspectRatio: 1,
            child: Image(
              image: AssetImage('assets/images/launch/bldr_launch.png'),
              fit: BoxFit.contain,
            ),
          ),
        ),
      );
}
