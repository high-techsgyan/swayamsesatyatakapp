import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:swayamsesatyatak/services/short_service.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:share_plus/share_plus.dart';

class ShortGridTab extends StatefulWidget {
  final Future<void> Function() fetchVideos;

  const ShortGridTab(
      {required this.fetchVideos, Key? key, required List videos})
      : super(key: key);

  @override
  _VideoListTabState createState() => _VideoListTabState();
}

class _VideoListTabState extends State<ShortGridTab> {
  final _videoUrlController = TextEditingController();
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref('Users');
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    checkIfAdmin();
  }

  Future<void> checkIfAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final DatabaseReference userRef = _usersRef.child(user.uid);
      final DatabaseEvent event = await userRef.once();
      final DataSnapshot userSnapshot = event.snapshot;

      if (userSnapshot.exists) {
        final userData = userSnapshot.value as Map<dynamic, dynamic>;
        if (userData['isAdmin'] == true) {
          setState(() {
            isAdmin = true;
          });
        }
      } else {
        _showErrorDialog('User not found.');
      }
    } else {
      _showErrorDialog('User is not logged in.');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> addVideo() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Add Short Video"),
          content: TextField(
            controller: _videoUrlController,
            decoration: InputDecoration(labelText: 'Video URL'),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final videoUrl = _videoUrlController.text.trim();
                if (videoUrl.isNotEmpty) {
                  try {
                    // Check if the video is short (under 60 seconds)
                    final videoDetails = await _fetchVideoDetails(videoUrl);
                    final duration = videoDetails['duration'] ?? 0;
                    if (duration <= 60) {
                      await FirebaseFirestore.instance
                          .collection('Shortvideos')
                          .add({'videoUrl': videoUrl});
                      _videoUrlController.clear();
                      _showSuccessDialog('Video added successfully');
                      Navigator.of(context).pop();
                      widget.fetchVideos();
                    } else {
                      _showErrorDialog(
                          'Only short videos (under 60 seconds) are allowed.');
                    }
                  } catch (e) {
                    _showErrorDialog('Failed to add video: ${e.toString()}');
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please fill in the video URL')),
                  );
                }
              },
              child: Text("Add"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  void _editTopic(
      BuildContext context, String shortvideoId, String currentUrl) {
    _videoUrlController.text = currentUrl;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Edit Video"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _videoUrlController,
                decoration: InputDecoration(labelText: 'Video URL'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final videoUrl = _videoUrlController.text;
                if (videoUrl.isNotEmpty) {
                  try {
                    await FirebaseFirestore.instance
                        .collection(
                            'Shortvideos') // Ensure this matches the collection name
                        .doc(shortvideoId)
                        .update({
                      'videoUrl': videoUrl,
                    });
                    _videoUrlController.clear();
                    _showSuccessDialog('Video updated successfully');
                    Navigator.of(context).pop();
                    widget.fetchVideos(); // Refresh the video list
                  } catch (e) {
                    _showErrorDialog('Failed to update video: ${e.toString()}');
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please fill in all fields')),
                  );
                }
              },
              child: Text("Update"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteTopic(String shortvideoId) async {
    try {
      await FirebaseFirestore.instance
          .collection(
              'Shortvideos') // Make sure to specify the correct collection name
          .doc(shortvideoId) // Reference the document by its ID
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Short video deleted')),
      );
      widget.fetchVideos(); // Refresh the video list after deletion
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete video: ${e.toString()}')),
      );
    }
  }

  void _shareVideo(String videoUrl) {
    Share.share('Check out this video: $videoUrl');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Short Videos"),
        actions: [
          if (isAdmin)
            IconButton(
              icon: Icon(Icons.add),
              onPressed: addVideo,
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance.collection('Shortvideos').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final shortVideos = snapshot.data!.docs;
          if (shortVideos.isEmpty) {
            return Center(child: Text("No short videos available"));
          }

          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 16 / 9,
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
            ),
            itemCount: shortVideos.length,
            itemBuilder: (context, index) {
              final shortVideo = shortVideos[index];
              return FutureBuilder<Map<String, dynamic>>(
                future: _fetchVideoDetails(shortVideo['videoUrl']),
                builder: (context, videoSnapshot) {
                  if (videoSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return Card(
                        child: Center(child: CircularProgressIndicator()));
                  }

                  if (videoSnapshot.hasError) {
                    return Card(
                      child: Center(child: Text("Error loading video details")),
                    );
                  }

                  final videoDetails = videoSnapshot.data!;
                  final thumbnailUrl =
                      videoDetails['thumbnails']['default']['url'];

                  return Card(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ShortVideoPlayerService(
                                  initialIndex:
                                      index, // Pass the current index here
                                ),
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(8)),
                            child: Image.network(
                              thumbnailUrl,
                              fit: BoxFit.cover,
                              height: 100,
                              width: double.infinity,
                            ),
                          ),
                        ),
                        if (isAdmin)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit),
                                onPressed: () => _editTopic(context,
                                    shortVideo.id, shortVideo['videoUrl']),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () => _deleteTopic(shortVideo.id),
                              ),
                            ],
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchVideoDetails(String videoUrl) async {
    final uri = Uri.parse(videoUrl);
    final videoId = uri.pathSegments.last;
    final apiKey = 'AIzaSyCxoxeD0frAURWa_yXA-sN1bnKESvWKjGQ';
    final response = await http.get(Uri.parse(
        'https://www.googleapis.com/youtube/v3/videos?id=$videoId&key=$apiKey&part=snippet,contentDetails'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['items'].isNotEmpty) {
        final videoData = data['items'][0];
        final duration =
            _parseDuration(videoData['contentDetails']['duration']);
        return {
          'thumbnails': videoData['snippet']['thumbnails'],
          'duration': duration,
        };
      } else {
        throw Exception('Video not found');
      }
    } else {
      throw Exception('Failed to load video details: ${response.reasonPhrase}');
    }
  }

  int _parseDuration(String duration) {
    final regex = RegExp(r'PT(\d+H)?(\d+M)?(\d+S)?');
    final match = regex.firstMatch(duration);
    if (match != null) {
      final hours =
          int.tryParse(match.group(1)?.replaceAll('H', '') ?? '0') ?? 0;
      final minutes =
          int.tryParse(match.group(2)?.replaceAll('M', '') ?? '0') ?? 0;
      final seconds =
          int.tryParse(match.group(3)?.replaceAll('S', '') ?? '0') ?? 0;
      return hours * 3600 + minutes * 60 + seconds;
    }
    return 0;
  }
}
