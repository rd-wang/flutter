import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Future<T?> showBottomSheetDialog<T>({
  required BuildContext context,
  required Widget body,
  bool scrollControlled = true,
  Color? bodyColor,
  EdgeInsets? bodyPadding,
  BorderRadius? borderRadius,
  double? maxHeight,
  bool isDismissible = true,
  bool enableDrag = true,
}) {
  const radius = Radius.circular(16);
  bodyColor ??= Theme.of(context).scaffoldBackgroundColor;
  bodyPadding ??= const EdgeInsets.all(0);
  borderRadius ??= const BorderRadius.only(topLeft: radius, topRight: radius);
  bool landscape = (MediaQuery.of(context).size.height - MediaQuery.of(context).size.width < 0) && !kIsWeb;
  return showModalBottomSheet(
      enableDrag: enableDrag,
      isDismissible: isDismissible,
      context: context,
      elevation: 0,
      backgroundColor: landscape ? Colors.transparent : bodyColor,
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      barrierColor: Colors.black.withOpacity(landscape ? 0 : 0.5),
      constraints: BoxConstraints(
        // maxHeight: maxHeight ?? (MediaQuery.of(context).size.height - MediaQuery.of(context).viewPadding.top),
        maxHeight: maxHeight ?? (landscape ? 1.sh : 0.9.sh),
        minHeight: 0.2.sh,
      ),
      isScrollControlled: scrollControlled,
      builder: (ctx) => landscape
          ? GestureDetector(
              onTap: () {
                if (isDismissible) {
                  Navigator.pop(context);
                }
              },
              child: Container(
                width: MediaQuery.of(context).size.width,
                color: Colors.transparent,
                padding: EdgeInsets.only(
                  left: bodyPadding!.left,
                  top: bodyPadding.top,
                  right: bodyPadding.right,
                  bottom: bodyPadding.bottom,
                ),
                alignment: Alignment.bottomRight,
                child: body,
              ),
            )
          : body);
}
