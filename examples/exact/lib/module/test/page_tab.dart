import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';

class TabBarPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Test3(),
    );
  }
}

@immutable
class Test3 extends StatelessWidget {
  Widget build(BuildContext context) {
    final List<String> _tabs = ['Tab 1', 'Tab 2'];
    return DefaultTabController(
      length: _tabs.length, // This is the number of tabs.
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              SliverOverlapAbsorber(
                handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                sliver: SliverAppBar(
                  title: const Text('Books'), // This is the title in the app bar.
                  floating: true,
                  pinned: true,
                  snap: false,
                  primary: true,
                  expandedHeight: 110,
                  forceElevated: innerBoxIsScrolled,
                  bottom: TabBar(
                    tabs: _tabs.map((String name) => Tab(text: name)).toList(),
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(children: [
            SafeArea(
              top: false,
              bottom: false,
              child: Builder(
                builder: (BuildContext context) {
                  return CustomScrollView(
                    key: PageStorageKey<String>("tab1"),
                    slivers: <Widget>[
                      SliverOverlapInjector(
                        handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.all(8.0),
                        sliver: ListTest3(),
                      ),
                    ],
                  );
                },
              ),
            ),
            Test4(),
          ]),
        ),
      ),
    );
  }
}

class Test4 extends StatelessWidget {
  Widget build(BuildContext context) {
    final List<String> _tabs = ['Tab 1', 'Tab 2'];
    return DefaultTabController(
      length: _tabs.length, // This is the number of tabs.
      child: Scaffold(
        body: NestedScrollViewScrollSynchronizer(
          child: NestedScrollView(
            headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
              return <Widget>[
                SliverOverlapAbsorber(
                  handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                  sliver: SliverAppBar(
                    title: const Text('Books'), // This is the title in the app bar.
                    floating: true,
                    pinned: true,
                    snap: false,
                    primary: true,
                    expandedHeight: 110,
                    forceElevated: innerBoxIsScrolled,
                    bottom: TabBar(
                      tabs: _tabs.map((String name) => Tab(text: name)).toList(),
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              children: _tabs.map((String name) {
                return SafeArea(
                  top: false,
                  bottom: false,
                  child: Builder(
                    builder: (BuildContext context) {
                      return CustomScrollView(
                        key: PageStorageKey<String>(name),
                        slivers: <Widget>[
                          SliverOverlapInjector(
                            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.all(8.0),
                            sliver: ListTest3(),
                          ),
                        ],
                      );
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

/// {@template nested_scroll_view_scroll_synchronizer}
/// Synchronizes the [child] header with the content.
///
/// Useful on scenarios where a [NestedScrollView] has a `TabBarView`.
///
/// **WARNING**: Make sure that the descendant [Scrollable]s are given a
/// [ScrollController] to prevent them from inheriting the
/// [NestedScrollView.controller].
///
/// **NOTE**: This aims to temporarily solve a known Flutter issue:
/// https://github.com/flutter/flutter/issues/81619
/// {@endtemplate}
class NestedScrollViewScrollSynchronizer extends StatelessWidget {
  /// {@macro nested_scroll_view_scroll_synchronizer}
  NestedScrollViewScrollSynchronizer({
    super.key,
    required this.child,
  }) : assert(
          child.controller != null,
          'NestedScrollView must have a controller.',
        );
  final NestedScrollView child;

  bool _onNotification(ScrollNotification notification) {
    final scrollController = child.controller!;
    if ((notification is ScrollUpdateNotification) &&
        (notification.dragDetails != null) &&
        (notification.metrics.axis == child.scrollDirection) &&
        scrollController.position.pixels != notification.metrics.pixels) {
      scrollController.jumpTo(
        scrollController.position.pixels + (notification.scrollDelta ?? 0),
      );
    }
    return true;
  }

  @override
  Widget build(BuildContext context) => NotificationListener<ScrollNotification>(
        onNotification: _onNotification,
        child: child,
      );
}

@immutable
class ListTest3 extends StatefulWidget {
  @override
  State<ListTest3> createState() => _ListTest3State();
}

class _ListTest3State extends State<ListTest3> {
  @override
  Widget build(BuildContext context) {
    return SliverFixedExtentList(
      itemExtent: 48.0,
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          return ListTile(
            tileColor: Color((Random().nextDouble() * 0xFFFFFF).toInt() << 0).withOpacity(1.0),
            title: Text('Item $index'),
          );
        },
        childCount: 30,
      ),
    );
  }
}
