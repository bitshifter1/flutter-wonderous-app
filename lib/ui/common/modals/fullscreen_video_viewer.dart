import 'package:chewie/chewie.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:wonders/common_libs.dart';
import 'package:wonders/logic/common/platform_info.dart';
import 'package:video_player/video_player.dart';
import 'package:flutterpi_gstreamer_video_player/flutterpi_gstreamer_video_player.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class FullscreenVideoViewer extends StatefulWidget {
  const FullscreenVideoViewer({super.key, required this.id});
  final String id;

  @override
  State<FullscreenVideoViewer> createState() => _FullscreenVideoViewerState();
}

class _FullscreenVideoViewerState extends State<FullscreenVideoViewer> {
  bool isPlaying = false;

  VideoPlayerController? _controller;        // Nullable: initialized async
  ChewieController? _chewieController;       // Nullable: initialized async
  final yt = YoutubeExplode();

  bool get _enableVideo => PlatformInfo.isMobile;

  @override
  void initState() {
    super.initState();
    _initVideo(); // Start async setup
  }

  /// Initializes the YouTube stream and Chewie controller
  Future<void> _initVideo() async {
    try {

      // 1️⃣ Fetch YouTube manifest
      final manifest = await yt.videos.streamsClient.getManifest(widget.id,
       // You can also pass a list of preferred clients, otherwise the library will handle it:
      ytClients: [
        YoutubeApiClient.androidVr,
      ]);

      final streamUrl = manifest.muxed.bestQuality.url.toString();

      // 2️⃣ Create and initialize the video player
      final controller = VideoPlayerController.networkUrl(Uri.parse(streamUrl));
      await controller.initialize();

      // 3️⃣ Create Chewie controller AFTER initialization
      final chewie = ChewieController(
        videoPlayerController: controller,
        autoInitialize: true,
        autoPlay: true,
        looping: false,
        additionalOptions: (context) => [
          OptionItem(
            onTap: () async {
              final pos = controller.value.position;
              final dur = controller.value.duration;
              final newPos = pos + const Duration(seconds: 5);
              await controller.seekTo(newPos < dur ? newPos : dur);
            },
            iconData: Icons.arrow_right,
            title: 'Step Forward 5s',
          ),
          OptionItem(
            onTap: () async {
              final pos = controller.value.position;
              final newPos = pos - const Duration(seconds: 5);
              await controller.seekTo(
                newPos > Duration.zero ? newPos : Duration.zero,
              );
            },
            iconData: Icons.arrow_left,
            title: 'Step Backward 5s',
          ),
          OptionItem(
            onTap: () async {
              final pos = controller.value.position;
              final dur = controller.value.duration;
              final newPos = pos + const Duration(seconds: 30);
              await controller.seekTo(newPos < dur ? newPos : dur);
            },
            iconData: Icons.fast_forward_outlined,
            title: 'Fast Seek 30s',
          ),
        ],
      );

      // 4️⃣ Update state safely
      if (mounted) {
        setState(() {
          _controller = controller;
          _chewieController = chewie;
        });
      }

    } catch (e, st) {
      debugPrint("ERROR in _initVideo: $e\n$st");
    }
  }

  @override
  void dispose() {
    RawKeyboard.instance.removeListener(_handleKeyDown);
    _controller?.dispose();
    _chewieController?.dispose();
    yt.close();
    super.dispose();
  }

  Future<void> _handleKeyDown(RawKeyEvent value) async {
    if (value.repeat) return;
    if (value is RawKeyDownEvent) {
      final k = value.logicalKey;
      if (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.space) {
        if (_enableVideo && _controller != null) {
          final playing = _controller!.value.isPlaying;
          if (playing) {
            await _controller!.pause();
          } else {
            await _controller!.play();
          }
          setState(() => isPlaying = !playing);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double aspect = context.isLandscape
        ? MediaQuery.of(context).size.aspectRatio
        : 9 / 9;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: (PlatformInfo.isMobile || kIsWeb)
                ? (_chewieController != null &&
                        _chewieController!
                            .videoPlayerController.value.isInitialized)
                    ? AspectRatio(
                        aspectRatio: _chewieController!
                            .videoPlayerController.value.aspectRatio,
                        child: Chewie(controller: _chewieController!),
                      )
                    : const CircularProgressIndicator()
                : const Placeholder(),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all($styles.insets.md),
              child: PointerInterceptor(child: BackBtn()),
            ),
          ),
        ],
      ),
    );
  }
}

