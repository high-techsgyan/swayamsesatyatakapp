import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:package_info_plus/package_info_plus.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    // Start the navigation process after a delay
    Future.delayed(const Duration(seconds: 2), _checkForUpdates);
  }

  Future<void> _checkForUpdates() async {
    try {
      final PackageInfo info = await PackageInfo.fromPlatform();
      final currentVersion = info.version;
      final latestVersionData = await _fetchLatestVersionFromSupabase();

      if (latestVersionData != null) {
        final latestVersion = latestVersionData['version'];
        if (currentVersion != latestVersion) {
          _showUpdateDialog(latestVersionData['url']);
        } else {
          _navigateToNextScreen();
        }
      } else {
        _showErrorDialog('Failed to check for updates. No data returned.');
      }
    } catch (e) {
      _showErrorDialog('Error: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>?> _fetchLatestVersionFromSupabase() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://gksxshcgikuirnfhbxbw.supabase.co/rest/v1/app_versions?select=*'),
        headers: {
          'Authorization':
              'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imdrc3hzaGNnaWt1aXJuZmhieGJ3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzA2ODYzMTAsImV4cCI6MjA0NjI2MjMxMH0.5xuyPQsCgxfMmzbQFofMvcWG-TE7P3lwuIYoa8_ZOm0',
          'apikey':
              'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imdrc3hzaGNnaWt1aXJuZmhieGJ3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzA2ODYzMTAsImV4cCI6MjA0NjI2MjMxMH0.5xuyPQsCgxfMmzbQFofMvcWG-TE7P3lwuIYoa8_ZOm0',
        },
      );

      // Debugging response
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.isNotEmpty) {
          return data[0]; // Get the latest version data
        } else {
          _showErrorDialog('No version data found in Supabase.');
        }
      } else {
        _showErrorDialog('Failed to fetch update: ${response.reasonPhrase}');
      }
    } catch (error) {
      _showErrorDialog('Network error: ${error.toString()}');
    }
    return null;
  }

 void _showUpdateDialog(String apkUrl) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Update Available'),
        content: const Text('A new version of the app is available. Would you like to update?'),
        actions: [
          TextButton(
            child: const Text('Update'),
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/updatePage', extra: apkUrl); // Pass the URL correctly
            },
          ),
          TextButton(
            child: const Text('Later'),
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToNextScreen(); // Navigate to the next screen without updating
            },
          ),
        ],
      );
    },
  );
}

  void _navigateToNextScreen() {
    User? user = _auth.currentUser;
    if (user != null) {
      context.go('/home');
    } else {
      context.go('/walkthrough');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToNextScreen();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/swayam_se_satya_tak.png', width: 200),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
