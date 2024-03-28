// 写一个statefulWidget,渲染一个gridview,gridview里面的item是一个card,card里面有一个图片和一个文字
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:main/home/controller/controller_home.dart';
import 'package:main/home/page/page_feature_tab.dart';

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);
  final HomePageController c = Get.put(HomePageController());

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    //返回一个嵌套滚动的布局包括伸缩的header
    return Scaffold(
      body: DefaultTabController(
        length: 3,
        child: NestedScrollView(
          controller: _scrollController,
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              SliverAppBar(
                backgroundColor: Colors.blueAccent,
                expandedHeight: 200.0,
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
                          percentage = (_scrollController.offset / 200.0).clamp(0.0, 1.0);
                        }
                        return Align(
                          alignment: Alignment.lerp(Alignment.bottomLeft, Alignment.bottomCenter, percentage)!,
                          child: Container(
                            margin: EdgeInsets.only(left: 16.h, bottom: 12.h, right: 16.h),
                            child: Text("Expandable Header",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20.0,
                                )),
                          ),
                        );
                      }),
                  background: Stack(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: Image.network(
                          "https://picsum.photos/350/400",
                          fit: BoxFit.cover,
                        ),
                      ),
                      ClipRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaY: 6, sigmaX: 6),
                          child: Container(),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  height: 200,
                  color: Colors.blue.withOpacity(0.3),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    tabs: <Widget>[
                      Tab(text: 'Feature'),
                      Tab(text: 'Tab 2'),
                      Tab(text: 'Tab 3'),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            // This is the TabBarView
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
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.black, // You can change the color as you like
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
