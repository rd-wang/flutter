import 'package:exact/base/base/base_view.dart';
import 'package:exact/base/notifications/utils/common_functions.dart'
    if (dart.library.html) 'package:exact/base/notifications/utils/common_web_functions.dart';
import 'package:exact/widget/rounded_button.dart';
import 'package:exact/widget/single_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:vibration/vibration.dart';

import '../../base/config/translations/strings_enum.dart';
import 'controller_call.dart';

class CallView extends RrView<CallController> {
  CallView({super.key});

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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image
          Image(
            image: controller.receivedAction.largeIconImage!,
            fit: BoxFit.cover,
          ),
          // Black Layer
          const DecoratedBox(
            decoration: BoxDecoration(color: Colors.black45),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    controller.receivedAction.payload?['username']?.replaceAll(r'\s+', r'\n') ?? 'Unknown',
                    maxLines: 4,
                    style: themeData.textTheme.headline3?.copyWith(color: Colors.white),
                  ),
                  Text(
                    controller.timer == null
                        ? 'Incoming call'
                        : 'Call in progress: ${printDuration(controller.secondsElapsed.value)}',
                    style: themeData.textTheme.headline6
                        ?.copyWith(color: Colors.white54, fontSize: controller.timer == null ? 20 : 12),
                  ),
                  const SizedBox(height: 50),
                  controller.timer == null
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            TextButton(
                                onPressed: () {},
                                style: ButtonStyle(
                                  overlayColor: MaterialStateProperty.all<Color>(Colors.white12),
                                ),
                                child: Column(
                                  children: [
                                    const Icon(FontAwesomeIcons.solidClock, color: Colors.white54),
                                    Text('Reminder me',
                                        style: themeData.textTheme.headline6
                                            ?.copyWith(color: Colors.white54, fontSize: 12, height: 2))
                                  ],
                                )),
                            const SizedBox(),
                            TextButton(
                              onPressed: () {},
                              style: ButtonStyle(
                                overlayColor: MaterialStateProperty.all<Color>(Colors.white12),
                              ),
                              child: Column(
                                children: [
                                  const Icon(FontAwesomeIcons.solidEnvelope, color: Colors.white54),
                                  Text('Message',
                                      style: themeData.textTheme.headline6
                                          ?.copyWith(color: Colors.white54, fontSize: 12, height: 2))
                                ],
                              ),
                            )
                          ],
                        )
                      : const SizedBox(),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.all(Radius.circular(45)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: controller.timer == null
                          ? [
                              RoundedButton(
                                press: controller.finishCall,
                                color: Colors.red,
                                icon: const Icon(FontAwesomeIcons.phoneAlt, color: Colors.white),
                              ),
                              SingleSliderToConfirm(
                                onConfirmation: () {
                                  Vibration.vibrate(duration: 100);
                                  controller.startCallingTimer();
                                },
                                width: mediaQueryData.size.width * 0.55,
                                backgroundColor: Colors.white60,
                                text: 'Slide to Talk',
                                stickToEnd: true,
                                textStyle: Theme.of(context)
                                    .textTheme
                                    .headline6
                                    ?.copyWith(color: Colors.white, fontSize: mediaQueryData.size.width * 0.05),
                                sliderButtonContent: RoundedButton(
                                  press: () {},
                                  color: Colors.white,
                                  icon: const Icon(FontAwesomeIcons.phoneAlt, color: Colors.green),
                                ),
                              )
                            ]
                          : [
                              RoundedButton(
                                press: () {},
                                color: Colors.white,
                                icon: const Icon(FontAwesomeIcons.microphone, color: Colors.black),
                              ),
                              RoundedButton(
                                press: controller.finishCall,
                                color: Colors.red,
                                icon: const Icon(FontAwesomeIcons.phoneAlt, color: Colors.white),
                              ),
                              RoundedButton(
                                press: () {},
                                color: Colors.white,
                                icon: const Icon(FontAwesomeIcons.volumeUp, color: Colors.black),
                              ),
                            ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
