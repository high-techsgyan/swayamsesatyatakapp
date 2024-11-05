import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart'; // Import Firebase Database
import 'package:swayamsesatyatak/views/videoscreen/playlist_services.dart';

class PlaylistListTab extends StatefulWidget {
  @override
  _PlaylistListTabState createState() => _PlaylistListTabState();
}

class _PlaylistListTabState extends State<PlaylistListTab> {
  final TextEditingController _playlistUrlController = TextEditingController();
  final String apiKey = 'AIzaSyCxoxeD0frAURWa_yXA-sN1bnKESvWKjGQ';
  final DatabaseReference _usersRef = FirebaseDatabase.instance
      .ref('Users'); // Replace with your YouTube API Key
  bool _isAdmin = false; // To store admin status

  @override
  void initState() {
    super.initState();
    checkIfAdmin(); // Check admin status on initialization
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
            _isAdmin = true;
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

  Future<void> addPlaylist() async {
    final playlistUrl = _playlistUrlController.text.trim();
    if (playlistUrl.isEmpty) return;

    try {
      final playlistId = _extractPlaylistId(playlistUrl);
      final details = await _fetchPlaylistDetails(playlistId);

      await FirebaseFirestore.instance.collection('playlists').add({
        'playlistId': playlistId,
        'title': details['title'],
        'thumbnail': details['thumbnail'],
        'videoCount': details['videoCount'],
      });

      _playlistUrlController.clear();
    } catch (e) {
      print("Error adding playlist: $e");
    }
  }

  Future<Map<String, dynamic>> _fetchPlaylistDetails(String playlistId) async {
    final url =
        'https://www.googleapis.com/youtube/v3/playlists?part=snippet,contentDetails&id=$playlistId&key=$apiKey';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final playlist = data['items'][0];
      return {
        'title': playlist['snippet']['title'],
        'thumbnail': playlist['snippet']['thumbnails']['default']['url'],
        'videoCount': playlist['contentDetails']['itemCount']
      };
    } else {
      throw Exception("Failed to fetch playlist details");
    }
  }

  String _extractPlaylistId(String url) {
    final uri = Uri.parse(url);
    return uri.queryParameters['list'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Playlists")),
      body: Column(
        children: [
          // Show input field and button only if user is admin
          if (_isAdmin)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _playlistUrlController,
                decoration: InputDecoration(
                  labelText: 'Playlist URL',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.add),
                    onPressed: addPlaylist,
                  ),
                ),
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('playlists')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final playlists = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlists[index];
                    return ListTile(
                      leading: Image.network(playlist['thumbnail']),
                      title: Text(playlist['title']),
                      subtitle: Text('Videos: ${playlist['videoCount']}'),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PlaylistVideoScreen(
                              playlistId: playlist['playlistId']),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
