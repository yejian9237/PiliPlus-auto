import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:PiliPlus/pages/car/car_home_page.dart';
import 'package:PiliPlus/pages/car/car_audio_page.dart';
import 'package:PiliPlus/pages/car/car_video_page.dart';
import 'package:PiliPlus/pages/car/landscape/car_home_page_landscape.dart';
import 'package:PiliPlus/pages/car/landscape/car_audio_page_landscape.dart';
import 'package:PiliPlus/pages/car/landscape/car_video_page_landscape.dart';
import 'package:PiliPlus/pages/car/widgets/car_adaptive_layout.dart';

class CarPageRouter {
  static const String home = '/car/home';
  static const String audio = '/car/audio';
  static const String video = '/car/video';

  static Widget buildHomePage() {
    return CarLayoutBuilder(
      builder: (context, orientation) {
        if (orientation == DeviceOrientation.landscape) {
          return const CarHomePageLandscape();
        }
        return const CarHomePage();
      },
    );
  }

  static Widget buildAudioPage() {
    return CarLayoutBuilder(
      builder: (context, orientation) {
        if (orientation == DeviceOrientation.landscape) {
          return const CarAudioPageLandscape();
        }
        return const CarAudioPage();
      },
    );
  }

  static Widget buildVideoPage({
    required String videoType,
    String? avid,
    String? bvid,
    int? cid,
    String? p,
  }) {
    return CarLayoutBuilder(
      builder: (context, orientation) {
        if (orientation == DeviceOrientation.landscape) {
          return CarVideoPageLandscape(
            videoType: videoType,
            avid: avid,
            bvid: bvid,
            cid: cid,
            p: p,
          );
        }
        return CarVideoPage(
          videoType: videoType,
          avid: avid,
          bvid: bvid,
          cid: cid,
          p: p,
        );
      },
    );
  }

  static void goHome() {
    Get.offAllNamed(home);
  }

  static void goAudio() {
    Get.toNamed(audio);
  }

  static void goVideo({
    required String videoType,
    String? avid,
    String? bvid,
    int? cid,
    String? p,
  }) {
    Get.toNamed(video, arguments: {
      'videoType': videoType,
      'avid': avid,
      'bvid': bvid,
      'cid': cid,
      'p': p,
    });
  }
}

class CarHomePageWithAutoRotate extends StatelessWidget {
  const CarHomePageWithAutoRotate({super.key});

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        if (orientation == Orientation.landscape) {
          return const CarHomePageLandscape();
        }
        return const CarHomePage();
      },
    );
  }
}

class CarAudioPageWithAutoRotate extends StatelessWidget {
  const CarAudioPageWithAutoRotate({super.key});

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        if (orientation == Orientation.landscape) {
          return const CarAudioPageLandscape();
        }
        return const CarAudioPage();
      },
    );
  }
}

class CarVideoPageWithAutoRotate extends StatefulWidget {
  final String videoType;
  final String? avid;
  final String? bvid;
  final int? cid;
  final String? p;

  const CarVideoPageWithAutoRotate({
    super.key,
    required this.videoType,
    this.avid,
    this.bvid,
    this.cid,
    this.p,
  });

  @override
  State<CarVideoPageWithAutoRotate> createState() => _CarVideoPageWithAutoRotateState();
}

class _CarVideoPageWithAutoRotateState extends State<CarVideoPageWithAutoRotate> {
  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        if (orientation == Orientation.landscape) {
          return CarVideoPageLandscape(
            videoType: widget.videoType,
            avid: widget.avid,
            bvid: widget.bvid,
            cid: widget.cid,
            p: widget.p,
          );
        }
        return CarVideoPage(
          videoType: widget.videoType,
          avid: widget.avid,
          bvid: widget.bvid,
          cid: widget.cid,
          p: widget.p,
        );
      },
    );
  }
}
