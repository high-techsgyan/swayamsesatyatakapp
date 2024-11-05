import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:swayamsesatyatak/services/videoplayer_services.dart';

class PlaylistVideoScreen extends StatefulWidget {
  final String playlistId;

  PlaylistVideoScreen({required this.playlistId});

  @override
  _PlaylistVideoScreenState createState() => _PlaylistVideoScreenState();
}

class _PlaylistVideoScreenState extends State<PlaylistVideoScreen> {
  List<Map<String, dynamic>> _videos = [];

  final String apiKey = 'AIzaSyCxoxeD0frAURWa_yXA-sN1bnKESvWKjGQ';

  @override
  void initState() {
    super.initState();
    _fetchPlaylistVideos();
  }

  Future<void> _fetchPlaylistVideos() async {
    final url =
        'https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&playlistId=${widget.playlistId}&maxResults=20&key=$apiKey';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final videoList = data['items'] as List;
      setState(() {
        _videos = videoList
            .map((video) => {
                  'title': video['snippet']['title'],
                  'thumbnail': video['snippet']['thumbnails']['default']['url'],
                  'videoId': video['snippet']['resourceId']['videoId'],
                })
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Playlist Videos")),
      body: _videos.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _videos.length,
              itemBuilder: (context, index) {
                final video = _videos[index];
                return ListTile(
                  leading: Image.network(video['thumbnail']),
                  title: Text(video['title']),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VideoPlayerScreen(
                            videoUrl:
                                'https://www.youtube.com/watch?v=${video['videoId']}'),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
