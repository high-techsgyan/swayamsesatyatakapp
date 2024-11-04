import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? user;
  String username = '';
  String userProfileImageUrl = '';

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
      if (snapshot.snapshot.value != null) {
        final userData = snapshot.snapshot.value as Map;

        setState(() {
          username = userData['username'] ?? 'Unknown User';
          userProfileImageUrl = userData['userprofile'] ?? '';
        });
      }
    }
  }

  // Logout the user and navigate to the login screen
  Future<void> _logout() async {
    await _auth.signOut();
    context.go('/login'); // Navigate to the login screen after logout
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile picture and username
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: userProfileImageUrl.isNotEmpty
                        ? NetworkImage(userProfileImageUrl)
                        : AssetImage('assets/images/default_profile.png')
                            as ImageProvider,
                  ),
                  SizedBox(height: 10),
                  Text(username, style: TextStyle(fontSize: 20)),
                ],
              ),
            ),
            SizedBox(height: 20),

            // List for navigation items

            Divider(),

            // Logout button
            Spacer(),
            ElevatedButton(
              onPressed: _logout,
              child: Text('Logout'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50), // Full-width button
              ),
            ),
          ],
        ),
      ),
    );
  }
}
