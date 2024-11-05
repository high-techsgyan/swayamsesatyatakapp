// video_screen.dart
import 'package:flutter/material.dart';
import 'video_list_tab.dart';
import 'short_grid_tab.dart';
import 'playlist_list_tab.dart';

class VideoScreen extends StatefulWidget {
  @override
  _VideoScreenState createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<dynamic> videos = [];
  final List<dynamic> shorts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchVideos();
    fetchShorts();
  }

  Future<void> fetchVideos() async {
    // Your fetchVideos implementation
  }

  Future<void> fetchShorts() async {
    // Your fetchShorts implementation
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: "Videos"),
            Tab(text: "Shorts"),
            Tab(text: "Playlists"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          VideoListTab(videos: videos, fetchVideos: fetchVideos),
          ShortGridTab(videos: shorts, fetchVideos: fetchShorts),
          PlaylistListTab(), // No need to pass playlists
        ],
      ),
    );
  }
}
