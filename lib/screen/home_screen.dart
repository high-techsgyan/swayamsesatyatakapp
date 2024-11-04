import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:swayamsesatyatak/views/book_views.dart';
import 'package:swayamsesatyatak/views/communityviews/community_screen.dart';
import 'package:swayamsesatyatak/views/dashboard_screen.dart';
import 'package:swayamsesatyatak/views/post_views.dart';
import 'package:swayamsesatyatak/views/videoscreen/video_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? user;
  String username = '';
  String userProfileImageUrl = '';
  int _selectedIndex = 0; // Track the selected tab index
  // ignore: unused_field
  String _searchQuery = '';
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // Fetch user data from Firebase Realtime Database
  Future<void> _fetchUserData() async {
    user = _auth.currentUser;
    if (user != null) {
      DatabaseReference userRef =
          FirebaseDatabase.instance.ref('Users/${user!.uid}');
      final snapshot = await userRef.once();
      final userData = snapshot.snapshot.value as Map;

      setState(() {
        username = userData['username'] ?? 'Unknown User';
        userProfileImageUrl = userData['userprofile'] ?? '';
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Update the selected index
      _searchResults.clear(); // Clear search results when changing tabs
      _searchQuery = ''; // Clear search query
    });
  }

  // Function to search for data in Firebase
  Future<void> _search(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
      });
      return;
    }

    List<Map<String, dynamic>> results = [];

    // Convert query to lowercase for case-insensitive search
    String lowercaseQuery = query.toLowerCase();

    // Search in Firebase Realtime Database (Users)
    DatabaseReference usersRef = FirebaseDatabase.instance.ref('Users');
    final usersSnapshot = await usersRef.once();
    final usersData = usersSnapshot.snapshot.value as Map?;

    // Check if usersData is not null and filter results
    if (usersData != null) {
      usersData.forEach((key, value) {
        if (value['username'] != null &&
            value['username'].toLowerCase().contains(lowercaseQuery)) {
          results.add({'name': value['username'], 'type': 'User'});
        }
      });
    }

    // Search in Firestore (courses -> subjects -> chapters -> topics)
    QuerySnapshot coursesSnapshot = await FirebaseFirestore.instance
        .collection('courses')
        .where('name', isGreaterThanOrEqualTo: lowercaseQuery)
        .get();

    QuerySnapshot subjectsSnapshot = await FirebaseFirestore.instance
        .collectionGroup(
            'subjects') // Using collection group to search all subjects
        .where('name', isGreaterThanOrEqualTo: lowercaseQuery)
        .get();

    QuerySnapshot chaptersSnapshot = await FirebaseFirestore.instance
        .collectionGroup('chapters') // Searching all chapters
        .where('name', isGreaterThanOrEqualTo: lowercaseQuery)
        .get();

    QuerySnapshot topicsSnapshot = await FirebaseFirestore.instance
        .collectionGroup('topics') // Searching all topics
        .where('name', isGreaterThanOrEqualTo: lowercaseQuery)
        .get();

    // Add Firestore results
    for (var doc in coursesSnapshot.docs) {
      results.add({
        'name': doc['name'],
        'type': 'Course',
      });
    }

    for (var doc in subjectsSnapshot.docs) {
      results.add({
        'name': doc['name'],
        'type': 'Subject',
      });
    }

    for (var doc in chaptersSnapshot.docs) {
      results.add({
        'name': doc['name'],
        'type': 'Chapter',
      });
    }

    for (var doc in topicsSnapshot.docs) {
      results.add({
        'name': doc['name'],
        'type': 'Topic',
      });
    }

    setState(() {
      _searchResults = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(''),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearchDialog();
            },
          ),
          IconButton(
            icon: CircleAvatar(
              backgroundImage: userProfileImageUrl.isNotEmpty
                  ? NetworkImage(userProfileImageUrl)
                  : AssetImage('assets/images/swayam_se_satya_tak.png')
                      as ImageProvider,
            ),
            onPressed: () {
              context.push('/profile'); // Navigate to Profile Screen
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Colors.purple),
              accountName: Text(username),
              accountEmail: Text(user?.email ?? ''),
              currentAccountPicture: CircleAvatar(
                backgroundImage: userProfileImageUrl.isNotEmpty
                    ? NetworkImage(userProfileImageUrl)
                    : AssetImage('assets/images/bomjva_logo.png')
                        as ImageProvider,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: Text('Home'),
              onTap: () {
                Navigator.pop(context);
                _onItemTapped(0); // Select Home tab
              },
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                context.push('/profile');
              },
            ),
          ],
        ),
      ),
      body: _getBody(), // Show the appropriate screen based on selected index
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.blue, // Set background color
        selectedItemColor:
            const Color.fromARGB(255, 186, 0, 223), // Set selected item color
        unselectedItemColor:
            const Color.fromARGB(179, 5, 57, 199), // Set unselected item color
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Community',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.subscriptions),
            label: 'Videos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.newspaper),
            label: 'post',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Books'),
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: 'Dashboard'),
        ],
        currentIndex: _selectedIndex, // Set the current index
        onTap: _onItemTapped, // Handle item taps
      ),
    );
  }

  Widget _getBody() {
    switch (_selectedIndex) {
      case 0:
        return CommunityScreen(); // Replace with your actual CommunityScreen widget
      case 1:
        return VideoScreen(); // Replace with your actual ClassScreen widget
      case 2:
        return PostListScreen(); // Replace with your actual BookScreen widget
      case 3:
        return BookScreen(); // Replace with your actual NoteScreen widget
      case 4:
        return DashboardScreen(); // Replace with your actual DashboardScreen widget
      default:
        return CommunityScreen();
    }
  }

  void showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          // To update dialog UI when search results change
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Search'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    onChanged: (query) {
                      setState(() {
                        _searchQuery = query; // Update query
                      });
                      _search(query); // Trigger search as the user types
                    },
                    decoration: InputDecoration(hintText: 'Search...'),
                  ),
                  SizedBox(height: 10),
                  // Display search results
                  Expanded(
                    child: _searchResults.isNotEmpty
                        ? ListView.builder(
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final result = _searchResults[index];
                              return ListTile(
                                title: Text(result['name']),
                                subtitle: Text(result['type']),
                              );
                            },
                          )
                        : Center(child: Text('No search results found.')),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
