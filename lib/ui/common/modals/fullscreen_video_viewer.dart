import 'package:flutter/foundation.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:wonders/common_libs.dart';
import 'package:wonders/logic/common/platform_info.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart'; 

class FullscreenVideoViewer extends StatefulWidget {
  const FullscreenVideoViewer({super.key, required this.id});
  final String id;

  @override
  State<FullscreenVideoViewer> createState() => _FullscreenVideoViewerState();
}

class _FullscreenVideoViewerState extends State<FullscreenVideoViewer> {
  bool isPlaying = false;
  // Create a [VideoController] to handle video output from [Player].
  late final player = Player();
  late final controller = VideoController(player);
  bool get _enableVideo => PlatformInfo.isMobile;

  @override
  void initState() {
    super.initState();
    appLogic.supportedOrientationsOverride = [Axis.horizontal, Axis.vertical];
    RawKeyboard.instance.addListener(_handleKeyDown);
    print("HELLLLO https://www.youtube.com/watch?v=${widget.id}");
    final playable = Media("https://user-images.githubusercontent.com/28951144/229373695-22f88f13-d18f-4288-9bf1-c3e078d83722.mp4");
    player.open(playable, play: false);
    player.stream.playing.listen(
     (bool playing) {
       if (playing) {
         isPlaying = true;
       } else {
         isPlaying = false;
       }
     },
   );
  }

  @override
  void dispose() {
    // when view closes, remove the override
    appLogic.supportedOrientationsOverride = null;
    RawKeyboard.instance.removeListener(_handleKeyDown);
    player.dispose();
    super.dispose();
  }

  Future<void> _handleKeyDown(RawKeyEvent value) async {
    if (value.repeat) return;
    if (value is RawKeyDownEvent) {
      final k = value.logicalKey;
      if (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.space) {
        if (_enableVideo) {
          if (isPlaying) {
            player.pause();
          } else {
            player.play();
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double aspect = context.isLandscape ? MediaQuery.of(context).size.aspectRatio : 9 / 9;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: (PlatformInfo.isMobile || kIsWeb)
                ? Video(controller: controller)
                : Placeholder(),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all($styles.insets.md),
              // Wrap btn in a PointerInterceptor to prevent the HTML video player from intercepting the pointer (https://pub.dev/packages/pointer_interceptor)
              child: PointerInterceptor(
                child: const BackBtn(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
