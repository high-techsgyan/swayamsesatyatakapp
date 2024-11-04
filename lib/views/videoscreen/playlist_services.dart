import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:swayamsesatyatak/services/videoplayer_services.dart';

class PlaylistScreen extends StatefulWidget {
  final String playlistId;

  PlaylistScreen({required this.playlistId});

  @override
  _PlaylistScreenState createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  List<dynamic> playlistVideos = [];

  @override
  void initState() {
    super.initState();
    fetchPlaylistVideos();
  }

  Future<void> fetchPlaylistVideos() async {
    final String apiKey = 'YOUR_YOUTUBE_API_KEY';
    final url = Uri.parse(
        'https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&playlistId=${widget.playlistId}&key=$apiKey');

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        playlistVideos = data['items'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Playlist")),
      body: ListView.builder(
        itemCount: playlistVideos.length,
        itemBuilder: (context, index) {
          final item = playlistVideos[index];
          return ListTile(
            leading:
                Image.network(item['snippet']['thumbnails']['default']['url']),
            title: Text(item['snippet']['title']),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VideoPlayerService(
                    videoId: item['snippet']['resourceId']['videoId'],
                    videoUrl: '',
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
