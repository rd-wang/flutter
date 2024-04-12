import 'dart:math';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:exact/base/base/base_controller.dart';
import 'package:exact/base/notifications/notifications_util.dart';
import 'package:exact/base/notifications/utils/common_functions.dart'
    if (dart.library.html) 'package:exact/base/notifications/utils/common_web_functions.dart';
import 'package:exact/base/notifications/utils/media_model.dart';
import 'package:exact/base/notifications/utils/media_player_central.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:palette_generator/palette_generator.dart';

import 'repo_media.dart';

class MediaController extends RrController<MediaRepo> {
  ImageProvider? diskImage;

  var isDragging = false.obs;
  var closeCaptionActivated = false.obs;
  var hasCloseCaption = false.obs;

  var isLighten = false.obs;
  Rx<Color?> mainColor = Colors.white.obs;
  Rx<Color?> contrastColor = Colors.white.obs;

  String? band;
  String? music;
  Duration? mediaLength;
  var durationPlayed = Duration.zero.obs;

  var isPlaying = MediaPlayerCentral.isPlaying.obs;

  @override
  void onClose() {
    unlockScreenPortrait();

    MediaPlayerCentral.mediaSink.close();
    MediaPlayerCentral.progressSink.close();
    super.onClose();
  }

  @override
  onInit() {
    super.onInit();
    repo.loadNothing();
    if (!MediaPlayerCentral.hasAnyMedia) {
      MediaPlayerCentral.addAll([
        MediaModel(
            diskImagePath: 'asset://assets/images/rock-disc.jpg',
            colorCaptureSize: const Size(788, 800),
            bandName: 'Bright Sharp',
            trackName: 'Champagne Supernova',
            trackSize: const Duration(minutes: 4, seconds: 21)),
        MediaModel(
            diskImagePath: 'asset://assets/images/classic-disc.jpg',
            colorCaptureSize: const Size(500, 500),
            bandName: 'Best of Mozart',
            trackName: 'Allegro',
            trackSize: const Duration(minutes: 7, seconds: 41)),
        MediaModel(
            diskImagePath: 'asset://assets/images/remix-disc.jpg',
            colorCaptureSize: const Size(500, 500),
            bandName: 'Dj Allucard',
            trackName: '21st Century',
            trackSize: const Duration(minutes: 4, seconds: 59)),
        MediaModel(
            diskImagePath: 'asset://assets/images/dj-disc.jpg',
            colorCaptureSize: const Size(500, 500),
            bandName: 'Dj Brainiak',
            trackName: 'Speed of light',
            trackSize: const Duration(minutes: 4, seconds: 59)),
        MediaModel(
            diskImagePath: 'asset://assets/images/80s-disc.jpg',
            colorCaptureSize: const Size(500, 500),
            bandName: 'Back to the 80\'s',
            trackName: 'Disco revenge',
            trackSize: const Duration(minutes: 4, seconds: 59)),
        MediaModel(
            diskImagePath: 'asset://assets/images/old-disc.jpg',
            colorCaptureSize: const Size(500, 500),
            bandName: 'PeacefulMind',
            trackName: 'Never look at back',
            trackSize: const Duration(minutes: 4, seconds: 59)),
      ]);
    }

    lockScreenPortrait();

    // this is not part of notification system, but just a media player simulator instead
    MediaPlayerCentral.mediaStream.listen((media) {
      switch (MediaPlayerCentral.mediaLifeCycle) {
        case MediaLifeCycle.stopped:
          isPlaying.value = false;

          NotificationUtils.cancelNotification(100);
          break;

        case MediaLifeCycle.paused:
          isPlaying.value = false;

          NotificationUtils.updateNotificationMediaPlayer(
              100, media, durationPlayed.value, NotificationPlayState.paused);
          break;

        case MediaLifeCycle.playing:
          isPlaying.value = true;
          NotificationUtils.updateNotificationMediaPlayer(
              100, media, durationPlayed.value, NotificationPlayState.playing);
          break;
      }
    });

    MediaPlayerCentral.mediaStream.listen((media) {
      _updatePlayer(media: media);
    });

    MediaPlayerCentral.progressStream.listen((moment) {
      if (!isDragging.value) {
        durationPlayed.value = moment;
        Get.log("currenttime:${durationPlayed.value.toString()}");
      }
    });

    _updatePlayer(media: MediaPlayerCentral.currentMedia);
  }

  Future<void> _updatePlayer({MediaModel? media}) async {
    if (media != null) {
      diskImage = media.diskImage;
      band = media.bandName;
      music = media.trackName;
      mediaLength = media.trackSize;
      hasCloseCaption.value = media.closeCaption.isNotEmpty;
    } else {
      diskImage = null;
      band = null;
      music = null;
      mediaLength = null;
      durationPlayed.value = Duration.zero;
    }

    _updatePaletteGenerator(media: media);
  }

  Future<void> _updatePaletteGenerator({MediaModel? media}) async {
    late PaletteGenerator paletteGenerator;
    if (media != null) {
      paletteGenerator =
          await PaletteGenerator.fromImageProvider(media.diskImage, maximumColorCount: 5, size: media.colorCaptureSize);
    }

    if (media != null && paletteGenerator.paletteColors.isNotEmpty) {
      mainColor.value = paletteGenerator.dominantColor!.color;
      contrastColor.value =
          getContrastColor(mainColor.value!).withOpacity(0.85); //paletteGenerator.paletteColors.last.color;//
    } else {
      mainColor.value = null;
      contrastColor.value = null;
    }
  }

  bool computeLuminance(Color color) {
    return color.computeLuminance() > 0.5;
  }

  Color getContrastColor(Color color) {
    double y = (299 * color.red + 587 * color.green + 114 * color.blue) / 1000;
    return y >= 128 ? Colors.black : Colors.white;
  }

  Color getComplementaryColor(Color color) {
    int minColor = min(min(color.red, color.green), color.blue);
    int maxColor = max(max(color.red, color.green), color.blue);
    return Color.fromARGB(
      255,
      maxColor - minColor - color.red,
      maxColor - minColor - color.green,
      maxColor - minColor - color.blue,
    );
    /*
    double y = (299 * color.red + 587 * color.green + 114 * color.blue) / 1000;
    return y >= 128 ? Colors.black : Colors.white;
    */
  }
}
