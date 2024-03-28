import 'package:flutter/widgets.dart';
import 'home/page/page_home.dart';
import 'meituan/shop/view/shop_page.dart';

class AppRoutes {
  static final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
    "/": (BuildContext context) => HomePage(),
    "/shop": (BuildContext context) => ShopPage(),
  };
}
