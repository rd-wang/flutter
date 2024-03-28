import 'package:flutter/widgets.dart';
import 'meituan/shop/view/shop_page.dart';

class AppRoutes {
  static final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
    "/": (BuildContext context) => ShopPage(),
  };
}
