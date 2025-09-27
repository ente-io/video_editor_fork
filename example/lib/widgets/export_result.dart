import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:fraction/fraction.dart';
import 'package:path/path.dart' as path;
import 'package:native_video_player/native_video_player.dart';

Future<void> _getImageDimension(File file,
    {required Function(Size) onResult}) async {
  var decodedImage = await decodeImageFromList(file.readAsBytesSync());
  onResult(Size(decodedImage.width.toDouble(), decodedImage.height.toDouble()));
}

String _fileMBSize(File file) =>
    ' ${(file.lengthSync() / (1024 * 1024)).toStringAsFixed(1)} MB';

class VideoResultPopup extends StatefulWidget {
  const VideoResultPopup({super.key, required this.video});

  final File video;

  @override
  State<VideoResultPopup> createState() => _VideoResultPopupState();
}

class _VideoResultPopupState extends State<VideoResultPopup> {
  NativeVideoPlayerController? _controller;
  StreamSubscription<void>? _eventsSubscription;
  Size _fileDimension = Size.zero;
  late final bool _isGif =
      path.extension(widget.video.path).toLowerCase() == ".gif";
  late String _fileMbSize;

  @override
  void initState() {
    super.initState();
    if (_isGif) {
      _getImageDimension(
        widget.video,
        onResult: (d) => setState(() => _fileDimension = d),
      );
    } else {
      _initVideo();
    }
    _fileMbSize = _fileMBSize(widget.video);
  }

  void _onControllerReady(NativeVideoPlayerController controller) {
    _controller = controller;
    _loadVideo();
  }

  Future<void> _initVideo() async {
    if (_controller != null) {
      await _loadVideo();
    }
  }

  Future<void> _loadVideo() async {
    if (_controller == null) return;

    try {
      _eventsSubscription = _controller!.events.listen((event) {
        if (event is PlaybackReadyEvent) {
          final info = _controller?.videoInfo;
          _fileDimension = Size(
            info?.width.toDouble() ?? 0,
            info?.height.toDouble() ?? 0,
          );
          setState(() {});
        } else if (event is PlaybackEndedEvent) {
          _controller?.seekTo(Duration.zero);
          _controller?.play();
        }
      });

      await _controller!.loadVideo(
        VideoSource(
          path: widget.video.path,
          type: VideoSourceType.file,
        ),
      );

      await _controller!.play();
    } catch (e) {
      debugPrint('Error loading video: $e');
    }
  }

  @override
  void dispose() {
    _eventsSubscription?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Center(
        child: Stack(
          alignment: Alignment.bottomLeft,
          children: [
            AspectRatio(
              aspectRatio: _fileDimension.aspectRatio == 0
                  ? 1
                  : _fileDimension.aspectRatio,
              child: _isGif
                  ? Image.file(widget.video)
                  : NativeVideoPlayerView(onViewReady: _onControllerReady),
            ),
            Positioned(
              bottom: 0,
              child: FileDescription(
                description: {
                  'Video path': widget.video.path,
                  if (!_isGif)
                    'Video duration':
                        '${((_controller?.videoInfo?.duration.inMilliseconds ?? 0) / 1000).toStringAsFixed(2)}s',
                  'Video ratio': Fraction.fromDouble(_fileDimension.aspectRatio)
                      .reduce()
                      .toString(),
                  'Video dimension': _fileDimension.toString(),
                  'Video size': _fileMbSize,
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CoverResultPopup extends StatefulWidget {
  const CoverResultPopup({super.key, required this.cover});

  final File cover;

  @override
  State<CoverResultPopup> createState() => _CoverResultPopupState();
}

class _CoverResultPopupState extends State<CoverResultPopup> {
  late final Uint8List _imagebytes = widget.cover.readAsBytesSync();
  Size? _fileDimension;
  late String _fileMbSize;

  @override
  void initState() {
    super.initState();
    _getImageDimension(
      widget.cover,
      onResult: (d) => setState(() => _fileDimension = d),
    );
    _fileMbSize = _fileMBSize(widget.cover);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Center(
        child: Stack(
          children: [
            Image.memory(_imagebytes),
            Positioned(
              bottom: 0,
              child: FileDescription(
                description: {
                  'Cover path': widget.cover.path,
                  'Cover ratio':
                      Fraction.fromDouble(_fileDimension?.aspectRatio ?? 0)
                          .reduce()
                          .toString(),
                  'Cover dimension': _fileDimension.toString(),
                  'Cover size': _fileMbSize,
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FileDescription extends StatelessWidget {
  const FileDescription({super.key, required this.description});

  final Map<String, String> description;

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: const TextStyle(fontSize: 11),
      child: Container(
        width: MediaQuery.of(context).size.width - 60,
        padding: const EdgeInsets.all(10),
        color: Colors.black.withOpacity(0.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: description.entries
              .map(
                (entry) => Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${entry.key}: ',
                        style: const TextStyle(fontSize: 11),
                      ),
                      TextSpan(
                        text: entry.value,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
