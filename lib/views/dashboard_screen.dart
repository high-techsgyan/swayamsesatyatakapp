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

  // Navigate to User Donation screen
  void _navigateToUserDonation() {
    context.push('/userdonation'); // Adjust the route as per your setup
  }

  // Navigate to User Books screen
  void _navigateToUserBooks() {
    context.push('/userbooks'); // Adjust the route as per your setup
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

            // Navigation buttons
            ElevatedButton(
              onPressed: _navigateToUserDonation,
              child: Text('Donation'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50), // Full-width button
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _navigateToUserBooks,
              child: Text('Books'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50), // Full-width button
              ),
            ),

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
