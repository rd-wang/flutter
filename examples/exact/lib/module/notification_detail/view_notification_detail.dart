import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:exact/base/base/base_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:palette_generator/palette_generator.dart';

import '../../base/config/translations/strings_enum.dart';
import 'controller_notification_detail.dart';

class NotificationView extends RrView<NotificationDetailPageController> {
  NotificationView({super.key});

  ReceivedAction receivedAction = Get.arguments["notification_action"];

  bool get hasTitle => receivedAction.title?.isNotEmpty ?? false;

  bool get hasBody => receivedAction.body?.isNotEmpty ?? false;

  bool get hasLargeIcon => receivedAction.largeIconImage != null;

  bool get hasBigPicture => receivedAction.bigPictureImage != null;

  double bigPictureSize = 0.0;
  double largeIconSize = 0.0;
  var isTotallyCollapsed = false.obs;
  var bigPictureIsPredominantlyWhite = true.obs;

  ScrollController scrollController = ScrollController();

  Future<bool> isImagePredominantlyWhite(ImageProvider imageProvider) async {
    final paletteGenerator = await PaletteGenerator.fromImageProvider(imageProvider);
    final dominantColor = paletteGenerator.dominantColor?.color ?? Colors.transparent;
    return dominantColor.computeLuminance() > 0.5;
  }

  @override
  String setTitle() {
    return Strings.notification.tr;
  }

  @override
  Widget buildContent(BuildContext context) {
    scrollController.addListener(_scrollListener);

    if (hasBigPicture) {
      isImagePredominantlyWhite(receivedAction.bigPictureImage!)
          .then((isPredominantlyWhite) => bigPictureIsPredominantlyWhite.value = isPredominantlyWhite);
    }
    bigPictureSize = MediaQuery.of(context).size.height * .4;
    largeIconSize = MediaQuery.of(context).size.height * (hasBigPicture ? .16 : .2);

    if (!hasBigPicture) {
      isTotallyCollapsed.value = true;
    }

    return Scaffold(
      body: CustomScrollView(
        controller: scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: <Widget>[
          SliverAppBar(
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.arrow_back_ios_rounded,
                color: isTotallyCollapsed.value || bigPictureIsPredominantlyWhite.value ? Colors.black : Colors.white,
              ),
            ),
            systemOverlayStyle: isTotallyCollapsed.value || bigPictureIsPredominantlyWhite.value
                ? SystemUiOverlayStyle.dark
                : SystemUiOverlayStyle.light,
            expandedHeight: hasBigPicture
                ? bigPictureSize + (hasLargeIcon ? 40 : 0)
                : (hasLargeIcon)
                    ? largeIconSize + 10
                    : MediaQuery.of(context).padding.top + 28,
            backgroundColor: Colors.transparent,
            stretch: true,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              centerTitle: true,
              expandedTitleScale: 1,
              collapseMode: CollapseMode.pin,
              title: (!hasLargeIcon)
                  ? null
                  : Stack(children: [
                      Positioned(
                        bottom: 0,
                        left: 16,
                        right: 16,
                        child: Row(
                          mainAxisAlignment: hasBigPicture ? MainAxisAlignment.start : MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: largeIconSize,
                              width: largeIconSize,
                              child: ClipRRect(
                                borderRadius: BorderRadius.all(Radius.circular(largeIconSize)),
                                child: FadeInImage(
                                  placeholder: const NetworkImage(
                                      'https://cdn.syncfusion.com/content/images/common/placeholder.gif'),
                                  image: receivedAction.largeIconImage!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]),
              background: hasBigPicture
                  ? Padding(
                      padding: EdgeInsets.only(bottom: hasLargeIcon ? 60 : 20),
                      child: FadeInImage(
                        placeholder:
                            const NetworkImage('https://cdn.syncfusion.com/content/images/common/placeholder.gif'),
                        height: bigPictureSize,
                        width: MediaQuery.of(context).size.width,
                        image: receivedAction.bigPictureImage!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : null,
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate(
              [
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0, left: 20, right: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(children: [
                          if (hasTitle)
                            TextSpan(
                              text: receivedAction.title!,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          if (hasBody)
                            WidgetSpan(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  top: hasTitle ? 16.0 : 0.0,
                                ),
                                child: SizedBox(
                                    width: MediaQuery.of(context).size.width,
                                    child: Text(receivedAction.bodyWithoutHtml ?? '',
                                        style: Theme.of(context).textTheme.bodyText2)),
                              ),
                            ),
                        ]),
                      ),
                    ],
                  ),
                ),
                Container(
                  color: Colors.black12,
                  padding: const EdgeInsets.all(20),
                  width: MediaQuery.of(context).size.width,
                  child: Text(receivedAction.toString()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _scrollListener() {
    bool pastScrollLimit = scrollController.position.pixels >= scrollController.position.maxScrollExtent - 240;

    if (!hasBigPicture) {
      isTotallyCollapsed.value = true;
      return;
    }

    if (isTotallyCollapsed.value) {
      if (!pastScrollLimit) {
        isTotallyCollapsed.value = false;
      }
    } else {
      if (pastScrollLimit) {
        isTotallyCollapsed.value = true;
      }
    }
  }
}
