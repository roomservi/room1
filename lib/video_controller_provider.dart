import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoControllerProvider extends ChangeNotifier {
  late final VideoPlayerController controller;
  bool _initialized = false;
  bool get isInitialized => _initialized;

  VideoControllerProvider() {
    controller =
        VideoPlayerController.asset('asset/images/sfondo.mp4')
          ..setLooping(true)
          ..setVolume(0.0)
          ..initialize().then((_) {
            controller.play();
            _initialized = true;
            notifyListeners();
          });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
