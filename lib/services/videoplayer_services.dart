import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:flutter/services.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;

  VideoPlayerScreen({required this.videoUrl});

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late YoutubePlayerController _controller;
  bool _isFullScreen = false;
  bool _isLoading = true; // Loading state

  @override
  void initState() {
    super.initState();

    // Extract video ID from the passed URL
    String videoId = YoutubePlayer.convertUrlToId(widget.videoUrl)!;

    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        disableDragSeek: false,
        controlsVisibleAtStart: true,
        hideThumbnail: true,
        enableCaption: false,
        showLiveFullscreenButton: false,
        useHybridComposition: true, // Improves performance on Android
      ),
    );

    _controller.addListener(_videoPlayerListener);
    // Removed automatic full-screen setting on init
  }

  @override
  void dispose() {
    _controller.dispose();
    _resetAppFullScreen(); // Reset full-screen mode when leaving the screen
    super.dispose();
  }

  // Listener to detect full-screen mode exit
  void _videoPlayerListener() {
    if (_controller.value.isFullScreen != _isFullScreen) {
      setState(() {
        _isFullScreen = _controller.value.isFullScreen;
      });

      // Exit full-screen app mode when exiting video full-screen
      if (!_isFullScreen) {
        _resetAppFullScreen(); // Ensure the app exits full-screen
      } else {
        _setAppFullScreen(); // Ensure the app enters full-screen when the video is full-screen
      }
    }

    // Handle loading state based on the controller value
    if (_controller.value.isReady) {
      setState(() {
        _isLoading = false; // Remove loading state when ready
      });
    }

    if (_controller.value.hasError) {
      print('Error occurred: ${_controller.value.errorCode}');
    }
  }

  // Set the app to full-screen mode
  void _setAppFullScreen() {
    SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky); // Full-screen app mode
  }

  // Reset the app to normal screen mode
  void _resetAppFullScreen() {
    SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge); // Reset app UI on exit
  }

  // Handle full-screen toggle for the video player
  void _toggleFullScreen() {
    _controller.toggleFullScreenMode();
  }

  // Automatically manage orientation and full-screen on device rotation
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isFullScreen) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isFullScreen
          ? null
          : AppBar(
              title: Text("YouTube Video Player"),
              leading: IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.of(context).pop();
                  if (_isFullScreen) {
                    _toggleFullScreen();
                  }
                },
              ),
            ),
      body: YoutubePlayerBuilder(
        player: YoutubePlayer(
          controller: _controller,
          showVideoProgressIndicator: true,
          progressIndicatorColor: Colors.red,
          onReady: () {
            // Remove loading state when player is ready
            setState(() {
              _isLoading = false;
            });
            print('Player is ready.');
          },
          onEnded: (YoutubeMetaData metaData) {
            print('Video ended.');
          },
        ),
        builder: (context, player) {
          return Stack(
            alignment: Alignment.center,
            children: [
              player,
              if (_isLoading)
                CircularProgressIndicator(), // Show single loading screen
            ],
          );
        },
      ),
    );
  }
}
