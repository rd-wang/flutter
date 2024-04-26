import 'dart:math';

import 'package:exact/base/base/base_view.dart';
import 'package:exact/base/config/translations/strings_enum.dart';
import 'package:exact/base/notifications/utils/common_functions.dart'
    if (dart.library.html) 'package:exact/base/notifications/utils/common_web_functions.dart';
import 'package:exact/base/notifications/utils/media_player_central.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'controller_media.dart';

class MediaView extends RrView<MediaController> {
  MediaView({super.key});

  @override
  String setTitle() {
    return Strings.notification.tr;
  }

  @override
  bool isShowDefaultAppBar() {
    return false;
  }

  @override
  Widget buildContent(BuildContext context) {
    MediaQueryData mediaQueryData = MediaQuery.of(context);
    ThemeData themeData = Theme.of(context);

    // controller.isLighten.value = themeData.brightness == Brightness.light;
    controller.mainColor.value = controller.mainColor.value ?? themeData.colorScheme.background;
    controller.contrastColor.value = controller.contrastColor.value;

    double maxSize = max(mediaQueryData.size.width, mediaQueryData.size.height);

    double imageHeight = (maxSize - mediaQueryData.padding.top) * 0.45;
    double imageWidth = mediaQueryData.size.width * 0.8;

    return Theme(
        data: Theme.of(context).copyWith(
            primaryColor: controller.mainColor.value,
            // ignore: deprecated_member_use
            secondaryHeaderColor: controller.contrastColor.value,
            scaffoldBackgroundColor: controller.mainColor.value,
            disabledColor: controller.contrastColor.value?.withOpacity(0.25),
            textTheme: Theme.of(context)
                .textTheme
                .copyWith(
                  displayMedium: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  displaySmall: const TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
                  titleLarge: const TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
                )
                .apply(
                  bodyColor: controller.contrastColor.value,
                  decorationColor: controller.contrastColor.value,
                  displayColor: controller.contrastColor.value,
                ),
            colorScheme: controller.contrastColor.value != null
                ? ColorScheme.light(primary: controller.contrastColor.value!)
                : null,
            buttonTheme: ButtonThemeData(
                textTheme: ButtonTextTheme.accent,
                disabledColor: controller.contrastColor.value?.withOpacity(0.25),
                buttonColor: controller.contrastColor.value),
            iconTheme: IconThemeData(color: controller.contrastColor.value),
            sliderTheme: SliderThemeData(
                trackHeight: 4.0,
                activeTrackColor: controller.contrastColor.value,
                inactiveTrackColor: controller.contrastColor.value?.withOpacity(0.25),
                disabledInactiveTrackColor: controller.contrastColor.value?.withOpacity(0.25),
                disabledThumbColor: controller.contrastColor.value?.withOpacity(0.25),
                thumbColor: controller.contrastColor.value,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 15)),
            canvasColor: controller.mainColor.value),
        child: Builder(builder: (BuildContext context) {
          return Obx(() => Stack(
                children: <Widget>[
                  ListView(
                    padding: EdgeInsets.zero,
                    children: <Widget>[
                      Container(
                        constraints: BoxConstraints(
                          minHeight: mediaQueryData.size.height,
                          minWidth: mediaQueryData.size.width,
                        ),
                        child: Stack(
                          children: <Widget>[
                            _buildBackgroundMedia(mediaQueryData),
                            _buildMediaPlayerContent(
                                mediaQueryData, themeData, imageHeight, imageWidth, maxSize, context),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    top: mediaQueryData.padding.top + 10,
                    left: 10,
                    child: Container(
                      decoration: BoxDecoration(
                        color: controller.mainColor.value,
                        borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10),
                            bottomLeft: Radius.circular(10),
                            bottomRight: Radius.circular(10)),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            spreadRadius: 5,
                            blurRadius: 7,
                            offset: Offset(0, 3), // changes position of shadow
                          ),
                        ],
                      ),
                      width: 50,
                      height: 40,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ],
              ));
        }));
  }

  Padding _buildMediaPlayerContent(MediaQueryData mediaQueryData, ThemeData themeData, double imageHeight,
      double imageWidth, double maxSize, BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: mediaQueryData.padding.top + 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Stack(
            children: <Widget>[
              Opacity(
                  opacity: controller.closeCaptionActivated.value ? 0.08 : 1.0,
                  child: mediaArt(imageHeight, imageWidth, mediaQueryData, maxSize)),
              controller.closeCaptionActivated.value
                  ? mediaCloseCaption(themeData, imageHeight, imageWidth, mediaQueryData, maxSize)
                  : const SizedBox.shrink()
            ],
          ),
          mediaInfo(maxSize, mediaQueryData, context),
          mediaTrackBar(maxSize, mediaQueryData),
          mediaPlayerControllers(maxSize)
        ],
      ),
    );
  }

  Widget mediaCloseCaption(
      ThemeData themeData, double imageHeight, double imageWidth, MediaQueryData mediaQueryData, double maxSize) {
    TextStyle? textStyle = themeData.textTheme.titleLarge?.copyWith(color: controller.contrastColor.value);
    String subtitle = MediaPlayerCentral.getCloseCaption(controller.durationPlayed.value);

    return SizedBox(
        width: mediaQueryData.size.width * 0.8,
        height: imageHeight,
        child: Center(child: Text(subtitle, style: textStyle)));
  }

  Widget mediaPlayerControllers(double maxSize) {
    return Center(
      child: Container(
        height: maxSize * 0.15,
        width: maxSize * 0.8,
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            IconButton(
              icon: Icon(
                Icons.list,
                color: controller.contrastColor.value,
              ),
              iconSize: maxSize * 0.05,
              onPressed: null,
            ),
            IconButton(
              icon: const Icon(Icons.skip_previous),
              iconSize: maxSize * 0.05,
              onPressed: (controller.durationPlayed.value < MediaPlayerCentral.replayTolerance) &&
                      !MediaPlayerCentral.hasPreviousMedia
                  ? null
                  : () {
                      MediaPlayerCentral.previousMedia();
                      controller.durationPlayed.value = MediaPlayerCentral.currentDuration;
                    },
            ),
            Container(
              padding: const EdgeInsets.all(5),
              margin: EdgeInsets.zero,
              decoration: BoxDecoration(
                color: controller.contrastColor.value?.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: controller.isPlaying.value
                  ? IconButton(
                      icon: const Icon(Icons.pause_circle_filled),
                      padding: EdgeInsets.zero,
                      iconSize: maxSize * 0.08,
                      onPressed: !MediaPlayerCentral.hasAnyMedia ? null : () => MediaPlayerCentral.playPause(),
                    )
                  : IconButton(
                      icon: const Icon(Icons.play_circle_filled),
                      padding: EdgeInsets.zero,
                      iconSize: maxSize * 0.08,
                      onPressed: !MediaPlayerCentral.hasAnyMedia ? null : () => MediaPlayerCentral.playPause(),
                    ),
            ),
            IconButton(
              icon: const Icon(Icons.skip_next),
              iconSize: maxSize * 0.05,
              onPressed: !MediaPlayerCentral.hasNextMedia
                  ? null
                  : () {
                      MediaPlayerCentral.nextMedia();
                      controller.durationPlayed.value = MediaPlayerCentral.currentDuration;
                    },
            ),
            IconButton(
              icon: Icon(
                CupertinoIcons.shuffle_medium,
                color: controller.contrastColor.value,
              ),
              iconSize: maxSize * 0.05,
              onPressed: null,
            )
          ],
        ),
      ),
    );
  }

  Widget mediaTrackBar(double maxSize, MediaQueryData mediaQueryData) {
    double maxValue = controller.mediaLength?.inSeconds.toDouble() ?? 0.0;

    return Container(
      margin: EdgeInsets.zero,
      height: maxSize * 0.15,
      width: mediaQueryData.size.width,
      padding: EdgeInsets.only(left: mediaQueryData.size.width * 0.05, right: mediaQueryData.size.width * 0.05),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
              margin: EdgeInsets.zero,
              height: maxSize * 0.05,
              width: maxSize,
              child: Slider(
                  min: 0.0,
                  max: maxValue,
                  value: min(maxValue, controller.durationPlayed.value.inSeconds.toDouble() ?? 0.0),
                  onChangeStart: (value) {
                    controller.isDragging.value = true;
                  },
                  onChanged: (value) {
                    controller.durationPlayed.value = Duration(seconds: value.toInt());
                  },
                  onChangeEnd: (value) {
                    controller.isDragging.value = false;
                    MediaPlayerCentral.goTo(controller.durationPlayed.value);
                  })),
          const SizedBox(height: 5),
          Container(
            padding: EdgeInsets.zero,
            width: maxSize,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(printDuration(controller.durationPlayed.value),
                    style: TextStyle(color: controller.contrastColor.value)),
                Text(printDuration(controller.mediaLength! - controller.durationPlayed.value),
                    style: TextStyle(color: controller.contrastColor.value)),
                controller.hasCloseCaption.value
                    ? IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(Icons.closed_caption,
                            size: 48,
                            color: controller.closeCaptionActivated.value
                                ? controller.contrastColor.value
                                : controller.contrastColor.value?.withOpacity(0.5)),
                        onPressed: () =>
                            controller.closeCaptionActivated.value = !controller.closeCaptionActivated.value,
                      )
                    : const SizedBox(height: 47),
                Text(printDuration(controller.mediaLength), style: TextStyle(color: controller.contrastColor.value)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget mediaInfo(double maxSize, MediaQueryData mediaQueryData, BuildContext context) {
    return SizedBox(
      height: maxSize * 0.2 - mediaQueryData.padding.top,
      width: mediaQueryData.size.width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            controller.band ?? 'No track',
            style: Theme.of(context).textTheme.displayMedium,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: maxSize * 0.01),
          Text(
            controller.music ?? '',
            style: Theme.of(context).textTheme.displaySmall,
            textAlign: TextAlign.center,
          )
        ],
      ),
    );
  }

  Widget mediaArt(double imageHeight, double imageWidth, MediaQueryData mediaQueryData, double maxSize) {
    return Center(
      child: SizedBox(
          height: imageHeight,
          width: imageWidth,
          child: ShaderMask(
              shaderCallback: (rect) {
                return const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black, Colors.black, Colors.transparent],
                    stops: [0.0, 0.75, 0.98]).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height));
              },
              blendMode: BlendMode.dstIn,
              child: controller.diskImage == null
                  ? Container(
                      width: mediaQueryData.size.width,
                      height: (maxSize - mediaQueryData.padding.top) * 0.45,
                      color: controller.contrastColor.value?.withOpacity(0.65))
                  : Image(
                      //ProgressiveImage
                      //placeholder: AssetImage('assets/images/placeholder.gif'),
                      //thumbnail: AssetImage('assets/images/placeholder.gif'),
                      image: controller.diskImage!,
                      width: mediaQueryData.size.width,
                      height: (maxSize - mediaQueryData.padding.top) * 0.45,
                      fit: BoxFit.cover,
                    ))),
    );
  }

  Widget _buildBackgroundMedia(MediaQueryData mediaQueryData) {
    return Container(
      height: mediaQueryData.size.height,
      width: mediaQueryData.size.width,
      decoration: controller.diskImage == null
          ? null
          : BoxDecoration(
              image: DecorationImage(image: controller.diskImage!, fit: BoxFit.cover),
            ),
      child: Container(
        decoration: BoxDecoration(color: controller.mainColor.value?.withOpacity(0.93)),
      ),
    );
  }
}
