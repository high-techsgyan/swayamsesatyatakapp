import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class ShortVideoPlayerService extends StatefulWidget {
  final int initialIndex;

  ShortVideoPlayerService({required this.initialIndex});

  @override
  _ShortVideoPlayerServiceState createState() =>
      _ShortVideoPlayerServiceState();
}

class _ShortVideoPlayerServiceState extends State<ShortVideoPlayerService> {
  late PageController _pageController;
  List<DocumentSnapshot> _videos = [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
    _currentIndex = widget.initialIndex;
    _loadVideos();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadVideos() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('Shortvideos').get();
    setState(() {
      _videos = snapshot.docs;
    });
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<bool> _onWillPop() async {
    return true; // Returning true to allow pop
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _videos.isEmpty
            ? Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Video ${_currentIndex + 1} of ${_videos.length}',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _videos.length,
                      scrollDirection: Axis.vertical,
                      onPageChanged: _onPageChanged,
                      itemBuilder: (context, index) {
                        if (index < _videos.length) {
                          return _ShortVideoPlayer(
                            videoUrl: _videos[index]['videoUrl'],
                            key: ValueKey(_videos[index].id), // Ensures unique key
                          );
                        } else {
                          return Center(child: Text("No more videos"));
                        }
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ShortVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const _ShortVideoPlayer({required this.videoUrl, Key? key}) : super(key: key);

  @override
  _ShortVideoPlayerState createState() => _ShortVideoPlayerState();
}

class _ShortVideoPlayerState extends State<_ShortVideoPlayer> {
  late YoutubePlayerController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    String videoId = YoutubePlayer.convertUrlToId(widget.videoUrl)!;

    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: YoutubePlayerFlags(
        autoPlay: true,
        loop: false,
        controlsVisibleAtStart: false,
        hideControls: true,
      ),
    );

    _controller.addListener(() {
      if (_controller.value.isReady && _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.pause();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: YoutubePlayer(
            controller: _controller,
            showVideoProgressIndicator: false,
            onReady: () {
              setState(() {
                _isLoading = false;
              });
            },
            bottomActions: [], // Hides any bottom controls for fullscreen effect
          ),
        ),
        if (_isLoading)
          Center(
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }
}
