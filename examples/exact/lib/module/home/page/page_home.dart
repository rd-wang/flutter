import 'package:exact/base/base/base_view.dart';
import 'package:exact/base/config/theme/theme_extensions/header_container_theme_data.dart';
import 'package:exact/base/config/translations/strings_enum.dart';
import 'package:exact/base/service/global_service.dart';
import 'package:exact/module/home/page/page_feature_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../controller/controller_home.dart';

class HomePage extends RrView<FeaturePageController> {
  final ScrollController _scrollController = ScrollController();

  HomePage({super.key});

  @override
  bool isShowDefaultAppBar() {
    return false;
  }

  @override
  Widget buildContent(BuildContext context) {
    return Scaffold(
      floatingActionButton: buildFloatingButton(context),
      body: DefaultTabController(
        length: 3,
        child: NestedScrollView(
          controller: _scrollController,
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              buildSliverAppBar(),
              buildSliverToBoxAdapter(),
              buildSliverPersistentHeader(),
            ];
          },
          body: const TabBarView(
            children: <Widget>[
              FeatureTab(),
              Center(child: Text('Tab 2 Content')),
              Center(child: Text('Tab 3 Content')),
            ],
          ),
        ),
      ),
    );
  }

  SliverPersistentHeader buildSliverPersistentHeader() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverAppBarDelegate(
        TabBar(
          tabs: <Widget>[
            Tab(text: Strings.feature.tr),
            Tab(text: Strings.unKnow.tr),
            Tab(text: Strings.unKnow.tr),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter buildSliverToBoxAdapter() {
    return SliverToBoxAdapter(
      child: Container(
        height: 30,
        alignment: Alignment.center,
        color: Colors.black26,
        child: Text(
          "${Strings.welcome.tr} exact",
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  SliverAppBar buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: controller.expendHeight,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        titlePadding: EdgeInsets.zero,
        title: AnimatedBuilder(
            animation: _scrollController,
            builder: (context, _) {
              double percentage = 1.0;
              if (_scrollController.hasClients) {
                percentage = ((_scrollController.offset + kToolbarHeight) / controller.expendHeight).clamp(0.0, 1.0);
              }
              return Align(
                alignment: Alignment.lerp(Alignment.bottomLeft, Alignment.bottomCenter, percentage)!,
                child: Container(
                  margin: EdgeInsets.only(left: 16.h, bottom: 12.h, right: 16.h),
                  child: Text(Strings.expandableHeader.tr,
                      style: Theme.of(context).textTheme.headline6!.copyWith(color: Colors.white)),
                ),
              );
            }),
        background: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                "assets/images/home_bg.png",
                fit: BoxFit.cover,
              ),
            ),
            // ClipRect(
            //   child: BackdropFilter(
            //     filter: ImageFilter.blur(sigmaY: 1, sigmaX: 1),
            //     child: Container(),
            //   ),
            // )
          ],
        ),
      ),
    );
  }

  Column buildFloatingButton(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          margin: EdgeInsets.symmetric(horizontal: 16.h, vertical: 8.h),
          child: InkWell(
            onTap: () => Get.find<GlobalService>().changeTheme(),
            child: Ink(
              child: Container(
                height: 39.h,
                width: 39.h,
                decoration: Theme.of(context).extension<HeaderContainerThemeData>()?.decoration,
                child: SvgPicture.asset(
                  Get.isDarkMode ? 'assets/vectors/moon.svg' : 'assets/vectors/sun.svg',
                  fit: BoxFit.none,
                  colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                  height: 10,
                  width: 10,
                ),
              ),
            ),
          ),
        ),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 16.h, vertical: 8.h),
          child: InkWell(
            onTap: () => Get.find<GlobalService>().changeLanguage(),
            child: Ink(
              child: Container(
                height: 39.h,
                width: 39.h,
                decoration: Theme.of(context).extension<HeaderContainerThemeData>()?.decoration,
                child: SvgPicture.asset(
                  'assets/vectors/language.svg',
                  fit: BoxFit.none,
                  colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                  height: 10,
                  width: 10,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;
  Color? backgroundColor;

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return backgroundColor == oldDelegate.backgroundColor;
  }
}
