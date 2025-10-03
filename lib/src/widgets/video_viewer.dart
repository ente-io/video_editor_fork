import 'package:flutter/material.dart';
import 'package:native_video_player/native_video_player.dart';
import 'package:video_editor/src/controller.dart';

class VideoViewer extends StatefulWidget {
  const VideoViewer({
    super.key,
    required this.controller,
    this.child,
    this.overrideAspectRatio,
  });

  final VideoEditorController controller;
  final Widget? child;
  final double? overrideAspectRatio;

  @override
  State<VideoViewer> createState() => _VideoViewerState();
}

class _VideoViewerState extends State<VideoViewer> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() {
    if (widget.controller.initialized && !_isInitialized) {
      // ignore: avoid_print
      print('[VideoViewer] Controller update: initialized=true, updating AspectRatio & overlays');
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final aspectRatio = widget.overrideAspectRatio ?? _calculateAspectRatio();

    return GestureDetector(
      onTap: () {
        final controller = widget.controller.nativeController;
        if (controller != null) {
          if (widget.controller.isPlaying) {
            controller.pause();
          } else {
            controller.play();
          }
        }
      },
      child: Center(
        child: Stack(
          children: [
            AspectRatio(
              aspectRatio: aspectRatio,
              child: NativeVideoPlayerView(
                onViewReady: (controller) async {
                  // ignore: avoid_print
                  print('[VideoViewer] onViewReady called');
                  widget.controller.setNativeController(controller);
                  // ignore: avoid_print
                  print('[VideoViewer] Native controller set');

                  // Initialize the video
                  // ignore: avoid_print
                  print('[VideoViewer] Calling initialize...');
                  await widget.controller.initialize();
                  // ignore: avoid_print
                  print('[VideoViewer] Initialize completed');
                },
              ),
            ),
            if (widget.child != null)
              AspectRatio(
                aspectRatio: aspectRatio,
                child: widget.child,
              ),
          ],
        ),
      ),
    );
  }

  double _calculateAspectRatio() {
    if (!_isInitialized) {
      return 16 / 9;
    }

    final dimension = widget.controller.videoDimension;
    if (dimension.width <= 0 || dimension.height <= 0) {
      return 16 / 9;
    }

    final quarterTurns = widget.controller.displayQuarterTurns;
    if (quarterTurns.isOdd) {
      return dimension.height / dimension.width;
    }
    return dimension.width / dimension.height;
  }
}
