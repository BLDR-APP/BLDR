// lib/widgets/muscle_visualizer_widget.dart
//
// compact — narrow sidebar next to the exercise GIF.
//   • Fetches front view only (portrait silhouette, fills card cleanly).
//   • No paywall. Free users see primary-only; PRO sees primary+secondary.
//
// full — standalone card (double.infinity × auto-height).
//   • Fetches front AND back views simultaneously, stacked vertically.
//   • PRO: full image. Free: blurred image + lock paywall overlay.
//
// Background: API renders background=transparent as white (#FFFFFF) in JPEG,
// so both card backgrounds are white for a seamless result.

import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import 'package:bldr_fitness/routes/app_routes.dart';
import 'package:bldr_fitness/services/muscle_visualizer_service.dart';

// ── enums ─────────────────────────────────────────────────────────────────────

enum VisualizerSize { compact, full }

/// workoutActivation — primary (gold) + secondary (light gold), two colours.
/// highlight         — all muscles in the same gold colour (retrospective view).
enum VisualizerMode { workoutActivation, highlight }

// ── widget ────────────────────────────────────────────────────────────────────

class MuscleVisualizerWidget extends StatefulWidget {
  final List<String> targetMuscles;
  final List<String> secondaryMuscles;
  final bool isPro;
  final VisualizerSize size;
  final VisualizerMode mode;

  // ── paywall (full + !isPro only) ──────────────────────────────────────────
  final String paywallMessage;
  final String paywallButtonLabel;
  final VoidCallback? onUpgradeTap;

  const MuscleVisualizerWidget({
    Key? key,
    required this.targetMuscles,
    this.secondaryMuscles = const [],
    this.isPro = false,
    this.size = VisualizerSize.compact,
    this.mode = VisualizerMode.workoutActivation,
    this.paywallMessage = 'Veja todos os músculos trabalhados com o plano PRO',
    this.paywallButtonLabel = 'Ver planos PRO',
    this.onUpgradeTap,
  }) : super(key: key);

  @override
  State<MuscleVisualizerWidget> createState() =>
      _MuscleVisualizerWidgetState();
}

class _MuscleVisualizerWidgetState extends State<MuscleVisualizerWidget> {
  static const _gold   = Color(0xFFD4AF37);
  static const _muted  = Color(0xFF888070);
  static const _card   = Color(0xFF1E1C18);
  static const _white  = Colors.white;

  // compact uses view=front (portrait silhouette, fills narrow card well)
  // full uses no view param (API returns combined front+back in one image)
  Uint8List? _bytes;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void didUpdateWidget(MuscleVisualizerWidget old) {
    super.didUpdateWidget(old);
    final musclesChanged =
        old.targetMuscles.join(',') != widget.targetMuscles.join(',') ||
        old.secondaryMuscles.join(',') != widget.secondaryMuscles.join(',');
    if (musclesChanged || old.isPro != widget.isPro || old.size != widget.size) {
      _fetch();
    }
  }

  Future<void> _fetch() async {
    if (mounted) setState(() { _bytes = null; _loading = true; });

    if (widget.targetMuscles.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    // compact → front-only portrait; full → combined (no view param = front+back)
    final view = widget.size == VisualizerSize.compact ? 'front' : '';

    if (widget.mode == VisualizerMode.highlight) {
      // Highlight mode: all muscles in same gold colour (retrospective view).
      // Combines target + secondary into a single uniform-coloured image.
      final allMuscles = [
        ...widget.targetMuscles,
        ...widget.secondaryMuscles,
      ];
      MuscleVisualizerService.instance
          .getHighlight(muscles: allMuscles, view: view)
          .then((b) { if (mounted) setState(() { _bytes = b; _loading = false; }); });
    } else {
      // PRO: include secondary muscles; free: primary only
      final secondary = widget.isPro ? widget.secondaryMuscles : <String>[];
      MuscleVisualizerService.instance
          .getVisualization(
            targetMuscles: widget.targetMuscles,
            secondaryMuscles: secondary,
            view: view,
          )
          .then((b) { if (mounted) setState(() { _bytes = b; _loading = false; }); });
    }
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return widget.size == VisualizerSize.compact
        ? _buildCompact()
        : _buildFull();
  }

  // ── compact ────────────────────────────────────────────────────────────────

  Widget _buildCompact() {
    return Container(
      width: 20.w,
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _imageContent(size: 22),
      ),
    );
  }

  // ── full ───────────────────────────────────────────────────────────────────

  Widget _buildFull() {
    return Container(
      width: double.infinity,
      height: 22.h,
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _imageContent(size: 32),
            if (!widget.isPro && !_loading && _bytes != null)
              _buildPaywall(),
          ],
        ),
      ),
    );
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  Widget _imageContent({required double size}) {
    if (_loading) {
      return Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(color: _gold, strokeWidth: 2),
        ),
      );
    }
    if (_bytes == null) {
      return Center(
        child: Icon(Icons.accessibility_new_rounded, color: _muted, size: size),
      );
    }
    return Image.memory(_bytes!, fit: BoxFit.contain);
  }

  Widget _buildPaywall() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _gold.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: _gold.withOpacity(0.4)),
                ),
                child: const Icon(Icons.lock_rounded, color: _gold, size: 22),
              ),
              SizedBox(height: 1.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 5.w),
                child: Text(
                  widget.paywallMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
              SizedBox(height: 1.5.h),
              GestureDetector(
                onTap: widget.onUpgradeTap ?? _defaultUpgradeTap,
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 5.w, vertical: 0.8.h),
                  decoration: BoxDecoration(
                    color: _gold,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.paywallButtonLabel,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
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

  void _defaultUpgradeTap() {
    Navigator.pushNamed(context, AppRoutes.checkoutScreen);
  }
}
