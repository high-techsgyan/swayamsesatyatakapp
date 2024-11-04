import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class ShortPlayerService extends StatefulWidget {
  final String videoId;

  ShortPlayerService({required this.videoId});

  @override
  _ShortPlayerServiceState createState() => _ShortPlayerServiceState();
}

class _ShortPlayerServiceState extends State<ShortPlayerService> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();

    // Initialize the controller with the video ID
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: YoutubePlayerFlags(
        autoPlay: true,
        loop: true,
        hideControls: false,
        disableDragSeek: true,
        showLiveFullscreenButton: false,
        mute: false,
      ),
    );

    _controller.addListener(() {
      if (_controller.value.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Failed to load video: ${_controller.value.errorCode}')),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: YoutubePlayerBuilder(
        player: YoutubePlayer(
          controller: _controller,
          showVideoProgressIndicator: true,
          onReady: () {
            // Video is ready to play
          },
        ),
        builder: (context, player) {
          return Stack(
            children: [
              Positioned.fill(child: player), // Display video in full screen
              Positioned(
                top: 40,
                left: 16,
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
