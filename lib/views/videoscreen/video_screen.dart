import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:swayamsesatyatak/services/videoplayer_services.dart';
import 'package:swayamsesatyatak/views/videoscreen/ShortScreen.dart';
import 'package:swayamsesatyatak/views/videoscreen/playlist_services.dart';

class VideoScreen extends StatefulWidget {
  @override
  _VideoScreenState createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String apiKey = 'AIzaSyCXAJ_pyHyYGV13ezxz2eORAnrQ6IUj-Yo';
  final String channelId1 = 'UCDzD-oB-xEiTAXRS09GK3Sw';
  final String channelId2 = 'UCACY7hCe_G_8NqnFHu0no3Q';
  List<dynamic> videos = [];
  List<dynamic> shorts = [];
  List<dynamic> playlists = [];

  String? nextPageTokenVideos;
  String? nextPageTokenShorts;
  String? nextPageTokenPlaylists;

  bool isLoadingVideos = false;
  bool isLoadingShorts = false;
  bool isLoadingPlaylists = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchVideos();
    fetchShorts();
    fetchPlaylists();
  }

  Future<void> fetchVideos() async {
    if (isLoadingVideos) return;
    setState(() => isLoadingVideos = true);

    final url = Uri.parse(
        'https://www.googleapis.com/youtube/v3/search?part=snippet&channelId=$channelId1&channelId=$channelId2&type=video&key=$apiKey&pageToken=${nextPageTokenVideos ?? ''}');

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        videos.addAll(data['items']);
        nextPageTokenVideos = data['nextPageToken'];
        isLoadingVideos = false;
      });
    }
  }

  Future<void> fetchShorts() async {
    if (isLoadingShorts) return;
    setState(() => isLoadingShorts = true);

    final url = Uri.parse(
        'https://www.googleapis.com/youtube/v3/search?part=snippet&channelId=$channelId1&channelId=$channelId2&type=video&videoDuration=short&key=$apiKey&pageToken=${nextPageTokenShorts ?? ''}');

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        shorts.addAll(data['items']);
        nextPageTokenShorts = data['nextPageToken'];
        isLoadingShorts = false;
      });
    }
  }

  Future<void> fetchPlaylists() async {
    if (isLoadingPlaylists) return;
    setState(() => isLoadingPlaylists = true);

    final url = Uri.parse(
        'https://www.googleapis.com/youtube/v3/playlists?part=snippet&channelId=$channelId1&channelId=$channelId2&key=$apiKey&pageToken=${nextPageTokenPlaylists ?? ''}');

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        playlists.addAll(data['items']);
        nextPageTokenPlaylists = data['nextPageToken'];
        isLoadingPlaylists = false;
      });
    }
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
          buildVideoList(),
          buildShortGrid(),
          buildPlaylistList(),
        ],
      ),
    );
  }

  Widget buildVideoList() {
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
          fetchVideos();
        }
        return true;
      },
      child: ListView.builder(
        itemCount: videos.length,
        itemBuilder: (context, index) {
          final item = videos[index];
          final videoId = item['id']['videoId'];
          final videoUrl =
              'https://www.youtube.com/watch?v=$videoId'; // Create a valid URL

          return ListTile(
            leading:
                Image.network(item['snippet']['thumbnails']['default']['url']),
            title: Text(item['snippet']['title']),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VideoPlayerService(
                    videoUrl: videoUrl,
                    videoId: videoId, // Use videoId as well if needed
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Updated buildShortGrid method in VideoScreen
  Widget buildShortGrid() {
    return GridView.builder(
      gridDelegate:
          SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
      itemCount: shorts.length,
      itemBuilder: (context, index) {
        final item = shorts[index];
        // ignore: unused_local_variable
        final videoId = item['id']['videoId'];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ShortScreen(channelId: channelId1),
              ),
            );
          },
          child: Container(
            padding: EdgeInsets.all(8.0),
            child:
                Image.network(item['snippet']['thumbnails']['default']['url']),
          ),
        );
      },
    );
  }

  Widget buildPlaylistList() {
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
          fetchPlaylists();
        }
        return true;
      },
      child: ListView.builder(
        itemCount: playlists.length,
        itemBuilder: (context, index) {
          final item = playlists[index];
          return ListTile(
            leading:
                Image.network(item['snippet']['thumbnails']['default']['url']),
            title: Text(item['snippet']['title']),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlaylistScreen(playlistId: item['id']),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
