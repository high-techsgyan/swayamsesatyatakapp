import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:swayamsesatyatak/services/videoplayer_services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:share_plus/share_plus.dart';

class VideoListTab extends StatefulWidget {
  final List<dynamic> videos; // List of videos to display
  final Future<void> Function() fetchVideos; // Function to fetch videos

  const VideoListTab({
    required this.videos,
    required this.fetchVideos,
    Key? key,
  }) : super(key: key);

  @override
  _VideoListTabState createState() => _VideoListTabState();
}

class _VideoListTabState extends State<VideoListTab> {
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
          title: Text("Add Long Video"),
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
                final videoUrl = _videoUrlController.text.trim();
                if (videoUrl.isNotEmpty) {
                  try {
                    await FirebaseFirestore.instance
                        .collection('longvideos')
                        .add({'videoUrl': videoUrl});

                    _videoUrlController.clear();
                    _showSuccessDialog('Video added successfully');
                    Navigator.of(context).pop();
                    widget
                        .fetchVideos(); // Call fetchVideos to refresh the list
                  } catch (e) {
                    _showErrorDialog('Failed to add video: ${e.toString()}');
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please fill in all fields')),
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

  void _editTopic(BuildContext context, String longvideoId, String currentUrl) {
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
                  await FirebaseFirestore.instance
                      .collection('longvideos')
                      .doc(longvideoId)
                      .update({
                    'videoUrl': videoUrl,
                  });
                  _videoUrlController.clear();
                  _showSuccessDialog('Video updated successfully');
                  Navigator.of(context).pop();
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
            )
          ],
        );
      },
    );
  }

 Future<void> _deleteTopic(String longvideoId) async {
  try {
    await FirebaseFirestore.instance
        .collection('longvideos') // Make sure to specify the collection name
        .doc(longvideoId) // Reference the document by its ID
        .delete();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Long video deleted')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to delete video: $e')),
    );
  }
}

  void _shareVideo(String videoUrl) {
    Share.share('Check out this video: $videoUrl');
  }

  // ... existing code remains unchanged

  @override
 @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text("Videos"),
      actions: [
        if (isAdmin)
          IconButton(
            icon: Icon(Icons.add),
            onPressed: addVideo,
          ),
      ],
    ),
    body: StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('longvideos').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final longvideos = snapshot.data!.docs;

        if (longvideos.isEmpty) {
          return Center(child: Text("No long videos available"));
        }

        return ListView.builder(
          itemCount: longvideos.length,
          itemBuilder: (context, index) {
            final longvideo = longvideos[index];
            return FutureBuilder<Map<String, dynamic>>(
              future: _fetchVideoDetails(longvideo['videoUrl']),
              builder: (context, videoSnapshot) {
                if (videoSnapshot.connectionState == ConnectionState.waiting) {
                  // Show loading indicator while waiting for video details
                  return Card(
                    margin: EdgeInsets.all(8),
                    child: ListTile(
                      title: Text(longvideo['videoUrl']),
                      subtitle: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }

                if (videoSnapshot.hasError) {
                  // Handle error case by showing an error message
                  return Card(
                    margin: EdgeInsets.all(8),
                    child: ListTile(
                      title: Text(longvideo['videoUrl']),
                      subtitle: Text(
                          "Error loading video details: ${videoSnapshot.error}"),
                    ),
                  );
                }

                // Once video details are fully loaded, proceed to display them
                final videoDetails = videoSnapshot.data!;
                final thumbnailUrl = videoDetails['thumbnails']['default']['url'];
                final title = videoDetails['title'];
                final description = videoDetails['description'];

                // Show only the first 50 characters of the description
                final shortDescription = description.length > 50
                    ? description.substring(0, 50) + '...'
                    : description;

                return Card(
                  margin: EdgeInsets.all(8),
                  child: Padding(
                    padding: const EdgeInsets.all(0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Thumbnail as a tappable widget
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VideoPlayerScreen(
                                    videoUrl: longvideo['videoUrl']),
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(4)),
                            child: Image.network(
                              thumbnailUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 200,
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        // Title as a tappable widget (using the fetched title)
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VideoPlayerScreen(
                                    videoUrl: longvideo['videoUrl']),
                              ),
                            );
                          },
                          child: Text(
                            title, // Use the fetched title here
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        SizedBox(height: 4),
                        // Short description
                        Text(
                          shortDescription,
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        SizedBox(height: 8),
                        // Action buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (isAdmin)
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit),
                                    onPressed: () => _editTopic(context,
                                        longvideo.id, longvideo['videoUrl']),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete),
                                    onPressed: () =>
                                        _deleteTopic(longvideo.id),
                                  ),
                                ],
                              ),
                            IconButton(
                              icon: Icon(Icons.share),
                              onPressed: () {
                                _shareVideo(longvideo['videoUrl']); // Share the video URL
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
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
    final videoId = uri.pathSegments.last; // Extracting video ID
    final apiKey =
        'AIzaSyCxoxeD0frAURWa_yXA-sN1bnKESvWKjGQ'; // Replace with your YouTube API key
    final response = await http.get(Uri.parse(
        'https://www.googleapis.com/youtube/v3/videos?id=$videoId&key=$apiKey&part=snippet'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['items'].isNotEmpty) {
        return data['items'][0]['snippet'];
      } else {
        throw Exception('Video not found');
      }
    } else {
      throw Exception('Failed to load video details: ${response.reasonPhrase}');
    }
  }
}
