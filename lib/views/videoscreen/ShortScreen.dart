import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/short_service.dart'; // Ensure you have the correct import path

class ShortScreen extends StatefulWidget {
  final String channelId;

  ShortScreen({required this.channelId});

  @override
  _ShortScreenState createState() => _ShortScreenState();
}

class _ShortScreenState extends State<ShortScreen> {
  List<dynamic> shorts = [];
  String? nextPageToken;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchShorts();
  }

  Future<void> fetchShorts() async {
    if (isLoading) return;

    setState(() => isLoading = true);

    final url = Uri.parse(
      'https://www.googleapis.com/youtube/v3/search?part=snippet&channelId=${widget.channelId}&type=video&videoDuration=short&maxResults=20&key=YOUR_API_KEY&pageToken=${nextPageToken ?? ''}'
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          shorts.addAll(data['items']);
          nextPageToken = data['nextPageToken'];
          isLoading = false;
        });
      } else {
        print("Error fetching shorts: ${response.statusCode}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error fetching shorts: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shorts.isEmpty && isLoading
          ? Center(child: CircularProgressIndicator())
          : PageView.builder(
              scrollDirection: Axis.vertical,
              itemCount: shorts.length,
              onPageChanged: (index) {
                if (index == shorts.length - 1) fetchShorts();
              },
              itemBuilder: (context, index) {
                final item = shorts[index];
                final videoId = item['id']['videoId'];

                // Check if videoId is available
                if (videoId != null) {
                  return ShortPlayerService(videoId: videoId);
                } else {
                  return Center(child: Text('Video ID not available'));
                }
              },
            ),
    );
  }
}
