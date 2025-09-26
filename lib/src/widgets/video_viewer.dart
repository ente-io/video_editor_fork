import 'package:flutter/material.dart';
import 'package:video_editor/src/controller.dart';
import 'package:video_player/video_player.dart';

class VideoViewer extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final aspectRatio =
        overrideAspectRatio ?? controller.video.value.aspectRatio;

    return GestureDetector(
      onTap: () {
        if (controller.video.value.isPlaying) {
          controller.video.pause();
        } else {
          controller.video.play();
        }
      },
      child: Center(
        child: Stack(
          children: [
            AspectRatio(
              aspectRatio: aspectRatio,
              child: VideoPlayer(controller.video),
            ),
            if (child != null)
              AspectRatio(
                aspectRatio: aspectRatio,
                child: child,
              ),
          ],
        ),
      ),
    );
  }
}
